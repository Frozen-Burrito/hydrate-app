import 'package:flutter/material.dart';
import 'package:hydrate_app/src/models/models.dart';

class DropdownLabels {

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
}