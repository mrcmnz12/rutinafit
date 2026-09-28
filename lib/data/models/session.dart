import '../../core/db/db_constants.dart';

/// Una sesión registrada en una fecha: puede ser una rutina de gym
/// (`kind == SessionKind.routine`, con `dayKey` apuntando a la rutina) o
/// una actividad libre (`kind == SessionKind.activity`, con `activityId`
/// apuntando al catálogo de actividades). Puede haber más de una sesión
/// por fecha — por ejemplo gym en la mañana y fútbol en la tarde.
class TrainingSession {
  final int? id;
  final String date; // ISO yyyy-MM-dd
  final String kind; // SessionKind.routine | SessionKind.activity
  final String? dayKey;
  final String? activityId;

  const TrainingSession({
    this.id,
    required this.date,
    this.kind = SessionKind.routine,
    this.dayKey,
    this.activityId,
  });

  bool get isRoutine => kind == SessionKind.routine;
  bool get isActivity => kind == SessionKind.activity;

  factory TrainingSession.fromMap(Map<String, Object?> map) {
    return TrainingSession(
      id: map['id'] as int?,
      date: map['date'] as String,
      kind: map['kind'] as String? ?? SessionKind.routine,
      dayKey: map['day_key'] as String?,
      activityId: map['activity_id'] as String?,
    );
  }

  Map<String, Object?> toMap() {
    final map = <String, Object?>{
      'date': date,
      'kind': kind,
      'day_key': dayKey,
      'activity_id': activityId,
    };
    if (id != null) map['id'] = id;
    return map;
  }
}
