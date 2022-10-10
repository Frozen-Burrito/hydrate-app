import 'package:hydrate_app/src/utils/string_utils.dart';

enum EntityMappingType {
  noMapping, 
  asMap,
  idOnly,
  notIncluded,
}

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

  /// Determina la forma en que las entidades anidadas serán mapeadas.
  final EntityMappingType subEntityMappingType;

  /// Si es __true__, todos los valores booleanos en las entradas del [Map] serán
  /// representados con enteros (0 es falso, cualquier otro número es verdadero). 
  /// Si es __false__, el [Map] usa los [bool] de Dart. 
  final bool useIntBooleanValues;

  const MapOptions({
    this.useCamelCasePropNames = false, 
    this.subEntityMappingType = EntityMappingType.noMapping, 
    this.useIntBooleanValues = false
  });

  /// Aplica las opciones de formato de [options] a la colección de [baseAttributes].
  /// 
  /// Permite adaptar los atributos de una entidad a diferentes formatos, como
  /// usar camelCase o usar enteros para representar [bool].
  Map<String, String> mapAttributeNames(
    Iterable<String> baseAttributes, {
      Map<String, String> specificAttributeMappings = const {},
  }) {
    // Aplicar las opciones de formato de [options] a los atributos de la entidad.
    final mappedNames = Map<String, String>.unmodifiable(
      baseAttributes
      .toList()
      .asMap()
      .map((i, value) => _applyMapOptions(value, specificAttributeMappings))
    );

    return mappedNames;
  }

  /// Aplica todas las [options] especificadas al [attribute].
  MapEntry<String, String> _applyMapOptions(
    String attribute, 
    Map<String, String> specificAttributeMappings,
  ) {

    String transformedAttribute = attribute;
    final bool shouldApplyAutoMapping = !(specificAttributeMappings.containsKey(attribute));

    if (shouldApplyAutoMapping) {
      // if (includeCompleteSubEntities) {
      //   transformedAttribute = transformedAttribute.replaceFirst("id_", "");
      // }
      switch (subEntityMappingType) { 
        case EntityMappingType.noMapping:
        case EntityMappingType.asMap:
          transformedAttribute = transformedAttribute.replaceFirst("id_", "");
          break;
        case EntityMappingType.idOnly:
          if (!transformedAttribute.startsWith("id_")) {
            transformedAttribute = "id_" + transformedAttribute;
          }
          break;
        case EntityMappingType.notIncluded:
          // TODO: Handle this case.
          break;
      }

      if (useCamelCasePropNames) {
        transformedAttribute = transformedAttribute.toCamelCase();
      }

    } else {
      transformedAttribute = specificAttributeMappings[attribute]!;
    }

    return MapEntry(attribute, transformedAttribute);
  }
}