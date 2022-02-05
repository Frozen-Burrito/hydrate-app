import 'package:flutter/material.dart';
import 'package:hydrate_app/src/widgets/custom_toolbar.dart';

class HistoryTab extends StatelessWidget {
  const HistoryTab({ Key? key }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: CustomToolbar(
        title: 'Hidratación',
        endActions: [
          IconButton(onPressed: () {}, icon: const Icon(Icons.more_vert)),
        ],
      ),
    );
  }
}