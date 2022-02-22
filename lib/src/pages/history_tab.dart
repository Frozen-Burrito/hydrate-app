import 'dart:math';
import 'package:flutter/material.dart';

import 'package:hydrate_app/src/widgets/custom_toolbar.dart';
import 'package:hydrate_app/src/widgets/opt_popup_menu.dart';

class HistoryTab extends StatelessWidget {
  const HistoryTab({ Key? key }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return CustomScrollView(
      slivers: <Widget> [
        SliverPersistentHeader(
          floating: true,
            delegate: _SliverCustomHeaderDelegate(
              minHeight: 168,
              maxHeight: 168,
              child: CustomToolbar(
                title: 'Inicio',
                endActions: [
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
                ],
              )
            ),
        ),
      ]
    );
  }
}

class _SliverCustomHeaderDelegate extends SliverPersistentHeaderDelegate {

  final double minHeight;
  final double maxHeight;
  final Widget child;

  _SliverCustomHeaderDelegate({
    required this.minHeight, 
    required this.maxHeight, 
    required this.child
  });

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) {
    return SizedBox.expand(
      child: child,
    );
  }

  @override
  double get maxExtent => max(minHeight, maxHeight);

  @override
  double get minExtent => min(minHeight, maxHeight);

  @override
  bool shouldRebuild(covariant _SliverCustomHeaderDelegate oldDelegate) {
    return maxHeight != oldDelegate.maxHeight || 
           minHeight != oldDelegate.minHeight ||
           child != oldDelegate.child;
  }
}