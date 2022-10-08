import 'package:flutter/material.dart';

enum AuthResult {
  none,
  authenticated,
  newProfileCreated,
  canLinkProfileToAccount,
  canSendAuthRequest,
  credentialsError,
  serviceUnavailable,
}

enum UsernameError { 
  none,
  noUsernameProvided,
  noEmailProvided,
  incorrectEmailFormat,
  usernameTooShort,
  usernameTooLong,
  incorrectUsernameFormat,
}

enum PasswordError { 
  none,
  noPasswordProvided,
  passwordTooShort,
  passwordTooLong,
  requiresSymbols,
  noPasswordConfirm,
  passwordsDoNotMatch,
}

class AuthValidators {

  static const _emailPattern = r'^(([^<>()[\]\\.,;:\s@\"]+(\.[^<>()[\]\\.,;:\s@\"]+)*)|(\".+\"))@((\[[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\])|(([a-zA-Z\-0-9]+\.)+[a-zA-Z]{2,}))$';

  static const _usernamePattern = r'^[a-z0-9_-]{4,20}$';

  static const _passwordPattern = r'^(?=.*?[A-Z])(?=.*?[a-z])(?=.*?[0-9]).{8,}$';

  static final emailRegExp = RegExp(_emailPattern);

  static final usernameRegExp = RegExp(_usernamePattern);

  static final passwordRegExp = RegExp(_passwordPattern);

  static bool valueCouldBeEmail(String value) => value.contains('@') || value.contains('.');

  static UsernameError emailValidator(final String? emailInput, final bool fieldEdited) {

    if (fieldEdited && emailInput != null) {
      if (emailInput.isEmpty) return UsernameError.noEmailProvided;

      final isNotAValidEmail = !emailRegExp.hasMatch(emailInput);
      
      if (isNotAValidEmail) {
        return UsernameError.incorrectEmailFormat;
      }
    }

    return UsernameError.none;
  }

  static UsernameError usernameValidator(final String? usernameInput) {

    if (usernameInput == null || usernameInput.isEmpty) {
      return UsernameError.noUsernameProvided;
    }

    if (usernameInput.characters.length < 4) {
      return UsernameError.usernameTooShort;
    }

    if (usernameInput.characters.length > 20) {
      return UsernameError.usernameTooLong;
    }

    if (!usernameRegExp.hasMatch(usernameInput)) {
      return UsernameError.incorrectUsernameFormat;
    }

    return UsernameError.none;
  }

  static PasswordError passwordValidator(final String? passwordInput, final bool fieldEdited) {

    if (fieldEdited && passwordInput != null) {
      if (passwordInput.isEmpty) return PasswordError.noPasswordProvided;

      if (passwordInput.characters.length < 8) {
        return PasswordError.passwordTooShort;
      } else if (passwordInput.characters.length > 40) {
        return PasswordError.passwordTooShort;
      }

      if (!passwordRegExp.hasMatch(passwordInput)) {
        return PasswordError.requiresSymbols;
      }
    }

    return PasswordError.none;
  }

  static PasswordError validatePasswordConfirm(String? password, String? confirmInput) {

    if (password != null && password.isNotEmpty) {

      if (confirmInput == null || confirmInput.isEmpty) {
        return PasswordError.noPasswordConfirm;
      }

      if (password != confirmInput) {
        return PasswordError.passwordsDoNotMatch;
      }
    }

    return PasswordError.none;
  }
}
