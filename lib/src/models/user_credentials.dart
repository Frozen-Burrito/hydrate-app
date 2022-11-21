import 'package:hydrate_app/src/models/enums/auth_action_type.dart';
import 'package:hydrate_app/src/models/validators/auth_validator.dart';

/// Un modelo serializable a JSON para enviar credenciales de usuario 
/// con un modelo de autenticación basado en email/password.
class UserCredentials {

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
  ) 
  {
    switch (authAction) {
      case AuthActionType.signIn:
        if (AuthValidator(authAction).canUsernameBeTreatedAsEmail(username)) {
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

  /// El nombre de usuario (o login) de las credenciales.
  final String username;

  /// El correo electrónico especificado.
  final String email;

  /// La contraseña, sin cifrar.
  final String password;

  static const String usernameAttribute = "username";
  static const String emailAttribute = "email";
  static const String passwordAttribute = "password";
  static const String passwordConfirmAttribute = "passwordConfirm";
  
  static const jwtPropIdentifier = 'token';

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