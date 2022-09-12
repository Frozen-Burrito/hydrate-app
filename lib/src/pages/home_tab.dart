import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

import 'package:hydrate_app/src/models/user_profile.dart';
import 'package:hydrate_app/src/provider/profile_provider.dart';
import 'package:hydrate_app/src/routes/route_names.dart';
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
              child: Consumer<ProfileProvider>(
                builder: (_, profileProvider, __) {
                  return FutureBuilder<UserProfile?>(
                    future: profileProvider.profile,
                    builder: (context, snapshot) {
                      if (snapshot.hasData) { 

                        final profile = snapshot.data!;

                        return AssetFadeInImage(
                          //TODO: usar valores reales para el current y el target.
                          image: profile.selectedEnvironment.imagePathForHydration(0, 0),
                          duration: const Duration(milliseconds: 500),
                        );
                      } else {
                        return const Center(child: CircularProgressIndicator());
                      }
                    }
                  );
                }
              ),
            )
          ),

          const GoalSliverList(),
        ], 
      ),
    );
  }
}

