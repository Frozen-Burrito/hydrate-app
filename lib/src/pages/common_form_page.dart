import 'package:flutter/material.dart';
import 'package:hydrate_app/src/models/api.dart';
import 'package:hydrate_app/src/utils/launch_url.dart';
import 'package:hydrate_app/src/widgets/custom_sliver_appbar.dart';

class CommonFormPage extends StatelessWidget {
  
  final String formTitle;

  final Widget formWidget;

  const CommonFormPage({ 
    required this.formTitle, 
    required this.formWidget, 
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
            leading: IconButton(
              icon: const Icon(Icons.arrow_back), 
              onPressed: () => Navigator.pop(context)
            ),
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
                  formWidget
                ]
              ),
            ),
        ],
      ),
    );
  }
}