enum AuthError {
  none,
  credentialsError,
  userExists,
  userDoesNotExist,
  incorrectPassword,
  incorrectFormat,
  serviceUnavailable,
}

class AuthValidators {

  static const _emailPattern = r'^(([^<>()[\]\\.,;:\s@\"]+(\.[^<>()[\]\\.,;:\s@\"]+)*)|(\".+\"))@((\[[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\])|(([a-zA-Z\-0-9]+\.)+[a-zA-Z]{2,}))$';

  static const _usernamePattern = r'^[a-z0-9_-]{4,20}$';

  static const _passwordPattern = r'^(?=.*?[A-Z])(?=.*?[a-z])(?=.*?[0-9]).{8,}$';

  static final emailRegExp = RegExp(_emailPattern);

  static final usernameRegExp = RegExp(_usernamePattern);

  static final passwordRegExp = RegExp(_passwordPattern);

  /// Retorna [true] si [email] tiene un formato de correo electrónico válido.
  static bool isValidEmail (final String email) => email.isNotEmpty && emailRegExp.hasMatch(email);

  static String? emailValidator(final String? emailInput, final bool fieldEdited) {

    if (fieldEdited && emailInput != null) {
      if (emailInput.isEmpty) return 'El correo electrónico es obligatorio';
      
      return isValidEmail(emailInput) ? null : 'El correo no tiene un formato válido.';
    }

    return null;
  }

  static String? usernameValidator(final String? usernameInput, final bool fieldEdited) {

    if (!fieldEdited || usernameInput == null || usernameInput.isEmpty) {
      return 'El nombre de usuario es obligatorio';
    }

    if (!usernameRegExp.hasMatch(usernameInput)) {
      return 'El usuario debe tener entre 4 y 20 letras o números';
    }

    return null;
  }

  static String? passwordValidator(final String? passwordInput, final bool fieldEdited) {

    if (fieldEdited && passwordInput != null) {
      if (passwordInput.isEmpty) return 'La contraseña es obligatoria';

      if (passwordInput.length < 8 || passwordInput.length > 40) {
        return 'La contraseña debe tener entre 8 y 40 caracteres';
      }

      if (!passwordRegExp.hasMatch(passwordInput)) {
        return 'La contraseña debe tener un número y una mayúscula';
      }
    }

    return null;
  }

  static String? confirmPasswordValidator(final String? password, final String? confirmInput, final bool fieldEdited) {

    if (fieldEdited && password != null && password.isNotEmpty) {

      if (confirmInput == null || confirmInput.isEmpty) {
        return 'Escribe la confirmación de contraseña';
      }

      if (password != confirmInput) {
        return 'Las contraseñas no coinciden';
      }
    }

    return null;
  }
}
