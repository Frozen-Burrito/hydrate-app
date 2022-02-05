import 'package:flutter/material.dart';
import 'package:hydrate_app/src/widgets/custom_toolbar.dart';

class HomeTab extends StatelessWidget {
  const HomeTab({ Key? key }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: CustomToolbar(
        title: 'Inicio',
        endActions: [
          IconButton(onPressed: () {}, icon: const Icon(Icons.task_alt_rounded)),
          IconButton(onPressed: () {}, icon: const Icon(Icons.more_vert)),
        ],
      ),
    );
  }
}