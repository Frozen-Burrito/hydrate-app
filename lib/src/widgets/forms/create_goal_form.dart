import 'package:flutter/material.dart';

import 'package:hydrate_app/src/db/sqlite_db.dart';
import 'package:hydrate_app/src/db/where_clause.dart';
import 'package:hydrate_app/src/models/goal.dart';
import 'package:hydrate_app/src/models/tag.dart';

class CreateGoalForm extends StatefulWidget {

  const CreateGoalForm(this.currentProfileId, { Key? key, }) : super(key: key);

  final int currentProfileId;

  @override
  State<CreateGoalForm> createState() => _CreateGoalFormState();
}

class _CreateGoalFormState extends State<CreateGoalForm> {

  final _formKey = GlobalKey<FormState>();

  final Goal newGoal = Goal( 
    term: GoalTerm.daily, 
    startDate: DateTime.now(), 
    endDate: DateTime.now(),
    tags: <Tag>[],
  );

  bool isLoading = false;

  final List<Tag> existingTags = [];

  int tagsLength = 0;
  int notesLength = 0;

  int? selectedTerm;

  final startDateController = TextEditingController();
  final endDateController = TextEditingController();
  
  @override
  void initState() {
    super.initState();
    _getExistingTags();
  }

  @override
  void dispose() {
    startDateController.dispose();
    endDateController.dispose();
    super.dispose();
  }

  final _termDropdownItems = GoalTerm.values
    .map((e) {

      const termLabels = <String>['Diario','Semanal','Mensual'];

      return DropdownMenuItem(
        value: e.index,
        child: Text(termLabels[e.index]),
      );
    }).toList();

  /// Verifica cada campo del formulario. Si no hay errores, inserta la nueva
  /// meta en la DB y redirige a [redirectRoute]. 
  void _validateAndSave(BuildContext context, {String? redirectRoute}) async {
    if (_formKey.currentState!.validate()) {
      // Asociar el perfil del usuario actual con la nueva meta.
      newGoal.profileId = widget.currentProfileId;

      // Asociar el perfil del usuario actual con las etiquetas de la meta.
      for (var tag in newGoal.tags) {
        tag.profileId = widget.currentProfileId;
      }

      int resultado = await SQLiteDB.instance.insert(newGoal);

      if (resultado >= 0) {
        if (redirectRoute != null) {
          Navigator.of(context).pushNamedAndRemoveUntil(redirectRoute, (route) => false);
        } else {
          Navigator.of(context).pop();
        }
      }
    }
  }

  /// Obtiene las [Tag] creadas por el usuario anteriormente. 
  Future<void> _getExistingTags() async {
    existingTags.clear();

    final tagResults = await SQLiteDB.instance.select<Tag>(
      Tag.fromMap, 
      where: [ WhereClause('id_perfil', widget.currentProfileId.toString())]
    );

    existingTags.addAll(tagResults);
  }

  @override
  Widget build(BuildContext context) {

    return Form(
      key: _formKey,
      autovalidateMode: AutovalidateMode.onUserInteraction,
      child: Card(
        margin: const EdgeInsets.only( top: 48.0 ),
        child: SizedBox(
          width: MediaQuery.of(context).size.width * 0.9,
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  'Escribe los detalles de tu nueva meta:', 
                  style: Theme.of(context).textTheme.bodyText1,
                ),
    
                const SizedBox( height: 16.0, ),
          
                DropdownButtonFormField(
                  decoration: const InputDecoration(
                    border: OutlineInputBorder(),
                    helperText: ' ',
                    hintText: '¿Cuál es el plazo de tu meta?' 
                  ),
                  items: _termDropdownItems,
                  value: selectedTerm,
                  validator: (int? value) => Goal.validateTerm(value),
                  onChanged: (int? newValue) {
                    newGoal.term = GoalTerm.values[newValue ?? 0];
                    setState(() {
                      selectedTerm = newValue ?? 0;
                    });
                  },
                ),
    
                const SizedBox( height: 16.0, ),
    
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children:  <Widget>[
                    Expanded(
                      child: TextFormField(
                        readOnly: true,
                        controller: startDateController,
                        decoration: const InputDecoration(
                          border: OutlineInputBorder(),
                          labelText: 'Inicio',
                          helperText: ' ', // Para evitar cambios en la altura del widget
                          suffixIcon: Icon(Icons.event_rounded)
                        ),
                        onTap: () async {
                          DateTime? newStartDate = await showDatePicker(
                            context: context, 
                            initialDate: DateTime.now(), 
                            firstDate: DateTime(2000), 
                            lastDate: DateTime(2100)
                          );

                          newGoal.startDate = newStartDate;

                          if (newStartDate != null) {
                            startDateController.text = newStartDate.toString().substring(0,10);
                          }
                        },
                      ),
                    ),
    
                    const SizedBox( width: 16.0 ,),
    
                    Expanded(
                      child: TextFormField(
                        readOnly: true,
                        controller: endDateController,
                        decoration: const InputDecoration(
                          border: OutlineInputBorder(),
                          labelText: 'Término',
                          helperText: ' ',
                          suffixIcon: Icon(Icons.event_rounded)
                        ),
                        validator: (value) => Goal.validateEndDate(newGoal.startDate, value),
                        onTap: () async {
                          DateTime? endDate = await showDatePicker(
                            context: context, 
                            initialDate: DateTime.now().add(const Duration( days: 30)), 
                            firstDate: DateTime(2000), 
                            lastDate: DateTime(2100)
                          );

                          if (endDate != null) {
                            newGoal.endDate = endDate;
                            endDateController.text = endDate.toString().substring(0,10);
                          }
                        },
                      ),
                    ),
                  ],
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
                          labelText: 'Recompensa',
                          hintText: '20',
                          helperText: ' ',
                          suffixIcon: Icon(Icons.monetization_on)
                        ),
                        onChanged: (value) => newGoal.reward = int.tryParse(value) ?? 0,
                        validator: (value) => Goal.validateReward(value),
                      ),
                    ),
    
                    const SizedBox( width: 16.0, ),
    
                    Expanded(
                      child: TextFormField(
                        autocorrect: false,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          border: OutlineInputBorder(),
                          labelText: 'Cantidad (ml)',
                          hintText: '100ml',
                          helperText: ' ',
                        ),
                        onChanged: (value) => newGoal.quantity = int.tryParse(value) ?? 0,
                        validator: (value) => Goal.validateWaterQuantity(value),
                      ),
                    ),
                  ]
                ),
    
                const SizedBox( height: 16.0, ),
    
                TextFormField(
                  keyboardType: TextInputType.text,
                  decoration: InputDecoration(
                    border: const OutlineInputBorder(),
                    labelText: 'Etiquetas',
                    helperText: ' ',
                    counterText: '${tagsLength.toString()}/3'
                  ),
                  onChanged: (value) => setState(() {
                    tagsLength = newGoal.parseTags(value, existingTags);
                  }),
                  validator: (value) => Goal.validateTags(value),
                ),
    
                const SizedBox( height: 16.0, ),
    
                TextFormField(
                  keyboardType: TextInputType.multiline,
                  maxLength: 100,
                  decoration: InputDecoration(
                    border: const OutlineInputBorder(),
                    labelText: 'Anotaciones',
                    hintText: 'Debo recordar tomar agua antes de...',
                    helperText: ' ',
                    counterText: '${notesLength.toString()}/100'
                  ),
                  onChanged: (value) => setState(() {
                    newGoal.notes = value;
                    notesLength = newGoal.notes?.length ?? 0;
                  }),
                  validator: (value) => Goal.validateNotes(value),
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
                        child: const Text('Crear'),
                        style: ElevatedButton.styleFrom(
                          primary: Colors.blue,
                        ),
                        onPressed: () => _validateAndSave(context, redirectRoute: '/'),
                      ),
                    ),
                  ]
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}