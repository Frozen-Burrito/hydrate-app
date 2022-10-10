import 'package:flutter/material.dart';
import 'package:hydrate_app/src/api/data_api.dart';
import 'package:hydrate_app/src/exceptions/entity_persistence_exception.dart';
import 'package:provider/provider.dart';

import 'package:hydrate_app/src/models/enums/time_term.dart';
import 'package:hydrate_app/src/models/goal.dart';
import 'package:hydrate_app/src/models/tag.dart';
import 'package:hydrate_app/src/services/goals_service.dart';
import 'package:hydrate_app/src/services/profile_service.dart';
import 'package:hydrate_app/src/routes/route_names.dart';
import 'package:hydrate_app/src/widgets/dialogs/replace_goal_dialog.dart';

class CreateGoalForm extends StatefulWidget {

  const CreateGoalForm({ Key? key, }) : super(key: key);

  @override
  State<CreateGoalForm> createState() => _CreateGoalFormState();
}

class _CreateGoalFormState extends State<CreateGoalForm> {

  final _formKey = GlobalKey<FormState>();

  final Goal newGoal = Goal.uncommited();

  int notesLength = 0;
  int? selectedTerm;

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

      const termLabels = <String>['Diario','Semanal','Mensual'];

      return DropdownMenuItem(
        value: e.index,
        child: Text(termLabels[e.index]),
      );
    }).toList();

  /// Verifica cada campo del formulario. Si no hay errores, inserta la nueva
  /// meta en la DB y redirige a [redirectRoute]. 
  void _validateAndSave(BuildContext context, {String? redirectRoute}) async {

    FocusScope.of(context).unfocus();
    
    final bool isFormNotValid = !(_formKey.currentState?.validate() ?? false);

    if (isFormNotValid) return;

    final goalService = Provider.of<GoalsService>(context, listen: false);

    bool canCreateNewGoal = true;
    bool wasGoalCreated = false;

    while (!wasGoalCreated && canCreateNewGoal) {
      try {
        final int createdGoalId = await goalService.createHydrationGoalWithLimit(newGoal);

        wasGoalCreated = createdGoalId >= 0;

        if (wasGoalCreated) {
          await goalService.syncUpdatedHydrationGoalsWithAccount();
          
          _navigateOnGoalCreated(context, redirectRoute);
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
      key: _formKey,
      autovalidateMode: AutovalidateMode.onUserInteraction,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
    
          DropdownButtonFormField(
            decoration: const InputDecoration(
              border: OutlineInputBorder(),
              helperText: ' ',
              //TODO: agregar i18n
              hintText: '¿Cuál es el plazo de tu meta?' 
            ),
            items: _termDropdownItems,
            value: selectedTerm,
            validator: (int? value) => Goal.validateTerm(value),
            onChanged: (int? newValue) {
              newGoal.term = TimeTerm.values[newValue ?? 0];
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
                    //TODO: agregar i18n
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
                    //TODO: agregar i18n
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
                    //TODO: agregar i18n
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

          _TagFormField(
            initialTagCount: newGoal.tags.length,
            onTagsChanged: newGoal.parseTags,
            onValidate: Goal.validateTags,
          ),

          const SizedBox( height: 16.0, ),

          TextFormField(
            keyboardType: TextInputType.multiline,
            maxLength: 100,
            decoration: InputDecoration(
              border: const OutlineInputBorder(),
              //TODO: agregar i18n
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
                  //TODO: agregar i18n
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
                  //TODO: agregar i18n
                  child: const Text('Crear'),
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

class _TagFormField extends StatefulWidget {

  const _TagFormField({
    Key? key,
    required this.onTagsChanged, 
    required this.onValidate,
    this.initialTagCount = 0,
  }) : super(key: key);

  final int initialTagCount;

  final int Function(String, List<Tag>) onTagsChanged;
  final String? Function(String?) onValidate;
  
  @override
  State<_TagFormField> createState() => _TagFormFieldState();
}

class _TagFormFieldState extends State<_TagFormField> {

  int numberOfTags = 0;

  @override
  void initState() {
    numberOfTags = widget.initialTagCount;
    super.initState();
  }

  @override
  Widget build(BuildContext context) {

    final goalProvider = Provider.of<GoalsService>(context);

    return FutureBuilder<List<Tag>?>(
      future: goalProvider.tags,
      initialData: const <Tag>[],
      builder: (context, snapshot) {

        final existingTags = snapshot.hasData 
          ? snapshot.data!
          : const <Tag>[];

        //TODO: usar el widget Autocomplete para mostrar posibles etiquetas
        // ver tambien: https://api.flutter.dev/flutter/material/Autocomplete-class.html
        return TextFormField(
          keyboardType: TextInputType.text,
          decoration: InputDecoration(
            border: const OutlineInputBorder(),
            //TODO: agregar i18n
            labelText: 'Etiquetas',
            helperText: ' ',
            counterText: '${numberOfTags.toString()}/3'
          ),
          onChanged: (value) => setState(() {
            numberOfTags = widget.onTagsChanged(value, existingTags);
          }),
          validator: (value) => widget.onValidate(value),
        );
      }
    );
  }
}