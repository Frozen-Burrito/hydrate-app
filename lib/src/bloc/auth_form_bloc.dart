import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:hydrate_app/src/api/auth_api.dart';
import 'package:hydrate_app/src/exceptions/api_exception.dart';
import 'package:hydrate_app/src/models/enums/auth_action_type.dart';
import 'package:hydrate_app/src/models/user_credentials.dart';
import 'package:hydrate_app/src/services/profile_service.dart';
import 'package:hydrate_app/src/utils/auth_validators.dart';

/// Un componente BLoC que puede recibir los valores de cada campo de un 
/// formulario de autenticación, validarlos, enviar el formulario, y 
/// determinar si el formulariotiene errores, está cargando, o fue enviado
/// con éxito.
/// 
/// Para realizar la autenticación, utiliza la API web de Hydrate.
class AuthFormBloc {
  /// Una referencia al formulario.
  final formKey = GlobalKey<FormState>();

  /// Un cliente HTTP con la implementación de la API web de Hydrate 
  /// para la autenticación y autorización de usuarios.
  final _authApi = AuthApi();

  final AuthActionType _authAction;

  String _username= "";
  String _email= "";
  String _password = "";

  bool _isLoading = false;
  AuthResult _formState = AuthResult.none;

  UsernameError _usernameError = UsernameError.none;
  UsernameError _emailError = UsernameError.none;
  PasswordError _passwordError = PasswordError.none;
  PasswordError _passwordConfirmError = PasswordError.none;

  /// Es __true__ cuando el formulario fue enviado, o está obteniendo
  /// información.
  Stream<bool> get isLoading => _loadingController.stream;
  /// Contiene el resultado de cada envío del formulario.
  Stream<AuthResult> get formState => _authResultController.stream;

  /// Si el valor de nombre de usuario recibido tiene un error de 
  /// validación, este stream tendrá ese [UsernameError].
  Stream<UsernameError> get usernameError => _usernameErrorController.stream;
  Stream<UsernameError> get emailError => _emailErrorController.stream;
  Stream<PasswordError> get passwordError => _passwordErrorController.stream;
  Stream<PasswordError> get passwordConfirmError => _passwordConfirmErrorController.stream;

  /// Recibe los valores para el nombre de usuario. Este sink debería ser usado
  /// cuando las credenciales acepten nombre de usuario o email.
  Sink<String> get usernameSink => _usernameController.sink;

  /// Recibe los valores para el correo electrónico.
  Sink<String> get emailSink => _emailController.sink;

  /// Recibe los valores para el password, si es necesario para el 
  /// [AuthActionType] de este componente.
  Sink<String> get passwordSink => _passwordController.sink;

  /// Recibe los valores para la confirmación de password, si la hay.
  Sink<String> get passwordConfirmSink => _passwordConfirmController.sink;
  
  /// Permite enviar el formulario, pasando el [BuildContext] del mismo.
  Sink<BuildContext> get formSubmit => _formSubmitController.sink;

  final StreamController<BuildContext> _formSubmitController = StreamController();

  final StreamController<String> _usernameController = StreamController();
  final StreamController<String> _emailController = StreamController();
  final StreamController<String> _passwordController = StreamController();
  final StreamController<String> _passwordConfirmController = StreamController();

  final StreamController<AuthResult> _authResultController = StreamController.broadcast();
  final StreamController<bool> _loadingController = StreamController.broadcast();

  final StreamController<UsernameError> _usernameErrorController = StreamController.broadcast();
  final StreamController<UsernameError> _emailErrorController = StreamController.broadcast();
  final StreamController<PasswordError> _passwordErrorController = StreamController.broadcast();
  final StreamController<PasswordError> _passwordConfirmErrorController = StreamController.broadcast();

  /// Crea una nueva instancia, dedicada a mantener el estado de 
  /// un formulario de inicio de sesión usando email (o nombre de 
  /// usuario) y password.
  factory AuthFormBloc.emailSignIn() {
    return AuthFormBloc._internal(
      authAction: AuthActionType.signIn,
    );
  }

  /// Crea una nueva instancia, dedicada a mantener el estado de un 
  /// formulario de creación de cuenta con email. 
  factory AuthFormBloc.emailSignUp() {
    return AuthFormBloc._internal(
      authAction: AuthActionType.signUp,
    );
  }

  AuthFormBloc._internal({ required AuthActionType authAction}) 
    : _authAction = authAction {
    // Send current value to each new subscription on listen.
    _authResultController.onListen = () {
      _authResultController.add(_formState);
    };

    _loadingController.onListen = () {
      _loadingController.add(_isLoading);
    };

    _usernameErrorController.onListen = () {
      _usernameErrorController.add(_usernameError);
    };

    _emailErrorController.onListen = () {
      _emailErrorController.add(_emailError);
    };

    _passwordErrorController.onListen = () {
      _passwordErrorController.add(_passwordError);
    };

    _passwordConfirmErrorController.onListen = () {
      _passwordConfirmErrorController.add(_passwordConfirmError);
    };

    // Listen for input on streams connected to public sinks.
    _formSubmitController.stream.listen(_submit);

    _usernameController.stream.listen(_handleUsernameChange);
    _emailController.stream.listen(_handleEmailChange);

    _passwordController.stream.listen(_handlePasswordChange);
    _passwordConfirmController.stream.listen(_handlePasswordConfirmChange);
  }

  Future<void> _submit(BuildContext context) async {

    _isLoading = true;
    _loadingController.add(_isLoading);
    
    _formState = AuthResult.none;
    _authResultController.add(_formState);

    final isFormInInvalidSate = !(formKey.currentState?.validate() ?? false);

    // Si el formulario no está en un estado válido, interrumpir el submit
    // inmediatamente.
    if (isFormInInvalidSate) return;

    try {
      // Intentar autenticar al usuario.
      final authToken = await _sendAuthRequest();

      // Obtener o crear un perfil para la cuenta de usuario. 
      final profileProvider = Provider.of<ProfileService>(context, listen: false);

      final linkResult = await profileProvider.handleAccountLink(
        authToken,
        wasAccountJustCreated: _authAction == AuthActionType.signUp,
      );

      switch (linkResult) { 
        case AccountLinkResult.localProfileInSync:
          _authResultController.add(AuthResult.authenticated);
          break;
        case AccountLinkResult.requiresInitialData:
          _authResultController.add(AuthResult.newProfileCreated);
          break;
        case AccountLinkResult.error:
          _authResultController.add(AuthResult.serviceUnavailable);
          break;
      }
      
    } on ApiException catch (ex) {
      
      switch (ex.type) {
        case ApiErrorType.unreachableHost:
        case ApiErrorType.serviceUnavailable:
          _authResultController.add(AuthResult.serviceUnavailable);
          break;
        case ApiErrorType.requestError:
          // Existe un error en las credenciales del usuario.
          _authResultController.add(AuthResult.credentialsError);
          break;
        default:
          print("Warning: API exception type was not handled (${ex.message})");
          _authResultController.add(AuthResult.serviceUnavailable);
          break;
      }
      
    } finally {
      _isLoading = false;
      _loadingController.add(false);
    }
  }

  /// Envía una solicitud de autenticación al servicio web, usando el 
  /// [AuthActionType] de este componente para especificar el tipo de 
  /// solicitud.
  /// 
  /// Este método puede lanzar un [ApiException] si ocurre un problema al
  /// enviar la petición, o la respuesta es una de error.
  Future<String> _sendAuthRequest() async {

    final authCredentials = UserCredentials.forAction(
      _authAction, 
      username: _username, 
      email: _email, 
      password: _password
    );
      
    final authToken = _authAction == AuthActionType.signIn
      ? await _authApi.signInWithEmail(authCredentials)
      : await _authApi.createAccountWithEmail(authCredentials);

    return authToken; 
  }

  void _handleUsernameChange(String inputUsername) {

    _usernameError = UserCredentials.canUseUsernameAsEmail(_authAction, inputUsername)
      ? AuthValidators.emailValidator(inputUsername, true)
      : AuthValidators.usernameValidator(inputUsername);

    _usernameErrorController.add(_usernameError);

    _username = inputUsername;

    if (canSubmitForm()) {
      _authResultController.add(AuthResult.canSendAuthRequest);
    }
  }

  void _handleEmailChange(String inputEmail) {

    _emailError = AuthValidators.emailValidator(inputEmail, true);

    _emailErrorController.add(_emailError);

    _email = inputEmail;
    
    if (canSubmitForm()) {
      _authResultController.add(AuthResult.canSendAuthRequest);
    }
  }

  void _handlePasswordChange(String inputPassword) {

    _passwordError = AuthValidators.passwordValidator(inputPassword, true);

    _passwordErrorController.add(_passwordError);

    _password = inputPassword;

    if (canSubmitForm()) {
      _authResultController.add(AuthResult.canSendAuthRequest);
    }
  }

  void _handlePasswordConfirmChange(String inputPasswordConfirm) {

    _passwordConfirmError = AuthValidators.validatePasswordConfirm(_password, inputPasswordConfirm);

    _passwordConfirmErrorController.add(_passwordConfirmError);
    
    if (canSubmitForm()) {
      _authResultController.add(AuthResult.canSendAuthRequest);
    }
  }

  bool canSubmitForm() { 
    return _usernameError == UsernameError.none && 
           _emailError == UsernameError.none && 
           _passwordError == PasswordError.none && 
           _passwordConfirmError == PasswordError.none;
  }

  @override
  bool operator==(covariant AuthFormBloc other) {

    final areFormKeysEqual = formKey == other.formKey;
    final areStateControllersEqual = _authResultController == other._authResultController;

    return areFormKeysEqual && areStateControllersEqual;
  }
  
  @override
  int get hashCode => Object.hashAll([
    formKey,
    _authAction,
    _formState,
    _isLoading,
    _username,
    _email,
    _password,
  ]);
}