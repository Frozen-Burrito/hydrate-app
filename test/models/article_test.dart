import 'package:flutter_test/flutter_test.dart';

import 'package:hydrate_app/src/models/article.dart';

void main() {

  group("Functional Article tests", () {

    test('When a new Article is created, it is not bookmarked by default', () {
      // Arrange
      final article = Article();

      // Act
      final isBookmarked = article.isBookmarked;

      // Assert
      expect(isBookmarked, isFalse);
    });

    test("Creating an Article instance with an invalid URL results in Article.url being null", () {
      // Arrange
      const String invalidUrl = "::some invalid url::";

      // Act
      final article = Article(articleUrl: invalidUrl);

      // Assert
      expect(article.url, isNull);
    });

    test("Creating an Article instance with a valid URL results in Article.url having its value", () {
      // Arrange
      const String acceptedUrl = "https://google.com";
      final Uri expected = Uri.parse(acceptedUrl);

      // Act
      final article = Article(articleUrl: acceptedUrl);

      // Assert
      expect(article.url, expected);
    });
  });

  group("Article as an SQLiteModel instance", () {
    test('Article.toMap() creates an equivalent map representation of the Article', () {
      // Arrange
      const articleId = 1;
      const title = "A test Article";
      const url = "https://article.com";
      const description = "A test description.";
      final DateTime now = DateTime.now();

      final article = Article(
        id: articleId, 
        title: title, 
        articleUrl: url, 
        description: description, 
        publishDate: now
      );

      final expectedMap = <String, dynamic>{
        Article.idFieldName: articleId,
        Article.titleFieldName: title,
        Article.urlFieldName: Uri.parse(url),
        Article.descriptionFieldName: description,
        Article.publishDateFieldName: now.toIso8601String()
      };

      // Act
      final actualMap = article.toMap();

      // Assert
      expect(actualMap, expectedMap);
    });

    test('Article.toMap() produces a map with a valid ISO 8601 string for the publish date', () {
      // Arrange
      final now = DateTime.now();
      final expectedDateStr = now.toIso8601String();
      final article = Article(publishDate: now);

      // Act
      final articleMap = article.toMap();
      final String? publishDateStr = articleMap[Article.publishDateFieldName] as String?;

      // Assert
      expect(publishDateStr, expectedDateStr);
    });

    test("Article's table name is consistent between Article.tableName and Article().table", () {
      // Arrange
      final article = Article();

      // Act 
      const staticTableName = Article.tableName;
      final instanceTableName = article.table;

      // Assert
      expect(staticTableName, instanceTableName);
    });
  });

  group("Common object method overrides", () {
    test("Article.toString() returns a non-empty string representation", () {
      // Arrange
      final article = Article();

      // Act
      final articleAsString = article.toString();

      // Assert
      expect(articleAsString.isNotEmpty, isTrue);
    });

    test("Article == operator implementation is reflexive", () {
      // Arrange
      final a = Article();

      // Act
      final comparisonResult = a == a;

      // Assert
      expect(comparisonResult, isTrue);
    });

    test("Article == operator implementation is symmetric", () {
      // Arrange
      final a = Article();
      final b = Article();

      // Act
      final firstResult = a == b;
      final secondResult = b == a;

      // Assert
      expect(firstResult, secondResult);
    });

    test("Article == operator implementation is transitive", () {
      // Arrange
      final a = Article();
      final b = Article();
      final c = Article();

      final expectedResult = (a == b) && (b == c);

      // Act
      final transitiveResult = a == c;

      // Assert
      expect(transitiveResult, expectedResult);
    });

    test("Article == operator implementation is reflexive", () {
      // Arrange
      final a = Article();

      // Act
      final comparisonResult = a == a;

      // Assert
      expect(comparisonResult, isTrue);
    });

    test("Comparing two article references with equal identities returns true", () {
      // Arrange
      final a = Article();
      final b = a;

      // Act
      final comparisonResult = a == b;

      // Assert
      expect(comparisonResult, isTrue);
    });

    test("Comparing two article instances with equal values returns true", () {
      // Arrange
      final a = Article();
      final b = Article();

      // Act
      final comparisonResult = a == b;

      // Assert
      expect(comparisonResult, isTrue);
    });

    test("Comparing two Article instances with different id values returns false", () {
      // Arrange
      final a = Article(id: 0);
      final b = Article(id: 1);

      // Act
      final comparisonResult = a == b;

      // Assert
      expect(comparisonResult, isFalse);
    });
  });
}