import 'package:flutter/material.dart';

import 'package:hydrate_app/src/db/sqlite_db.dart';
import 'package:hydrate_app/src/db/where_clause.dart';
import 'package:hydrate_app/src/models/goal.dart';
import 'package:hydrate_app/src/models/models.dart';
import 'package:hydrate_app/src/models/tag.dart';
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

  final List<ActivityType> activityTypes = [];

  int titleLength = 0;
  int notesLength = 0;

  final dateController = TextEditingController();
  final durationController = TextEditingController();
  final distanceController = TextEditingController();
  final kCalController = TextEditingController();
  
  @override
  void initState() {
    super.initState();
    _getActivityTypes();
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

      int resultado = await SQLiteDB.instance.insert(newActivityRecord);

      if (resultado >= 0) {
        if (redirectRoute != null) {
          Navigator.of(context).pushNamedAndRemoveUntil(redirectRoute, (route) => false);
        } else {
          Navigator.of(context).pop();
        }
      }
    }
  }

  /// Obtiene los [ActivityTypes] disponibles. 
  Future<void> _getActivityTypes() async {
    activityTypes.clear();

    final tagResults = await SQLiteDB.instance.select<ActivityType>(
      ActivityType.fromMap, 
      ActivityType.tableName,
    );

    setState(() {
      activityTypes.addAll(tagResults);
    });
  }

  @override
  Widget build(BuildContext context) {

    return Form(
      key: _formKey,
      autovalidateMode: AutovalidateMode.onUserInteraction,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
    
          DropdownButtonFormField(
            decoration: const InputDecoration(
              border: OutlineInputBorder(),
              labelText: '¿Qué tipo de actividad hiciste?',
              helperText: ' ',
              hintText: 'Selecciona' 
            ),
            items: DropdownLabels.activityTypes(activityTypes),
            value: newActivityRecord.activityType.activityTypeValue.index,
            validator: (int? value) => ActivityType.validateType(value),
            onChanged: (int? newValue) {
              // Obtener el tipo de actividad correspondiente.
              int activityTypeIdx = activityTypes
                .indexWhere((t) => t.activityTypeValue.index == newValue);

              setState(() {
                newActivityRecord.activityType = activityTypes[activityTypeIdx];
              });
            },
          ),

          const SizedBox( height: 16.0, ),

          TextFormField(
            maxLength: 40,
            maxLines: 1,
            decoration: InputDecoration(
              border: const OutlineInputBorder(),
              labelText: 'Título de la actividad',
              hintText: 'Ir a la escuela en la mañana',
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
            decoration: const InputDecoration(
              border: OutlineInputBorder(),
              labelText: 'Fecha',
              helperText: ' ', // Para evitar cambios en la altura del widget
              suffixIcon: Icon(Icons.event_rounded)
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

                dateController.text = newActivityRecord.numericDate;
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
                  decoration: const InputDecoration(
                    border: OutlineInputBorder(),
                    labelText: 'Duración (minutos)',
                    hintText: '20 min.',
                    helperText: ' ',
                    suffixIcon: Icon(Icons.timer_rounded)
                  ),
                  onChanged: (value) {
                    setState(() {
                      newActivityRecord.duration = int.tryParse(value.split(" ").first) ?? 0;
                    });

                    durationController.text = newActivityRecord.formattedDuration; 
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
                  decoration: const InputDecoration(
                    border: OutlineInputBorder(),
                    labelText: 'Distancia',
                    hintText: '1 km',
                    helperText: ' ',
                  ),
                  onChanged: (value) {

                    setState(() {
                      newActivityRecord.distance = double.tryParse(value.split(" ").first) ?? 0.0;
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
                  decoration: const InputDecoration(
                    border: OutlineInputBorder(),
                    labelText: 'Kilocalorías quemadas',
                    hintText: '1700 kCal',
                    helperText: ' ',
                    suffixIcon: Icon(Icons.bolt),
                  ),
                  onChanged: (value) {
                    setState(() {
                      newActivityRecord.kiloCaloriesBurned = int.tryParse(value.split(" ").first) ?? 0;
                    });

                    kCalController.text = newActivityRecord.formattedKcal; 
                  },
                  validator: (value) => ActivityRecord.validateKcal(value),
                ),
              ),

              const SizedBox( width: 16.0, ),

              Expanded(
                child: CheckboxListTile(
                  title: const Text('Al aire libre'),
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
                  child: const Text('Cancelar'),
                  style: ElevatedButton.styleFrom(
                    primary: Colors.grey.shade700,
                  ),
                  onPressed: () => Navigator.pop(context),
                ),
              ),

              const SizedBox( width: 16.0, ),

              Expanded(
                child: ElevatedButton(
                  child: const Text('Registrar'),
                  style: ElevatedButton.styleFrom(
                    primary: Colors.blue,
                  ),
                  onPressed: () => _validateAndSave(context, redirectRoute: RouteNames.home),
                ),
              ),
            ]
          ),
        ],
      ),
    );
  }
}