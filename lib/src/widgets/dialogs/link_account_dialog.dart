import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

class LinkAccountDialog extends StatelessWidget {

  const LinkAccountDialog({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {

    final localizations = AppLocalizations.of(context)!;

    //TODO: agregar i18n.
    final dialogTitle = "¿Asociar cuenta con el perfil local de usuario?";
    final content = "Tu perfil de usuario local no tiene una cuenta asociada. Asociar una cuenta te permite acceder a tu perfil desde varios dispositivos.";
    final String cancelButtonText = "Continuar sin asociar";
    final String acceptButtonText = "Asociar perfil";

    return AlertDialog(
      title: Text(dialogTitle),
      content: Text(content),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false), 
          child: Text(cancelButtonText),
        ),
        TextButton(
          onPressed: () => Navigator.pop(context, true), 
          child: Text(acceptButtonText),
        ),
      ],
    );
  }
}