import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:hydrate_app/src/pages/articles_tab.dart';
import 'package:hydrate_app/src/pages/history_tab.dart';
import 'package:hydrate_app/src/pages/home_tab.dart';
import 'package:hydrate_app/src/pages/profile_tab.dart';
import 'package:hydrate_app/src/provider/nav_provider.dart';
import 'package:hydrate_app/src/routes/route_names.dart';
import 'package:hydrate_app/src/widgets/bottom_nav_bar.dart';
import 'package:hydrate_app/src/widgets/tab_page_view.dart';

class MainPage extends StatelessWidget {
  const MainPage({ Key? key }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => NavigationProvider(),
      child: Scaffold(
        body: const TabPageView(
          tabs: <Widget>[
            ArticlesTab(),
            HomeTab(),
            HistoryTab(),
            ProfileTab(),
          ],
        ),
        floatingActionButtonLocation: FloatingActionButtonLocation.endDocked,
        floatingActionButton: FloatingActionButton(
          child: const Icon(Icons.directions_run),
          tooltip: 'Registrar actividad',
          backgroundColor: Theme.of(context).colorScheme.primary,
          foregroundColor: Theme.of(context).colorScheme.onPrimary,
          onPressed: () => Navigator.pushNamed(context, RouteNames.newActivity)
        ),
        bottomNavigationBar: const BottomNavBar(),
      ),
    );
  }
}