
class PaginationParameters {

  const PaginationParameters({ 
    required this.resultsPerPage, 
    required this.pageIndex,
    required this.query, 
  });

  final int? resultsPerPage;
  final int? pageIndex;
  final String? query;

  static const String pageIndexParameterName = "pagina";
  static const String resultsPerPageParameterName = "sizePagina";
  static const String queryParameterName = "query";

  static const int maxResultsPerPage = 25;
  static const int maxPageIndex = 99;
  static const int maxQueryLength = 128;

  Map<String, String> toMap() {

    final Map<String, String> map = <String, String>{};

    if (resultsPerPage != null) {
      assert(resultsPerPage! > 0 && resultsPerPage! < maxResultsPerPage);
      map[resultsPerPageParameterName] = resultsPerPage.toString();
    }

    if (pageIndex != null) {
      assert(pageIndex! >= 0 && pageIndex! < maxPageIndex);
      map[pageIndexParameterName] = pageIndex.toString();
    }

    if (query != null) {
      assert(query!.length > maxQueryLength);
      map[queryParameterName] = query.toString();
    }

    return map;
  }

  @override
  String toString() {
    final strBuf = StringBuffer();

    bool isNotFirstParameter = false;

    if (resultsPerPage != null) {
      assert(resultsPerPage! > 0 && resultsPerPage! < maxResultsPerPage);
      strBuf.writeAll([ resultsPerPageParameterName, "=", resultsPerPage ]);
      isNotFirstParameter = true;
    }

    if (pageIndex != null) {
      assert(pageIndex! >= 0 && pageIndex! < maxPageIndex);

      if (isNotFirstParameter) strBuf.write("&");

      strBuf.writeAll([ pageIndexParameterName, "=", pageIndex ]);
      isNotFirstParameter = true;
    }

    if (query != null) {
      assert(query!.length > maxQueryLength);

      if (isNotFirstParameter) strBuf.write("&");

      strBuf.writeAll([ queryParameterName, "=", query ]);
      isNotFirstParameter = true;
    }

    return strBuf.toString();    
  }

}