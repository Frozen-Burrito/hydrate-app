import 'package:hydrate_app/src/models/enums/auth_action_type.dart';
import 'package:hydrate_app/src/utils/auth_validators.dart';

class UserCredentials {

  final String username;
  final String email;
  final String password;

  const UserCredentials({
    this.username = '',
    this.email = '', 
    this.password = ''
  }); 

  factory UserCredentials.forAction(
    AuthActionType authAction, { 
      required String username,
      required String email, 
      required String password
    }
  ) {
    if (canUseUsernameAsEmail(authAction, username)) {
      return UserCredentials(
        email: username,
        username: '',
        password: password,
      );
    } else {
      return UserCredentials(
        email: email,
        username: '',
        password: password,
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