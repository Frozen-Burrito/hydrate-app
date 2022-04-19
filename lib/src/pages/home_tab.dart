import 'package:flutter/material.dart';

import 'package:hydrate_app/src/db/sqlite_db.dart';
import 'package:hydrate_app/src/widgets/coin_display.dart';
import 'package:hydrate_app/src/widgets/custom_sliver_appbar.dart';
import 'package:hydrate_app/src/widgets/goal_sliver_list.dart';
import 'package:hydrate_app/src/widgets/opt_popup_menu.dart';

class HomeTab extends StatelessWidget {
  const HomeTab({ Key? key }) : super(key: key);

  @override
  Widget build(BuildContext context) {

    SQLiteDB.instance;
    
    return SafeArea(
      top: false,
      bottom: false,
      child: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: <Widget> [

          CustomSliverAppBar(
            title: 'Inicio',
            leading: const <Widget> [CoinDisplay()],
            actions: <Widget>[
              IconButton(
                icon: const Icon(Icons.task_alt),
                onPressed: () => Navigator.pushNamed(context, '/new-goal'), 
              ),
              const AuthOptionsMenu(),
            ],
          ),

          const SliverToBoxAdapter(
            child: Image( 
              image: AssetImage('assets/img/placeholder.png'),
            )
          ),

          const GoalSliverList(),
        ], 
      ),
    );
  }
}
