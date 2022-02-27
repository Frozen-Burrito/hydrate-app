import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:hydrate_app/src/provider/nav_provider.dart';
import 'package:hydrate_app/src/widgets/bottom_nav_bar.dart';
import 'package:hydrate_app/src/widgets/tab_page_view.dart';

class MainPage extends StatelessWidget {
  const MainPage({ Key? key }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => NavigationProvider(),
      child: const Scaffold(
        body: TabPageView(),
        bottomNavigationBar: BottomNavBar(),
      ),
    );
  }
}