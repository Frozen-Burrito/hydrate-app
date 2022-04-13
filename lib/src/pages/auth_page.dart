import 'package:flutter/material.dart';

import 'package:hydrate_app/src/widgets/forms/login_form.dart';
import 'package:hydrate_app/src/widgets/forms/signup_form.dart';
import 'package:hydrate_app/src/widgets/shapes.dart';

enum AuthFormType {
  login,
  signup
}

class AuthPage extends StatelessWidget {
  const AuthPage({ Key? key }) : super(key: key);

  @override
  Widget build(BuildContext context) {

    final formType = ModalRoute.of(context)!.settings.arguments as AuthFormType;

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
                      onPressed: () => Navigator.of(context).pushNamedAndRemoveUntil('/', (route) => false), 
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

                      formType == AuthFormType.login 
                        ? const LoginForm()
                        : const SignupForm(),

                      const SizedBox( height: 32.0,),

                      Text('¿${formType == AuthFormType.login ? 'No' : 'Ya'} tienes una cuenta?'),

                      TextButton(
                        child: Text(
                          formType == AuthFormType.login ? 'Regístrate' : 'Inicia sesión',
                          style: Theme.of(context).textTheme.bodyText1?.copyWith(
                            color: Theme.of(context).colorScheme.primary,
                            fontWeight: FontWeight.w600,
                            fontSize: 18.0
                          )
                        ),
                        onPressed: () => Navigator.pushNamed(
                          context, 
                          'auth',
                          arguments: formType == AuthFormType.login ? AuthFormType.signup : AuthFormType.login
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