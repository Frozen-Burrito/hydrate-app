import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart';
import 'package:hydrate_app/src/utils/auth_validators.dart';

class LoginForm extends StatefulWidget {
  const LoginForm({ Key? key }) : super(key: key);

  @override
  State<LoginForm> createState() => _LoginFormState();
}

class _LoginFormState extends State<LoginForm> {

  final _formKey = GlobalKey<FormState>();

  String email = '';
  String password = '';

  bool isLoading = false;
  bool hasError = false;
  AuthError authError = AuthError.none;

  void _validateAndAuthenticate(BuildContext context, { String? redirectRoute }) async {
    if (_formKey.currentState!.validate()) {

      setState(() { isLoading = true; });

      //TODO: Enviar peticion de login con email y password
      final res = await get(Uri.parse('http://google.com'));

      print(res.body);

      // Map<String, dynamic> body = jsonDecode(res.body);

      if (res.statusCode == 200) {
        // La autenticacion fue exitosa.
        setState(() {
          isLoading = false;
          hasError = false;
        });

        if (redirectRoute != null) {
          Navigator.of(context).pushNamedAndRemoveUntil(redirectRoute, (route) => false);
        } else {
          Navigator.of(context).pop();
        }
      } else if (res.statusCode == 401) {
        // Existe un error en las credenciales del usuario.
        setState(() {
          isLoading = false;
          hasError = true;
          // authError = body['errorType'] ?? AuthError.credentialsError;
        });
      } else if (res.statusCode >= 500) {
        // Hubo un error en el servidor.
        setState(() {
          isLoading = false;
          hasError = true;
          authError = AuthError.serviceUnavailable;
        });
      }
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
                    prefixIcon: const Icon(Icons.mail),
                    labelText: 'Correo Electrónico',
                    helperText: ' ',
                    errorText: hasError 
                      && (authError == AuthError.userDoesNotExist || authError == AuthError.credentialsError)
                      ? 'No hay un usuario registrado con el correo'
                      : null
                  ),
                  onChanged: (value) => setState(() {
                    email = value;
                  }),
                  validator: (value) => emailValidator(value),
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
                      && (authError == AuthError.incorrectPassword || authError == AuthError.credentialsError)
                      ? 'La contraseña es incorrecta'
                      : null
                  ),
                  onChanged: (value) => setState(() {
                    password = value;
                  }),
                  validator: (value) => passwordValidator(value),
                ),

                const SizedBox( height: 32.0, ),

                ElevatedButton(
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
              ],
            )
          )
        )
      )
    );
  }
}