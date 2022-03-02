import 'package:flutter/material.dart';
import 'package:hydrate_app/src/db/sqlite_db.dart';
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
        slivers: <Widget> [

          CustomSliverAppBar(
            title: 'Inicio',
            actions: <Widget>[
              IconButton(
                icon: const Icon(Icons.task_alt),
                onPressed: () => Navigator.pushNamed(context, '/new-goal'), 
              ),
              OptionsPopupMenu(
                options: <MenuItem> [
                  //TODO: Quitar los MenuItems temporales de navegacion a los formularios
                  MenuItem(
                    icon: Icons.checklist, 
                    label: 'Formulario Inicial',
                    onSelected: () => Navigator.pushNamed(context, '/form/initial'),
                  ),
                  MenuItem(
                    icon: Icons.checklist, 
                    label: 'Formulario Recurrente',
                    onSelected: () => Navigator.pushNamed(context, '/form/periodic'),
                  ),
                  MenuItem(
                    icon: Icons.checklist, 
                    label: 'Formulario Médico',
                    onSelected: () => Navigator.pushNamed(context, '/form/medical'),
                  ),
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
