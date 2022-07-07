
class UserCredentials {

  final String username;
  final String email;
  final String password;

  UserCredentials({
    this.username = '',
    this.email = '', 
    this.password = ''
  }); 

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