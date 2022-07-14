
extension StringExtensions on String {

  String toCamelCase() {

    final substrings = replaceAll(" ", "_").split("_");

    final capitalizedSubstrs = substrings.map((String substr) {
      // No capitalizar el primer substring.
      if (substr == substrings.first) {
        return substr;
      } else {
        return substr.substring(0, 1).toUpperCase() + substr.substring(1);
      }
    });

    return capitalizedSubstrs.join();
  }
}