import 'package:flutter/material.dart';

/// Un [SliverAppBar] personalizable para toda la app.
/// 
/// Puede recibir un título y acciones opcionales para mostrarlos como parte del
/// AppBar.
class CustomSliverAppBar extends StatelessWidget {

  /// El contenido para el título del encabezado, suele ser el nombre de la página.
  final String title;

  /// Lista opcional de acciones alineadas al inicio (izquierda) de la pantalla.
  final List<Widget>? leading;
  /// Lista opcional de acciones alineadas al final (derecha) de la pantalla.
  final List<Widget>? actions;
  
  /// [PreferredSizeWidget] opcional, mostrado abajo del toolbar. Suele ser un [TabBar].
  /// Si es null, el appbar muestra un [Divider].
  final PreferredSizeWidget? bottom;

  const CustomSliverAppBar({ 
    this.title = 'Toolbar', 
    this.leading, 
    this.actions,
    this.bottom,
    Key? key }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return SliverAppBar(
      title: Padding(
        padding: const EdgeInsets.symmetric( vertical: 10.0 ),
        child: Text(title),
      ),
      titleTextStyle: Theme.of(context).textTheme.headline4?.copyWith(
        fontSize: 22.0
      ),
      titleSpacing: 4.0,
      centerTitle: true,
      floating: true,
      leadingWidth: MediaQuery.of(context).size.width * 0.25,
      leading: Row(children: leading ?? <Widget>[],),
      actions: actions,
      bottom: bottom ?? const PreferredSize(
        preferredSize: Size(double.infinity, 5),
        child: Divider( thickness: 1.0, height: 1.0,),
      ),
    );
}
}