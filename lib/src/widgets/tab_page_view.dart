import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:hydrate_app/src/provider/nav_provider.dart';
import 'package:hydrate_app/src/pages/articles_tab.dart';
import 'package:hydrate_app/src/pages/history_tab.dart';
import 'package:hydrate_app/src/pages/home_tab.dart';

class TabPageView extends StatelessWidget {
  const TabPageView({ Key? key }) : super(key: key);

  @override
  Widget build(BuildContext context) {

    final navProvider = Provider.of<NavigationProvider>(context);

    return PageView(
      onPageChanged: (int pageIndex) => navProvider.activePage = pageIndex,
      controller: navProvider.pageController,
      physics: const BouncingScrollPhysics(),
      children: <Widget> [
        ArticlesTab(),
        const HomeTab(),
        const HistoryTab(),
      ],
    );
  }
}