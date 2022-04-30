import 'package:flutter/material.dart';
import 'package:hydrate_app/src/models/api.dart';
import 'package:hydrate_app/src/utils/launch_url.dart';
import 'package:hydrate_app/src/widgets/custom_sliver_appbar.dart';
import 'package:hydrate_app/src/widgets/forms/card_form_container.dart';

class CommonFormPage extends StatelessWidget {
  
  final String formTitle;
  final String formLabel;

  final Widget formWidget;

  final bool displayBackAction;

  const CommonFormPage({ 
    required this.formTitle, 
    required this.formLabel, 
    required this.formWidget,
    this.displayBackAction = true,
    Key? key 
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.blue,
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: <Widget>[
          CustomSliverAppBar(
            title: formTitle,
            leading: <Widget>[
              (displayBackAction) 
              ? IconButton(
                icon: const Icon(Icons.arrow_back), 
                onPressed: () => Navigator.pop(context),
              )
              : const SizedBox(width: 0.0,),
            ],
            actions: <Widget>[
              IconButton(
                icon: const Icon(Icons.help),
                onPressed: () => UrlLauncher.launchUrlInBrowser(API.uriFor('guias-formularios')), 
              ),
            ],
          ),

          SliverToBoxAdapter(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: <Widget>[
                  CardFormContainer(
                    formWidget,
                    formLabel: formLabel,
                  ),

                  const SizedBox( height: 48.0, ),
                ]
              ),
            ),
        ],
      ),
    );
  }
}