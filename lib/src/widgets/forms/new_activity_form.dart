import 'dart:math';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

import 'package:hydrate_app/src/models/models.dart';
import 'package:hydrate_app/src/provider/activity_provider.dart';
import 'package:hydrate_app/src/provider/profile_provider.dart';
import 'package:hydrate_app/src/routes/route_names.dart';
import 'package:hydrate_app/src/utils/dropdown_labels.dart';

class NewActivityForm extends StatelessWidget {

  const NewActivityForm(this.currentProfileId, { Key? key }) : super(key: key);

  final int currentProfileId;

  /// Verifica cada campo del formulario. Si no hay errores, inserta la nueva
  /// meta en la DB y redirige a [redirectRoute]. 
  void _saveActivityRecord(BuildContext context, ActivityRecord newActivity, {String? redirectRoute}) async {
    // Asociar el perfil del usuario actual con la nueva meta.
    newActivity.profileId = currentProfileId;

    final provider = Provider.of<ActivityProvider>(context, listen: false);

    if (newActivity.activityType.id < 0) {
      final activityTypes = await provider.activityTypes;

      int actTypeIndex = activityTypes.indexWhere((t) => t.id == 0);

      newActivity.activityType = activityTypes[actTypeIndex];
    }

    assert(newActivity.activityType.id >= 0);

    int resultado = await provider.createActivityRecord(newActivity);

    if (resultado >= 0) {
      if (redirectRoute != null) {
        Navigator.of(context).pushNamedAndRemoveUntil(redirectRoute, (route) => false);
      } else {
        Navigator.of(context).pop();
      }
    }
  }

  @override
  Widget build(BuildContext context) {

    final activityProvider = Provider.of<ActivityProvider>(context);
    final localizations = AppLocalizations.of(context)!;

    return FutureBuilder<Map<DateTime, List<ActivityRecord>>>(
      future: activityProvider.activitiesFromPastWeek,
      initialData: const {},
      builder: (context, snapshot) {

        if (snapshot.hasData) {

          final activityRecords = snapshot.data;

          bool hasExhausting = activityProvider.hasExhaustingActivities(activityRecords);

          return Column(
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              
              Container(
                margin: EdgeInsets.only( 
                  bottom: hasExhausting ? 16.0 : 0.0 
                ),
                child: hasExhausting  
                  ? Chip(
                    backgroundColor: Colors.yellow.shade700.withOpacity(0.3),
                    avatar: Icon(
                      Icons.warning_rounded,
                      color: Colors.yellow.shade500,
                    ),
                    label: Text(
                      //TODO: Agregar i18n.
                      'Actividad extenuante reciente',
                      style: Theme.of(context).textTheme.bodyText2?.copyWith(
                        color: Colors.yellow.shade500
                      ),
                    ),
                  )
                  : null
              ),
              
              _NewActivityFormFields(
                onSave: _saveActivityRecord
              ),
            ],
          );
        } else if (snapshot.hasError) {
          return Center(
            //TODO: Actualizar este texto, son registros, no tipos, de actividad.
            child: Text(localizations.noActTypes),
          );
        }

        return const Center(
          child: CircularProgressIndicator(),
        );          
      }
    );
  }
}

class _NewActivityFormFields extends StatefulWidget {

  const _NewActivityFormFields({
    required this.onSave,
    Key? key, 
  }) : super(key: key);

  final Function(BuildContext, ActivityRecord, { String redirectRoute }) onSave;

  @override
  State<_NewActivityFormFields> createState() => _NewActivityFormFieldsState();
}

class _NewActivityFormFieldsState extends State<_NewActivityFormFields> {

  final _formKey = GlobalKey<FormState>();

  final newActivityRecord = ActivityRecord.uncommited();

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

  void onActivityTypeSelected(ActivityType activityType, double userWeight) {
    setState(() {
      newActivityRecord.activityType = activityType;

      newActivityRecord.aproximateData(userWeight);
    });

    kCalController.text = newActivityRecord.formattedKcal;
    distanceController.text = newActivityRecord.formattedDistance;
  }

  @override
  Widget build(BuildContext context) {

    final userWeight = Provider.of<ProfileProvider>(context).profile.weight;

    final localizations = AppLocalizations.of(context)!;

    return Form(
      key: _formKey,
      autovalidateMode: AutovalidateMode.onUserInteraction,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[

          _ActivityTypeDropdown(
            value: newActivityRecord.activityType.id,
            onActivityTypeChange: (activityType) {
              onActivityTypeSelected(activityType, userWeight);
            }
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
                  onPressed: () {

                    bool isFormValid = _formKey.currentState?.validate() ?? false;
                    
                    if (isFormValid) {
                      widget.onSave(
                        context, 
                        newActivityRecord, 
                        redirectRoute: RouteNames.home
                      );
                    }
                  } 
                ),
              ),
            ]
          ),
        ],
      ),
    );
  }
}

class _ActivityTypeDropdown extends StatelessWidget {

  const _ActivityTypeDropdown({
    required this.value, 
    required this.onActivityTypeChange,
    Key? key,
  }) : super(key: key);

  final int value;
  final void Function(ActivityType) onActivityTypeChange;

  @override
  Widget build(BuildContext context) {

    final localizations = AppLocalizations.of(context)!;
    final activityProvider = Provider.of<ActivityProvider>(context);

    return FutureBuilder<List<ActivityType>>(
      future: activityProvider.activityTypes,
      initialData: const [],
      builder: (context, snapshot) {

        final activityTypes = snapshot.data;

        final dropdownItems = activityTypes != null
          ? DropdownLabels.activityTypes(context, activityTypes)
          : null;

        final onChangeHandler = activityTypes != null
          ? (int? newValue) {
              // Obtener el tipo de actividad correspondiente.
              int typeIndex = activityTypes
                .indexWhere((t) => t.id == newValue);

              final selectedType = activityTypes[typeIndex];

              onActivityTypeChange(selectedType);
            }
          : null;

        return DropdownButtonFormField(
          //TODO: Agregar a localizations un disabledHint para dropdown de tipos de act.
          disabledHint: const Text('No se encontraron actividades'),
          decoration: InputDecoration(
            border: const OutlineInputBorder(),
            labelText: localizations.whatType,
            helperText: ' ',
            hintText: localizations.select
          ),
          items: dropdownItems,
          value: max(value, 0),
          validator: (int? value) => ActivityType.validateType(value),
          onChanged: onChangeHandler
        );
      }
    );
  }
}

