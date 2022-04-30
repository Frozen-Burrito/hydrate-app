import 'package:flutter/material.dart';
import 'package:hydrate_app/src/models/api.dart';
import 'package:hydrate_app/src/provider/profile_provider.dart';
import 'package:hydrate_app/src/utils/launch_url.dart';
import 'package:hydrate_app/src/widgets/custom_sliver_appbar.dart';
import 'package:hydrate_app/src/widgets/forms/card_form_container.dart';
import 'package:provider/provider.dart';

class CommonFormPage extends StatelessWidget {
  
  final String formTitle;
  final String formLabel;

  final Widget formWidget;

  final bool displayBackAction;

  final Color? backgroundColor;

  final Widget? shapeDecoration;

  const CommonFormPage({ 
    required this.formTitle, 
    required this.formLabel, 
    required this.formWidget,
    this.displayBackAction = true,
    this.backgroundColor,
    this.shapeDecoration,
    Key? key, 
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: (backgroundColor == null )
        ? Theme.of(context).scaffoldBackgroundColor
        : backgroundColor,
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
              child: Stack(
              children: <Widget> [
                (shapeDecoration != null) 
                ? shapeDecoration as Widget
                : const SizedBox(width: 0.0,),

                Center(
                  child: formWidget
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}