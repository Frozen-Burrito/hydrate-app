import 'package:flutter/material.dart';
import 'package:hydrate_app/src/models/goal.dart';
import 'package:hydrate_app/src/provider/goals_provider.dart';
import 'package:provider/provider.dart';

class ReplaceGoalDialog extends StatefulWidget {

  const ReplaceGoalDialog({Key? key,}) : super(key: key);

  @override
  State<ReplaceGoalDialog> createState() => _ReplaceGoalDialogState();
}

class _ReplaceGoalDialogState extends State<ReplaceGoalDialog> {

  final List<int> selectedGoals = <int>[];

  //TODO: Agregar localizaciones.
  @override
  Widget build(BuildContext context) {

    final goalsProvider = Provider.of<GoalProvider>(context);

    return AlertDialog(
      title: const Text('¿Reemplazar una meta?'),
      content: FutureBuilder<List<Goal>>(
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
                  Text('Tienes ${goals.length} metas definidas. Para agregar una nueva meta, debes reeemplazar al menos una de ellas.'),

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
                          title: Text('${goals[i].quantity.toString()} ml, ${goals[i].notes}'),
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
          child: const Text('Cancelar'),
        ),
        TextButton(
          onPressed: selectedGoals.isNotEmpty
            ? () => Navigator.pop(context, selectedGoals)
            : null, 
          child: const Text('Reemplazar'),
        ),
      ],
    );
  }
}