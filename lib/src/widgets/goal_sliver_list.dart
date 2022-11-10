import 'dart:math';

import 'package:flutter/material.dart';
import 'package:hydrate_app/src/exceptions/entity_persistence_exception.dart';
import 'package:hydrate_app/src/widgets/dialogs/replace_goal_dialog.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';

import 'package:hydrate_app/src/models/goal.dart';
import 'package:hydrate_app/src/routes/route_names.dart';
import 'package:hydrate_app/src/services/goals_service.dart';
import 'package:hydrate_app/src/services/hydration_record_service.dart';
import 'package:hydrate_app/src/utils/datetime_extensions.dart';
import 'package:hydrate_app/src/widgets/data_placeholder.dart';
import 'package:hydrate_app/src/widgets/shapes.dart';

class GoalSliverList extends StatelessWidget {

  const GoalSliverList({
    Key? key,
    required this.hydrationGoalSource,
    this.showPlaceholderWhenEmpty = true,
    this.showLoadingIndicator = true,
    this.goalsAreRecommendations = false,
  }) : super(key: key);

  final Future<List<Goal>> hydrationGoalSource;

  final bool showPlaceholderWhenEmpty;

  final bool showLoadingIndicator;

  final bool goalsAreRecommendations;

  @override
  Widget build(BuildContext context) {

    return SliverPadding(
      padding: const EdgeInsets.all(8.0),
      sliver: FutureBuilder<List<Goal>?>(
        future: hydrationGoalSource,
        builder: (context, snapshot) {
          
          if (snapshot.hasData) {

            final hydrationGoals = snapshot.data ?? const <Goal>[];

            if (hydrationGoals.isNotEmpty) {
              return SliverList(
                delegate: SliverChildBuilderDelegate(
                  (BuildContext context, int i) {
                    return _GoalCard(
                      goal: hydrationGoals[i],
                      isRecommendation: goalsAreRecommendations,
                    );
                  },
                  childCount: hydrationGoals.length,
                ),
              );
            } else if (showPlaceholderWhenEmpty) {
              // Retornar un placeholder si los datos están cargando, o no hay datos aín.
              //TODO: Agregar i18n.
              return SliverToBoxAdapter(
                child: DataPlaceholder(
                  message: "Aún no has creado metas de hidratación.",
                  icon: Icons.flag,
                  hasTopSpacing: false,
                  action: ElevatedButton(
                    onPressed: () => Navigator.pushNamed(context, RouteNames.newHydrationGoal), 
                    child: const Text("Crea una meta"),
                    style: ElevatedButton.styleFrom(
                      primary: Colors.blue,
                    ),
                  ),
                ),
              );  
            }
          } else if (snapshot.hasError) {
            // Retornar un placeholder, indicando que hubo un error.
            print(snapshot.error);
            return const SliverToBoxAdapter(
              child: DataPlaceholder(
                isLoading: false,
                //TODO: agregar i18n
                message: "Hubo un error obteniendo tus metas de hidratación.",
                icon: Icons.error,
                hasTopSpacing: false,
              ),
            ); 
          } else if (showLoadingIndicator) {
            // El future no tiene datos ni error, aún no ha sido
            // completado.
            return const SliverToBoxAdapter(
              child: DataPlaceholder(
                isLoading: true,
                hasTopSpacing: false,
              ),
            );  
          }

          return const SliverToBoxAdapter(
            child: SizedBox( height: 0.0, width: 0.0 )
          );
        },
      ),
    );
  }
}

enum GoalCardAction { none, togglePrimary, share }

class _GoalCard extends StatelessWidget {

  const _GoalCard({ 
    required this.goal, 
    this.isRecommendation = false,
    Key? key 
  }) : super(key: key);

  final Goal goal;

  final bool isRecommendation;

  //TODO: Agregar i18n para plazos de tiempo
  static const termLabels = <String>['Diario','Semanal','Mensual'];
  static const timeMeasureNames = <String>["día", "semana", "mes"];
  
  //TODO: Agregar i18n para rangos de fechas en metas
  String _buildDateLabel(DateTime? start, DateTime? end) {

    final strBuf = StringBuffer();

    if (start != null) {
      strBuf.writeAll([ "Desde ", start.toLocalizedDate]);
    }

    if (end != null) {
      strBuf.writeAll([ " hasta ", end.toLocalizedDate]);
    }

    return strBuf.toString();
  }

  String _getGoalTitle(BuildContext context) {
    if (isRecommendation) {
      return "Meta Recomendada";
    } else {
      return goal.notes ?? "Meta de hidratación";
    }
  }

  String _getFormattedGoalTarget(BuildContext context) => "${goal.quantity.toString()}ml";

  List<PopupMenuEntry<GoalCardAction>> _buildGoalActions(BuildContext context) {
    return <PopupMenuEntry<GoalCardAction>>[
      PopupMenuItem(
        value: GoalCardAction.none,
        child: ListTile(
          title: Text(goal.notes ?? "Meta de hidratación"),
        ),
      ),
      const PopupMenuDivider(),
      PopupMenuItem(
        value: GoalCardAction.togglePrimary,
        child: Consumer<GoalsService>(
          builder: (_, goalsService, __) {
            return ListTile(
              leading: Icon( goal.isMainGoal ? Icons.flag : Icons.flag_outlined ), 
              title: Text(goal.isMainGoal ? "Quitar meta principal" : "Hacer meta principal"),
            );
          }
        ),
      ),
      const PopupMenuItem(
        value: GoalCardAction.share,
        child: ListTile(
          leading: Icon( Icons.share ), 
          title: Text("Compartir"),
        ),
      ),
    ];
  }

  @override
  Widget build(BuildContext context) {

    final mainCard = Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              mainAxisSize: MainAxisSize.max,
              children: [
                SizedBox(
                  width: MediaQuery.of(context).size.width * 0.6,
                  child: Text(
                    _getGoalTitle(context), 
                    style: Theme.of(context).textTheme.headline6,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),

                const SizedBox( width: 4.0 ),

                Column(
                  children: <Widget> [
                    Text(
                      _getFormattedGoalTarget(context),
                      style: Theme.of(context).textTheme.subtitle1,
                    ),
                    
                    Padding(
                      padding: const EdgeInsets.all(4.0),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: <Widget>[
                          const Padding(
                            padding: EdgeInsets.all(4.0),
                            child: CoinShape(radius: 8.0,),
                          ),
                
                          const SizedBox( width: 4.0,),
                
                          Text(
                            goal.reward.toString(),
                            style: Theme.of(context).textTheme.bodyText2,
                            textAlign: TextAlign.right,
                          ),
                        ],
                      ),
                    ),
                  ],
                ), 

                if (!isRecommendation)
                Consumer<GoalsService>(
                  builder: (context, goalsService, __) {
                    return PopupMenuButton<GoalCardAction>(
                      onSelected: (GoalCardAction selectedAction) {
                        switch (selectedAction) {
                          case GoalCardAction.togglePrimary:
                            goalsService.setMainGoal(goal.id);
                            break;
                          case GoalCardAction.share:
                            const String subject = "Progreso en mis metas de hidratación"; 
                            final String timeTermName = timeMeasureNames[goal.term.index];
                            final String message = "Este mes he alcanzado mi meta de tomar ${goal.quantity}ml de agua natural cada $timeTermName. Estoy muy orgullos@ de mis resultados!";
                            Share.share(message, subject: subject);
                            break;
                          case GoalCardAction.none:
                            break;
                        }
                      },
                      itemBuilder: _buildGoalActions,
                      initialValue: GoalCardAction.none,
                    );
                  }
                ),
              ]
            ),

            const SizedBox( height: 8.0, ),

            Text(
              termLabels[goal.term.index],
              style: Theme.of(context).textTheme.subtitle1?.copyWith(
                color: Theme.of(context).colorScheme.primary
              )
            ),

            if (goal.tags.isNotEmpty)
            SizedBox(
              height: 48.0,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: goal.tags.length,
                itemBuilder: (BuildContext context, int i) {
                  return Container(
                    margin: const EdgeInsets.only( right: 8.0 ),
                    child: Chip(
                      key: Key(goal.tags[i].id.toString()),
                      label: Text(
                        goal.tags[i].value,
                        style: Theme.of(context).textTheme.bodyText2?.copyWith(
                          fontWeight: FontWeight.w500
                        ),
                      ),
                    ),
                  );
                }
              ),
            ),
              
            Text(
              _buildDateLabel(goal.startDate, goal.endDate), 
              style: Theme.of(context).textTheme.bodyText1,
              textAlign: TextAlign.left
            ),

            ( isRecommendation 
            ? _GoalRecommendationActions( recommendedGoal: goal, )
            : _GoalProgressBar(goal: goal)
            ),
          ],
        ),
      ),
    );

    final columnItems = <Widget>[];

    if (goal.isMainGoal) {
      columnItems.add(
        Container(
          width: double.maxFinite,
          margin: const EdgeInsets.only( bottom: 8.0, left: 8.0 ),
          child: Text(
            //TODO: agregar i18n
            "Tu Meta Principal", 
            style: Theme.of(context).textTheme.headline5,
          )
        ),
      );
    }

    columnItems.add(mainCard);

    if (goal.isMainGoal) {
      columnItems.add(
        const Divider( thickness: 1.0, height: 24.0, ),
      );
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: columnItems,
    );
  }
}

class _GoalProgressBar extends StatelessWidget {

  const _GoalProgressBar({
    Key? key,
    required this.goal,
  }) : super(key: key);

  final Goal goal;

  @override
  Widget build(BuildContext context) {
    return Consumer<HydrationRecordService>(
      builder: (_, hydrationProvider, __) {
        return FutureBuilder<int>(
          future: hydrationProvider.getGoalProgressInMl(goal),
          initialData: 0,
          builder: (context, snapshot) {
            
            final goalQuantityMl = min(max(goal.quantity, Goal.waterQuantityMlRange.min), Goal.waterQuantityMlRange.max);
            final progressInMl = max(min(snapshot.data!, goalQuantityMl), 0);

            final adjustedProgress = progressInMl / goalQuantityMl.toDouble();
            final isGoalComplete = progressInMl >= goalQuantityMl;

            return Container(
              margin: const EdgeInsets.only( top: 16.0 ),
              child: Row(
                children: [
                  Expanded(
                    child: LinearProgressIndicator(
                      value: adjustedProgress,
                    ),
                  ),
        
                  (isGoalComplete) 
                  ? Container(
                      margin: const EdgeInsets.only( left: 8.0 ),
                      child: Icon(
                        Icons.check,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                    )
                  : const SizedBox( width: 0, ),
                ],
              ),
            );
          }
        );
      }
    );
  }
}

class _GoalRecommendationActions extends StatelessWidget {

  const _GoalRecommendationActions({
    Key? key,
    required this.recommendedGoal,
  }) : super(key: key);

  final Goal recommendedGoal;

  static const int _maxGoalPersistAttempts = 3;

  Future<void> _handleRecommendationAccepted(BuildContext context) async {

    final goalService = Provider.of<GoalsService>(context, listen: false);
    
    bool canCreateNewGoal = true;
    bool wasGoalCreated = false;
    int goalCreationAttemptCount = 0;

    recommendedGoal.id = -1;
    recommendedGoal.isMainGoal = false;

    while (!wasGoalCreated && canCreateNewGoal && goalCreationAttemptCount <= _maxGoalPersistAttempts) {
      try {
        final int createdGoalId = await goalService.createHydrationGoalWithLimit(recommendedGoal);

        wasGoalCreated = createdGoalId >= 0;

        if (wasGoalCreated) {
          await goalService.syncUpdatedHydrationGoalsWithAccount();
        } else {
          _showGoalCreateError(context);
        }

      } on EntityPersistException catch (ex) {
        final hasToReplaceGoal = ex.exceptionType == EntityPersitExceptionType.hasReachedEntityCountLimit;

        if (hasToReplaceGoal) {
          final wereGoalsReplaced = await _tryToReplaceExistingGoals(context, goalService);

          canCreateNewGoal = wereGoalsReplaced;
        }
      }
    }
  }

  Future<bool> _tryToReplaceExistingGoals(BuildContext context, GoalsService goalService) async {
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
    //TODO: agregar i18n.
    return Container(
      padding: const EdgeInsets.only( top: 16.0 ),
      child: Row(
        children: <Widget>[
          Expanded(
            child: Consumer<GoalsService>(
              builder: (context, goalsService, __) {
                return OutlinedButton.icon(
                  icon: const Icon( Icons.close, color: Colors.red, ),
                  label: Text("Rechazar"),
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 16.0),
                    textStyle: Theme.of(context).textTheme.bodyText1,
                  ),
                  onPressed: () => goalsService.rejectRecommendedGoal(recommendedGoal),
                );
              }
            ),
          ),

          const SizedBox( width: 16.0, ),

          Expanded(
            child: OutlinedButton.icon(
              icon: Icon( Icons.check, color: Colors.green.shade300, ),
              label: Text("Aceptar"),
              style: TextButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 16.0),
                textStyle: Theme.of(context).textTheme.bodyText1,
              ),
              onPressed: () => _handleRecommendationAccepted(context),
            ),
          ),
        ],
      ),
    );
  }
}