import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

import 'package:hydrate_app/src/models/goal.dart';
import 'package:hydrate_app/src/services/goals_service.dart';

class ReplaceGoalDialog extends StatefulWidget {

  const ReplaceGoalDialog({Key? key,}) : super(key: key);

  @override
  State<ReplaceGoalDialog> createState() => _ReplaceGoalDialogState();
}

class _ReplaceGoalDialogState extends State<ReplaceGoalDialog> {

  final List<int> selectedGoals = <int>[];

  String _buildGoalItemTitle(Goal hydrationGoal) {

    final goalNotes = hydrationGoal.notes;
    final waterVolumeStr = hydrationGoal.quantity.toString();

    return "$waterVolumeStr ml, $goalNotes";
  }

  String _buildDialogDescription(BuildContext context, int goalCount) {
    final localizations = AppLocalizations.of(context)!;

    final StringBuffer strBuf = StringBuffer(localizations.youHave);
    strBuf.writeAll([" ", goalCount]);
    strBuf.writeAll([" ", localizations.activeGoals, "."]);
    strBuf.writeAll([" ", localizations.reasonToReplaceGoal, "."]);

    return strBuf.toString();
  }

  @override
  Widget build(BuildContext context) {

    final goalsProvider = Provider.of<GoalsService>(context);
    final localizations = AppLocalizations.of(context)!;

    return AlertDialog(
      title: Text(localizations.askGoalReplacement),
      content: FutureBuilder<List<Goal>?>(
        future: goalsProvider.goals,
        builder: (context, snapshot) {

          final goals = snapshot.data;

          if (snapshot.hasData && goals != null) {

            return SizedBox(
              height: MediaQuery.of(context).size.height * 0.4,
              width: double.maxFinite,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(_buildDialogDescription(context, goals.length)),

                  const SizedBox(height: 8.0,),

                  Expanded(
                    child: ListView.builder(
                      shrinkWrap: true,
                      itemBuilder: (context, i) {
                  
                        final goal = goals[i];
                        final isGoalSelected = selectedGoals.contains(goal.id);
                  
                        return CheckboxListTile(
                          value: isGoalSelected,
                          onChanged: (bool? value) {
                            // Agregar o remover la meta de las metas seleccionadas.
                            final bool isChecked = value ?? false; 
                            setState(() {
                              if (isChecked) {
                                selectedGoals.add(goal.id);
                              } else {
                                selectedGoals.remove(goal.id);
                              }
                            });
                          },
                          title: Text(_buildGoalItemTitle(goals[i])),
                        );
                      },
                      itemCount: goals.length,
                    ),
                  ),
                ],
              ),
            );
          } else {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }
        }
      ), 
      actions: <Widget>[
        TextButton(
          onPressed: () => Navigator.pop(context, null), 
          child: Text(localizations.cancel),
        ),
        TextButton(
          onPressed: selectedGoals.isNotEmpty
            ? () => Navigator.pop(context, selectedGoals)
            : null, 
          child: Text(localizations.replace),
        ),
      ],
    );
  }
}