import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

import 'package:hydrate_app/src/models/models.dart';
import 'package:hydrate_app/src/provider/activity_provider.dart';
import 'package:hydrate_app/src/provider/profile_provider.dart';
import 'package:hydrate_app/src/routes/route_names.dart';
import 'package:hydrate_app/src/utils/dropdown_labels.dart';

class NewActivityForm extends StatefulWidget {

  const NewActivityForm(this.currentProfileId, { Key? key, }) : super(key: key);

  final int currentProfileId;

  @override
  State<NewActivityForm> createState() => _NewActivityFormState();
}

class _NewActivityFormState extends State<NewActivityForm> {

  final _formKey = GlobalKey<FormState>();

  final newActivityRecord = ActivityRecord(
    title: '', 
    date: DateTime.now(), 
    duration: 0, 
    activityType: ActivityType(mets: 0.0, activityTypeValue: ActivityTypeValue.walk), 
    profileId: -1
  );

  bool isLoading = false;

  int titleLength = 0;
  int notesLength = 0;

  final dateController = TextEditingController();
  final durationController = TextEditingController();
  final distanceController = TextEditingController();
  final kCalController = TextEditingController();
  
  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    dateController.dispose();
    durationController.dispose();
    distanceController.dispose();
    kCalController.dispose();
    super.dispose();
  }

  /// Verifica cada campo del formulario. Si no hay errores, inserta la nueva
  /// meta en la DB y redirige a [redirectRoute]. 
  void _validateAndSave(BuildContext context, {String? redirectRoute}) async {
    if (_formKey.currentState!.validate()) {
      // Asociar el perfil del usuario actual con la nueva meta.
      newActivityRecord.profileId = widget.currentProfileId;

      final provider = Provider.of<ActivityProvider>(context, listen: false);

      if (newActivityRecord.activityType.id < 0) {
        int activityTypeIdx = provider.activityTypes
                    .indexWhere((t) => t.activityTypeValue.index == 0);

        newActivityRecord.activityType = provider.activityTypes[activityTypeIdx];
      }

      int resultado = await provider.createActivityRecord(newActivityRecord);

      if (resultado >= 0) {
        if (redirectRoute != null) {
          Navigator.of(context).pushNamedAndRemoveUntil(redirectRoute, (route) => false);
        } else {
          Navigator.of(context).pop();
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {

    final userWeight = Provider.of<ProfileProvider>(context).profile.weight;

    final localizations = AppLocalizations.of(context)!;

    return Form(
      key: _formKey,
      autovalidateMode: AutovalidateMode.onUserInteraction,
      child: Consumer<ActivityProvider>(
        builder: (_, provider, __) {

          if (provider.areTypesLoading) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          } else if (provider.activityTypes.isEmpty) {
            return Center(
              child: Text(localizations.noActTypes),
            );
          }

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[

              DropdownButtonFormField(
                decoration: InputDecoration(
                  border: const OutlineInputBorder(),
                  labelText: localizations.whatType,
                  helperText: ' ',
                  hintText: localizations.select
                ),
                items: DropdownLabels.activityTypes(context, provider.activityTypes),
                value: newActivityRecord.activityType.activityTypeValue.index,
                validator: (int? value) => ActivityType.validateType(value),
                onChanged: (int? newValue) {
                  // Obtener el tipo de actividad correspondiente.
                  int activityTypeIdx = provider.activityTypes
                    .indexWhere((t) => t.activityTypeValue.index == newValue);
        
                  setState(() {
                    newActivityRecord.activityType = provider.activityTypes[activityTypeIdx];

                    newActivityRecord.aproximateData(userWeight);
                  });

                  kCalController.text = newActivityRecord.formattedKcal;
                  distanceController.text = newActivityRecord.formattedDistance;
                },
              ),
        
              const SizedBox( height: 16.0, ),
        
              TextFormField(
                maxLength: 40,
                maxLines: 1,
                decoration: InputDecoration(
                  border: const OutlineInputBorder(),
                  labelText: localizations.activityTitle,
                  hintText: localizations.activityTitleHint,
                  helperText: ' ',
                  suffixIcon: const Icon(Icons.text_fields),
                  counterText: '${titleLength.toString()}/40'
                ),
                validator: (value) => ActivityRecord.validateTitle(value),
                onChanged: (value) => setState(() {
                  newActivityRecord.title = value;
                  titleLength = newActivityRecord.title.length;
                }),
              ),
        
              const SizedBox( height: 16.0, ),
        
              TextFormField(
                readOnly: true,
                controller: dateController,
                decoration: InputDecoration(
                  border: const OutlineInputBorder(),
                  labelText: localizations.date,
                  helperText: ' ', // Para evitar cambios en la altura del widget
                  suffixIcon: const Icon(Icons.event_rounded)
                ),
                onTap: () async {
        
                  final now = DateTime.now();
        
                  final newActivityDate = await showDatePicker(
                    context: context, 
                    initialDate: now, 
                    firstDate: DateTime(2000), 
                    lastDate: now
                  );
        
                  final newActivityTime = await showTimePicker(
                    context: context, 
                    initialTime: TimeOfDay.fromDateTime(now)
                  );
        
                  if (newActivityDate != null && newActivityTime != null) {
        
                    newActivityRecord.date = DateTime(
                      newActivityDate.year,
                      newActivityDate.month,
                      newActivityDate.day,
                      newActivityTime.hour,
                      newActivityTime.minute,
                    );
        
                    dateController.text = newActivityRecord.formattedDate;
                  }
                  
                },
              ),
        
              const SizedBox( height: 16.0, ),
        
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: <Widget>[
                  Expanded(
                    child: TextFormField(
                      autocorrect: false,
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                        border: const OutlineInputBorder(),
                        labelText: '${localizations.duration} (minutos)',
                        hintText: '20 min.',
                        helperText: ' ',
                        suffixIcon: const Icon(Icons.timer_rounded)
                      ),
                      onChanged: (value) {
                        setState(() {
                          newActivityRecord.duration = int.tryParse(value.split(" ").first) ?? 0;

                          newActivityRecord.aproximateData(userWeight);
                       
                          kCalController.text = newActivityRecord.formattedKcal;
                          distanceController.text = newActivityRecord.formattedDistance;
                          durationController.text = newActivityRecord.formattedDuration; 
                        });
                      },
                      validator: (value) => ActivityRecord.validateDuration(value),
                    ),
                  ),
        
                  const SizedBox( width: 16.0, ),
        
                  Expanded(
                    child: TextFormField(
                      autocorrect: false,
                      controller: distanceController,
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                        border: const OutlineInputBorder(),
                        labelText: localizations.distance,
                        hintText: '1 km',
                        helperText: ' ',
                      ),
                      onChanged: (value) {
        
                        setState(() {
                          newActivityRecord.distance = double.tryParse(value.split(" ").first) ?? 0.0;

                          newActivityRecord.distanceModifiedByUser();
                        });
        
                        // distanceController.text = newActivityRecord.formattedDistance; 
                      },
                      validator: (value) => ActivityRecord.validateDitance(value),
                    ),
                  ),
                ]
              ),
        
              const SizedBox( height: 16.0, ),
        
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: <Widget>[
                  Expanded(
                    child: TextFormField(
                      autocorrect: false,
                      keyboardType: TextInputType.number,
                      controller: kCalController,
                      decoration: InputDecoration(
                        border: const OutlineInputBorder(),
                        labelText: localizations.kcalBurned,
                        hintText: '1700 kCal',
                        helperText: ' ',
                        suffixIcon: const Icon(Icons.bolt),
                      ),
                      onChanged: (value) {
                        setState(() {
                          newActivityRecord.kiloCaloriesBurned = int.tryParse(value.split(" ").first) ?? 0;

                          newActivityRecord.kCalModifiedByUser();
                        });
        
                        // kCalController.text = newActivityRecord.formattedKcal; 
                      },
                      validator: (value) => ActivityRecord.validateKcal(value),
                    ),
                  ),
        
                  const SizedBox( width: 16.0, ),
        
                  Expanded(
                    child: CheckboxListTile(
                      title: Text(localizations.outdoor),
                      dense: true,
                      value: newActivityRecord.doneOutdoors, 
                      onChanged: (bool? value) {
                        setState(() {
                          newActivityRecord.doneOutdoors = value ?? false;
                        });
                      }
                    ),
                  ),
                ]
              ),
        
              const SizedBox( height: 16.0, ),
        
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: <Widget>[
                  Expanded(
                    child: ElevatedButton(
                      child: Text(localizations.cancel),
                      style: ElevatedButton.styleFrom(
                        primary: Colors.grey.shade700,
                      ),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ),
        
                  const SizedBox( width: 16.0, ),
        
                  Expanded(
                    child: ElevatedButton(
                      child: Text(localizations.create),
                      style: ElevatedButton.styleFrom(
                        primary: Colors.blue,
                      ),
                      onPressed: () => _validateAndSave(context, redirectRoute: RouteNames.home),
                    ),
                  ),
                ]
              ),
            ],
          );
        }
      ),
    );
  }
}