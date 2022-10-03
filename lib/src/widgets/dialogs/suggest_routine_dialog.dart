import 'package:flutter/material.dart';

class SuggestRoutineDialog extends StatelessWidget {

  const SuggestRoutineDialog({
    Key? key,
    this.similarActivityCount = 1
  }) : super(key: key);

  final int similarActivityCount;

  @override
  Widget build(BuildContext context) {

    final content = '''Hay $similarActivityCount registros de actividad en la semana pasada que son similares a la actividad que estás registrando. ¿Deseas crear una rutina con ellas?''';

    return AlertDialog(
      title: const Text('¿Quieres crear una rutina?'),
      content: Text(content),
      actions: <Widget>[
        TextButton(
          onPressed: () => Navigator.pop(context, false), 
          child: const Text('No'),
        ),
        TextButton(
          onPressed: () => Navigator.pop(context, true), 
          child: const Text('Sí, crear rutina'),
        ),
      ],
    );
  }
}