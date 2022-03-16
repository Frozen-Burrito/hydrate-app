import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:hydrate_app/src/provider/hydration_record_provider.dart';
import 'package:hydrate_app/src/widgets/custom_sliver_appbar.dart';
import 'package:hydrate_app/src/widgets/opt_popup_menu.dart';
import 'package:hydrate_app/src/widgets/water_intake_sliver_list.dart';

class HistoryTab extends StatelessWidget {

  const HistoryTab({ Key? key }) : super(key: key);

  @override
  Widget build(BuildContext context) {

    final createTestRecords = Provider.of<HydrationRecordProvider>(context, listen: false).insertTestRecords;

    return CustomScrollView(
      physics: const BouncingScrollPhysics(),
      slivers: <Widget> [
        CustomSliverAppBar(
          title: 'Hidratación',
          leading: IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => createTestRecords(),
          ),
          actions: const <Widget>[
            AuthOptionsMenu()
          ]
        ),

        SliverToBoxAdapter(
          child: Container(
            width: MediaQuery.of(context).size.width,
            color: Colors.grey.shade100,
            height: 300.0,
          ),
        ),

        const WaterIntakeSliverList(),
      ]
    );
  }
}
