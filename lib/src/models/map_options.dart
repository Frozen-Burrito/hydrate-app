import 'package:hydrate_app/src/utils/string_utils.dart';

/// Contiene opciones para especificar la forma en que una clase debería 
/// convertirse a un [Map] y viceversa, así como el formato de los nombres de 
/// llave.
/// 
/// Principalmente usado para manejar las diferencias en formato entre la base
/// de datos local (separado con guiones, usando 0 y 1 para representar bools)
/// y el JSON usado por la API web (con camelCase).
class MapOptions {

  /// Es __true__ si las llaves del [Map] deberían usar formato camelCase.
  final bool useCamelCasePropNames;

  /// Es __true__ si el [Map] debería incluir los mapas de entidades compuestas.
  /// Si es __false__, el [Map] debe incluir solamente el ID de la sub-entidad.
  final bool includeCompleteSubEntities;

  /// Si es __true__, todos los valores booleanos en las entradas del [Map] serán
  /// representados con enteros (0 es falso, cualquier otro número es verdadero). 
  /// Si es __false__, el [Map] usa los [bool] de Dart. 
  final bool useIntBooleanValues;

  const MapOptions({
    this.useCamelCasePropNames = false, 
    this.includeCompleteSubEntities = true, 
    this.useIntBooleanValues = false
  });

  /// Aplica las opciones de formato de [options] a la colección de [baseAttributes].
  /// 
  /// Permite adaptar los atributos de una entidad a diferentes formatos, como
  /// usar camelCase o usar enteros para representar [bool].
  static Map<String, String> mapAttributeNames(
    Iterable<String> baseAttributes,
    MapOptions options
  ) {
    // Aplicar las opciones de formato de [options] a los atributos de la entidad.
    final mappedNames = Map<String, String>.unmodifiable(
      baseAttributes
      .toList()
      .asMap()
      .map((i, value) => _applyMapOptions(value, options))
    );

    return mappedNames;
  }

  /// Aplica todas las [options] especificadas al [attribute].
  static MapEntry<String, String> _applyMapOptions(
    String attribute, 
    MapOptions options
  ) {

    String transformedAttribute = attribute;

    if (options.includeCompleteSubEntities && transformedAttribute != "id_perfil") {
      transformedAttribute = transformedAttribute.replaceFirst("id_", "");
    }

    if (options.useCamelCasePropNames) {
      transformedAttribute = transformedAttribute.toCamelCase();
    }

    return MapEntry(attribute, transformedAttribute);
  }
}