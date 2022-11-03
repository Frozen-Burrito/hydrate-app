import "package:flutter_test/flutter_test.dart";
import 'package:hydrate_app/src/models/map_options.dart';

void main() {
  group("Test attribute name mapping", () {
    test("mapAttributeNames() by default returns a map with the same length as baseAttributes", () {
      // Arrange
      const List<String> baseAttributes = [ "id", "nombre", "fecha_de_nacimiento", "id_perfil", ];
      final int expectedAttributeCount = baseAttributes.length;
      const mapOptions = MapOptions();

      // Act 
      final mappedAttributeNames = mapOptions.mapAttributeNames(baseAttributes);
      final int mappedAttributeCount = mappedAttributeNames.length;

      // Assert
      expect(mappedAttributeCount, expectedAttributeCount);
    });

    test("mapAttributeNames() converts to camelCase correctly when useCamelCasePropNames: true", () {
      // Arrange
      const List<String> snakeCaseAttributes = [ "id", "nombre", "fecha_de_nacimiento", "id_perfil", ];
      const List<String> camelCaseAttributes = [ "id", "nombre", "fechaDeNacimiento", "idPerfil", ];
      const mapOptions = MapOptions( useCamelCasePropNames: true );

      // Act 
      final mappedAttributeNames = mapOptions.mapAttributeNames(snakeCaseAttributes);

      // Assert
      expect(mappedAttributeNames.values, containsAllInOrder(camelCaseAttributes));
    });

    test("mapAttributeNames() uses a specific attribute name when provided with one, even if there are options that could modify it", () {
      // Arrange
      const String specificAttributeBase = "fecha_de_nacimiento";
      const String expectedSpecificAttribute = "unCampoEspecifico";
      const List<String> baseAttributes = [ "id", "nombre", specificAttributeBase, "id_perfil", ];
      const mapOptions = MapOptions( 
        useCamelCasePropNames: true,
        subEntityMappingType: EntityMappingType.idOnly
      );

      const specificAttributeMappings = <String, String>{
        specificAttributeBase: expectedSpecificAttribute
      };

      // Act 
      final mappedAttributeNames = mapOptions.mapAttributeNames(
        baseAttributes, 
        specificAttributeMappings: specificAttributeMappings
      );

      // Assert
      expect(mappedAttributeNames[specificAttributeBase], expectedSpecificAttribute);
    });
    
    test("mapAttributeNames() maintains the original form of the attributes when subEntityMappingType = EntityMappingType.noMapping", () {
      // Arrange
      const List<String> baseAttributes = [ "id", "nombre", "fecha_de_nacimiento", "id_perfil", ];
      final List<String> expectedAttributes = List.of(baseAttributes);
      const mapOptions = MapOptions( subEntityMappingType: EntityMappingType.noMapping );

      // Act 
      final mappedAttributeNames = mapOptions.mapAttributeNames(baseAttributes);

      // Assert
      expect(mappedAttributeNames.values, containsAllInOrder(expectedAttributes));
    });

    test("mapAttributeNames() replaces 'id' fields with the name of the sub-entity when subEntityMappingType = EntityMappingType.asMap", () {
      // Arrange
      const String baseSubEntityAttribute = "id_perfil";
      const String expectedSubEntityAttribute = "perfil";
      const List<String> baseAttributes = [ "id", "nombre", "fecha_de_nacimiento", baseSubEntityAttribute, ];
      const mapOptions = MapOptions( subEntityMappingType: EntityMappingType.asMap );

      // Act 
      final mappedAttributeNames = mapOptions.mapAttributeNames(baseAttributes);

      // Assert
      expect(mappedAttributeNames[baseSubEntityAttribute], expectedSubEntityAttribute);
    });

    
    test("mapAttributeNames() does not alter 'id' fields when subEntityMappingType = EntityMappingType.idOnly", () {
      // Arrange
      const String baseSubEntityAttribute = "id_perfil";
      const String expectedSubEntityAttribute = baseSubEntityAttribute;
      const List<String> baseAttributes = [ "id", "nombre", "fecha_de_nacimiento", baseSubEntityAttribute, ];
      const mapOptions = MapOptions( subEntityMappingType: EntityMappingType.idOnly );

      // Act 
      final mappedAttributeNames = mapOptions.mapAttributeNames(baseAttributes);

      // Assert
      expect(mappedAttributeNames[baseSubEntityAttribute], expectedSubEntityAttribute);
    });
  });

  group("Common object methods", () {
    test("MapOptions.toString() has a specific implementation", () {
      // Arrange
      const defaultStrValue = "Instance of 'MapOptions'";
      const mapOptions = MapOptions();

      // Act
      final mapOptionsAsString = mapOptions.toString();

      // Assert
      expect(mapOptionsAsString, isNot(defaultStrValue));
    });
  });
}