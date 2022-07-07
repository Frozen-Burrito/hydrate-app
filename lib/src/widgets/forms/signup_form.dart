import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

import 'package:hydrate_app/src/models/api.dart';
import 'package:hydrate_app/src/models/user_credentials.dart';
import 'package:hydrate_app/src/provider/profile_provider.dart';
import 'package:hydrate_app/src/provider/settings_provider.dart';
import 'package:hydrate_app/src/routes/route_names.dart';
import 'package:hydrate_app/src/utils/auth_validators.dart';
import 'package:hydrate_app/src/utils/jwt_parser.dart';

class SignupForm extends StatefulWidget {
  const SignupForm({ Key? key }) : super(key: key);

  @override
  State<SignupForm> createState() => _SignupFormState();
}

class _SignupFormState extends State<SignupForm> {

  final _formKey = GlobalKey<FormState>();

  final signupApiUrl = '/usuarios/registro';

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
    
    if (!_formKey.currentState!.validate()) return;

    setState(() { isLoading = true; });

    final profileProvider = Provider.of<ProfileProvider>(context, listen: false);
    final settingsProvider = Provider.of<SettingsProvider>(context, listen: false);

    final userCredentials = UserCredentials(
      email: email,
      username: username,
      password: password
    );

    try {
      final res = await API.post(signupApiUrl, userCredentials.toMap());

      final resBody = json.decode(res.body);
      final token = resBody[UserCredentials.jwtPropIdentifier];

      if (res.statusCode == HttpStatus.ok && token is String) {
        // El registro y la autenticación fueron exitosos.

        // Guardar el token JWT.
        settingsProvider.authToken = token;

        // Obtener el ID de la cuenta de usuario desde el token.
        final tokenClaims = parseJWT(token);

        String newAccountID = tokenClaims['id'];

        if (profileProvider.linkedAccountId.isNotEmpty) {
          // Si el perfil actual ya tiene asociada una cuenta de usuario,
          // crear un nuevo perfil con el ID de la nueva cuenta.
          profileProvider.newDefaultProfile(existingAccountId: newAccountID);

          // Se registró la nueva cuenta, asociada con un nuevo perfil. Redirigir
          // al formulario inicial para que el usuario pueda configurar su nuevo
          // perfil.
          Navigator.of(context).popAndPushNamed(RouteNames.initialForm, result: token);

        } else if (profileProvider.profileChanges != null) {
          // Si el perfil de usuario no esta asociado con una cuenta de usuario, 
          // asociar el perfil con la cuenta creada.
          profileProvider.profileChanges!.userAccountID = newAccountID;

          profileProvider.saveProfileChanges(restrictModifications: false);

          // Se registró la nueva cuenta y se asoció por defecto al perfil local.
          Navigator.of(context).popAndPushNamed(RouteNames.home, result: token);
        }

      } else if (res.statusCode >= HttpStatus.badRequest) {
        // Existe un error en las credenciales del usuario.
        final error = AuthError.values[resBody['tipo'] ?? 1];

        setState(() {
          isLoading = false;
          hasError = true;
          authError = error;
        });
      } else if (res.statusCode >= HttpStatus.internalServerError) {
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

    final localizations = AppLocalizations.of(context)!;

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
                  localizations.createAccount, 
                  style: Theme.of(context).textTheme.headline4,
                ),

                const SizedBox( height: 32.0, ),

                TextFormField(
                  autocorrect: false,
                  keyboardType: TextInputType.emailAddress,
                  decoration: InputDecoration(
                    border: const OutlineInputBorder(),
                    prefixIcon: const Icon(Icons.mail),
                    labelText: localizations.email,
                    helperText: ' ',
                    errorText: hasError 
                      && (authError == AuthError.userExists || authError == AuthError.credentialsError)
                      ? localizations.errUserExistsEmail
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
                    labelText: localizations.username,
                    helperText: ' ',
                    errorText: hasError 
                      && (authError == AuthError.userExists || authError == AuthError.credentialsError)
                      ? localizations.errUserExistsName
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
                    labelText: localizations.password,
                    helperText: ' ',
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
                  decoration: InputDecoration(
                    border: const OutlineInputBorder(),
                    prefixIcon: const Icon(Icons.vpn_key),
                    labelText: localizations.passwordConfirm,
                    helperText: ' ',
                  ),
                  onChanged: (value) => setState(() {
                    confirmPassword = value;
                    editedConfirm = true;
                  }),
                  validator: (value) => AuthValidators.confirmPasswordValidator(password, value, editedConfirm),
                ),

                authError == AuthError.serviceUnavailable 
                  ? Padding(
                    padding: const EdgeInsets.only(top: 8.0, bottom: 16.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: <Widget>[
                        const Icon(Icons.cloud_off),

                        const SizedBox( width: 4.0, ),
                        
                        Expanded(
                          child: Text(
                            localizations.errCheckInternetConn, 
                            textAlign: TextAlign.start,
                            maxLines: 2,
                            softWrap: true,
                          ),
                        ),
                      ],
                    ),
                  )
                  : const SizedBox( height: 8.0, ),

                ElevatedButton(
                  child: isLoading 
                    ? const SizedBox(
                        height: 24.0,
                        width: 24.0,
                        child: CircularProgressIndicator()
                      )
                    : Text(localizations.continueAction),
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