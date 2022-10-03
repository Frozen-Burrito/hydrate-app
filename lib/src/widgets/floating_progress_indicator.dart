import 'package:flutter/material.dart';

class FloatingProgressIndicator extends StatelessWidget {
  
  const FloatingProgressIndicator({
    Key? key, 
    this.value,
    this.width = 32.0,
    this.height = 32.0,
  }) : super(key: key);

  final double? value;

  final double width;
  final double height;
  
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(8.0),
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface.withOpacity(0.6),
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: Theme.of(context).colorScheme.shadow,
            blurRadius: 4.0,
            spreadRadius: 4.0,
          ),
        ]
      ),
      child: Center(
        child: CircularProgressIndicator(
          value: value,
        ),
      ),
    );
  }
}