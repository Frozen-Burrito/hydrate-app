import 'package:flutter/material.dart';
import 'package:hydrate_app/src/utils/launch_url.dart';

class UrlListTile extends StatelessWidget {

  const UrlListTile({ 
    Key? key, 
    required this.title,
    this.leadingIcon = Icons.question_answer,
    required this.uriToLaunch, 
  }) : super(key: key);

  final String title;

  final IconData leadingIcon;

  final Uri uriToLaunch;

  @override
  Widget build(BuildContext context) {

    return ListTile(
      minVerticalPadding: 24.0,
      leading: Icon(
        leadingIcon, 
        size: 24.0, 
      ),
      title: Text(title),
      contentPadding: const EdgeInsets.all( 16.0, ),
      trailing: const Icon(
        Icons.arrow_forward,
        size: 24.0,
      ),
      onTap: () => UrlLauncher.launchUrlInBrowser(uriToLaunch),
    );
  }
}