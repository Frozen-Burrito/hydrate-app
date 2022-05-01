import 'package:flutter/material.dart';

class ButtonTabBar extends StatefulWidget {

  final List<String> tabs;

  final MainAxisAlignment mainAxisAlignment;

  const ButtonTabBar({
    required this.tabs,
    this.mainAxisAlignment = MainAxisAlignment.center, 
    Key? key,
  }) : super(key: key);

  @override
  State<ButtonTabBar> createState() => _ButtonTabBarState();
}

class _ButtonTabBarState extends State<ButtonTabBar> {

  int currentIndex = 0;

  TabController? tabController;

  void _updateCurrentIndex() {
    if (mounted) {
      setState(() {
        currentIndex = tabController?.index ?? 1;
      });
    }
  }

  @override
  void dispose() {
    tabController?.removeListener(_updateCurrentIndex);

    super.dispose();
  }

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

    tabController = DefaultTabController.of(context);

    tabController?.addListener(_updateCurrentIndex);

    return Row(
      mainAxisAlignment: widget.mainAxisAlignment,
      children: widget.tabs.asMap().entries.map((e) {
        return Container(
          margin: const EdgeInsets.only(right: 16.0),
          child: ElevatedButton(
            child: Text(e.value),
            style: (currentIndex == e.key) ? selectedBtnStyle : unselectedBtnStyle,
            onPressed: () => tabController?.animateTo(e.key), 
          ),
        );
      }).toList(),
    );
  }
}
