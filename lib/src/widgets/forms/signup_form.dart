import 'package:flutter/material.dart';
import 'package:hydrate_app/src/utils/auth_validators.dart';

class SignupForm extends StatefulWidget {
  const SignupForm({ Key? key }) : super(key: key);

  @override
  State<SignupForm> createState() => _SignupFormState();
}

class _SignupFormState extends State<SignupForm> {

  final _formKey = GlobalKey<FormState>();

  String email = '';
  String username = '';
  String password = '';
  String confirmPassword = '';

  bool editedEmail = false;
  bool editedUsername = false;
  bool editedPassword = false;
  bool editedConfirm = false;

  bool isLoading = false;
  bool hasError = false;
  AuthError authError = AuthError.none;

  void _validateAndAuthenticate(BuildContext context, { String? redirectRoute }) async {
  
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
                  'Crea una cuenta', 
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
                      && (authError == AuthError.userExists || authError == AuthError.credentialsError)
                      ? 'Ya existe un usuario registrado con este correo'
                      : null
                  ),
                  onChanged: (value) => setState(() {
                    email = value;
                    editedEmail = true;
                  }),
                  validator: (value) => AuthValidators.emailValidator(value, editedEmail),
                ),

                const SizedBox( height: 8.0, ),

                TextFormField(
                  autocorrect: false,
                  keyboardType: TextInputType.text,
                  decoration: InputDecoration(
                    border: const OutlineInputBorder(),
                    prefixIcon: const Icon(Icons.person),
                    labelText: 'Nombre de usuario',
                    helperText: ' ',
                    errorText: hasError 
                      && (authError == AuthError.userExists || authError == AuthError.credentialsError)
                      ? 'Ya existe un usuario registrado con este nombre'
                      : null
                  ),
                  onChanged: (value) => setState(() {
                    username = value;
                    editedUsername = true;
                  }),
                  validator: (value) => AuthValidators.usernameValidator(value, editedUsername),
                ),

                const SizedBox( height: 8.0, ),

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
                    editedPassword = true;
                  }),
                  validator: (value) => AuthValidators.passwordValidator(value, editedPassword),
                ),

                const SizedBox( height: 8.0, ),

                TextFormField(
                  autocorrect: false,
                  obscureText: true,
                  keyboardType: TextInputType.visiblePassword,
                  decoration: const InputDecoration(
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.vpn_key),
                    labelText: 'Confirma la contraseña',
                    helperText: ' ',
                  ),
                  onChanged: (value) => setState(() {
                    confirmPassword = value;
                    editedConfirm = true;
                  }),
                  validator: (value) => AuthValidators.confirmPasswordValidator(password, value),
                ),

                const SizedBox( height: 8.0, ),

                ElevatedButton(
                  child: isLoading 
                    ? const SizedBox(
                        height: 24.0,
                        width: 24.0,
                        child: CircularProgressIndicator()
                      )
                    : const Text('Continuar'),
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