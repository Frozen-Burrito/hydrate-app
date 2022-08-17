import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:hydrate_app/src/models/api.dart';
import 'package:hydrate_app/src/models/enums/auth_action_type.dart';
import 'package:hydrate_app/src/models/user_credentials.dart';
import 'package:hydrate_app/src/provider/profile_provider.dart';
import 'package:hydrate_app/src/provider/settings_provider.dart';
import 'package:hydrate_app/src/utils/auth_validators.dart';

class AuthFormBloc {

  final formKey = GlobalKey<FormState>();

  final AuthActionType _authAction;
  final String _apiEndpoint;

  String _username= '';
  String _email= '';
  String _password = '';
  String _passwordConfirm = '';

  bool _isLoading = false;
  AuthResult _formState = AuthResult.none;

  UsernameError _usernameError = UsernameError.none;
  UsernameError _emailError = UsernameError.none;
  PasswordError _passwordError = PasswordError.none;
  PasswordError _passwordConfirmError = PasswordError.none;

  Stream<bool> get isLoading => _loadingController.stream;
  Stream<AuthResult> get formState => _authResultController.stream;

  Stream<UsernameError> get usernameError => _usernameErrorController.stream;
  Stream<UsernameError> get emailError => _emailErrorController.stream;
  Stream<PasswordError> get passwordError => _passwordErrorController.stream;
  Stream<PasswordError> get passwordConfirmError => _passwordConfirmErrorController.stream;

  Sink<String> get usernameSink => _usernameController.sink;
  Sink<String> get emailSink => _emailController.sink;
  Sink<String> get passwordSink => _passwordController.sink;
  Sink<String> get passwordConfirmSink => _passwordConfirmController.sink;
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

  factory AuthFormBloc.emailSignIn() {
    return AuthFormBloc._internal(
      authEndpoint: 'login',
      authAction: AuthActionType.signIn,
    );
  }

  factory AuthFormBloc.emailSignUp() {
    return AuthFormBloc._internal(
      authEndpoint: 'signUp',
      authAction: AuthActionType.signUp,
    );
  }

  AuthFormBloc._internal({ 
    String authEndpoint = '',
    AuthActionType authAction = AuthActionType.none 
  }) : _apiEndpoint = authEndpoint,
       _authAction = authAction {
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

    if (isFormInInvalidSate) return;

    try {
      // Try to login.
      await _sendAuthRequest(context);
      
    } on SocketException {
      // La conexión a internet fue interrumpida, o hubo algún otro error de 
      // conexión.
      _authResultController.add(AuthResult.serviceUnavailable);
    } finally {
      _isLoading = false;
      _loadingController.add(false);
    }
  }

  Future<void> _sendAuthRequest(BuildContext context) async {

    final authCredentials = UserCredentials.forAction(
      _authAction, 
      username: _username, 
      email: _email, 
      password: _password
    );

    final res = await API.post(_apiEndpoint, authCredentials.toMap());

    final isResponseOk = res.statusCode == HttpStatus.ok;
    final responseHasBody = res.body.isNotEmpty;

    if (isResponseOk && res.body.isNotEmpty) {

    }

    if (isResponseOk && responseHasBody) {
      // Try to obtain the JWT from the response body.
      final decodedBody = json.decode(res.body);
      final authToken = decodedBody[UserCredentials.jwtPropIdentifier];

      if (authToken is String) {
        // La autenticación fue exitosa. Guardar el token JWT.
        Provider.of<SettingsProvider>(context, listen: false).authToken = authToken;
      
        final profileProvider = Provider.of<ProfileProvider>(context, listen: false);

        final linkResult = await profileProvider.handleAccountLink(authToken, isNewAccount: false);

        switch (linkResult) { 
          case AccountLinkResult.noAccountId:
            _authResultController.add(AuthResult.serviceUnavailable);
            break;
          case AccountLinkResult.alreadyLinked:
            _authResultController.add(AuthResult.authenticated);
            break;
          case AccountLinkResult.newProfileCreated:
            _authResultController.add(AuthResult.newProfileCreated);
            break;
        }
      } else {
        // El token JWT no es un String, posiblemente hubo un error en el servidor.
      _authResultController.add(AuthResult.serviceUnavailable);
      }    

    } else if (res.statusCode >= HttpStatus.internalServerError) {
      // Hubo un error en el servidor.
      _authResultController.add(AuthResult.serviceUnavailable);

    } else if (res.statusCode >= HttpStatus.badRequest) {
      // Existe un error en las credenciales del usuario.
      _authResultController.add(AuthResult.credentialsError);
    }
  }

  void _handleUsernameChange(String inputUsername) {

    _usernameError = UserCredentials.canUseUsernameAsEmail(_authAction, inputUsername)
      ? AuthValidators.emailValidator(inputUsername, true)
      : AuthValidators.usernameValidator(inputUsername);

    _usernameErrorController.add(_usernameError);

    _username = inputUsername;
  }

  void _handleEmailChange(String inputEmail) {

    _emailError = AuthValidators.emailValidator(inputEmail, true);

    _emailErrorController.add(_emailError);

    _email = inputEmail;
  }

  void _handlePasswordChange(String inputPassword) {

    _passwordError = AuthValidators.passwordValidator(inputPassword, true);

    _passwordErrorController.add(_passwordError);

    _password = inputPassword;
  }

  void _handlePasswordConfirmChange(String inputPasswordConfirm) {

    _passwordConfirmError = AuthValidators.validatePasswordConfirm(_password, inputPasswordConfirm);

    _passwordConfirmErrorController.add(_passwordConfirmError);

    _passwordConfirm = inputPasswordConfirm;
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
    
  ]);
}