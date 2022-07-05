import 'package:flutter/material.dart';

/// Muestra el estado del proceso de obtención de información.
/// 
/// Sirve como contenido provisional de un sliver mientras el componente padre 
/// obtiene la información, usualmente desde una base de datos o la red.
/// 
/// Suele representar estados de:
/// - Carga
/// - Error
/// - Datos inexistentes
class SliverDataPlaceholder extends StatelessWidget {

  /// Si el contenido está cargando, sin haber un error. Se muestra un 
  /// [CircularProgressIndicator] si es [true].
  final bool isLoading;

  /// Contenido de un [Text] con el mensaje para el usuario sobre el estatus 
  /// de la información.
  final String message;

  /// Contenido de un [Text] con más detalles sobre el estatus de la información.
  final String details;

  /// Usado por el [Icon] principal.
  final IconData icon;

  final Widget? action;

  final bool hasTopSpacing;

  const SliverDataPlaceholder({
    this.isLoading = false,
    this.message = '',
    this.details = '',
    this.icon = Icons.error,
    this.action,
    this.hasTopSpacing = true,
    Key? key }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return SliverToBoxAdapter(
      child: IconTheme(
        data: IconThemeData(color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6)),
        child: Column(
          mainAxisSize: MainAxisSize.max,
          crossAxisAlignment: CrossAxisAlignment.center,
          mainAxisAlignment: MainAxisAlignment.center,
          children: isLoading 
          ? <Widget> [
            SizedBox( height: hasTopSpacing ? 64.0 : 0.0, ),
            
            const Center(
              child: CircularProgressIndicator()
            ),
          ]
          : <Widget>[
            SizedBox( height: hasTopSpacing ? 64.0 : 0.0,),

            Icon(
              icon,
              size: 100.0,
            ),
          
            const SizedBox( height: 16.0,),

            // Texto del contenido principal.
            SizedBox(
              width: MediaQuery.of(context).size.width * 0.8,
              child: Text(
                message,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyText1?.copyWith(
                  color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6)
                ),
              ),
            ),
      
            const SizedBox( height: 8.0,),

            // Texto del contenido detallado.
            SizedBox(
              width: MediaQuery.of(context).size.width * 0.8,
              child: Text(
                details,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyText2?.copyWith(
                  color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6)
                ),
              ),
            ),

            const SizedBox( height: 8.0,),

            (action ?? const SizedBox( height: 0.0, ))
          ],
        ),
      ),
    );
  }
}