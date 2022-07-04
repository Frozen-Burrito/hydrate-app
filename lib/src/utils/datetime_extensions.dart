import 'dart:math';

import 'package:flutter/material.dart';

extension DateTimeExtensions on DateTime {

  /// Retorna un [DateTime] que solo tiene asignados el año, mes
  /// y día de esta fecha. Por esto, la hora, minuto y demás partes 
  /// de la fecha producida son igual a 0.
  DateTime get onlyDate {
    return DateTime(year, month, day);
  }

  /// Retorna la hora y minuto de esta fecha. 
  TimeOfDay get onlyTime {
    return TimeOfDay(hour: hour, minute: minute);
  }
}

extension DayOfWeekExtensions on int {

  /// Los valores binarios asociados con cada día de la semana.
  /// 
  /// El primer valor es asociado con [DateTime.monday] y el penúltimo 
  /// con [DateTime.sunday]. El último indica todos los días.
  static const dayFlagValues = <int>[
    0x01, 0x02, 0x04, 0x08, 0x10, 0x20, 0x40, 0x80
  ];

  /// Asigna un valor que tiene un solo bit por día de la semana.
  /// Por ejemplo, 
  /// ```
  /// flagValue(DateTime.monday) == 1 // true (0000 0001)
  /// flagValue(DateTime.thursday) == 8 // true (0000 1000)
  /// flagValue(DateTime.sunday) == 64 // true (0100 0000)
  /// ```
  int get flagValue {
    return pow(2, this - 1).toInt();
  }

  /// Asigna los bits de un valor en el que cada bit identifica un 
  /// día de la semana encontrado en [daysOfWeek].
  /// 
  /// Los valores int de [daysOfWeek] se basan en las constantes dadas por
  /// [DateTime], como [DateTime.monday]. 
  int setDayBits(Iterable<int> daysOfWeek) {
    
    int flagSet = this;

    daysOfWeek.forEach((day) { 
      flagSet |= dayFlagValues[day];
    });

    return flagSet;
  }

  /// Convierte los bits del valor de este número entero en días de la semana,
  /// con los valores dados por las constantes de [DateTime], como 
  /// [DateTime.tuesday].
  List<int> get toWeekdays {

    List<int> weekdays = <int>[];
    
    for (var i = 1; i <= 7; i++) {
      if ((this & (1 << i)) != 0) {
        weekdays.add(i);
      }
    } 

    return weekdays;
  }
}
