
import 'package:url_launcher/url_launcher.dart';

class UrlLauncher {

  static Future<void> launchUrlInBrowser(Uri url) async {

    final launchSuccessful = await launchUrl(url, mode: LaunchMode.externalApplication);

    if (!launchSuccessful) {
      throw 'No se pudo abrir la URL en el navegador: $url';
    }
  }
}