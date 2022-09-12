import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

import 'package:hydrate_app/src/services/nav_provider.dart';

/// Una [BottomNavigationBar] con las tres principales opciones de navegación.
class BottomNavBar extends StatelessWidget {
  const BottomNavBar({ Key? key }) : super(key: key);

  @override
  Widget build(BuildContext context) {

    final navProvider = Provider.of<NavigationProvider>(context);

    final localizations = AppLocalizations.of(context)!;

    return BottomAppBar(
      shape: const CircularNotchedRectangle(),
      notchMargin: 6.0,
      child: SizedBox(
        height: 64.0,
        child: Row(
          mainAxisSize: MainAxisSize.max,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            BottomAppBarItem(
              icon: Icons.auto_stories_rounded,
              label: localizations.resources,
              onTap: (i) => navProvider.activePage = i,
              pageIndex: 0,
            ),
            BottomAppBarItem(
              icon: Icons.opacity,
              label: localizations.home,
              onTap: (i) => navProvider.activePage = i,
              pageIndex: 1,
            ),
            BottomAppBarItem(
              icon: Icons.timeline_rounded,
              label: localizations.history,
              onTap: (i) => navProvider.activePage = i,
              pageIndex: 2,
            ),
            BottomAppBarItem(
              icon: Icons.account_circle,
              label: localizations.profile,
              onTap: (i) => navProvider.activePage = i,
              pageIndex: 3,
            ),
            const BottomAppBarItem.spacer()
          ],
        ),
      ),
    );
  }
}

class BottomAppBarItem extends StatelessWidget {

  final String label;
  final IconData icon;
  final int pageIndex;
  final ValueChanged<int>? onTap;
  
  const BottomAppBarItem({ 
    required this.label, 
    required this.icon,
    required this.pageIndex,
    required this.onTap,
    Key? key,  
  }) : super(key: key);

  const BottomAppBarItem.spacer({
    this.label = '', 
    this.icon = Icons.space_bar, 
    this.pageIndex = -1, 
    this.onTap,
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {

    final navProvider = Provider.of<NavigationProvider>(context);

    final isSelected =  navProvider.activePage == pageIndex;

    Color itemColor = isSelected
      ? Theme.of(context).colorScheme.primary
      : Theme.of(context).colorScheme.onSurface;

    if (pageIndex < 0) itemColor = Colors.transparent;

    return Expanded(
      child: SizedBox(
        height: 48.0,
        child: InkResponse(
          focusColor: Colors.transparent,
          hoverColor: Colors.transparent,
          highlightColor: Colors.transparent,
          radius: 28.0,
          onTap: (onTap != null) 
            ? () => navProvider.activePage = pageIndex
            : null,
          child: Padding(
            padding: const EdgeInsets.all(4.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget> [
                Icon(icon, color: itemColor),

                (isSelected) 
                ? Text(
                    label,
                    style: Theme.of(context).textTheme.bodyText2?.copyWith(
                      color: itemColor,
                      fontSize: 12.0,
                    ),
                  )
                : const SizedBox( height: 0.0),
              ],
            ),
          ),
        )
      ),
    );
  }
}