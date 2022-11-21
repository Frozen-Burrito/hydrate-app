import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:provider/provider.dart';

import 'package:hydrate_app/src/bloc/auth_form_bloc.dart';
import 'package:hydrate_app/src/routes/route_names.dart';
import 'package:hydrate_app/src/models/enums/error_types.dart';
import 'package:hydrate_app/src/models/validators/validation_message_builder.dart';
import 'package:hydrate_app/src/services/profile_service.dart';
import 'package:hydrate_app/src/widgets/dialogs/link_account_dialog.dart';
import 'package:hydrate_app/src/widgets/form_state_provider.dart';

class LoginForm extends StatelessWidget {

  LoginForm({Key? key}) : super(key: key);

  final AuthFormBloc bloc = AuthFormBloc.emailSignIn();

  void _handleLoginSubmit(BuildContext context) {
    FocusScope.of(context).unfocus();
    bloc.submitForm(context);
  }

  void _handleAuthResult(BuildContext context, AuthResult? authResult) {

    if (authResult == AuthResult.canFetchProfileSettings) {
      final authToken = Provider.of<ProfileService>(context, listen: false).authToken;
      bloc.fetchProfileSettings(context, authToken);

    } else if (authResult == AuthResult.authenticated) {
      Navigator.of(context).popAndPushNamed(RouteNames.home);

    } else if (authResult == AuthResult.newProfileCreated) {
      Navigator.of(context).popAndPushNamed(RouteNames.initialForm);

    } else if (authResult == AuthResult.canLinkProfileToAccount) {
      askUserForAccountLinkConfirm(context);
    }
  }

  Future<void> askUserForAccountLinkConfirm(BuildContext context) async {

    final shouldLinkProfile = (await showDialog<bool?>(
      context: context, 
      builder: (_) => const LinkAccountDialog(),
    )) ?? false;

    if (shouldLinkProfile) {
      bloc.linkAccountToProfile(context);
    }
  }
  
  String _buildMessageForAuthResult(AppLocalizations localizations, AuthResult authResult) {

    final String message;

    switch (authResult) {
      case AuthResult.credentialsError:
        message = localizations.errNoUser;
        break;
      case AuthResult.serviceUnavailable:
        message = localizations.errCheckInternetConn;
        break;
      default: 
        message = "";
        break;
    }

    return message;
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
                    
                      final isAuthErrorResult = snapshot.data == AuthResult.credentialsError
                        || snapshot.data == AuthResult.serviceUnavailable;

                      if (snapshot.hasData && isAuthErrorResult) {
                        return Padding(
                          padding: const EdgeInsets.only(top: 8.0, bottom: 16.0),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: <Widget>[
                              Icon((snapshot.data == AuthResult.serviceUnavailable)
                                ? Icons.cloud_off
                                : Icons.error
                              ),
      
                              const SizedBox( width: 8.0, ),
                              
                              Expanded(
                                child: Text(
                                  _buildMessageForAuthResult(localizations, snapshot.data!), 
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
    
                  SizedBox(
                    width: MediaQuery.of(context).size.width * 0.5,
                    child: StreamBuilder<bool>(
                      initialData: false,
                      stream: bloc.isLoading,
                      builder: (context, snapshot) {
    
                        final isFormLoading = snapshot.data ?? false;

                        return StreamBuilder<AuthResult>(
                          stream: bloc.formState,
                          builder: (context, snapshot) {

                            final canFormBeSubmitted = snapshot.data == AuthResult.canSendAuthRequest;

                            Future.microtask(() => _handleAuthResult(context, snapshot.data));

                            return ElevatedButton(
                              onPressed: (canFormBeSubmitted && !isFormLoading)
                                ? () => _handleLoginSubmit(context)
                                : null,
                              style: ElevatedButton.styleFrom(
                                primary: Theme.of(context).colorScheme.primary,
                                padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 16.0),
                                textStyle: Theme.of(context).textTheme.bodyText1,
                              ), 
                              child: (isFormLoading)
                                ? const SizedBox(
                                  height: 24.0,
                                  width: 24.0,
                                  child: CircularProgressIndicator()
                                )
                                : Text(
                                  localizations.continueAction, 
                                  textAlign: TextAlign.center,
                                ),
                            );
                          }
                        );
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
                    helperText: " ",
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
                    helperText: " ",
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
