import 'package:flutter/material.dart';
import 'package:hydrate_app/src/provider/nav_provider.dart';
import 'package:provider/provider.dart';

/// Una [BottomNavigationBar] con las tres principales opciones de navegación.
class BottomNavBar extends StatelessWidget {
  const BottomNavBar({ Key? key }) : super(key: key);

  @override
  Widget build(BuildContext context) {

    final navProvider = Provider.of<NavigationProvider>(context);

    return BottomNavigationBar(
      currentIndex: navProvider.activePage,  
      onTap: (i) => navProvider.activePage = i,
      items: const <BottomNavigationBarItem>[
        BottomNavigationBarItem(
          icon: Icon(Icons.auto_stories_rounded),
          label: 'Artículos'
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.home),
          label: 'Inicio'
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.timeline_rounded),
          label: 'Historial'
        ),
      ],
    );
  }
}