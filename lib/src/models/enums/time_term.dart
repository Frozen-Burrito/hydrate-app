/// Representa un plazo temporal. Puede ser usado para describir la 
/// frecuencia de un evento.
enum TimeTerm {
  daily,
  weekly,
  monthly,
}

extension TimeTermExtension on TimeTerm {

  int get inDays {
    switch(this) {
      case TimeTerm.daily: 
        return 1;
      case TimeTerm.weekly: 
        return 7;
      case TimeTerm.monthly: 
        return 30;
    }
  } 
}