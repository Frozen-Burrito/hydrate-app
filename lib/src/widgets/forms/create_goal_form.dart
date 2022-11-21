import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:provider/provider.dart';

import 'package:hydrate_app/src/exceptions/entity_persistence_exception.dart';
import 'package:hydrate_app/src/models/enums/time_term.dart';
import 'package:hydrate_app/src/models/goal.dart';
import 'package:hydrate_app/src/models/map_options.dart';
import 'package:hydrate_app/src/models/tag.dart';
import 'package:hydrate_app/src/models/validators/goal_validator.dart';
import 'package:hydrate_app/src/models/validators/validation_message_builder.dart';
import 'package:hydrate_app/src/services/form_control_bloc.dart';
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

  List<DropdownMenuItem<int>> _buildTermDropdownItems(BuildContext context) {
    final localizations = AppLocalizations.of(context)!;
    final localizedLabels = <String>[
      localizations.daily,
      localizations.weekly,
      localizations.monthly,
    ];

    return TimeTerm.values
      .map((e) => DropdownMenuItem(
        value: e.index,
        child: Text(localizedLabels[e.index]),
      )).toList();
  }

  String _buildNotesCountText(BuildContext context, String notes) {
    final notesLengthStr = notes.characters.length.toString();
    final maxNotesLengthStr = GoalValidator.notesLengthRange.max.toInt().toString();

    return "$notesLengthStr/$maxNotesLengthStr";
  }

  String? _validateGoalTerm(ValidationMessageBuilder messageBuilder, int? termIndex) {
    final termError = Goal.validator.validateTerm(termIndex);
    return messageBuilder.forGoalTerm(termError);
  }

  String? _validateEndDate(ValidationMessageBuilder messageBuilder, DateTime? startDate, String? endDate) {
    final endDateError = Goal.validator.validateEndDate(startDate, endDate);
    return messageBuilder.forGoalEndDate(endDateError);
  }

  String? _validateReward(ValidationMessageBuilder messageBuilder, String? inputValue) {
    final rewardError = Goal.validator.validateReward(inputValue);
    return messageBuilder.forGoalReward(rewardError);
  }

  String? _validateWaterVolume(ValidationMessageBuilder messageBuilder, String? inputValue) {
    final waterVolumeError = Goal.validator.validateWaterQuantity(inputValue);
    return messageBuilder.forGoalWaterVolume(waterVolumeError);
  }

  String? _validateNotes(ValidationMessageBuilder messageBuilder, String? notes) {
    final notesError = Goal.validator.validateNotes(notes);
    return messageBuilder.forGoalNotes(notesError);
  }

  @override
  Widget build(BuildContext context) {

    final localizations = AppLocalizations.of(context)!;
    final validationMessageBuilder = ValidationMessageBuilder.of(context);

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
                decoration: InputDecoration(
                  border: const OutlineInputBorder(),
                  helperText: " ",
                  hintText: localizations.goalTermHint, 
                ),
                items: _buildTermDropdownItems(context),
                value: snapshot.data?.index ?? 0,
                validator: (int? value) => _validateGoalTerm(validationMessageBuilder, value),
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
                  decoration: InputDecoration(
                    border: const OutlineInputBorder(),
                    labelText: localizations.startDate,
                    helperText: " ",
                    suffixIcon: const Icon(Icons.event_rounded)
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
                      decoration: InputDecoration(
                        border: const OutlineInputBorder(),
                        labelText: localizations.endDate,
                        helperText: " ",
                        suffixIcon: const Icon(Icons.event_rounded)
                      ),
                      validator: (value) => _validateEndDate(
                        validationMessageBuilder,
                        snapshot.data,
                        value,
                      ),
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
                  decoration: InputDecoration(
                    border: const OutlineInputBorder(),
                    labelText: localizations.reward,
                    hintText: localizations.rewardHint,
                    helperText: " ",
                    suffixIcon: const Icon(Icons.monetization_on)
                  ),
                  onChanged: (value) => formControl.changeFieldValue(
                    Goal.rewardFieldName, 
                    int.tryParse(value) ?? 0
                  ),
                  validator: (value) => _validateReward(validationMessageBuilder, value),
                ),
              ),

              const SizedBox( width: 16.0, ),

              Expanded(
                child: TextFormField(
                  autocorrect: false,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    border: const OutlineInputBorder(),
                    labelText: localizations.amountMl,
                    hintText: localizations.amountMlHint,
                    helperText: " ",
                  ),
                  onChanged: (value) => formControl.changeFieldValue(
                    Goal.quantityFieldName, 
                    int.tryParse(value) ?? 0,
                  ),
                  validator: (value) => _validateWaterVolume(validationMessageBuilder, value),
                ),
              ),
            ]
          ),

          const SizedBox( height: 16.0, ),

          Consumer<GoalsService>(
            builder: (context, goalsService, __) {
              return FutureBuilder<List<Tag>>(
                future: goalsService.tags,
                builder: (context, snapshot) {
                  return _TagFormField(
                    formControl: formControl,
                    availableTags: snapshot.data ?? const <Tag>{},
                  );
                }
              );
            }
          ),

          const SizedBox( height: 16.0, ),

          StreamBuilder<String>(
            stream: formControl.getFieldValueStream<String>(Goal.notesFieldName),
            builder: (context, snapshot) {

              final String notes = snapshot.data ?? "";
              
              return TextFormField(
                keyboardType: TextInputType.text,
                maxLength: GoalValidator.notesLengthRange.max.toInt(),
                maxLines: 1,
                decoration: InputDecoration(
                  border: const OutlineInputBorder(),
                  labelText: localizations.notesLabel,
                  hintText: localizations.notesHint,
                  helperText: " ",
                  counterText: _buildNotesCountText(context, notes),
                ),
                onChanged: (value) => formControl.changeFieldValue(Goal.notesFieldName, value,),
                validator: (value) => _validateNotes(validationMessageBuilder, value),
              );
            }
          ),

          const SizedBox( height: 16.0, ),

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
                      child = Text(
                        localizations.create, 
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
                      child = Text(
                        localizations.create, 
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

class _TagFormField extends StatefulWidget {

  const _TagFormField({
    Key? key,
    required this.formControl,
    this.availableTags = const <Tag>{},
  }) : super(key: key);

  final FormControlBloc formControl; 

  final Iterable<Tag> availableTags;

  static String _displayStringForTag(Tag tag) => tag.value;

  @override
  State<_TagFormField> createState() => _TagFormFieldState();
}

class _TagFormFieldState extends State<_TagFormField> {

  late TextEditingController _autocompleteTextController;

  bool _tagHasValue(Tag tag, String value) => tag.value.toLowerCase() == value.toLowerCase();

  Iterable<Tag> _buildTagOptions(String inputValue, int profileId) {
    // Mostrar tags existentes, y una opcion para agregar un nuevo tag
    // Siempre retorna al menos una opcion.
    final Set<Tag> options = <Tag>{};

    if (inputValue.characters.isEmpty) {
      return options;
    }

    options.addAll(widget.availableTags.where((tag) {
      return  tag.value.toLowerCase()
      .contains(inputValue.toLowerCase()) &&
      tag.profileId == profileId;
    }));

    // Opcion para crear una nueva etiqueta.
    final isExactInputNotCreated = !(options.any((tag) => _tagHasValue(tag, inputValue)));
    if (isExactInputNotCreated) {
      options.add(Tag( 
        value: inputValue, 
        profileId: profileId,
      ));
    }

    return options;
  }

  void _selectTag(Tag selectedTag, List<Tag> currentTags) {
    final modifiedTags = List.from(currentTags);

    if (modifiedTags.contains(selectedTag)) return;

    if (modifiedTags.length >= GoalValidator.tagCountRange.max.toInt()) {
      modifiedTags.removeLast();
    }
    modifiedTags.add(selectedTag);

    widget.formControl.changeFieldValue(
      Goal.tagsFieldName, 
      modifiedTags,
    );

    _autocompleteTextController.clear();
  }

  String? _validateTagCount(ValidationMessageBuilder messageBuilder, List<Tag> inputValue) {
    final tagCountError = Goal.validator.validateTags(inputValue);
    return messageBuilder.forGoalTagCount(tagCountError);
  }

  String _buildTagCountText(List<Tag> tags) {
    final tagCount = tags.length.toString();
    final maxTagCount = GoalValidator.tagCountRange.max.toInt().toString();

    return "$tagCount/$maxTagCount";
  }

  @override
  Widget build(BuildContext context) {

    final localizations = AppLocalizations.of(context)!;
    final validationMessageBuilder = ValidationMessageBuilder.of(context);

    return StreamBuilder<List<dynamic>>(
      stream: widget.formControl.getFieldValueStream<List<dynamic>>(Goal.tagsFieldName),
      initialData: const <Tag>[],
      builder: (context, snapshot) {
    
        final addedTags = snapshot.data?.cast<Tag>() ?? const <Tag>[]; 
        
        return Column(
          children: <Widget>[
            Consumer<ProfileService>(
              builder: (context, profileService, __) { 
                return Autocomplete<Tag>(
                  displayStringForOption: _TagFormField._displayStringForTag,
                  optionsBuilder: (TextEditingValue textEditingValue) {
                    return _buildTagOptions(
                      textEditingValue.text, 
                      profileService.profileId
                    );
                  },
                  onSelected: (Tag selectedTag) => _selectTag(selectedTag, addedTags),
                  fieldViewBuilder: (context, textController, focusNode, _) {

                    _autocompleteTextController = textController;

                    return TextFormField(
                      controller: _autocompleteTextController,
                      focusNode: focusNode,
                      decoration: InputDecoration(
                        border: const OutlineInputBorder(),
                        labelText: localizations.tags,
                      ),
                      validator: (_) => _validateTagCount(validationMessageBuilder, addedTags),
                    );
                  },
                );
              }
            ),

            Container(
              margin: const EdgeInsets.only( top: 4.0 ),
              child: Row(
                // mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: <Widget>[
                  (addedTags.isNotEmpty
                    ? _TagList(
                      tags: addedTags, 
                      changeFieldValue: widget.formControl.changeFieldValue
                    )
                    : const SizedBox( width: 0.0) 
                  ),
                  
                  Text(
                    _buildTagCountText(addedTags),
                    style: Theme.of(context).textTheme.bodyText2?.copyWith(
                      color: Theme.of(context).colorScheme.onSurface,
                      fontSize: 12.0,
                      fontWeight: FontWeight.w500
                    ),
                  ),
                ],
              ),
            )
          ],
        );
      }
    );    
  }
}

class _TagList extends StatelessWidget {
  const _TagList({
    Key? key,
    required this.tags,
    required this.changeFieldValue,
  }) : super(key: key);

  final List<Tag> tags;
  final void Function(String, Object?) changeFieldValue;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 40.0,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        shrinkWrap: true,
        itemCount: tags.length,
        itemBuilder: (BuildContext context, int i) {
          return Container(
            margin: const EdgeInsets.only( right: 8.0 ),
            child: Chip(
              key: Key(tags[i].id.toString()),
              label: Text(
                tags[i].value,
                style: Theme.of(context).textTheme.bodyText2?.copyWith(
                  fontWeight: FontWeight.w500
                ),
              ),
              onDeleted: () {
                tags.removeAt(i);
                changeFieldValue(
                  Goal.tagsFieldName, 
                  tags,
                );
              },
            ),
          );
        }
      ),
    );
  }
}
