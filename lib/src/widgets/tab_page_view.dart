import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:hydrate_app/src/pages/articles_tab.dart';
import 'package:hydrate_app/src/provider/nav_provider.dart';

class TabPageView extends StatelessWidget {
  const TabPageView({ Key? key }) : super(key: key);

  @override
  Widget build(BuildContext context) {

    final navProvider = Provider.of<NavigationProvider>(context);

    return PageView(
      onPageChanged: (int pageIndex) => navProvider.activePage = pageIndex,
      controller: navProvider.pageController,
      physics: const BouncingScrollPhysics(),
      children: const <Widget> [
        ArticlesTab('Articulos'),
        ArticlesTab('Inicio'),
        ArticlesTab('Historial'),
      ],
    );
  }
}