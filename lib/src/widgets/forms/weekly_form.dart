import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:provider/provider.dart';

import 'package:hydrate_app/src/models/habits.dart';
import 'package:hydrate_app/src/models/validators/validation_message_builder.dart';
import 'package:hydrate_app/src/routes/route_names.dart';
import 'package:hydrate_app/src/services/goals_service.dart';

class WeeklyForm extends StatefulWidget {
  const WeeklyForm({ Key? key }) : super(key: key);

  @override
  _WeeklyFormState createState() => _WeeklyFormState();
}

class _WeeklyFormState extends State<WeeklyForm> {

  final _formKey = GlobalKey<FormState>();

  final Habits _userHabits = Habits.uncommitted();
  
  /// Verifica cada campo del formulario. Si no hay errores, registra la nueva
  /// información del usuario en la DB y redirige a [redirectRoute]. 
  void _validateAndSave(BuildContext context, {String? redirectRoute}) async {
    // Asegurar que el Form está en un estado válido.
    if (_formKey.currentState!.validate()) {

      final saveReport = Provider.of<GoalsService>(context, listen: false).saveWeeklyReport;

      int resultado = await saveReport(_userHabits);

      if (resultado >= 0) {
        if (redirectRoute != null) {
          Navigator.of(context).pushNamedAndRemoveUntil(redirectRoute, (route) => false);
        } else {
          Navigator.of(context).pop();
        }
      } else {
        // Si el reporte no fue guardado, mantener la app en la vista actual y 
        // notificar al usuario.
        final localizations = AppLocalizations.of(context)!;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(localizations.weekSummarySaveError)),
        );
      }
    }
  }
  
  String? _validateDailyHours(ValidationMessageBuilder messageBuilder, String? inputValue) {
    final totalHoursError = Habits.validator.validateHourTotal(_userHabits.totalHoursPerDay);
    return messageBuilder.forTotalDailyHours(totalHoursError);
  }

  String? _validateMaxTemperature(ValidationMessageBuilder messageBuilder, String? inputValue) {
    final maxTemperatureError = Habits.validator.validateMaxTemperature(inputValue);
    return messageBuilder.forMaxTemperature(maxTemperatureError);
  }

  @override
  Widget build(BuildContext context) {

    final localizations = AppLocalizations.of(context)!;
    final messageBuilder = ValidationMessageBuilder.of(context);

    return Form(
      key: _formKey,
      autovalidateMode: AutovalidateMode.onUserInteraction,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[

          TextFormField(
            autocorrect: false,
            keyboardType: TextInputType.number,
            decoration: InputDecoration(
              border: const OutlineInputBorder(),
              labelText: localizations.hoursOfSleep,
              hintText: localizations.hoursOfSleepHint,
              helperText: " ",
              suffixIcon: const Icon(Icons.bedtime)
            ),
            onChanged: (value) {
              setState(() {
                _userHabits.hoursOfSleep = double.tryParse(value) ?? 0.0;
              });
            },
            validator: (value) => _validateDailyHours(messageBuilder, value),
          ),

          const SizedBox( height: 16.0, ),

          TextFormField(
            autocorrect: false,
            keyboardType: TextInputType.number,
            decoration: InputDecoration(
              border: const OutlineInputBorder(),
              labelText: localizations.hoursOfActivity,
              hintText: localizations.hoursOfActivityHint,
              helperText: " ",
              suffixIcon: const Icon(Icons.directions_run)
            ),
            onChanged: (value) {
              setState(() {
                _userHabits.hoursOfActivity = double.tryParse(value) ?? 0.0;
              });
            },
            validator: (value) => _validateDailyHours(messageBuilder, value),
          ),

          const SizedBox( height: 16.0, ),

          TextFormField(
            autocorrect: false,
            keyboardType: TextInputType.number,
            decoration: InputDecoration(
              border: const OutlineInputBorder(),
              labelText: localizations.hoursOfOccupation,
              hintText: localizations.hoursOfOccupationHint,
              helperText: " ",
              suffixIcon: const Icon(Icons.work)
            ),
            onChanged: (value) {
              setState(() {
                _userHabits.hoursOfOccupation = double.tryParse(value) ?? 0.0;
              });
            },
            validator: (value) => _validateDailyHours(messageBuilder, value),
          ),

          Text(
            localizations.maxTemperatureDetails, 
            style: TextStyle(fontSize: 14.0, color: Colors.grey.shade700),
          ),

          const SizedBox( height: 16.0, ),

          TextFormField(
            autocorrect: false,
            keyboardType: TextInputType.number,
            decoration: InputDecoration(
              border: const OutlineInputBorder(),
              labelText: localizations.maxTemperatureLabel,
              hintText: localizations.maxTemperatureHint,
              helperText: " ",
              suffixIcon: const Icon(Icons.thermostat)
            ),
            onChanged: (value) {
              setState(() {
                _userHabits.maxTemperature = double.tryParse(value) ?? 0.0;
              });
            },
            validator: (value) => _validateMaxTemperature(messageBuilder, value),
          ),

          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              Expanded(
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    primary: Colors.grey.shade700,
                    padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 16.0),
                    textStyle: Theme.of(context).textTheme.button,
                  ),
                  onPressed: () => Navigator.pop(context),
                  child: Text(localizations.cancel),
                ),
              ),

              const SizedBox( width: 16.0, ),

              Expanded(
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    primary: Theme.of(context).colorScheme.primary,
                    padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 16.0),
                    textStyle: Theme.of(context).textTheme.button,
                  ),
                  onPressed: () => _validateAndSave(context, redirectRoute: RouteNames.home),
                  child: Text(localizations.continueAction),
                ),
              ),
            ]
          ),
        ]
      ),
    );
  }
}