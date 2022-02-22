import 'package:flutter/material.dart';

import 'package:hydrate_app/src/widgets/opt_popup_menu.dart';

class HomeTab extends StatelessWidget {
  const HomeTab({ Key? key }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return CustomScrollView(
      slivers: <Widget> [
        SliverAppBar(
          title: const Padding(
            padding: EdgeInsets.symmetric( vertical: 10.0 ),
            child: Text('Inicio'),
          ),
          titleTextStyle: const TextStyle(color: Colors.black, fontWeight: FontWeight.w600, fontSize: 24),
          centerTitle: true,
          backgroundColor: Colors.white,
          floating: true,
          actionsIconTheme: const IconThemeData(color: Colors.black),
          actions: <Widget> [
            IconButton(onPressed: (){}, icon: const Icon(Icons.task_alt)),
            OptionsPopupMenu(
              options: <MenuItem> [
                MenuItem(
                  icon: Icons.account_circle_rounded, 
                  label: 'Iniciar Sesión',
                  onSelected: () => print('Iniciando sesion...'),
                ),
                MenuItem(
                  icon: Icons.settings, 
                  label: 'Ajustes',
                  onSelected: () => Navigator.pushNamed(context, '/config'),
                ),
              ]
            ),
          ],
        ),
      ], 
    );
  }
}
