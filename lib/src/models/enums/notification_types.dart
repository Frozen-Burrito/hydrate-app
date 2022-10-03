/// Describe las notificaciones enviadas por la app.
enum NotificationTypes {
  /// Las notificaciones están desactivadas. La app no enviará ninguna notificación.
  disabled,

  /// La app enviará notificaciones sobre las metas del usuario. 
  goals,

  /// La app enviará notificaciones con el nivel de batería de la botella.
  battery,

  /// La app enviará notificaciones con recordatorios de actividad y rutinas.
  activity,

  /// La app enviará notificaciones de metas y de nivel de batería.
  all
}