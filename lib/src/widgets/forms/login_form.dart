import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import 'package:hydrate_app/src/models/user_credentials.dart';
import 'package:hydrate_app/src/utils/auth_validators.dart';

class LoginForm extends StatefulWidget {
  const LoginForm({ Key? key }) : super(key: key);

  @override
  State<LoginForm> createState() => _LoginFormState();
}

class _LoginFormState extends State<LoginForm> {

  final _formKey = GlobalKey<FormState>();

  final apiUrl = Uri.parse('https://servicio-web-hydrate.azurewebsites.net/api/v1/usuarios/login');

  String emailOrUsername = '';
  String password = '';

  bool editedEmail = false;
  bool editedPassword = false;

  bool isLoading = false;
  bool hasError = false;
  AuthError authError = AuthError.none;

  void _validateAndAuthenticate(BuildContext context, { String? redirectRoute }) async {
    
    if (!_formKey.currentState!.validate()) return;

    setState(() { isLoading = true; });

    final userCredentials = UserCredentials(
      email: AuthValidators.isValidEmail(emailOrUsername) ? emailOrUsername : '',
      username: AuthValidators.isValidEmail(emailOrUsername) ? '' : emailOrUsername,
      password: password
    );

    final reqBody = json.encode(userCredentials.toMap());

    print('Peticion: $reqBody');

    try {
      final res = await http.post(apiUrl, headers: {"content-type": "application/json"}, body: reqBody);

      final resBody = json.decode(res.body);

      print('Respuesta (${res.statusCode}): $resBody');

      if (res.statusCode == 200) {
        // La autenticacion fue exitosa, redirigir a una nueva pagina.
        if (redirectRoute != null) {
          Navigator.of(context).pushNamedAndRemoveUntil(redirectRoute, (route) => false);
        } else {
          Navigator.of(context).pop();
        }
      } else if (res.statusCode >= 400) {
        // Existe un error en las credenciales del usuario.
        final error = AuthError.values[resBody['tipo'] ?? 1];

        final List<String> validationErrors = [];

        setState(() {
          isLoading = false;
          hasError = true;
          authError = error;
        });
      } else if (res.statusCode >= 500) {
        // Hubo un error en el servidor.
        setState(() {
          isLoading = false;
          hasError = true;
          authError = AuthError.serviceUnavailable;
        });
      }

    } on SocketException {
      setState(() {
        isLoading = false;
        hasError = true;
        authError = AuthError.serviceUnavailable;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Form(
      key: _formKey,
      autovalidateMode: AutovalidateMode.onUserInteraction,
      child: Card(
        margin: const EdgeInsets.only( top: 48.0 ),
        child: SizedBox(
          width: MediaQuery.of(context).size.width * 0.9,
          child: Padding(
            padding: const EdgeInsets.all(32.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: <Widget>[
                Text(
                  'Inicia Sesión', 
                  style: Theme.of(context).textTheme.headline4,
                ),

                const SizedBox( height: 32.0, ),

                TextFormField(
                  autocorrect: false,
                  keyboardType: TextInputType.emailAddress,
                  decoration: InputDecoration(
                    border: const OutlineInputBorder(),
                    prefixIcon: const Icon(Icons.person),
                    labelText: 'Correo electrónico o usuario',
                    helperText: ' ',
                    errorText: hasError 
                      && (authError == AuthError.userDoesNotExist || authError == AuthError.credentialsError)
                      ? 'No hay un usuario registrado con ese identificador'
                      : null
                  ),
                  onChanged: (value) => setState(() {
                    emailOrUsername = value;
                    editedEmail = true;
                  }),
                  validator: (value) => value != null && value.contains('@')
                    ? AuthValidators.emailValidator(value, editedEmail)
                    : AuthValidators.usernameValidator(value, editedEmail),
                ),

                const SizedBox( height: 16.0, ),

                TextFormField(
                  autocorrect: false,
                  obscureText: true,
                  keyboardType: TextInputType.visiblePassword,
                  decoration: InputDecoration(
                    border: const OutlineInputBorder(),
                    prefixIcon: const Icon(Icons.vpn_key),
                    labelText: 'Contraseña',
                    helperText: ' ',
                    errorText: hasError 
                      && (authError == AuthError.incorrectPassword)
                      ? 'La contraseña es incorrecta'
                      : null
                  ),
                  onChanged: (value) => setState(() {
                    editedPassword = true;
                    password = value;
                  }),
                  validator: (value) => AuthValidators.passwordValidator(value, editedPassword)
                ),

                authError == AuthError.serviceUnavailable 
                  ? Padding(
                    padding: const EdgeInsets.only(top: 8.0, bottom: 16.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: const <Widget>[
                        Icon(Icons.cloud_off),

                        SizedBox( width: 8.0, ),
                        
                        Expanded(
                          child: Text(
                            'Revisa tu conexión a internet e intenta de nuevo.', 
                            textAlign: TextAlign.start,
                            maxLines: 2,
                            softWrap: true,
                          ),
                        ),
                      ],
                    ),
                  )
                  : const SizedBox( height: 32.0, ),

                SizedBox(
                  width: MediaQuery.of(context).size.width * 0.4,
                  child: ElevatedButton(
                    child: isLoading 
                      ? const SizedBox(
                          height: 24.0,
                          width: 24.0,
                          child: CircularProgressIndicator()
                        )
                      : const Text('Inicia Sesión'),
                    style: ElevatedButton.styleFrom(
                      primary: Theme.of(context).colorScheme.primary,
                      padding: const EdgeInsets.symmetric(horizontal: 32.0, vertical: 12.0),
                      textStyle: Theme.of(context).textTheme.bodyText1,
                    ),
                    onPressed: isLoading ? null : () => _validateAndAuthenticate(context, redirectRoute: '/'),
                  ),
                ),
              ],
            )
          )
        )
      )
    );
  }
}