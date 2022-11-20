import 'package:hydrate_app/src/db/sqlite_keywords.dart';
import 'package:hydrate_app/src/db/sqlite_model.dart';
import 'package:hydrate_app/src/models/map_options.dart';
import 'package:hydrate_app/src/models/user_profile.dart';
import 'package:hydrate_app/src/models/validators/range.dart';
import 'package:hydrate_app/src/utils/map_extensions.dart';

class HydrationRecord extends SQLiteModel {

  HydrationRecord({
    this.id = -1,
    this.volumeInMl = 0,
    int batteryPercentage = 0,
    this.ambientTemperature = 0.0,
    required DateTime date,
    this.profileId = -1
  }) : batteryRecord = BatteryRecord( date, batteryPercentage );

  @override
  int id;
  final int volumeInMl;
  /// Temperatura ambiente registrada, en grados celsius (-40.0°C, 75.0°C).
  final double ambientTemperature;
  int profileId;

  final BatteryRecord batteryRecord; 

  DateTime get date => batteryRecord.date;

  double get volumeInLiters => volumeInMl / 1000.0;

  static const String idAttribute = "id";
  static const String amountAttribute = "cantidad";
  static const String batteryChargeAttribute = "porcentaje_bateria";
  static const String dateAttribute = "fecha";
  static const String temperatureAttribute = "temperatura";
  static const String profileIdAttribute = "id_perfil";

  static const baseAttributes = <String>[
    idAttribute,
    amountAttribute,
    batteryChargeAttribute,
    dateAttribute,
    temperatureAttribute,
    profileIdAttribute,
  ];

  static const Map<String, String> jsonAttributes = <String, String>{
    idAttribute: "id",
    amountAttribute: "cantidadEnMl",
    batteryChargeAttribute: "porcentajeCargaBateria",
    dateAttribute: "fecha",
    temperatureAttribute: "temperaturaAproximada",
    profileIdAttribute: "idPerfilUsuario",
  };

  static const String tableName = "consumo";

  @override
  String get table => tableName;

  static const String createTableQuery = """
    CREATE TABLE ${HydrationRecord.tableName} (
      $idAttribute ${SQLiteKeywords.idType},
      $amountAttribute ${SQLiteKeywords.integerType} ${SQLiteKeywords.notNullType},
      $batteryChargeAttribute ${SQLiteKeywords.integerType} ${SQLiteKeywords.notNullType},
      $dateAttribute ${SQLiteKeywords.textType} ${SQLiteKeywords.notNullType},
      $temperatureAttribute ${SQLiteKeywords.realType} ${SQLiteKeywords.notNullType},
      $profileIdAttribute ${SQLiteKeywords.integerType} ${SQLiteKeywords.notNullType},

      ${SQLiteKeywords.fk} ($profileIdAttribute) ${SQLiteKeywords.references} ${UserProfile.tableName} (id)
          ${SQLiteKeywords.onDelete} ${SQLiteKeywords.cascadeAction}
    )
  """;

  static HydrationRecord fromMap(Map<String, Object?> map, { MapOptions options = const MapOptions(), }) {

    final int id = map.getIntegerOrDefault(attribute: idAttribute, defaultValue: -1);

    final int parsedAmountMl = map.getIntegerInRange(
      attribute: amountAttribute,
      range: const Range( min: 1, max: 5000 )
    );

    final int batteryPercentage = map.getIntegerInRange(
      attribute: batteryChargeAttribute, 
      range: const Range( min: 0, max: 100) 
    );

    final double temperature = map.getDoubleInRange(
      attribute: temperatureAttribute, 
      range: const Range( min: -40.0, max: 75.0 )
    );

    final DateTime date = map.getDateTimeOrDefault(attribute: dateAttribute, defaultValue: DateTime.now())!;

    final int profileId = map.getIntegerOrDefault(
      attribute: profileIdAttribute,
      defaultValue: -1
    );

    return HydrationRecord(
      id: id,
      volumeInMl: parsedAmountMl,
      batteryPercentage: batteryPercentage,
      ambientTemperature: temperature,
      date: date,
      profileId: profileId,
    );
  } 

  @override
  Map<String, Object?> toMap({ MapOptions options = const MapOptions(), }) {

    final Map<String, Object?> map = {};

    if (id >= 0) map[idAttribute] = id;

    map.addAll({
      amountAttribute: volumeInMl,
      batteryChargeAttribute: batteryRecord.level,
      temperatureAttribute: ambientTemperature,
      dateAttribute: batteryRecord.date.toIso8601String(),
      profileIdAttribute: profileId,
    });

    return Map.unmodifiable(map);
  }

  factory HydrationRecord.fromJson(Map<String, Object?> json) => HydrationRecord(
    id: json.getIntegerOrDefault(attribute: jsonAttributes[idAttribute]!, defaultValue: -1),
    volumeInMl: json.getIntegerOrDefault(attribute: jsonAttributes[amountAttribute]!),
    ambientTemperature: json.getDoubleOrDefault(attribute: jsonAttributes[temperatureAttribute]!),
    profileId: json.getIntegerOrDefault(attribute: jsonAttributes[profileIdAttribute]!, defaultValue: -1),
    date: json.getDateTimeOrDefault(attribute: jsonAttributes[dateAttribute]!, defaultValue: DateTime.now())!,
    batteryPercentage: json.getIntegerInRange(attribute: jsonAttributes[batteryChargeAttribute]!, range: const Range( max: 100 )),
  );

  Map<String, Object?> toJson({ List<String>? attributes }) {

    final Map<String, Object?> map = {};

    if (id >= 0) map[jsonAttributes[idAttribute]!] = id;

    map.addAll({
      jsonAttributes[amountAttribute]!: volumeInMl,
      jsonAttributes[batteryChargeAttribute]!: batteryRecord.level,
      jsonAttributes[dateAttribute]!: batteryRecord.date.toIso8601String(),
      jsonAttributes[temperatureAttribute]!: ambientTemperature,
      jsonAttributes[profileIdAttribute]!: profileId,
    });
    
    if (attributes != null && attributes.isNotEmpty) {
      map.removeWhere((attributeName, _) => !(attributes.contains(attributeName)));
    }

    assert(map.length <= jsonAttributes.length);
    assert(map.isNotEmpty);

    return Map.unmodifiable(map);
  }

  @override
  String toString() {
    final strBuf = StringBuffer("<HydrationRecord>{");

    strBuf.writeAll(["id:", id, ", "]);
    strBuf.writeAll(["amount:", volumeInMl, " ml, "]);
    strBuf.writeAll(["temperature:", ambientTemperature, " °C, "]);
    strBuf.writeAll(["remaining battery:", batteryRecord.level, "%, "]);
    strBuf.writeAll(["date:", batteryRecord.date.toIso8601String(), ", "]);
    strBuf.writeAll(["profileId:", profileId, ", "]);

    strBuf.write("}");

    return strBuf.toString();    
  }

  @override
  bool operator==(Object? other) {

    if (other is! HydrationRecord) return false;

    final areIdsEqual = id == other.id;
    final isVolumeEqual = volumeInMl == other.volumeInMl;
    final isAmbientTemperatureEqual = ambientTemperature == other.ambientTemperature;
    final isFromSameProfile = profileId == other.profileId;
    final isBatteryInfoEqual = batteryRecord ==  other.batteryRecord;

    return areIdsEqual && isVolumeEqual && isAmbientTemperatureEqual && 
           isFromSameProfile && isBatteryInfoEqual;
  }

  @override
  int get hashCode => Object.hashAll([
    id, 
    volumeInMl,
    ambientTemperature,
    profileId,
    batteryRecord,
  ]);
}

class BatteryRecord {

  const BatteryRecord( this.date, this.level );

  final DateTime date;
  final int level;

  @override
  String toString() => "BatteryLevel: { date: $date, level: $level% }";

  @override 
  bool operator==(Object? other) {
    if (other is! BatteryRecord) return false;

    return date.isAtSameMomentAs(other.date) && level == other.level;
  }

  @override
  int get hashCode => Object.hashAll([ level, date ]);
}
