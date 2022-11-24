import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

class SuggestRoutineDialog extends StatelessWidget {

  const SuggestRoutineDialog({
    Key? key,
    this.similarActivityCount = 1
  }) : super(key: key);

  final int similarActivityCount;

  @override
  Widget build(BuildContext context) {

    final localizations = AppLocalizations.of(context)!;
    final content = """${localizations.thereAre} $similarActivityCount ${localizations.similarActivities}. ${localizations.askToCreateRoutineDetails}""";

    return AlertDialog(
      title: Text(localizations.askToCreateRoutine),
      content: Text(content),
      actions: <Widget>[
        TextButton(
          onPressed: () => Navigator.pop(context, false), 
          child: Text(localizations.no),
        ),
        TextButton(
          onPressed: () => Navigator.pop(context, true), 
          child: Text(localizations.createRoutine),
        ),
      ],
    );
  }
}