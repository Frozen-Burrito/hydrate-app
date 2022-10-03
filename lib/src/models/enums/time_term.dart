/// Representa un plazo temporal. Puede ser usado para describir la 
/// frecuencia de un evento.
enum TimeTerm {
  daily,
  weekly,
  monthly,
}

extension TimeTermExtension on TimeTerm {

  static const avgDaysPerMonth = 30;

  int get inDays {
    switch(this) {
      case TimeTerm.daily: 
        return 1;
      case TimeTerm.weekly: 
        return DateTime.daysPerWeek;
      case TimeTerm.monthly: 
        return avgDaysPerMonth;
    }
  } 
}