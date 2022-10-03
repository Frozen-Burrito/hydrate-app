import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:hydrate_app/src/services/nav_provider.dart';

class TabPageView extends StatelessWidget {

  final List<Widget> tabs;

  const TabPageView({ Key? key, required this.tabs }) : super(key: key);

  @override
  Widget build(BuildContext context) {

    final navProvider = Provider.of<NavigationProvider>(context);

    return PageView(
      onPageChanged: (int pageIndex) => navProvider.activePage = pageIndex,
      controller: navProvider.pageController,
      physics: const BouncingScrollPhysics(),
      children: tabs
    );
  }
}