import 'package:flutter/material.dart';
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
              child: Text( 'Reporte ${isMedical ? 'Médico' : 'Semanal'} Disponible', maxLines: 2, )
            )
          ),
        ],
      ),
      content: const Text('Ha pasado un tiempo desde tu último reporte. ¿Quieres agregar datos sobre tu progreso?'),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false), 
          child: const Text('Por ahora no'),
        ),
        TextButton(
          onPressed: () => Navigator.popAndPushNamed(
            context, 
            isMedical ? RouteNames.medicalForm : RouteNames.weeklyForm,
            result: true,
          ),
          child: const Text('Responder'),
        ),
      ],
    );
  }
}

enum ReportType {
  periodic,
  medical,
}
