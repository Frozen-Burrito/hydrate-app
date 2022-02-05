import 'package:flutter/material.dart';

/// Un widget para ser usado como un [AppBar] superior.
/// 
/// Puede recibir un título y acciones opcionales para mostrarlos como parte del
/// AppBar.
class CustomToolbar extends StatelessWidget {

  /// El contenido para el título del encabezado, suele ser el nombre de la página.
  final String title;

  /// Lista opcional de acciones alineadas al inicio (izquierda) de la pantalla.
  final List<Widget>? startActions;
  /// Lista opcional de acciones alineadas al final (derecha) de la pantalla.
  final List<Widget>? endActions;
  /// [Widget] hijo opcional, mostrado abajo del toolbar.
  final Widget? child;

  const CustomToolbar({ 
    this.title = 'Toolbar', 
    this.startActions, 
    this.endActions,
    this.child,
    Key? key }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
        color: Colors.white, //TODO: Usar tema de color de la app
        child: SafeArea(
          top: true,
          bottom: false,
          child: Column(
            children: <Widget> [
              Padding(
                padding: const EdgeInsets.symmetric( vertical: 20.0 ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    SizedBox(
                      width: 100.0,
                      child: Row (
                        mainAxisAlignment: MainAxisAlignment.start,
                        children: <Widget> [ 
                          ...?startActions, 
                          const SizedBox( width: 5.0,) 
                        ],
                      ),
                    ),
        
                    Text(
                      title,
                      style: const TextStyle(fontSize: 24.0, fontWeight: FontWeight.w700)
                    ),
        
                    SizedBox(
                      width: 100.0,
                      child: Row (
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: <Widget> [ 
                          // const SizedBox( width: 5.0,),
                          ...?endActions 
                        ],
                      ),
                    ),
                  ],
                ),
              ),
        
              const Divider(thickness: 1.0,),
        
              Container(
                child: child,
              )
            ]
          ),
        ),
      );
  }
}