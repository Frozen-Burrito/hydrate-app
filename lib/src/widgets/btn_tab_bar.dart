import 'package:flutter/material.dart';
import 'package:hydrate_app/src/provider/nav_provider.dart';
import 'package:provider/provider.dart';

// class ButtonTabBar extends StatefulWidget {

//   final List<String> tabs;

//   final MainAxisAlignment mainAxisAlignment;

//   final int currentIndex; 

//   const ButtonTabBar({
//     required this.tabs,
//     this.currentIndex = 0,
//     this.mainAxisAlignment = MainAxisAlignment.center, 
//     Key? key,
//   }) : super(key: key);

//   @override
//   State<ButtonTabBar> createState() => _ButtonTabBarState();
// }

// class _ButtonTabBarState extends State<ButtonTabBar> {

//   // int currentIndex = 0;

//   TabController? tabController;

//   // void _updateCurrentIndex() {
//   //   if (mounted) {
//   //     setState(() {
//   //       print('Tab idx updated: ${tabController?.index}');
//   //       currentIndex = tabController?.index ?? 1;
//   //     });
//   //   }
//   // }

//   // @override
//   // void initState() {
//   //   super.initState();

//   //   currentIndex = tabController?.index ?? 1;
//   //   print('Tab idx updated: ${tabController?.index}');
//   // }

//   // @override
//   // void dispose() {
//   //   tabController?.removeListener(_updateCurrentIndex);

//   //   super.dispose();
//   // }

//   @override
//   Widget build(BuildContext context) {   

//     final selectedBtnStyle = ElevatedButton.styleFrom(
//       primary: Theme.of(context).colorScheme.primary,
//       onPrimary: Theme.of(context).colorScheme.onPrimary,
//     );

//     final unselectedBtnStyle = ElevatedButton.styleFrom(
//       primary: Theme.of(context).colorScheme.surface,
//       onPrimary: Theme.of(context).colorScheme.onSurface,
//     );

//     tabController = DefaultTabController.of(context);

//     // print('Rebuilt');

//     // tabController?.addListener(_updateCurrentIndex);

//     return Row(
//       mainAxisAlignment: widget.mainAxisAlignment,
//       children: widget.tabs.asMap().entries.map((e) {
//         return Container(
//           margin: const EdgeInsets.only(right: 16.0),
//           child: ElevatedButton(
//             child: Text(e.value),
//             style: (widget.currentIndex == e.key) ? selectedBtnStyle : unselectedBtnStyle,
//             onPressed: () => tabController?.animateTo(e.key), 
//           ),
//         );
//       }).toList(),
//     );
//   }
// }

class ButtonTabBar extends StatelessWidget {

  final List<String> tabs;

  final MainAxisAlignment mainAxisAlignment;

  const ButtonTabBar({ 
    required this.tabs,
    this.mainAxisAlignment = MainAxisAlignment.center, 
    Key? key 
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {

    final selectedBtnStyle = ElevatedButton.styleFrom(
      primary: Theme.of(context).colorScheme.primary,
      onPrimary: Theme.of(context).colorScheme.onPrimary,
    );

    final unselectedBtnStyle = ElevatedButton.styleFrom(
      primary: Theme.of(context).colorScheme.surface,
      onPrimary: Theme.of(context).colorScheme.onSurface,
    );

    final navProvider = Provider.of<NavigationProvider>(context);

    return Row(
      mainAxisAlignment: mainAxisAlignment,
      children: tabs.asMap().entries.map((e) {
        return Container(
          margin: const EdgeInsets.only(right: 16.0),
          child: ElevatedButton(
            child: Text(e.value),
            style: (navProvider.activePage == e.key) ? selectedBtnStyle : unselectedBtnStyle,
            onPressed: () => navProvider.activePage = e.key, 
          ),
        );
      }).toList(),
    );
  }
}
