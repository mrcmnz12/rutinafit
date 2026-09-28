/// Un registro de peso corporal en una fecha. Única por fecha.
class BodyWeightEntry {
  final int? id;
  final String date;
  final double kg;

  const BodyWeightEntry({this.id, required this.date, required this.kg});

  factory BodyWeightEntry.fromMap(Map<String, Object?> map) {
    return BodyWeightEntry(
      id: map['id'] as int?,
      date: map['date'] as String,
      kg: (map['kg'] as num).toDouble(),
    );
  }

  Map<String, Object?> toMap() {
    final map = <String, Object?>{'date': date, 'kg': kg};
    if (id != null) map['id'] = id;
    return map;
  }
}
