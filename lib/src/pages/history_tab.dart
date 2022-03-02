import 'package:flutter/material.dart';

import 'package:hydrate_app/src/widgets/custom_sliver_appbar.dart';
import 'package:hydrate_app/src/widgets/opt_popup_menu.dart';

class HistoryTab extends StatelessWidget {
  const HistoryTab({ Key? key }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return CustomScrollView(
      slivers: <Widget> [

        CustomSliverAppBar(
          title: 'Hidratación',
          actions: <Widget>[
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
            )
          ]
        ),
      ]
    );
  }
}
