import 'package:flutter/material.dart';
import 'package:hydrate_app/src/api/api_client.dart';
import 'package:hydrate_app/src/utils/launch_url.dart';
import 'package:hydrate_app/src/widgets/custom_sliver_appbar.dart';
import 'package:hydrate_app/src/widgets/forms/card_form_container.dart';

class CommonFormView extends StatelessWidget {
  
  final String formTitle;
  final String formLabel;

  final Widget formWidget;

  final bool displayBackAction;

  final Color? backgroundColor;

  final Widget? shapeDecoration;

  const CommonFormView({ 
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
            leading: (displayBackAction) 
              ? <Widget>[
                IconButton(
                  icon: const Icon(Icons.arrow_back), 
                  onPressed: () => Navigator.pop(context),
                )
              ] : null,
            actions: <Widget>[
              IconButton(
                icon: const Icon(Icons.help),
                onPressed: () {
                  final url = ApiClient.urlForPage("guias-formularios");
                  UrlLauncher.launchUrlInBrowser(url);
                }, 
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
                  child: CardFormContainer(
                    formWidget,
                    formLabel: formLabel,
                  )
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}