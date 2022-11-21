import 'package:flutter/widgets.dart';

import 'package:hydrate_app/src/models/enums/auth_action_type.dart';
import 'package:hydrate_app/src/models/enums/error_types.dart';
import 'package:hydrate_app/src/models/user_credentials.dart';
import 'package:hydrate_app/src/models/validators/range.dart';
import 'package:hydrate_app/src/models/validators/validator.dart';

class AuthValidator extends Validator{

  const AuthValidator(this.authAction);

  final AuthActionType authAction;

  static const _emailPattern = r'^(([^<>()[\]\\.,;:\s@\"]+(\.[^<>()[\]\\.,;:\s@\"]+)*)|(\".+\"))@((\[[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\])|(([a-zA-Z\-0-9]+\.)+[a-zA-Z]{2,}))$';
  static final emailRegExp = RegExp(_emailPattern);

  static const _usernamePattern = r'^[a-z0-9_-]{4,20}$';
  static final usernameRegExp = RegExp(_usernamePattern);

  static const _passwordPattern = r'^(?=.*?[A-Z])(?=.*?[a-z])(?=.*?[0-9]).{8,}$';
  static final passwordRegExp = RegExp(_passwordPattern);

  static const Range usernameLengthRange = Range(min: 4, max: 20); 
  static const Range passwordLengthRange = Range(min: 8, max: 40);

  static const Set<String> requiredFields = <String>{};
  
  @override
  bool isFieldRequired(String fieldName) => requiredFields.contains(fieldName);

  @override
  bool isValid(Object? instanceToValidate, { String? passwordConfirm }) {
    if (instanceToValidate is! UserCredentials) {
      throw UnsupportedError("An AuthValidator cannot validate a value that is not an instance of UserCredentials");
    }

    if (authAction == AuthActionType.signIn) {
      final bool isSignInValid;
      if (canUsernameBeTreatedAsEmail(instanceToValidate.username)) {
        isSignInValid = validateEmail(instanceToValidate.username) == UsernameError.none;
      } else {
        isSignInValid = validateUsername(instanceToValidate.username) == UsernameError.none;
      }

      final bool isPasswordValid = validatePassword(instanceToValidate.password) == PasswordError.none;

      return isSignInValid && isPasswordValid;

    } else if (authAction == AuthActionType.signUp) {
      final bool isUsernameValid = validateUsername(instanceToValidate.username) == UsernameError.none;
      final bool isEmailValid = validateEmail(instanceToValidate.email) == UsernameError.none;
      final bool isPasswordValid = validatePassword(instanceToValidate.password) == PasswordError.none;
      final bool isPasswordConfirmValid = validatePasswordConfirm(instanceToValidate.password, passwordConfirm) == PasswordError.none;

      return isUsernameValid && isEmailValid && isPasswordValid && isPasswordConfirmValid;
    } else {
      print("AuthValidator used to validate unsupported auth action ($authAction)");
      return false;
    }
  }

  bool canUsernameBeTreatedAsEmail(String value) {
    final supportsEmailAsUsername = authAction == AuthActionType.signIn;
    final usernameCanBeEmail = value.contains('@') || value.contains('.');

    return usernameCanBeEmail && supportsEmailAsUsername;
  }

  UsernameError validateEmail(String? emailInput) {

    if (emailInput != null) {
      if (emailInput.isEmpty) return UsernameError.noEmailProvided;

      final isNotAValidEmail = !emailRegExp.hasMatch(emailInput);
      
      if (isNotAValidEmail) {
        return UsernameError.incorrectEmailFormat;
      }
    } else if (isFieldRequired("email")) {
      return UsernameError.noEmailProvided;
    }

    return UsernameError.none;
  }

  UsernameError validateUsername(String? usernameInput) {

    if (usernameInput == null || usernameInput.isEmpty) {
      return UsernameError.noUsernameProvided;
    }

    final lengthComparison = usernameLengthRange.compareTo(usernameInput.characters.length);

    if (lengthComparison < 0) {
      return UsernameError.usernameTooShort;
    }

    if (lengthComparison > 0) {
      return UsernameError.usernameTooLong;
    }

    if (!usernameRegExp.hasMatch(usernameInput)) {
      return UsernameError.incorrectUsernameFormat;
    }

    return UsernameError.none;
  }

  PasswordError validatePassword(String? passwordInput) {

    if (passwordInput != null) {
      if (passwordInput.isEmpty) return PasswordError.noPasswordProvided;

      final passwordLength = passwordInput.characters.length;
      final lengthComparison = passwordLengthRange.compareTo(passwordLength);

      if (lengthComparison < 0) {
        return PasswordError.passwordTooShort;
      } else if (lengthComparison > 0) {
        return PasswordError.passwordTooShort;
      }

      if (!passwordRegExp.hasMatch(passwordInput)) {
        return PasswordError.requiresSymbols;
      }
    } else if (isFieldRequired(UserCredentials.passwordAttribute)) {
      return PasswordError.noPasswordProvided;
    }

    return PasswordError.none;
  }

  PasswordError validatePasswordConfirm(String? password, String? confirmInput) {

    if (password != null && password.isNotEmpty) {

      if (confirmInput == null || confirmInput.isEmpty) {
        return PasswordError.noPasswordConfirm;
      }

      if (password != confirmInput) {
        return PasswordError.passwordsDoNotMatch;
      }
    } else if (isFieldRequired(UserCredentials.passwordConfirmAttribute)) {
      return PasswordError.noPasswordConfirm;
    }

    return PasswordError.none;
  }
}
