import 'package:flutter/material.dart';

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
          SliverAppBar(
            title: const Padding(
              padding: EdgeInsets.symmetric( vertical: 10.0 ),
              child: Text('Nueva Meta'),
            ),
            titleTextStyle: Theme.of(context).textTheme.headline4,
            centerTitle: true,
            backgroundColor: Colors.white,
            floating: true,
            leading: IconButton(
              color: Colors.black, 
              icon: const Icon(Icons.arrow_back), 
              onPressed: () => Navigator.pop(context)
            ),
            actionsIconTheme: const IconThemeData(color: Colors.black),
            actions: <Widget> [
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
