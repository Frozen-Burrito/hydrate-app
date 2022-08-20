import "package:flutter_test/flutter_test.dart";
import 'package:hydrate_app/src/api/paged_result.dart';
import 'package:hydrate_app/src/models/article.dart';
import 'package:hydrate_app/src/models/map_options.dart';

void main() {

  final Article validArticle = Article(
    id: 1,
    title: "An Article",
    description: "A description.",
    articleUrl: "https://google.com",
    publishDate: DateTime(2016, 5, 26),
  );

  final Article anotherValidArticle = Article(
    id: 2,
    title: "Another article",
    description: "Another description.",
    articleUrl: "https://google.com",
    publishDate: DateTime(2016, 5, 27),
  );

  group("Common tests", () {

    test("PagedResult.isEmpty returns true when results has no elements", () {
      // Arrange
      final emptyResults = <Article>[];

      // Act
      final pagedResult = PagedResult(1, 1, 1, null, null, emptyResults);

      // Assert
      expect(pagedResult.isEmpty, isTrue);
    });

    test("PagedResult.isEmpty returns false when results has at least 1 element", () {
      // Arrange
      final nonEmptyResults = <Article>[ validArticle ];

      // Act
      final pagedResult = PagedResult(1, 1, 1, null, null, nonEmptyResults);

      // Assert
      expect(pagedResult.isEmpty, isFalse);
    });

    test("PagedResult.empty() returns a paged result with an empty 'results' collection", () {
      // Arrange
      // Act
      final results = PagedResult.empty().results;

      // Assert
      expect(results.isEmpty, isTrue);
    });
  });
  
  group("Tests for JSON result parsing", () {

    test("PagedResult.fromJson() returns an empty result when 'jsonString' is can't be parsed as a Map<String, Object?>", () {
      // Arrange
      const incorrectJsonStr = "[{ \"id\": 1, \"name\": \"Juan\" }]";

      // Act
      final pagedResult = PagedResult.fromJson(incorrectJsonStr, mapper: Article.fromMap);

      // Assert
      expect(pagedResult.isEmpty, isTrue);
    });

    test("PagedResult.fromJson() returns a correct PagedResult for the jsonString", () {
      // Arrange
      const correctJson = '{"resultadosPorPagina":1,"paginaActual":1,"paginasTotales":1,"urlPaginaSiguiente":null,"urlPaginaAnterior":null,"resultados":[{"id":1,"titulo":"An Article","url":"https://google.com","descripcion":"A description.","fechaPublicacion":"2016-05-26T00:00:00.000"}]}';
      final articleResults = <Article>[ validArticle ];

      final expected = PagedResult(1, 1, 1, null, null, articleResults);

      // Act
      final parsedResult = PagedResult.fromJson(
        correctJson, 
        mapper: (Map<String, Object?> map) {
          return Article.fromMap(
            map, 
            options: const MapOptions( useCamelCasePropNames: true )
          );
        }
      );

      // Assert
      expect(parsedResult, expected);
    });
  });

  group("Overriden Object methods", () {
    test("Comparing two same-identity PagedResult instances with the == operator returns true", () {
      // Arrange
      final articleResults = <Article>[ validArticle ];
      final a = PagedResult(1, 1, 1, null, null, articleResults);
      final b = a;

      // Act
      final bool comparisonResult = a == b;

      // Assert
      expect(comparisonResult, isTrue);
    });

    test("Comparing two different-identity, equal-value PagedResult instances with the == operator returns true", () {
      // Arrange
      final articleResults = <Article>[ validArticle ];
      final a = PagedResult(1, 1, 1, null, null, articleResults);
      final b = PagedResult(1, 1, 1, null, null, articleResults);

      // Act
      final bool comparisonResult = a == b;

      // Assert
      expect(comparisonResult, isTrue);
    });

    test("Comparing two PagedResults with different result collections returns false", () {
      // Arrange
      final resultsForA = <Article>[ validArticle ];
      final resultsForB = <Article>[ anotherValidArticle ];

      final a = PagedResult(1, 1, 1, null, null, resultsForA);
      final b = PagedResult(1, 1, 1, null, null, resultsForB);

      // Act
      final bool comparisonResult = a == b;

      // Assert
      expect(comparisonResult, isFalse);
    });

    test("Paged result.toString() porduces a non-empty, non-blankspace, String", () {
      // Arrange
      final pagedResult = PagedResult.empty();

      // Act
      final stringRepresentation = pagedResult.toString();

      // Assert      
      expect(stringRepresentation.trim().isNotEmpty, isTrue);
    });
  });
}