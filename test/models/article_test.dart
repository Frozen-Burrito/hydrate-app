import 'package:flutter_test/flutter_test.dart';

import 'package:hydrate_app/src/models/article.dart';

void main() {
  group('Modelo de artículo', () {
    test('Llamar .toMap() crea una representación en mapa equivalente.', () {
      // Arrange
      const title = 'Un título de prueba';
      const url = 'https://article.com';
      const description = 'Una descripción de prueba.';
      final DateTime now = DateTime.now();

      final article = Article(
        id: 0, 
        title: title, 
        url: url, 
        description: description, 
        publishDate: now
      );

      final expectedMap = <String, dynamic>{
        'id': 0,
        'titulo': title,
        'url': url,
        'descripcion': description,
        'fecha_pub': now.toIso8601String()
      };

      // Act
      final actualMap = article.toMap();

      // Assert
      expect(actualMap, expectedMap);
    });

    test('La fecha de publicación en string tiene formato ISO 8601', () {
      // Arrange
      final now = DateTime.now();
      final expectedDateStr = now.toIso8601String();
      final article = Article(id: -1, title: '', url: '', publishDate: now);

      // Act
      final articleMap = article.toMap();
      final String? publishDateStr = articleMap['fecha_pub'] as String?;

      // Assert
      expect(publishDateStr, expectedDateStr);
    });

    test('El artículo no está marcado por defecto', () {
      // Arrange
      const expectedIsBookmarked = false;
      final article = Article(id: -1, title: '', url: '');

      // Act
      final isBookmarked = article.isBookmarked;

      // Assert
      expect(isBookmarked, expectedIsBookmarked);
    });

    test('El nombre de la tabla es consistente.', () {
      // Arrange
      final article = Article(id: -1, title: '', url: '');

      // Act 
      const staticTableName = Article.tableName;
      final instanceTableName = article.table;

      // Assert
      expect(staticTableName, instanceTableName);
    });
  });
}