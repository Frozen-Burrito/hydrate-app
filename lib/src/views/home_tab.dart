import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

import 'package:hydrate_app/src/models/environment.dart';
import 'package:hydrate_app/src/models/goal.dart';
import 'package:hydrate_app/src/models/user_profile.dart';
import 'package:hydrate_app/src/routes/route_names.dart';
import 'package:hydrate_app/src/services/goals_service.dart';
import 'package:hydrate_app/src/services/hydration_record_service.dart';
import 'package:hydrate_app/src/services/profile_service.dart';
import 'package:hydrate_app/src/widgets/asset_fade_in_image.dart';
import 'package:hydrate_app/src/widgets/coin_display.dart';
import 'package:hydrate_app/src/widgets/custom_sliver_appbar.dart';
import 'package:hydrate_app/src/widgets/goal_sliver_list.dart';
import 'package:hydrate_app/src/widgets/opt_popup_menu.dart';

class HomeTab extends StatelessWidget {

  const HomeTab({ Key? key }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      bottom: false,
      child: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: <Widget> [

          CustomSliverAppBar(
            title: AppLocalizations.of(context)!.home,
            leading: const <Widget> [CoinDisplay()],
            actions: <Widget>[
              IconButton(
                icon: const Icon(Icons.task_alt),
                onPressed: () => Navigator.pushNamed(context, RouteNames.newHydrationGoal), 
              ),
              const AuthOptionsMenu(),
            ],
          ),

          SliverToBoxAdapter(
            child: SizedBox(
              height: 360.0,
              width: 360.0,
              child: Consumer<ProfileService>(
                builder: (_, profileService, __) {
                  return FutureBuilder<UserProfile?>(
                    future: profileService.profile,
                    builder: (context, snapshot) {
                      if (snapshot.hasData) {
                        final environment = snapshot.data!.selectedEnvironment;
                        return _HydrationEnvironment(
                          selectedEnvironment: environment
                        );
                      } else {
                        return const Center(child: CircularProgressIndicator());
                      }
                    }
                  );
                }
              ),
            ),
          ),

          Consumer<GoalsService>(
            builder: (_, hydrationGoalService, __) {
              return GoalSliverList(
                hydrationGoalSource: hydrationGoalService.activeGoals,
              );
            }
          ),

          Consumer<GoalsService>(
            builder: (_, goalsService, __) {
              return FutureBuilder<int>(
                future: goalsService.getNumberOfDaysForRecommendation(),
                initialData: 1,
                builder: (context, snapshot) {

                  final daysOfHydrationRequired = snapshot.data ?? 1;
                  final endDate = DateTime.now();
                  final beginDate = endDate.subtract( Duration( days: daysOfHydrationRequired ));

                  return Consumer<HydrationRecordService>(
                    builder: (context, hydrationRecordService, __) {
                      return FutureBuilder<List<int>>(
                        future: hydrationRecordService.totalsFromPrevDaysInMl(
                          begin: beginDate, 
                          end: endDate,
                          sortByDateAscending: false,
                        ),
                        builder: (context, snapshot) {
                          final totalHydrationPerDay = snapshot.data;
                          final recommendedGoals = goalsService.getRecommendedGoals(
                            totalWaterIntakeForPeriod: totalHydrationPerDay
                          );

                          return GoalSliverList(
                            hydrationGoalSource: recommendedGoals,
                            goalsAreRecommendations: true,
                            showLoadingIndicator: false,
                            showPlaceholderWhenEmpty: false,
                          );
                        }
                      );
                    }
                  );
                }
              );
            }
          ),          
        ], 
      ),
    );
  }
}

class _HydrationEnvironment extends StatelessWidget {

  const _HydrationEnvironment({
    Key? key,
    required this.selectedEnvironment,
  }) : super(key: key);

  final Environment selectedEnvironment;

  @override
  Widget build(BuildContext context) {

    final hydrationService = Provider.of<HydrationRecordService>(context);
    final goalsService = Provider.of<GoalsService>(context);
    
    return FutureBuilder<Goal?>(
      future: goalsService.mainActiveGoal,
      builder: (context, snapshot) {

        final goal = snapshot.data;

        final Future<int> goalProgressFuture = (goal != null)
          ? hydrationService.getGoalProgressInMl(goal)
          : Future.value(0);

        return FutureBuilder<int>(
          future: goalProgressFuture,
          initialData: 0,
          builder: (context, snapshot) {

            final int mainGoalProgress =  snapshot.data ?? 0;
            final int target = goal?.quantity ?? 0;

            return AssetFadeInImage(
              image: selectedEnvironment.imagePathForHydration(mainGoalProgress, target),
              duration: const Duration(milliseconds: 500),
            );
          },
        );
      }
    );
  }
}

