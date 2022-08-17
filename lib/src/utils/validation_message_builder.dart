import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

import 'package:hydrate_app/src/utils/auth_validators.dart';

class ValidationMessageBuilder {

  ValidationMessageBuilder.of(BuildContext context) 
    : _localizations = AppLocalizations.of(context)!;

  //TODO: Implement i18n validation messages.
  final AppLocalizations _localizations;

  static const String usernameIsRequiredMsg = 'El nombre de usuario es obligatorio';
  static const String usernameTooShortMsg = 'El usuario debe tener más de 4 letras o números';
  static const String usernameTooLongMsg = 'El usuario debe tener menos de 20 letras o números';
  static const String emailIsRequiredMsg = 'El correo electrónico es obligatorio';
  static const String incorrectEmailFormatMsg = 'El correo no tiene un formato válido';

  static const String passwordIsRequiredMsg = 'La contraseña es obligatoria';
  static const String passwordTooShortMsg = 'La contraseña debe tener más de 8 caracteres';
  static const String passwordTooLongMsg = 'La contraseña debe tener menos de 40 caracteres';
  static const String passwordRequiresSymbolsMsg = 'La contraseña debe tener un número y una mayúscula';

  String? messageForUsername(UsernameError usernameError) {

    switch(usernameError) {
      case UsernameError.none: return null;
      case UsernameError.noUsernameProvided: return usernameIsRequiredMsg;
      case UsernameError.noEmailProvided: return emailIsRequiredMsg;
      case UsernameError.incorrectEmailFormat: return incorrectEmailFormatMsg;
      case UsernameError.usernameTooShort: return usernameTooShortMsg;
      case UsernameError.usernameTooLong: return usernameTooLongMsg;
      default: 
        print('Unhandled username/email validation message for error: $usernameError');
        return 'unkown error';
    }
  } 

  String? messageForPassword(PasswordError passwordError) {
    
    switch(passwordError) {
      case PasswordError.none: return null;
      case PasswordError.noPasswordProvided: return passwordIsRequiredMsg;
      case PasswordError.passwordTooShort: return passwordTooShortMsg;
      case PasswordError.passwordTooLong: return passwordTooLongMsg;
      case PasswordError.requiresSymbols: return passwordRequiresSymbolsMsg;
      default: 
        print('Unhandled password validation message for error: $passwordError');
        return 'unkown error';
    }
  } 
}