import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

import 'package:hydrate_app/src/models/enums/auth_action_type.dart';
import 'package:hydrate_app/src/widgets/forms/login_form.dart';
import 'package:hydrate_app/src/widgets/forms/signup_form.dart';
import 'package:hydrate_app/src/routes/route_names.dart';
import 'package:hydrate_app/src/widgets/shapes.dart';

class AuthView extends StatelessWidget {
  const AuthView({ Key? key }) : super(key: key);

  AuthActionType _getFormTypeFromArgs(BuildContext context) {
    if (ModalRoute.of(context)!.settings.arguments is AuthActionType) {
      return ModalRoute.of(context)!.settings.arguments as AuthActionType;
    } else {
      return AuthActionType.signIn;
    }
  }

  @override
  Widget build(BuildContext context) {

    final formType = _getFormTypeFromArgs(context);
    final isSignIn = formType == AuthActionType.signIn;

    final localizations = AppLocalizations.of(context)!;

    return Scaffold(
      body: SafeArea(
        top: false,
        bottom: false,
        child: CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: <Widget> [

            SliverToBoxAdapter(
              child: Stack(
                alignment: Alignment.topCenter,
                children: <Widget>[
                  const RoundedRectangle(),

                  Positioned(
                    top: 48.0,
                    right: 32.0,
                    child: IconButton(
                      icon: const Icon(Icons.close, size: 36.0,),
                      onPressed: () => Navigator.of(context)
                          .pushNamedAndRemoveUntil(RouteNames.home, (route) => false), 
                    ),
                  ),

                  Column(
                    children: <Widget>[

                      const SizedBox( height: 72.0,),

                      Center(
                        child: Icon(
                          Icons.account_circle, 
                          size: 80.0,
                          color: Theme.of(context).colorScheme.onPrimary
                        ),
                      ),

                      (isSignIn ? LoginForm() : SignupForm()),

                      const SizedBox( height: 32.0,),

                      Text(
                        ((isSignIn) 
                          ? localizations.dont
                          : localizations.already) + localizations.haveAccount
                      ),

                      TextButton(
                        child: Text(
                          (isSignIn
                            ? localizations.signUp 
                            : localizations.signIn),
                          style: Theme.of(context).textTheme.bodyText1?.copyWith(
                            color: Theme.of(context).colorScheme.primary,
                            fontWeight: FontWeight.w600,
                            fontSize: 18.0
                          )
                        ),
                        onPressed: () => Navigator.pushNamed(
                          context, 
                          RouteNames.authentication,
                          arguments: (isSignIn) ? AuthActionType.signUp : AuthActionType.signIn
                        )
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ]
        ),
      )
    );
  }
}