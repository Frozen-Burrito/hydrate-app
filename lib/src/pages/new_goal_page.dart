import 'package:flutter/material.dart';
import 'package:hydrate_app/src/widgets/custom_sliver_appbar.dart';

import 'package:hydrate_app/src/widgets/forms/create_goal_form.dart';
import 'package:hydrate_app/src/widgets/shapes.dart';

class NewGoalPage extends StatelessWidget {
  const NewGoalPage({ Key? key }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: <Widget>[

          CustomSliverAppBar(
            title: 'Nueva Meta',
            leading: <Widget>[
              IconButton(
                icon: const Icon(Icons.arrow_back), 
                onPressed: () => Navigator.pop(context)
              ),
            ],
            actions: <Widget>[
              IconButton(
                icon: const Icon(Icons.help),
                onPressed: (){}, 
              ),
            ],
          ),
        
          SliverToBoxAdapter(
            child: Stack(
              children: const <Widget> [
                WaveShape(),

                Center(
                  child: CreateGoalForm()
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
