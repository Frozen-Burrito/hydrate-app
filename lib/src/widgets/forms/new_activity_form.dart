import 'dart:math';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

import 'package:hydrate_app/src/models/models.dart';
import 'package:hydrate_app/src/models/routine_occurrence.dart';
import 'package:hydrate_app/src/models/validators/activity_validator.dart';
import 'package:hydrate_app/src/models/validators/validation_message_builder.dart';
import 'package:hydrate_app/src/routes/route_names.dart';
import 'package:hydrate_app/src/services/activity_service.dart';
import 'package:hydrate_app/src/services/profile_service.dart';
import 'package:hydrate_app/src/utils/datetime_extensions.dart';
import 'package:hydrate_app/src/utils/dropdown_labels.dart';
import 'package:hydrate_app/src/widgets/dialogs/suggest_routine_dialog.dart';

class NewActivityForm extends StatelessWidget {

  const NewActivityForm({ Key? key }) : super(key: key);

  /// Agrega un registro para [newActivity], asociado con el perfil de usuario 
  /// activo. Si es exitoso, redirige la app a [redirectRoute].
  void _saveActivityRecord(BuildContext context, ActivityRecord newActivity, {String? redirectRoute}) async {

    // Obtener instancias de providers, usando el context.
    final activityProvider = Provider.of<ActivityService>(context, listen: false);

    final profileProvider = Provider.of<ProfileService>(context, listen: false);

    // Asociar el perfil del usuario actual con la nueva meta.
    newActivity.profileId = profileProvider.profileId;

    if (newActivity.activityType.id < 0) {
      final activityTypes = await activityProvider.activityTypes;

      if (activityTypes != null) {
        int actTypeIndex = activityTypes.indexWhere((t) => t.id == 0);

        newActivity.activityType = activityTypes[actTypeIndex];
      }
    }

    assert(newActivity.activityType.id >= 0);

    final pastWeekActivities = await activityProvider.activitiesFromPastWeek;

    final today = DateTime.now().onlyDate;
    final activitiesToday = pastWeekActivities[today]?.length ?? 0;

    // Dar una recompensa al usuario si [newActivity] es de sus primeras actividades
    // el día de hoy.
    await giveActivityReward(
      activitiesToday, 
      newActivity, 
      profileProvider.profileChanges.addCoins,
      profileProvider.saveProfileChanges
    );

    // Obtener todos los registros de actividades de la semana pasada que sean 
    // similares a newActivity.
    final similarActivities = await activityProvider
        .isActivitySimilarToPrevious(newActivity, onlyPastWeek: true);

    int resultadoDeSave = -1;

    // Determinar si puede crear una rutina con la nueva actividad.
    if (similarActivities.isNotEmpty) {
      // Hay actividades similares. Preguntar si desea crear una rutina con ellas.
      final shouldCreateRoutine = await showAskIfRoutineDialog(
        context, 
        similarActivities.length
      ) ?? false;

      // Revisar si usuario eligió crear una nueva rutina.
      if (shouldCreateRoutine) {
        // Obtener los días de la semana en que el usuario realiza la actividad. 
        final routineDays = similarActivities.map((activity) => activity.date.weekday);

        // Asegurar que los días de la rutina no contengan duplicados (que no haya
        // dos elementos en la lista con el mismo día) convirtiendo temporalmente a un Set.
        final uniqueRoutineDays = routineDays.toSet().toList();

        final baseActivity = similarActivities.first;

        // Crear nueva rutina a partir de actividades previas.
        final newRoutine = Routine(
          uniqueRoutineDays,
          activityId: baseActivity.id,
          timeOfDay: baseActivity.date.onlyTime, 
          profileId: profileProvider.profileId
        );
        
        resultadoDeSave = await activityProvider.createRoutine(newRoutine);
      }
    } else {
      // Crear registro local de actividad.
      resultadoDeSave = await activityProvider.createActivityRecord(newActivity);
    }

    if (resultadoDeSave >= 0) {
      if (redirectRoute != null) {
        Navigator.of(context).pushNamedAndRemoveUntil(redirectRoute, (route) => false);
      } else {
        Navigator.of(context).pop();
      }
    }
  }

  /// Revisa si el usuario ha registrado [] o menos actividades en el día actual.
  /// 
  /// Si es así, otorga una recompensa en monedas al perfil de usuario, dada por
  /// [newActivity.coinReward]. Si no, no realiza ninguna modificación al perfil.
  Future<void> giveActivityReward(
    int numOfActivitiesToday, 
    ActivityRecord newActivity,
    void Function(int) giveCoinsToProfile,
    Future<void> Function() saveProfile
  ) {

    if (numOfActivitiesToday <ActivityService.actPerDayWithReward) {
      // Si esta nueva actividad es de las tres primeras del día actual,
      // entregar recompensa en monedas al usuario.
      giveCoinsToProfile(newActivity.coinReward);

      return saveProfile();
    } else {
      return Future.value();
    }
  }

  Future<bool?> showAskIfRoutineDialog(BuildContext context, int numOfSimilarActivities) {

    return showDialog<bool>(
      context: context, 
      builder: (context) => SuggestRoutineDialog(
        similarActivityCount: numOfSimilarActivities,
      )
    );
  }

  @override
  Widget build(BuildContext context) {

    final activityProvider = Provider.of<ActivityService>(context);
    final localizations = AppLocalizations.of(context)!;

    return FutureBuilder<Map<DateTime, List<RoutineOccurrence>>>(
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

  Future<void> _onTapDateField() async {
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

      dateController.text = newActivityRecord.date.toLocalizedDateTime;
    }
  }

  String? _validateTitle(ValidationMessageBuilder messageBuilder, String? input) {
    final titleError = ActivityRecord.validator.validateTitle(input);
    return messageBuilder.forActivityTitle(titleError);
  }

  String? _validateDuration(ValidationMessageBuilder messageBuilder, String? input) {
    final durationError = ActivityRecord.validator
      .validateDurationInMinutes(input, includesUnits: input?.split(" ").length == 2);

    return messageBuilder.forActivityDuration(durationError);
  }

  String? _validateDistance(ValidationMessageBuilder messageBuilder, String? input) {
    final distanceError = ActivityRecord.validator
      .validateDistanceInMeters(input, includesUnits: input?.split(" ").length == 2);

    return messageBuilder.forActivityDistance(distanceError);
  }

  String? _validateKilocalories(ValidationMessageBuilder messageBuilder, String? input) {
    final kCalsError = ActivityRecord.validator
      .validateKcalConsumed(input, includesUnits: input?.split(" ").length == 2);

    return messageBuilder.forActivityKcals(kCalsError);
  }

  @override
  Widget build(BuildContext context) {

    final localizations = AppLocalizations.of(context)!;
    final profileProvider = Provider.of<ProfileService>(context, listen: false);
    final validationMsgBuilder = ValidationMessageBuilder.of(context);

    return FutureBuilder<UserProfile?>(
      future: profileProvider.profile,
      builder: (context, snapshot) {

        if (snapshot.hasData) {

          final userWeight = snapshot.data!.weight;

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
                    counterText: '${titleLength.toString()}/${ActivityValidator.titleLengthRange.max}'
                  ),
                  validator: (value) => _validateTitle(validationMsgBuilder, value),
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
                  onTap: _onTapDateField,
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
                          //TODO: agregar i18n
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
                        validator: (value) => _validateDuration(validationMsgBuilder, value),
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
                          hintText: '1.2 km',
                          helperText: ' ',
                        ),
                        onChanged: (value) {
          
                          setState(() {
                            newActivityRecord.distance = double.tryParse(value.split(" ").first) ?? 0.0;

                            newActivityRecord.userModifiedDistance();
                          });
          
                          // distanceController.text = newActivityRecord.formattedDistance; 
                        },
                        validator: (value) => _validateDistance(validationMsgBuilder, value),
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
                          hintText: '300 kCal',
                          helperText: ' ',
                          suffixIcon: const Icon(Icons.bolt),
                        ),
                        onChanged: (value) {
                          setState(() {
                            newActivityRecord.kiloCaloriesBurned = int.tryParse(value.split(" ").first) ?? 0;

                            newActivityRecord.userModifiedKcal();
                          });
          
                          // kCalController.text = newActivityRecord.formattedKcal; 
                        },
                        validator: (value) => _validateKilocalories(validationMsgBuilder, value),
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
        } else {
          return const Center(
            //TODO: agregar i18n
            child: Text('No hay un perfil de usuario activo.'),
          );
        }
      }
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
    final activityProvider = Provider.of<ActivityService>(context);

    return FutureBuilder<List<ActivityType>?>(
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

