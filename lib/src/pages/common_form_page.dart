import 'package:flutter/material.dart';

class CommonFormPage extends StatelessWidget {
  
  final String formTitle;

  final Widget formWidget;

  const CommonFormPage({ 
    required this.formTitle, 
    required this.formWidget, 
    Key? key 
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.blue,
      body: CustomScrollView(
        physics: BouncingScrollPhysics(),
        slivers: <Widget>[
          SliverAppBar(
            title: Padding(
              padding: const EdgeInsets.symmetric( vertical: 10.0 ),
              child: Text(formTitle),
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
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: <Widget>[
                  formWidget
                ]
              ),
            ),
        ],
      ),
    );
  }
}