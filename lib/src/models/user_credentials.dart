import 'package:hydrate_app/src/models/enums/auth_action_type.dart';
import 'package:hydrate_app/src/utils/auth_validators.dart';

/// Un modelo serializable a JSON para enviar credenciales de usuario 
/// con un modelo de autenticación basado en email/password.
class UserCredentials {

  /// El nombre de usuario (o login) de las credenciales.
  final String username;

  /// El correo electrónico especificado.
  final String email;

  /// La contraseña, sin cifrar.
  final String password;

  const UserCredentials({
    this.username = "",
    this.email = "", 
    this.password = ""
  }); 

  /// Crea una instancia de esta clase apropiada para la [authAction] 
  /// descrita por la API web de autenticación de Hydrate. 
  factory UserCredentials.forAction(
    AuthActionType authAction, { 
      required String username,
      required String email, 
      required String password
    }
  ) {

    switch (authAction) {
      case AuthActionType.signIn:
        if (canUseUsernameAsEmail(authAction, username)) {
          return UserCredentials(
            email: username,
            username: "",
            password: password,
          );
        } else {
          return UserCredentials(
            email: "",
            username: username,
            password: password,
          );
        }
      case AuthActionType.signUp:
        return UserCredentials(
          email: email,
          username: username,
          password: password,
        );
      default: 
        throw ArgumentError.value(
          authAction, 
          "authAction", 
          "UserCredentials no soporta la acción de autenticación $authAction"
        );
    }
  }

  static const jwtPropIdentifier = 'token';

  static bool canUseUsernameAsEmail(AuthActionType authAction, String possibleEmail) {
    final supportsEmailAsUsername = authAction == AuthActionType.signIn;
    final valueCouldBeEmail = AuthValidators.valueCouldBeEmail(possibleEmail);

    return (supportsEmailAsUsername && valueCouldBeEmail);
  }

  static UserCredentials fromMap(Map<String, String> map) {
    
    return UserCredentials(
      username: map['nombreUsuario'] ?? '',
      email: map['email'] ?? '',
    );
  }

  Map<String, String> toMap() {
    
    if (username.isEmpty && email.isEmpty) {
      throw ArgumentError.value('', 'username o email', 'Debe haber exactamente una credencial');
    }

    final Map<String, String> map = {
      'password': password,
    };

    if (username.isNotEmpty) map['nombreUsuario'] = username;

    if (email.isNotEmpty) map['email'] = email;

    return map;
  }
}