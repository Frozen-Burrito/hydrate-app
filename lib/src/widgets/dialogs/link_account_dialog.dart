import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

class LinkAccountDialog extends StatelessWidget {

  const LinkAccountDialog({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {

    final localizations = AppLocalizations.of(context)!;

    final String dialogTitle = localizations.askAccountLink;
    final String content = "${localizations.profileHasNoLinkedAccount}. ${localizations.accountLinkBenefits}.";
    final String cancelButtonText = localizations.continueWithoutLink;
    final String acceptButtonText = localizations.linkProfileToAccount;

    return AlertDialog(
      title: Text(dialogTitle),
      content: Text(content),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false), 
          child: Text(cancelButtonText),
        ),
        TextButton(
          onPressed: () => Navigator.pop(context, true), 
          child: Text(acceptButtonText),
        ),
      ],
    );
  }
}