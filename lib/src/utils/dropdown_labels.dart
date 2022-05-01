import 'package:flutter/material.dart';
import 'package:hydrate_app/src/models/models.dart';

class DropdownLabels {

  static final activityLabels = <IconLabel> [
    IconLabel('Caminar', Icons.directions_walk),
    IconLabel('Correr', Icons.directions_walk),
    IconLabel('Andar en bicicleta', Icons.directions_bike),
    IconLabel('Nadar', Icons.pool),
    IconLabel('Fútbol', Icons.sports_soccer),
    IconLabel('Básquetbol', Icons.sports_basketball),
    IconLabel('Volleybol', Icons.sports_volleyball),
    IconLabel('Danza', Icons.emoji_people),
    IconLabel('Yoga', Icons.self_improvement),
  ];

  static get sexDropdownItems => _sexDropdownItems;
  static get occupationDropdownItems => _occupationDropdownItems;
  static get conditionDropdownItems => _conditionDropdownItems;

  static get occupationLabels => <String>[
    'Prefiero no especificar',
    'Estudiante',
    'Oficinista',
    'Trabajador Físico',
    'Padre o Madre',
    'Atleta',
    'Otro'
  ];

  static final _sexDropdownItems = UserSex.values
    .map((e) {

      const labels = <String>['Otro','Mujer','Hombre'];

      return DropdownMenuItem(
        value: e.index,
        child: Text(labels[e.index]),
      );
    }).toList();
    
  static List<DropdownMenuItem<int>> getCountryDropdownItems(List<Country> countries) {

    final labels = <String, String>{
      'MX': 'México',
      'EU': 'E.U.',
      'OT': 'Otro'
    };

    return countries.map((country) {
      return DropdownMenuItem(
        value: country.id,
        child: Text(labels[country.code] ?? 'No especificado', overflow: TextOverflow.ellipsis,),
      );
    }).toList();
  }

  static List<DropdownMenuItem<int>> activityTypes(List<ActivityType> activityTypes) {

    return activityTypes.map((activityType) {
      return DropdownMenuItem(
        value: activityType.activityTypeValue.index,
        child: Row(
          children: [
            
            Icon(activityLabels[activityType.activityTypeValue.index].icon),

            const SizedBox( width: 4.0,),

            Text(
              activityLabels[activityType.activityTypeValue.index].label, 
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      );
    }).toList();
  }
   
  static final _occupationDropdownItems = Occupation.values
    .map((e) {

      const labels = <String>[
        'Prefiero no especificar',
        'Estudiante',
        'Oficinista',
        'Trabajador Físico',
        'Padre o Madre',
        'Atleta',
        'Otro'
      ];

      return DropdownMenuItem(
        value: e.index,
        child: Text(labels[e.index]),
      );
    }).toList();

  static final _conditionDropdownItems = MedicalCondition.values
    .map((e) {

      const labels = <String>['Prefiero no especificar', 'Ninguna','Insuficiencia Renal','Síndrome Nefrótico','Otro'];

      return DropdownMenuItem(
        value: e.index,
        child: Text(labels[e.index]),
      );
    }).toList();
}

class IconLabel {

  final String label;
  final IconData icon;

  IconLabel(this.label, this.icon);
}
