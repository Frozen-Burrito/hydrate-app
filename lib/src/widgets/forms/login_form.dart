import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

import 'package:hydrate_app/src/bloc/auth_form_bloc.dart';
import 'package:hydrate_app/src/routes/route_names.dart';
import 'package:hydrate_app/src/models/validators/validation_message_builder.dart';
import 'package:hydrate_app/src/utils/auth_validators.dart';
import 'package:hydrate_app/src/widgets/form_state_provider.dart';

class LoginForm extends StatelessWidget {

  LoginForm({Key? key}) : super(key: key);

  final AuthFormBloc bloc = AuthFormBloc.emailSignIn();

  Future<void> _handleLoginSubmit(BuildContext context) async {
    // Submit the form.
    bloc.formSubmit.add(context);

    // Wait for the result of the submit event.
    await for(final result in bloc.formState) {
      if (result == AuthResult.authenticated) {
        // El usuario ya tiene un perfil. Redirigir a vista de inicio.
        Navigator.of(context).popAndPushNamed(RouteNames.home);
      } else if (result == AuthResult.newProfileCreated) {
        // El usuario todavía no ha llenado su perfil inicial. Redirigir
        // al formulario inicial para que el usuario pueda configurar su nuevo
        // perfil.
        Navigator.of(context).popAndPushNamed(RouteNames.initialForm);
      }
    }
  }

  @override
  Widget build(BuildContext context) {

    final localizations = AppLocalizations.of(context)!;
    
    return FormStateProvider(
      model: bloc,
      child: Form(
        key: bloc.formKey,
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
    
                  const _LoginFormGroup(),
    
                  StreamBuilder<AuthResult>(
                    stream: bloc.formState,
                    initialData: AuthResult.none,
                    builder: (context, snapshot) {
                      
                      if (snapshot.data == AuthResult.none) {
                        return const SizedBox( height: 32.0, );
                      }
    
                      final isServiceUnavailable = snapshot.data == AuthResult.serviceUnavailable;
    
                      return Padding(
                        padding: const EdgeInsets.only(top: 8.0, bottom: 16.0),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: <Widget>[
                            Icon(isServiceUnavailable
                              ? Icons.cloud_off
                              : Icons.error
                            ),
    
                            const SizedBox( width: 8.0, ),
                            
                            Expanded(
                              child: Text(
                                isServiceUnavailable 
                                  ? localizations.errCheckInternetConn
                                  //TODO: Add i18n
                                  : 'Your credentials are incorrect.', 
                                textAlign: TextAlign.start,
                                maxLines: 2,
                                softWrap: true,
                              ),
                            ),
                          ],
                        ),
                      );
                    }
                  ),
    
                  SizedBox(
                    width: MediaQuery.of(context).size.width * 0.5,
                    child: StreamBuilder<bool>(
                      initialData: false,
                      stream: bloc.isLoading,
                      builder: (context, snapshot) {
    
                        final isFormLoading = snapshot.data ?? false;

                        if (isFormLoading) {
                          return ElevatedButton(
                            onPressed: null,
                            style: ElevatedButton.styleFrom(
                              primary: Theme.of(context).colorScheme.primary,
                              padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 16.0),
                              textStyle: Theme.of(context).textTheme.bodyText1,
                            ), 
                            child: const SizedBox(
                              height: 24.0,
                              width: 24.0,
                              child: CircularProgressIndicator()
                            ),
                          );
                        } else {
                          return ElevatedButton(
                            onPressed: () {
                              FocusScope.of(context).unfocus();
                              _handleLoginSubmit(context);
                            },
                            style: ElevatedButton.styleFrom(
                              primary: Theme.of(context).colorScheme.primary,
                              padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 16.0),
                              textStyle: Theme.of(context).textTheme.bodyText1,
                            ), 
                            child: Text(
                              localizations.continueAction, 
                              textAlign: TextAlign.center,
                            ),
                          );
                        }
                      },
                    ),
                  ),
                ],
              )
            )
          )
        )
      ),
    );  
  }
}

class _LoginFormGroup extends StatelessWidget {
  const _LoginFormGroup({Key? key,}) : super(key: key);

  @override
  Widget build(BuildContext context) {

    final bloc = FormStateProvider.of(context).model;
    final localizations = AppLocalizations.of(context)!;
    final validationMsgBuilder = ValidationMessageBuilder.of(context);

    return StreamBuilder<bool>(
      initialData: false,
      stream: bloc.isLoading,
      builder: (context, snapshot) {
        return Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: <Widget>[
            StreamBuilder<UsernameError>(
              initialData: UsernameError.none,
              stream: bloc.usernameError,
              builder: (context, snapshot) {
                return TextFormField(
                  autocorrect: false,
                  keyboardType: TextInputType.emailAddress,
                  decoration: InputDecoration(
                    border: const OutlineInputBorder(),
                    prefixIcon: const Icon(Icons.person),
                    labelText: localizations.emailOrUsername,
                    helperText: ' ',
                    errorText: validationMsgBuilder.messageForUsername(snapshot.data!),
                  ),
                  onChanged: (inputValue) => bloc.usernameSink.add(inputValue),
                );
              }
            ),

            const SizedBox( height: 16.0, ),

            StreamBuilder<PasswordError>(
              initialData: PasswordError.none,
              stream: bloc.passwordError,
              builder: (context, snapshot) {
                return TextFormField(
                  autocorrect: false,
                  obscureText: true,
                  keyboardType: TextInputType.visiblePassword,
                  decoration: InputDecoration(
                    border: const OutlineInputBorder(),
                    prefixIcon: const Icon(Icons.vpn_key),
                    labelText: localizations.password,
                    helperText: ' ',
                    errorText: validationMsgBuilder.messageForPassword(snapshot.data!),
                  ),
                  onChanged: (inputValue) => bloc.passwordSink.add(inputValue),
                );
              }
            ),
          ],
        );
      },
    );
  }
}