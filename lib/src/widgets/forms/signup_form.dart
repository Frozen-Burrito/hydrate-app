import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

import 'package:hydrate_app/src/bloc/auth_form_bloc.dart';
import 'package:hydrate_app/src/routes/route_names.dart';
import 'package:hydrate_app/src/utils/auth_validators.dart';
import 'package:hydrate_app/src/utils/validation_message_builder.dart';
import 'package:hydrate_app/src/widgets/form_state_provider.dart';

class SignupForm extends StatelessWidget {
  const SignupForm({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return FormStateProvider(
      model: AuthFormBloc.emailSignUp(), 
      child: const _SignupForm(),
    );
  }
}

class _SignupForm extends StatelessWidget {

  const _SignupForm({Key? key}) : super(key: key);

  Future<void> _handleFormSubmit(BuildContext context) async {
    // Submit the form.
    final bloc = FormStateProvider.of(context).model;
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

    final bloc = FormStateProvider.of(context).model;
    final localizations = AppLocalizations.of(context)!;

    return Form(
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
                  localizations.createAccount, 
                  style: Theme.of(context).textTheme.headline4,
                ),

                const SizedBox( height: 32.0, ),

                const _SignUpFormFields(),

                StreamBuilder<AuthResult>(
                  initialData: AuthResult.none,
                  stream: bloc.formState,
                  builder: (context, snapshot) {

                    final isAuthErrorResult = snapshot.data == AuthResult.credentialsError
                      || snapshot.data == AuthResult.serviceUnavailable;

                    if (isAuthErrorResult) {
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
                    } else {
                      return const SizedBox( height: 32.0, );
                    }
                  }
                ),

                StreamBuilder<bool>(
                  initialData: false,
                  stream: bloc.isLoading,
                  builder: (context, snapshot) {

                    final isFormLoading = snapshot.data ?? false;

                    final onBtnPressed = isFormLoading 
                      ? null 
                      : () => _handleFormSubmit(context);

                    return ElevatedButton(
                      child: isFormLoading 
                        ? const SizedBox(
                            height: 24.0,
                            width: 24.0,
                            child: CircularProgressIndicator()
                          )
                        : Text(
                            localizations.continueAction,
                            textAlign: TextAlign.center,
                          ),
                      style: ElevatedButton.styleFrom(
                        primary: Theme.of(context).colorScheme.primary,
                        padding: const EdgeInsets.symmetric(horizontal: 32.0, vertical: 12.0),
                        textStyle: Theme.of(context).textTheme.bodyText1,
                      ),
                      onPressed: onBtnPressed,
                    );
                  }
                ),
              ],
            )
          )
        )
      )
    );
  }
}

class _SignUpFormFields extends StatelessWidget {

  const _SignUpFormFields({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final bloc = FormStateProvider.of(context).model;
    final localizations = AppLocalizations.of(context)!;
    final validationMsgBuilder = ValidationMessageBuilder.of(context);

    return StreamBuilder<bool>(
      initialData: false,
      stream: bloc.isLoading,
      builder: (context, snapshot) {

        final shouldEnableFields = snapshot.data ?? false;

        return Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            StreamBuilder<UsernameError>(
              initialData: UsernameError.none,
              stream: bloc.emailError,
              builder: (context, snapshot) {
                return TextFormField(
                  autocorrect: false,
                  enabled: shouldEnableFields,
                  keyboardType: TextInputType.emailAddress,
                  decoration: InputDecoration(
                    border: const OutlineInputBorder(),
                    prefixIcon: const Icon(Icons.mail),
                    labelText: localizations.email,
                    helperText: ' ',
                    errorText: validationMsgBuilder.messageForUsername(snapshot.data!)
                  ),
                  onChanged: (emailValue) => bloc.emailSink.add(emailValue),
                );
              }
            ),

            const SizedBox( height: 8.0, ),

            StreamBuilder<UsernameError>(
              initialData: UsernameError.none,
              stream: bloc.usernameError,
              builder: (context, snapshot) {
                return TextFormField(
                  autocorrect: false,
                  keyboardType: TextInputType.text,
                  decoration: InputDecoration(
                    border: const OutlineInputBorder(),
                    prefixIcon: const Icon(Icons.person),
                    labelText: localizations.username,
                    helperText: ' ',
                    errorText: validationMsgBuilder.messageForUsername(snapshot.data!),
                  ),
                  onChanged: (usernameValue) => bloc.usernameSink.add(usernameValue),
                );
              }
            ),

            const SizedBox( height: 8.0, ),

            StreamBuilder<PasswordError>(
              initialData: PasswordError.none,
              stream: bloc.passwordError,
              builder: (context, snapshot) {
                return TextFormField(
                  autocorrect: false,
                  enabled: shouldEnableFields,
                  obscureText: true,
                  keyboardType: TextInputType.visiblePassword,
                  decoration: InputDecoration(
                    border: const OutlineInputBorder(),
                    prefixIcon: const Icon(Icons.vpn_key),
                    labelText: localizations.password,
                    helperText: ' ',
                    errorText: validationMsgBuilder.messageForPassword(snapshot.data!)
                  ),
                  onChanged: (passwordValue) => bloc.passwordSink.add(passwordValue),
                );
              }
            ),

            StreamBuilder<PasswordError>(
              initialData: PasswordError.none,
              stream: bloc.passwordConfirmError,
              builder: (context, snapshot) {
                return TextFormField(
                  autocorrect: false,
                  obscureText: true,
                  keyboardType: TextInputType.visiblePassword,
                  decoration: InputDecoration(
                    border: const OutlineInputBorder(),
                    prefixIcon: const Icon(Icons.vpn_key),
                    labelText: localizations.passwordConfirm,
                    helperText: ' ',
                    errorText: validationMsgBuilder.messageForPassword(snapshot.data!),
                  ),
                  onChanged: (passwordValue) => bloc.passwordSink.add(passwordValue),
                );
              }
            ),
          ],
        ); 
      },
    );
  }
}
