import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:provider/provider.dart';

import 'package:hydrate_app/src/provider/profile_provider.dart';
import 'package:hydrate_app/src/models/enums/auth_action_type.dart';
import 'package:hydrate_app/src/routes/route_names.dart';

/// Un [PopupMenuButton] que despliega una lista de [options].
/// 
/// Cada elemento de [options] es un [MenuItem]. Este widget 
/// solo recibe un [icon], por lo que actúa como un [IconButton].
class OptionsPopupMenu extends StatelessWidget {

  /// Incluye todos los elementos que debe mostrar el menú desplegable.
  final List<MenuItem> options;

  /// El icono para el [IconButton] que abre el menú. [Icons.more_vert] por 
  /// default.
  final IconData? icon;

  /// Crea una nueva instancia constante de [OptionsPopupMenu].
  /// 
  /// Es obligatorio especificar una lista de [MenuItem], con las opciones del
  /// menú. Opcionalmente, también recibe un [key].
  const OptionsPopupMenu({ 
    required this.options, 
    this.icon,
    Key? key, 
  }) : super(key: key);

  /// Implementación de [Widget.build] que retorna un [OptionsPopupMenu].
  @override
  Widget build(BuildContext context) {
    return PopupMenuButton(
      icon: Icon(icon ?? Icons.more_vert),
      onSelected: (MenuItem item) => item.onSelected!(),
      itemBuilder: (BuildContext context) => <PopupMenuEntry<MenuItem>>[
        ...options.map((MenuItem item) => item.isDivider 
          ? const PopupMenuDivider( height: 20.0, ) as PopupMenuEntry<MenuItem>
          : PopupMenuItem(
            value: item,
            child: Row(
              children: <Widget> [
                Icon(item.icon),
                const SizedBox( width: 10.0, ),
                Text(item.label),
              ],
            ),
          )
        )
      ]
    );
  }
}

/// Un widget con opciones preconfiguradas para un [OptionsPopupMenu], según la
/// autenticación del usuario.
class AuthOptionsMenu extends StatelessWidget {

  const AuthOptionsMenu({ Key? key }) : super(key: key);

  @override
  Widget build(BuildContext context) {

    final profileProvider = Provider.of<ProfileProvider>(context);
    final localizations = AppLocalizations.of(context)!;
    
    return OptionsPopupMenu(
      options: profileProvider.linkedAccountId.isEmpty 
        ? <MenuItem> [
          MenuItem(
            icon: Icons.settings, 
            label: localizations.settings,
            onSelected: () => Navigator.pushNamed(context, RouteNames.config),
          ),
          
          MenuItem(isDivider: true, label: '', icon: Icons.settings),

          MenuItem(
            icon: Icons.account_circle_rounded, 
            label: localizations.signIn,
            onSelected: () => Navigator.pushNamed(
              context, 
              RouteNames.authentication, 
              arguments: AuthActionType.signIn
            ),
          ),

          MenuItem(
            icon: Icons.badge_rounded, 
            label: localizations.signUp,
            onSelected: () => Navigator.pushNamed(
              context, 
              RouteNames.authentication, 
              arguments: AuthActionType.signUp
            ),
          ),
        ]
        : <MenuItem> [

          MenuItem(
            icon: Icons.settings, 
            label: localizations.settings,
            onSelected: () => Navigator.pushNamed(context, RouteNames.config),
          ),

          MenuItem(isDivider: true, label: '', icon: Icons.settings),

          MenuItem(
            icon: Icons.logout,
            label: localizations.signOut,
            onSelected: () {
              profileProvider.logOut();
              Navigator.pushNamed(context, RouteNames.home);
            },
          ),
        ],
    );
  }
}

/// Representa una posible opción de [OptionsPopupMenu].
class MenuItem {

  final bool isDivider;
  /// El texto asociado con la opción.
  final String label;
  /// Un [IconData] para el ícono de la opción en el menú.
  final IconData icon;
  /// Un callback opcional, llamado cuando el elemento es seleccionado en el 
  /// menú.
  final void Function()? onSelected;

  /// Crea una nueva instancia de [MenuItem].
  MenuItem({
    required this.label, 
    required this.icon,
    this.isDivider = false,
    this.onSelected
  });
}