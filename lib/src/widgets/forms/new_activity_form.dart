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
    final activityService = Provider.of<ActivityService>(context, listen: false);
    final profileService = Provider.of<ProfileService>(context, listen: false);

    assert(newActivity.activityType.id >= 0);

    final wasRoutineCreated = await _createRoutineIfPossible(context, newActivity);

    bool wasActivityCreated = false;
    if (wasRoutineCreated) {
      _navigateToRoute(context, redirectRoute);

    } else {
      // Crear registro local de actividad.
      final int newActivityId = await activityService.createActivityRecord(newActivity);
      wasActivityCreated = newActivityId >= 0;

      if (wasActivityCreated) {
        final shouldGiveRewardForActivity = await activityService.shouldGiveRewardForNewActivity();

        if (shouldGiveRewardForActivity) {  

          profileService.profileChanges.addCoins(newActivity.coinReward);

          await profileService.saveProfileChanges();
        }

        await activityService.syncLocalActivityRecordsWithAccount();

        _navigateToRoute(context, redirectRoute);
      }
    }
  }

  /// Revisa si puede convertir actividades previas y [newActivity] en una 
  /// rutina. Si puede hacerlo, pide confirmación del usuario. En caso de que el
  /// usuario acceda, la nueva rutina es creada.
  /// 
  /// Retorna __true__ si la rutina fue creada y __false__ en caso contrario.
  Future<bool> _createRoutineIfPossible(BuildContext context, ActivityRecord newActivity) async {

    final activityService = Provider.of<ActivityService>(context, listen: false);

    // Obtener todos los registros de actividades de la semana pasada que sean 
    // similares a newActivity.
    final similarActivities = await activityService
        .isActivitySimilarToPrevious(newActivity, onlyPastWeek: true);

    bool wasRoutineCreated = false;

    if (similarActivities.isNotEmpty) {
      // Hay actividades similares. Preguntar si desea crear una rutina con ellas.
      final userWantsToCreateRoutine = (await _showShouldCreateRoutineDialog(
        context, 
        similarActivities.length
      )) ?? false;

      if (userWantsToCreateRoutine) {
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
        );
        
        final int newRoutineId = await activityService.createRoutine(newRoutine);

        wasRoutineCreated = newRoutineId >= 0;

        if (wasRoutineCreated) {
          await activityService.syncLocalRoutinesWithAccount();
        }
      }
    }

    return wasRoutineCreated;
  }

  Future<bool?> _showShouldCreateRoutineDialog(BuildContext context, int numOfSimilarActivities) {
    return showDialog<bool>(
      context: context, 
      builder: (context) => SuggestRoutineDialog(
        similarActivityCount: numOfSimilarActivities,
      )
    );
  }

  void _navigateToRoute(BuildContext context, String? route) {
    if (route != null) {
      Navigator.of(context).pushNamedAndRemoveUntil(route, (route) => false);
    } else {
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {

    final activityProvider = Provider.of<ActivityService>(context);
    final localizations = AppLocalizations.of(context)!;

    return FutureBuilder<List<List<RoutineOccurrence>>>(
      future: activityProvider.activitiesFromPastWeek,
      initialData: const <List<RoutineOccurrence>>[],
      builder: (context, snapshot) {
        if (snapshot.hasData) {

          final activityRecords = snapshot.data!;

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
                      localizations.recentIntenseActvity,
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
            child: Text(localizations.errorFetchingActivity),
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

      dateController.text = newActivityRecord.date.toLocalizedDateTime(context);
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

  String _buildTitleCountText(int titleLength) {
    final titleLengthStr = titleLength.toString();
    final maxTitleLengthStr = ActivityValidator.titleLengthRange.max.toInt().toString();

    return "$titleLengthStr/$maxTitleLengthStr";
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
                  selectedActivityTypeId: newActivityRecord.activityType.id,
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
                    helperText: " ",
                    suffixIcon: const Icon(Icons.text_fields),
                    counterText: _buildTitleCountText(titleLength),
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
                    helperText: " ",
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
                          labelText: "${localizations.duration} (${localizations.minutes})",
                          hintText: localizations.durationHint,
                          helperText: " ",
                          suffixIcon: const Icon(Icons.timer_rounded)
                        ),
                        onChanged: (value) {
                          setState(() {
                            newActivityRecord.duration = int.tryParse(value.split(" ").first) ?? 0;

                            newActivityRecord.aproximateData(userWeight);
                          
                            distanceController.text = newActivityRecord.formattedDistance;
                            durationController.text = newActivityRecord.formattedDuration; 
                            kCalController.text = newActivityRecord.formattedKcal;
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
                          hintText: localizations.distanceHint,
                          helperText: " ",
                        ),
                        onChanged: (value) {
                          setState(() {
                            newActivityRecord.distance = double.tryParse(value.split(" ").first) ?? 0.0;

                            newActivityRecord.userModifiedDistance();
                          });          
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
                          hintText: localizations.kcalHint,
                          helperText: " ",
                          suffixIcon: const Icon(Icons.bolt),
                        ),
                        onChanged: (value) {
                          setState(() {
                            newActivityRecord.kiloCaloriesBurned = int.tryParse(value.split(" ").first) ?? 0;

                            newActivityRecord.userModifiedKcal();
                          });          
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
          return Center(
            child: Text("${localizations.noProfileSelected}."),
          );
        }
      }
    );
  }
}

class _ActivityTypeDropdown extends StatelessWidget {

  const _ActivityTypeDropdown({
    required this.selectedActivityTypeId, 
    required this.onActivityTypeChange,
    Key? key,
  }) : super(key: key);

  final int selectedActivityTypeId;
  final void Function(ActivityType) onActivityTypeChange;

  void _handleActivityTypeChanged(int? newValue, List<ActivityType> activityTypes) {
    // Obtener el tipo de actividad correspondiente.
    int typeIndex = activityTypes
      .indexWhere((t) => t.id == newValue);

    assert(typeIndex != -1);

    final selectedType = activityTypes[typeIndex];

    onActivityTypeChange(selectedType);
  }

  int _getDropdownValue(int selectedItemId, List<ActivityType> activityTypes) {

    if (activityTypes.isEmpty) return 0;

    final int dropdownValue;

    if (selectedItemId >= 0) {
      dropdownValue = selectedItemId;
    } else {
      dropdownValue = activityTypes.first.id;
      Future.microtask(() => _handleActivityTypeChanged(dropdownValue, activityTypes));
    }

    assert(dropdownValue >= 0);

    return dropdownValue;
  }

  @override
  Widget build(BuildContext context) {

    final localizations = AppLocalizations.of(context)!;
    final activityProvider = Provider.of<ActivityService>(context);

    return FutureBuilder<List<ActivityType>?>(
      future: activityProvider.activityTypes,
      initialData: const <ActivityType>[],
      builder: (context, snapshot) {

        final activityTypes = snapshot.data ?? <ActivityType>[];

        final List<DropdownMenuItem<int>>? dropdownItems;
        final void Function(int?)? onChangeHandler;

        if (activityTypes.isNotEmpty) {
          dropdownItems = DropdownLabels.activityTypes(context, activityTypes);
          onChangeHandler = (int? newValue) => _handleActivityTypeChanged(newValue, activityTypes);
        } else {
          dropdownItems = null;
          onChangeHandler = null;
        }

        return DropdownButtonFormField(
          disabledHint: Text(localizations.noActTypes),
          decoration: InputDecoration(
            border: const OutlineInputBorder(),
            labelText: localizations.whatType,
            helperText: " ",
            hintText: localizations.select
          ),
          items: dropdownItems,
          value: _getDropdownValue(selectedActivityTypeId, activityTypes),
          validator: (int? value) => ActivityType.validateType(value, activityTypes),
          onChanged: onChangeHandler
        );
      }
    );
  }
}

