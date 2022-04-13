import 'package:flutter_test/flutter_test.dart';

import 'package:hydrate_app/src/models/api.dart';

void main() {
  group('Modelo de API', () {
    
    test('La URL base de la API es la del servicio web', () {
      // Arrange
      const String host = 'servicio-web-hydrate.azurewebsites.net';
      const String apiRoute = 'api';
      const String version = 'v1';

      const String expectedBaseUrl = 'https://$host/$apiRoute/$version';

      // Act
      String actualBaseUrl = API.baseUrl;

      // Assert
      expect(actualBaseUrl, expectedBaseUrl);
    });

    test('Utilizar una URL no válida genera una [FormatException]', () {
      // Arrange
      const String invalidUrl = 'google.com';

      // Act
      // Assert
      expect(API.get(invalidUrl), throwsFormatException);
    });
  });
}