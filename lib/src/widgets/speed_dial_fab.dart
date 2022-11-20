import 'package:flutter/material.dart';

class SpeedDialFAB extends StatefulWidget {

  const SpeedDialFAB({
    Key? key,
    required this.icon,
    this.backgroundColor,
    this.foregroundColor,
    this.tooltip,
    this.items = const <SpeedDialItem>[], 
    this.transitionDuration = const Duration( milliseconds: 500 ),
  }) : super(key: key);

  final IconData icon;

  final Color? backgroundColor;
  final Color? foregroundColor;

  final String? tooltip;

  final List<SpeedDialItem> items;

  final Duration transitionDuration;

  static const int maxOptionCount = 3;

  @override
  State<SpeedDialFAB> createState() => _SpeedDialFABState();
}

class _SpeedDialFABState extends State<SpeedDialFAB>
  with SingleTickerProviderStateMixin {

  late final AnimationController _controller;

  late final Animation<double> _expandAnimation;

  bool _isExpanded = false;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: widget.transitionDuration,
    );

    _controller.addListener(() {
      setState(() { });
    });

    _expandAnimation = Tween<double>(
      begin: 150.0,
      end: -20.0
    ).animate(CurvedAnimation(
      parent: _controller, 
      curve: Curves.easeInOut
    ));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onTap() {
    if (_isExpanded) {
      _controller.reverse();
    } else {
      _controller.forward();
    }

    _isExpanded = !_isExpanded;
  }

  @override
  Widget build(BuildContext context) {

    List<Widget> speedDialOptions = <Widget>[];

    for (int i = 0; i < widget.items.length; ++i) {
      speedDialOptions.add(Transform(
        transform: Matrix4.translationValues(
          0.0, _expandAnimation.value, 0.0
        ),
        child: FloatingActionButton(
          backgroundColor: widget.items[i].color,
          tooltip: widget.items[i].tooltip,
          heroTag: null,
          mini: true,
          onPressed: widget.items[i].onPressed,
          child: Icon( widget.items[i].icon ),
        ),
      ));
    }

    speedDialOptions.add(FloatingActionButton(
      onPressed: _onTap,
      tooltip: widget.tooltip,
      heroTag: null,
      backgroundColor: widget.backgroundColor,
      foregroundColor: widget.foregroundColor,
      child: Icon( widget.icon ),
    ));

    return Column(
      mainAxisAlignment: MainAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: speedDialOptions,
    );
  }
}

class SpeedDialItem {

  const SpeedDialItem({ 
    required this.color, 
    required this.icon, 
    this.tooltip,
    this.onPressed
  });

  final Color color;
  final IconData icon;
  final String? tooltip;
  final VoidCallback? onPressed;

  @override
  String toString() {
    return "SpeedDialItem { color: $color, icon: $icon }";
  }

  @override 
  bool operator==(Object? other) {
    if (other.runtimeType != runtimeType) {
      return false;
    }

    return other is SpeedDialItem && 
           other.color == color && 
           other.onPressed == onPressed && 
           other.icon == icon &&
           other.tooltip == tooltip;
  }

  @override
  int get hashCode => Object.hashAll([
    color,
    icon,
    onPressed,
    tooltip,
  ]);
}
