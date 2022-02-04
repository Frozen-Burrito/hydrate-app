import 'package:flutter/material.dart';

class ArticlesTab extends StatelessWidget {
  
  //TODO: Crear las otras tabs, este string es solo para probar.
  final String tabName;
  
  const ArticlesTab(this.tabName, { Key? key }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text(tabName),
    );
  }
}