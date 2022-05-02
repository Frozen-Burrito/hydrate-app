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

class LoginForm extends StatefulWidget {
  const LoginForm({ Key? key }) : super(key: key);

  @override
  State<LoginForm> createState() => _LoginFormState();
}

class _LoginFormState extends State<LoginForm> {

  final _formKey = GlobalKey<FormState>();

  final loginApiUrl = '/usuarios/login';

  String emailOrUsername = '';
  String password = '';

  bool editedEmail = false;
  bool editedPassword = false;

  bool isLoading = false;
  bool hasError = false;
  AuthError authError = AuthError.none;

  void _validateAndAuthenticate(BuildContext context) async {
    
    if (!_formKey.currentState!.validate()) return;

    setState(() { isLoading = true; });

    final profileProvider = Provider.of<ProfileProvider>(context, listen: false);
    final settingsProvider = Provider.of<SettingsProvider>(context, listen: false);

    final userCredentials = UserCredentials(
      email: AuthValidators.isValidEmail(emailOrUsername) ? emailOrUsername : '',
      username: AuthValidators.isValidEmail(emailOrUsername) ? '' : emailOrUsername,
      password: password
    );

    try {
      final res = await API.post(loginApiUrl, userCredentials.toMap());

      final resBody = json.decode(res.body);

      print('Respuesta (${res.statusCode}): $resBody');

      if (res.statusCode == 200 && resBody['token'] is String) {

        // La autenticación fue exitosa.
        String jwt = resBody['token'];

        // Guardar el token JWT.
        settingsProvider.authToken = jwt;

        final tokenClaims = parseJWT(jwt);

        print('Claims: $tokenClaims');

        String accountId = tokenClaims['id'];

        if (profileProvider.profile.userAccountID.isNotEmpty) {
          int profileLinkedToAccount = await profileProvider.findAndSetProfileLinkedToAccount(accountId);

          if (profileLinkedToAccount < 0) {
            // Aun no existe un perfil asociado con la cuenta. Crear uno nuevo.
            profileProvider.newDefaultProfile(accountID: accountId);

            Navigator.of(context).popAndPushNamed(RouteNames.authentication, result: resBody['token']);
          } else {
            // Ya existe un perfil para esta cuenta.
            profileProvider.loadUserProfile(profileId: profileLinkedToAccount, accountId: accountId);

            Navigator.of(context).popAndPushNamed(RouteNames.home, result: resBody['token']);
          }
        } else {
          // Asociar el perfil actual con la cuenta autenticada.
          profileProvider.profileChanges.userAccountID = accountId;

          profileProvider.saveProfileChanges(restrictModifications: false);

          Navigator.of(context).popAndPushNamed('/', result: resBody['token']);
        }     
      } else if (res.statusCode >= 400) {
        // Existe un error en las credenciales del usuario.
        final error = AuthError.values[resBody['tipo'] ?? 1];

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
                  localizations.signIn, 
                  style: Theme.of(context).textTheme.headline4,
                ),

                const SizedBox( height: 32.0, ),

                TextFormField(
                  autocorrect: false,
                  keyboardType: TextInputType.emailAddress,
                  decoration: InputDecoration(
                    border: const OutlineInputBorder(),
                    prefixIcon: const Icon(Icons.person),
                    labelText: localizations.emailOrUsername,
                    helperText: ' ',
                    errorText: hasError 
                      && (authError == AuthError.userDoesNotExist || authError == AuthError.credentialsError)
                      ? localizations.errNoUser
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
                    labelText: localizations.password,
                    helperText: ' ',
                    errorText: hasError 
                      && (authError == AuthError.incorrectPassword)
                      ? localizations.errIncorrectPassword
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
                      children: <Widget>[
                        const Icon(Icons.cloud_off),

                        const SizedBox( width: 8.0, ),
                        
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
                      : Text(localizations.signIn),
                    style: ElevatedButton.styleFrom(
                      primary: Theme.of(context).colorScheme.primary,
                      padding: const EdgeInsets.symmetric(horizontal: 32.0, vertical: 12.0),
                      textStyle: Theme.of(context).textTheme.bodyText1,
                    ),
                    onPressed: isLoading ? null : () => _validateAndAuthenticate(context),
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