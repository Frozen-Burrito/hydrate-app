import 'package:flutter/material.dart';
import 'package:hydrate_app/src/provider/nav_provider.dart';
import 'package:hydrate_app/src/widgets/tab_page_view.dart';
import 'package:provider/provider.dart';

import 'package:hydrate_app/src/provider/hydration_record_provider.dart';
import 'package:hydrate_app/src/widgets/activity_sliver_list.dart';
import 'package:hydrate_app/src/widgets/btn_tab_bar.dart';
import 'package:hydrate_app/src/widgets/custom_sliver_appbar.dart';
import 'package:hydrate_app/src/widgets/opt_popup_menu.dart';
import 'package:hydrate_app/src/widgets/hydration_sliver_list.dart';

class HistoryTab extends StatelessWidget {

  const HistoryTab({ Key? key }) : super(key: key);

  @override
  Widget build(BuildContext context) {

    final hydrationProvider = Provider.of<HydrationRecordProvider>(context);
    final createTestRecords = hydrationProvider.insertTestRecords;

    return ChangeNotifierProvider(
      create: (_) => NavigationProvider(0),
      child: NestedScrollView(
        headerSliverBuilder: (BuildContext context, bool innerBoxIsScrolled) {

          return <Widget> [
            SliverOverlapAbsorber(
              handle: NestedScrollView.sliverOverlapAbsorberHandleFor(context),
              sliver: CustomSliverAppBar(
                title: 'Historial',
                leading: <Widget>[
                  IconButton(
                    icon: const Icon(Icons.refresh),
                    onPressed: createTestRecords,
                  ),
                ],
                bottom: const PreferredSize(
                  preferredSize: Size(double.infinity, 48.0),
                  child: ButtonTabBar(
                    tabs: <String>[
                      'Hidratación',
                      'Actividad'
                    ],
                  )
                ),
                actions: const <Widget>[
                  AuthOptionsMenu(),
                ],
              ),
            ),
          ];
        },
        body: const TabPageView(
          tabs: [
            HydrationSliverList(),
            ActivitySliverList()
          ],
        ),
      )
    );
  }
}
