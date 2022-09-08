import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

import 'package:hydrate_app/src/models/user_profile.dart';
import 'package:hydrate_app/src/provider/profile_provider.dart';
import 'package:hydrate_app/src/routes/route_names.dart';
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

                        return _AssetFadeInImage(
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

class _AssetFadeInImage extends StatefulWidget {

  const _AssetFadeInImage({
    Key? key,
    required this.image,
    this.duration = const Duration(milliseconds: 500),
  }) : super(key: key);

  final String image;

  final Duration duration;

  @override
  State<_AssetFadeInImage> createState() => _AssetFadeInImageState();
}

class _AssetFadeInImageState extends State<_AssetFadeInImage>  
    with TickerProviderStateMixin {

  late final AnimationController _controller = AnimationController(
    duration: widget.duration,
    vsync: this,
  );

  late final Animation<double> _opacityAnimation = CurvedAnimation(
    parent: _controller, 
    curve: Curves.decelerate
  );

  @override
  void initState() {
    super.initState();

    _controller.forward();

    _opacityAnimation.addListener(() {
      print(_opacityAnimation.value);
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.transparent,
      child: FadeTransition(
        opacity: _opacityAnimation,
        child: Image( 
          image: AssetImage(widget.image),
        ),
      ),
    );
  }
}
