import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:hydrate_app/src/services/nav_provider.dart';

class ButtonTabBar extends StatelessWidget {

  final List<String> tabs;

  final MainAxisAlignment mainAxisAlignment;

  const ButtonTabBar({ 
    required this.tabs,
    this.mainAxisAlignment = MainAxisAlignment.center, 
    Key? key 
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {

    final selectedBtnStyle = ElevatedButton.styleFrom(
      primary: Theme.of(context).colorScheme.primary,
      onPrimary: Theme.of(context).colorScheme.onPrimary,
    );

    final unselectedBtnStyle = ElevatedButton.styleFrom(
      primary: Theme.of(context).colorScheme.surface,
      onPrimary: Theme.of(context).colorScheme.onSurface,
    );

    final navProvider = Provider.of<NavigationProvider>(context);

    return Row(
      mainAxisAlignment: mainAxisAlignment,
      children: tabs.asMap().entries.map((e) {
        return Container(
          margin: const EdgeInsets.only(right: 16.0),
          child: ElevatedButton(
            child: Text(e.value),
            style: (navProvider.activePage == e.key) ? selectedBtnStyle : unselectedBtnStyle,
            onPressed: () => navProvider.activePage = e.key, 
          ),
        );
      }).toList(),
    );
  }
}
