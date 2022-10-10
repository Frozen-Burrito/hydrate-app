import 'dart:convert';
import 'package:flutter/foundation.dart';

import 'package:hydrate_app/src/models/map_options.dart';

class PagedResult<T> {

  const PagedResult(
    this.resultsPerPage, 
    this.currentPage, 
    this.totalPages, 
    this.uriForNextPage, 
    this.uriForPreviousPage, 
    this.results
  );

  PagedResult.empty() : this(
    0, 
    0, 
    0, 
    null, 
    null, 
    <T>[]
  );

  factory PagedResult.fromJson(String jsonString, {
    required T Function(Map<String, Object?>) mapper,
    MapOptions mapOptions = const MapOptions(), 
  }) {
    
    final map = json.decode(jsonString);

    if (map is! Map<String, Object?>) return PagedResult.empty();

    final parsedResultsPerPage = int.tryParse(map[_jsonAttributeNames["resultsPerPage"]].toString()) ?? 0;
    final parsedCurrentPage = int.tryParse(map[_jsonAttributeNames["currentPage"]].toString()) ?? 0; 
    final parsedTotalPages = int.tryParse(map[_jsonAttributeNames["totalPages"]].toString()) ?? 0;

    final uriForNextPage = map[_jsonAttributeNames["uriForNextPage"]] ?? ':: NOT VALID URI ::';
    final uriForPrevPage = map[_jsonAttributeNames["uriForPreviousPage"]] ?? ':: NOT VALID URI ::';

    final parsedUriForNextPage = Uri.tryParse(uriForNextPage.toString()); 
    final parsedUriForPreviousPage = Uri.tryParse(uriForPrevPage.toString());

    final List<T> parsedResults = <T>[];
    final Object? resultsFieldValue = map[_jsonAttributeNames["results"]];

    if (resultsFieldValue is List) {

      for (final result in resultsFieldValue) {

        if (result is! Map<String, dynamic>) {
          // Si el resultado no es un Mapa y no puede ser mapeado con mapper(),
          // advertir e ignorar el resultado.
          _warnAboutResult(result);
          continue;
        }

        try {
          // Intentar transformar el resultado en una entidad usando mapper(). 
          final mappedResult = mapper(result);
          // Si no hubo un error mapeando el resultado, agregarlo a la lista de 
          // resultados.
          parsedResults.add(mappedResult);

        } on Exception {
          _warnAboutResult(result);
        }
      }
    }

    return PagedResult(
      parsedResultsPerPage, 
      parsedCurrentPage, 
      parsedTotalPages, 
      parsedUriForNextPage, 
      parsedUriForPreviousPage, 
      parsedResults
    );
  }

  final int resultsPerPage;
  final int currentPage;
  final int totalPages;

  final Uri? uriForNextPage;
  final Uri? uriForPreviousPage;

  final List<T> results;

  static const Map<String, String> _jsonAttributeNames = {
    "resultsPerPage": "resultadosPorPagina", 
    "currentPage": "paginaActual", 
    "totalPages": "paginasTotales", 
    "uriForNextPage": "urlPaginaSiguiente", 
    "uriForPreviousPage": "urlPaginaAnterior", 
    "results": "resultados"
  };

  bool get isEmpty => results.isEmpty;

  bool get isNotEmpty => results.isNotEmpty;

  static void _warnAboutResult(Object? result) {
    print("Warning: a results item could not be parsed and was excluded from PagedResult. Item: $result");
  }

  @override
  String toString() {

    final strBuf = StringBuffer("PagedResult<");

    strBuf.writeAll([ T.runtimeType, ">: {"]);

    strBuf.writeAll([ "currentPage: ", currentPage, "/", totalPages, ", " ]);
    strBuf.writeAll([ "resultsPerPage: ", resultsPerPage, ", " ]);
    strBuf.writeAll([ "previousPage: ", uriForPreviousPage, ", " ]);
    strBuf.writeAll([ "nextPage: ", uriForNextPage, ", " ]);
    strBuf.writeAll([ "result count: ", results.length, ", " ]);

    return strBuf.toString();
  }

  @override
  bool operator==(covariant PagedResult other) {

    final doUrisCorrespond = uriForPreviousPage == other.uriForPreviousPage 
                          && uriForNextPage == other.uriForNextPage;

    final areResultCountsEqual = resultsPerPage == other.resultsPerPage;
    final isCurrentPageEqual = currentPage == other.currentPage && doUrisCorrespond;
    final areTotalPageCountsEqual = totalPages == other.totalPages;

    final areResultsEqual = listEquals(results, other.results);

    return areResultCountsEqual && isCurrentPageEqual 
        && areTotalPageCountsEqual && areResultsEqual;
  }

  @override
  int get hashCode => Object.hashAll([ 
    resultsPerPage,
    currentPage,
    totalPages,
    uriForNextPage,
    uriForPreviousPage,
    results,
  ]);
}