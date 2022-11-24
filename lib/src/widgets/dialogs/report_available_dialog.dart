import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

import 'package:hydrate_app/src/routes/route_names.dart';

class ReportAvailableDialog extends StatelessWidget {

  const ReportAvailableDialog(this.reportType, {Key? key}) : super(key: key);

  const ReportAvailableDialog.weekly({Key? key}) : this(
    ReportType.periodic,
    key: key
  );

  const ReportAvailableDialog.medical({Key? key}) : this(
    ReportType.medical,
    key: key
  );

  final ReportType reportType;

  @override
  Widget build(BuildContext context) {

    final localizations = AppLocalizations.of(context)!;
    final isMedical = reportType == ReportType.medical;

    return AlertDialog(
      titleTextStyle: Theme.of(context).textTheme.headline5,
      contentTextStyle: Theme.of(context).textTheme.bodyText1,
      title: Row(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon( isMedical ? Icons.medical_information : Icons.checklist ),

          Expanded(
            child: Container(
              margin: const EdgeInsets.only( left: 8.0 ),
              child: Text(
                isMedical ? localizations.medicalReportAvailable : localizations.weeklySummaryAvailable, 
                maxLines: 2, 
              ),
            )
          ),
        ],
      ),
      content: Text("${localizations.aWhileSinceLastReport}. ${localizations.askAddProgressData}"),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false), 
          child: Text(localizations.notNow),
        ),
        TextButton(
          onPressed: () => Navigator.popAndPushNamed(
            context, 
            isMedical ? RouteNames.medicalForm : RouteNames.weeklyForm,
            result: true,
          ),
          child: Text(localizations.respond),
        ),
      ],
    );
  }
}

enum ReportType {
  periodic,
  medical,
}
