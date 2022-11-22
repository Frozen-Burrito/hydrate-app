import 'dart:async';
import 'package:flutter/material.dart';
import 'package:hydrate_app/src/models/validators/auth_validator.dart';
import 'package:provider/provider.dart';

import 'package:hydrate_app/src/api/auth_api.dart';
import 'package:hydrate_app/src/exceptions/api_exception.dart';
import 'package:hydrate_app/src/models/enums/auth_action_type.dart';
import 'package:hydrate_app/src/models/enums/error_types.dart';
import 'package:hydrate_app/src/models/user_credentials.dart';
import 'package:hydrate_app/src/services/activity_service.dart';
import 'package:hydrate_app/src/services/device_pairing_service.dart';
import 'package:hydrate_app/src/services/profile_service.dart';
import 'package:hydrate_app/src/services/settings_service.dart';
import 'package:hydrate_app/src/utils/jwt_parser.dart';

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

  final AuthValidator _authValidator;

  String _username= "";
  String _email= "";
  String _password = "";
  String _passwordConfirm = "";

  bool _isLoading = false;
  AuthResult _formState = AuthResult.none;

  UsernameError _usernameError = UsernameError.none;
  UsernameError _emailError = UsernameError.none;
  PasswordError _passwordError = PasswordError.none;
  PasswordError _passwordConfirmError = PasswordError.none;

  final Set<String> _requiredFields;

  Set<String> get requiredFields => Set.unmodifiable(_requiredFields);

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

  static const String usernameFieldName = "username";
  static const String emailFieldName = "email";
  static const String passwordFieldName = "password";
  static const String passwordConfirmFieldName = "passwordConfirm";

  static const int noErrorIndex = 0;

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

    const Set<String> requiredFields = <String>{
      usernameFieldName,
      passwordFieldName,
    };

    return AuthFormBloc._internal(
      authAction: AuthActionType.signIn,
      requiredFields: requiredFields,
    );
  }

  /// Crea una nueva instancia, dedicada a mantener el estado de un 
  /// formulario de creación de cuenta con email. 
  factory AuthFormBloc.emailSignUp() {

    const Set<String> requiredFields = <String>{
      usernameFieldName,
      emailFieldName,
      passwordFieldName,
      passwordConfirmFieldName,
    };

    return AuthFormBloc._internal(
      authAction: AuthActionType.signUp,
      requiredFields: requiredFields,
    );
  }

  AuthFormBloc._internal({ 
    required AuthActionType authAction,
    required Set<String> requiredFields,
  }) : _authAction = authAction, 
       _requiredFields = requiredFields, 
      _authValidator = AuthValidator(authAction) {
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

    _usernameController.stream.listen(_handleUsernameChange);
    _emailController.stream.listen(_handleEmailChange);

    _passwordController.stream.listen(_handlePasswordChange);
    _passwordConfirmController.stream.listen(_handlePasswordConfirmChange);
  }

  Future<void> submitForm(BuildContext context) async {

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

      final profileService = Provider.of<ProfileService>(context, listen: false);
      final bool canCurrentProfileBeLinked = await profileService.setLocalProfileForAccount(authToken);

      if (authToken.isNotEmpty && !isTokenExpired(authToken)) {

        final successAuthResult = canCurrentProfileBeLinked 
          ? AuthResult.canLinkProfileToAccount
          : AuthResult.canFetchProfileSettings;

        _authResultController.add(successAuthResult);
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

  Future<void> linkAccountToProfile(BuildContext context) async {
    try {
      final profileProvider = Provider.of<ProfileService>(context, listen: false);

      await profileProvider.handleAccountLink();

      _authResultController.add(AuthResult.canFetchProfileSettings);

    } on Exception catch (ex) {
      debugPrint("Excepcion al asociar perfil con cuenta ($ex)");
      _authResultController.add(AuthResult.serviceUnavailable);
    }
  }

  Future<void> fetchProfileSettings(BuildContext context, String authToken) async {

    final settingsService = Provider.of<SettingsService>(context, listen: false);
    final profileService = Provider.of<ProfileService>(context, listen: false);
    final devicePairingService = Provider.of<DevicePairingService>(context, listen: false);
    final activityService = Provider.of<ActivityService>(context, listen: false);

    final settingsForProfile = await settingsService.fecthSettingsForAccount(authToken);

    final updatedSettings = await settingsService.updateLocalSettings(settingsForProfile);

    if (updatedSettings.isNotEmpty) {
      settingsService.applyCurrentSettings(
        userAuthToken: authToken,
        notify: false,
        activityService: activityService,
        profileService: profileService,
        devicePairingService: devicePairingService,
      );
    }

    _authResultController.add(AuthResult.authenticated);   
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

    if (_authValidator.canUsernameBeTreatedAsEmail(inputUsername)) {
      _usernameError = _authValidator.validateEmail(inputUsername);
    } else {
      _usernameError = _authValidator.validateUsername(inputUsername);
    }

    _usernameErrorController.add(_usernameError);

    _username = inputUsername;

    if (canSubmitForm()) {
      _authResultController.add(AuthResult.canSendAuthRequest);
    }
  }

  void _handleEmailChange(String inputEmail) {

    _emailError = _authValidator.validateEmail(inputEmail);

    _emailErrorController.add(_emailError);

    _email = inputEmail;
    
    if (canSubmitForm()) {
      _authResultController.add(AuthResult.canSendAuthRequest);
    }
  }

  void _handlePasswordChange(String inputPassword) {

    _passwordError = _authValidator.validatePassword(inputPassword);

    _passwordErrorController.add(_passwordError);

    _password = inputPassword;

    if (canSubmitForm()) {
      _authResultController.add(AuthResult.canSendAuthRequest);
    }
  }

  void _handlePasswordConfirmChange(String inputPasswordConfirm) {

    _passwordConfirmError = _authValidator.validatePasswordConfirm(_password, inputPasswordConfirm);

    _passwordConfirmErrorController.add(_passwordConfirmError);

    _passwordConfirm = inputPasswordConfirm;
    
    if (canSubmitForm()) {
      _authResultController.add(AuthResult.canSendAuthRequest);
    }
  }

  bool canSubmitForm() { 

    final isUsernameValid = _isFieldValid(usernameFieldName, _username, _usernameError.index);
    final isEmailValid = _isFieldValid(emailFieldName, _email, _emailError.index);
    final isPasswordValid = _isFieldValid(passwordFieldName, _password, _passwordError.index);
    final isPasswordConfirmValid = _isFieldValid(passwordConfirmFieldName, _passwordConfirm, _passwordConfirmError.index);

    return isUsernameValid && isEmailValid && isPasswordValid && isPasswordConfirmValid;
  }

  bool _isFieldValid(String fieldName, String fieldValue, int errorIndex) {

    final isFieldRequired = _requiredFields.contains(fieldName);

    bool isFieldValid = errorIndex == noErrorIndex;

    if (isFieldRequired) {
      isFieldValid = isFieldValid && fieldValue.isNotEmpty;
    } 
    
    return isFieldValid;
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