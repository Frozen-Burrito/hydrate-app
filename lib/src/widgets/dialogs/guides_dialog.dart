import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

import 'package:hydrate_app/src/api/api_client.dart';
import 'package:hydrate_app/src/utils/launch_url.dart';

class GuidesDialog extends StatelessWidget {
  const GuidesDialog({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {

    final localizations = AppLocalizations.of(context)!;

    return AlertDialog(
      title: Row(
        mainAxisAlignment: MainAxisAlignment.start,
        children: [
          const Icon( Icons.tips_and_updates ),

          Text(localizations.firstSteps),
        ],
      ),
      content: Text("${localizations.userGuideDetails}. ${localizations.askVisitUserGuides}"),
      actions: [
        TextButton(
          onPressed: () {
            Navigator.pop(context, false);
          }, 
          child: Text(localizations.dontShowAgain),
        ),
        TextButton(
          onPressed: () {
            final url = ApiClient.urlForPage("guias");
            UrlLauncher.launchUrlInBrowser(url);
            Navigator.pop(context, true);
          },
          child: Text(localizations.goToUserGuides),
        ),
      ],
    );
  }
}