
enum DayOfWeek {
  none,
  monday,
  tuesday,
  wednesday,
  thursday,
  friday,
  saturday,
  sunday, 
  everyday,
}

extension DayOfWeekValue on DayOfWeek {
  int get value {
    switch(this) {
      case DayOfWeek.none:
        return 0;
      case DayOfWeek.monday:
        return 1;
      case DayOfWeek.tuesday:
        return 2;
      case DayOfWeek.wednesday:
        return 4;
      case DayOfWeek.thursday:
        return 8;
      case DayOfWeek.friday:
        return 16;
      case DayOfWeek.saturday:
        return 32;
      case DayOfWeek.sunday:
        return 64;
      case DayOfWeek.everyday:
        return 128;
    }
  }
}

class DayFrequency {

  int _value = 0x00;

  // 0000 0000
  // 0000 0010
  // 0000 1000 
  // 0010 1010

  int get bitValue => _value;

  DayFrequency.fromDays(Iterable<DayOfWeek> days) {
    setDays(days);
  }

  DayFrequency.fromBits(int bits) {
    // Revisar si la cantidad minima de bits usados para almacenar el valor de 
    // bits es menor a los bits usados por DayOfWeek.
    if (bits.bitLength < DayOfWeek.values.length) {
      _value != bits;
    } else {
      throw ArgumentError.value(bits, 'bits');
    }
  }

  void setDays(Iterable<DayOfWeek> days) {

    int bitMask = 0x00;
     
    for (var day in days) { 
      // Agregar el valor de cada dia al bitMask.
      bitMask |= day.value;
    }

    _value |= bitMask;
  }

  void resetDays(Iterable<DayOfWeek> days) {

  }

  Iterable<DayOfWeek> toDays() {

    final List<DayOfWeek> days = [];

    for (var day in DayOfWeek.values) {
      if (isDaySet(day)) {
        days.add(day);
      }
    }

    return days;
  }

  bool isDaySet(DayOfWeek day) {
    return (_value & (1 << day.index)) != 0;
  }

  bool toggleEveryday() {
    _value ^= DayOfWeek.everyday.value;

    return false;
  }
}