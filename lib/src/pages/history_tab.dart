import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:hydrate_app/src/pages/auth_page.dart';
import 'package:hydrate_app/src/provider/hydration_record_provider.dart';
import 'package:hydrate_app/src/provider/settings_provider.dart';
import 'package:hydrate_app/src/widgets/custom_sliver_appbar.dart';
import 'package:hydrate_app/src/widgets/opt_popup_menu.dart';
import 'package:hydrate_app/src/widgets/water_intake_sliver_list.dart';

class HistoryTab extends StatelessWidget {

  const HistoryTab({ Key? key }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    
    final settingsProvider = Provider.of<SettingsProvider>(context);

    final createTestRecords = Provider.of<HydrationRecordProvider>(context, listen: false).insertTestRecords;

    final menuItemsDefault = <MenuItem> [
      MenuItem(
        icon: Icons.account_circle_rounded, 
        label: 'Iniciar Sesión',
        onSelected: () async {
          final token = await Navigator.pushNamed(context, 'auth', arguments: AuthFormType.login) ?? '';

          if (token is String) {
            settingsProvider.authToken = token;
          }
        },
      ),

      MenuItem(isDivider: true, label: '', icon: Icons.settings),

      MenuItem(
        icon: Icons.settings, 
        label: 'Ajustes',
        onSelected: () => Navigator.pushNamed(context, '/config'),
      ),
    ];

    final menuItemsAuth = <MenuItem> [
      MenuItem(
        icon: Icons.account_circle_rounded, 
        label: 'Perfil',
        onSelected: () => print("Navegando al perfil..."),
      ),

      MenuItem(isDivider: true, label: '', icon: Icons.settings),

      MenuItem(
        icon: Icons.logout,
        label: 'Cerrar Sesión',
        onSelected: () => settingsProvider.logOut(),
      ),

      MenuItem(
        icon: Icons.settings, 
        label: 'Ajustes',
        onSelected: () => Navigator.pushNamed(context, '/config'),
      ),
    ];

    print(settingsProvider.authToken);

    return CustomScrollView(
      physics: const BouncingScrollPhysics(),
      slivers: <Widget> [
        CustomSliverAppBar(
          title: 'Hidratación',
          leading: IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => createTestRecords(),
          ),
          actions: <Widget>[
            OptionsPopupMenu(
              options: settingsProvider.authToken.isEmpty 
                ? menuItemsDefault
                : menuItemsAuth
            )
          ]
        ),

        SliverToBoxAdapter(
          child: Container(
            width: MediaQuery.of(context).size.width,
            color: Colors.grey.shade100,
            height: 300.0,
          ),
        ),

        const WaterIntakeSliverList(),
      ]
    );
  }
}
