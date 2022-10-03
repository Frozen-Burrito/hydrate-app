/// Describe las notificaciones enviadas por la app.
enum NotificationSource {
  /// Las notificaciones están desactivadas. La app no enviará ninguna notificación.
  disabled,

  /// La app enviará notificaciones sobre las metas del usuario. 
  goals,

  /// La app enviará notificaciones con el nivel de batería de la botella.
  battery,

  /// La app enviará notificaciones con recordatorios de actividad y rutinas.
  activity,

  /// La app recibirá notificaciones con recordatorios de descanso.
  rest,

  /// La app enviará notificaciones de metas y de nivel de batería.
  all
}

extension NotificationSourceExtension on NotificationSource {

  static const Map<NotificationSource, int> notificationSourceBits = {
    NotificationSource.goals: 0x01,
    NotificationSource.battery: 0x02,
    NotificationSource.activity: 0x04,
    NotificationSource.rest: 0x08,
    NotificationSource.all: 0xFF,
  };

  int get bits => notificationSourceBits[this]!;

  static Set<NotificationSource> notificationSourceFromBits(int bits) {

    final Set<NotificationSource> notificationSources = {};

    if (bits > 0) {
      notificationSourceBits.forEach((notificationSource, notificationSourceBitmask) {
        if (((notificationSourceBitmask & bits) == notificationSourceBitmask)) {
          notificationSources.add(notificationSource);
        }
      });
    } else {
      notificationSources.add(NotificationSource.disabled);
    }

    return notificationSources;
  }
}
