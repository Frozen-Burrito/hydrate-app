import 'package:flutter/material.dart';
import 'package:hydrate_app/src/models/map_options.dart';
import 'package:provider/provider.dart';

import 'package:hydrate_app/src/exceptions/entity_persistence_exception.dart';
import 'package:hydrate_app/src/models/enums/time_term.dart';
import 'package:hydrate_app/src/models/goal.dart';
import 'package:hydrate_app/src/models/tag.dart';
import 'package:hydrate_app/src/services/form_control_bloc.dart';
import 'package:hydrate_app/src/services/goals_service.dart';
import 'package:hydrate_app/src/routes/route_names.dart';
import 'package:hydrate_app/src/widgets/dialogs/replace_goal_dialog.dart';

class CreateGoalForm extends StatefulWidget {

  const CreateGoalForm({ Key? key, }) : super(key: key);

  @override
  State<CreateGoalForm> createState() => _CreateGoalFormState();
}

class _CreateGoalFormState extends State<CreateGoalForm> {

  late final formControl = FormControlBloc(
    fields: Goal.defaultFieldValues,
    defaultFieldValues: Goal.defaultFieldValues,
    requiredFields: Goal.requiredFields,
    validateOnChange: true,
    onFormSuccess: _saveNewHydrationGoal,
  );

  static const String successRedirectRoute = RouteNames.home;
  static const int maxGoalPersistAttempts = 3;

  // Controladores para los campos de fechas.
  final startDateController = TextEditingController();
  final endDateController = TextEditingController();

  @override
  void dispose() {
    startDateController.dispose();
    endDateController.dispose();
    super.dispose();
  }

  final _termDropdownItems = TimeTerm.values
    .map((e) {
      //TODO: agregar i18n.
      const termLabels = <String>['Diario','Semanal','Mensual'];

      return DropdownMenuItem(
        value: e.index,
        child: Text(termLabels[e.index]),
      );
    }).toList();

  void _submit(BuildContext context) {
    FocusScope.of(context).unfocus();
    formControl.submitForm();                    
  }

  Future<void> _saveNewHydrationGoal(Map<String, Object?> newGoalValues) async {

    final goalService = Provider.of<GoalsService>(context, listen: false);

    final newHydrationGoal = Goal.fromMap(
      newGoalValues, 
      options: const MapOptions(
        subEntityMappingType: EntityMappingType.noMapping,
      )
    );

    bool canCreateNewGoal = true;
    bool wasGoalCreated = false;
    int goalCreationAttemptCount = 0;

    while (!wasGoalCreated && canCreateNewGoal && goalCreationAttemptCount <= maxGoalPersistAttempts) {
      ++goalCreationAttemptCount;
      try {
        final int createdGoalId = await goalService.createHydrationGoalWithLimit(newHydrationGoal);

        wasGoalCreated = createdGoalId >= 0;

        if (wasGoalCreated) {
          await goalService.syncUpdatedHydrationGoalsWithAccount();
          
          _navigateOnGoalCreated(context, successRedirectRoute);
        } else {
          _showGoalCreateError(context);
        }

      } on EntityPersistException catch (ex) {
        final hasToReplaceGoal = ex.exceptionType == EntityPersitExceptionType.hasReachedEntityCountLimit;

        if (hasToReplaceGoal) {
          final wereGoalsReplaced = await _tryToReplaceExistingGoals(goalService);

          canCreateNewGoal = wereGoalsReplaced;
        }
      }
    }   
  }

  Future<bool> _tryToReplaceExistingGoals(GoalsService goalService) async {
    // Si el usuario ha llegado al límite de metas simultáneas, preguntarle
    // si desea reemplazar metas existentes usando un Dialog.
    List<int> goalIdsToReplace = (await showAskForGoalReplacementDialog(context)) 
      ?? const <int>[]; 

    final bool didUserChooseGoalsToReplace = goalIdsToReplace.isNotEmpty;
    bool wereGoalsReplaced = false;

    if (didUserChooseGoalsToReplace) {
      // Remover todas las metas especificadas por el usuario.
      for (final goalId in goalIdsToReplace) {
        final int goalsEliminated = await goalService.deleteHydrationGoal(goalId);

        wereGoalsReplaced = goalsEliminated >= 0;
      }
    }

    return wereGoalsReplaced;
  }

  Future<List<int>?> showAskForGoalReplacementDialog(BuildContext context) {
    return showDialog<List<int>>(
      context: context,
      builder: (context) => const ReplaceGoalDialog(),
    );
  }

  void _navigateOnGoalCreated(BuildContext context, String? redirectRoute) {
    if (redirectRoute != null) {
      Navigator.of(context).pushNamedAndRemoveUntil(redirectRoute, (route) => false);
    } else {
      Navigator.of(context).pop();
    }
  }

  void _showGoalCreateError(BuildContext context) {
    // Si por alguna razón no se agregó la meta de hidratación, mostrar el error. 
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar( 
        content: Text("Hubo un error al crear la meta"),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {

    return Form(
      key: formControl.formKey,
      autovalidateMode: AutovalidateMode.onUserInteraction,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
    
          StreamBuilder<TimeTerm>(
            stream: formControl.getFieldValueStream<TimeTerm>(Goal.termFieldName),
            initialData: TimeTerm.daily,
            builder: (context, snapshot) {
              return DropdownButtonFormField(
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  helperText: " ",
                  //TODO: agregar i18n
                  hintText: "¿Cuál es el plazo de tu meta?" 
                ),
                items: _termDropdownItems,
                value: snapshot.data?.index ?? 0,
                validator: (int? value) => Goal.validateTerm(value),
                onChanged: (int? newValue) => formControl.changeFieldValue(
                  Goal.termFieldName, 
                  TimeTerm.values[newValue ?? 0]
                ),
              );
            }
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
                    //TODO: agregar i18n
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

                    if (newStartDate != null) {
                      formControl.changeFieldValue(Goal.startDateFieldName, newStartDate);
                      startDateController.text = newStartDate.toString().substring(0,10);
                    }
                  },
                ),
              ),

              const SizedBox( width: 16.0 ,),

              Expanded(
                child: StreamBuilder<DateTime>(
                  stream: formControl.getFieldValueStream(Goal.startDateFieldName),
                  builder: (context, snapshot) {
                    return TextFormField(
                      readOnly: true,
                      controller: endDateController,
                      decoration: const InputDecoration(
                        border: OutlineInputBorder(),
                        //TODO: agregar i18n
                        labelText: 'Término',
                        helperText: ' ',
                        suffixIcon: Icon(Icons.event_rounded)
                      ),
                      validator: (value) => Goal.validateEndDate(snapshot.data, value),
                      onTap: () async {
                        DateTime? endDate = await showDatePicker(
                          context: context, 
                          initialDate: DateTime.now().add(Goal.defaultGoalDuration), 
                          firstDate: DateTime(2000), 
                          lastDate: DateTime(2100)
                        );
                
                        if (endDate != null) {
                          formControl.changeFieldValue(Goal.endDateFieldName, endDate);
                          endDateController.text = endDate.toString().substring(0,10);
                        }
                      },
                    );
                  }
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
                    //TODO: agregar i18n
                    labelText: "Recompensa",
                    hintText: "20",
                    helperText: " ",
                    suffixIcon: Icon(Icons.monetization_on)
                  ),
                  onChanged: (value) => formControl.changeFieldValue(
                    Goal.rewardFieldName, 
                    int.tryParse(value) ?? 0
                  ),
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
                    //TODO: agregar i18n
                    labelText: "Cantidad (ml)",
                    hintText: "100ml",
                    helperText: " ",
                  ),
                  onChanged: (value) => formControl.changeFieldValue(
                    Goal.quantityFieldName, 
                    int.tryParse(value) ?? 0,
                  ),
                  validator: (value) => Goal.validateWaterQuantity(value),
                ),
              ),
            ]
          ),

          const SizedBox( height: 16.0, ),

          _TagFormField(formControl: formControl),

          const SizedBox( height: 16.0, ),

          StreamBuilder<String>(
            stream: formControl.getFieldValueStream<String>(Goal.notesFieldName),
            builder: (context, snapshot) {

              final String notes = snapshot.data ?? "";
              
              return TextFormField(
                keyboardType: TextInputType.text,
                maxLength: Goal.maxNotesLength,
                maxLines: 1,
                decoration: InputDecoration(
                  border: const OutlineInputBorder(),
                  //TODO: agregar i18n
                  labelText: "Anotaciones",
                  hintText: "Debo recordar tomar agua antes de...",
                  helperText: " ",
                  counterText: "${notes.characters.length.toString()}/${Goal.maxNotesLength}"
                ),
                onChanged: (value) => formControl.changeFieldValue(Goal.notesFieldName, value,),
                validator: (value) => Goal.validateNotes(value),
              );
            }
          ),

          const SizedBox( height: 16.0, ),

          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              Expanded(
                child: ElevatedButton(
                  //TODO: agregar i18n
                  style: ElevatedButton.styleFrom(
                    primary: Colors.grey.shade700,
                    padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 16.0),
                    textStyle: Theme.of(context).textTheme.button,
                  ),
                  onPressed: () => Navigator.pop(context),
                  child: const Text("Cancelar"),
                ),
              ),

              const SizedBox( width: 16.0, ),

              StreamBuilder<FormFieldsState>(
                stream: formControl.formState,
                builder: (context, snapshot) {

                  final void Function()? onPressed;
                  final Widget? child;

                  switch (snapshot.data) {
                    case null:
                    case FormFieldsState.empty:
                    case FormFieldsState.incomplete:
                      onPressed = null;
                      child = const Text(
                        //TODO: agregar i18n
                        "Crear", 
                        textAlign: TextAlign.center,
                      );
                      break;
                    case FormFieldsState.loading:
                      onPressed = null;
                      child = const SizedBox(
                        height: 24.0,
                        width: 24.0,
                        child: CircularProgressIndicator()
                      );
                      break;
                    case FormFieldsState.canSubmit:
                    case FormFieldsState.error:
                    case FormFieldsState.success:
                      onPressed = () => _submit(context);
                      child = const Text(
                        //TODO: agregar i18n
                        "Crear", 
                        textAlign: TextAlign.center,
                      );
                      break;
                  }

                  return Expanded(
                    child: ElevatedButton(
                      onPressed: onPressed,
                      style: ElevatedButton.styleFrom(
                        primary: Theme.of(context).colorScheme.primary,
                        padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 16.0),
                        textStyle: Theme.of(context).textTheme.button,
                      ), 
                      child: child,
                    ),
                  );
                }
              ),
            ]
          ),
        ],
      ),
    );
  }
}

class _TagFormField extends StatelessWidget {

  const _TagFormField({
    Key? key,
    required this.formControl,
  }) : super(key: key);

  final FormControlBloc formControl; 

  @override
  Widget build(BuildContext context) {

    final goalService = Provider.of<GoalsService>(context);

    return FutureBuilder<List<Tag>>(
      future: goalService.tags,
      initialData: const <Tag>[],
      builder: (context, snapshot) {

        final existingTags = snapshot.data ?? const <Tag>[]; 

        //TODO: usar el widget Autocomplete para mostrar posibles etiquetas
        // ver tambien: https://api.flutter.dev/flutter/material/Autocomplete-class.html
        return StreamBuilder<List<Tag>>(
          stream: formControl.getFieldValueStream<List<Tag>>(Goal.tagsFieldName),
          initialData: const <Tag>[],
          builder: (context, snapshot) {

            final addedTags = snapshot.data ?? const <Tag>[]; 
            
            return TextFormField(
              keyboardType: TextInputType.text,
              decoration: InputDecoration(
                border: const OutlineInputBorder(),
                //TODO: agregar i18n
                labelText: "Etiquetas",
                helperText: " ",
                counterText: "${addedTags.length.toString()}/${Goal.maxTagCount}"
              ),
              onChanged: (value) => formControl.changeFieldValue(
                Goal.tagsFieldName, 
                Tag.parseFromString(addedTags, value, existingTags),
              ),
              validator: (value) => Goal.validateTags(value),
            );
          }
        );
      }
    );    
  }
}
