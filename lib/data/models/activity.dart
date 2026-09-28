/// Una actividad del catálogo (fútbol, zumba, spinning, etc.) que se
/// puede fijar a uno o más días de la semana. A diferencia de las
/// rutinas de gym, no tiene ejercicios ni sets: solo nombre, color y una
/// duración estimada.
class Activity {
  final String id;
  final String name;
  final String color; // hex, ej. "#2e9e77"
  final int durationMinutes;
  final int sortOrder;

  const Activity({
    required this.id,
    required this.name,
    required this.color,
    required this.durationMinutes,
    this.sortOrder = 0,
  });

  Activity copyWith({String? name, String? color, int? durationMinutes, int? sortOrder}) {
    return Activity(
      id: id,
      name: name ?? this.name,
      color: color ?? this.color,
      durationMinutes: durationMinutes ?? this.durationMinutes,
      sortOrder: sortOrder ?? this.sortOrder,
    );
  }

  factory Activity.fromMap(Map<String, Object?> map) {
    return Activity(
      id: map['id'] as String,
      name: map['name'] as String,
      color: map['color'] as String,
      durationMinutes: map['duration_minutes'] as int,
      sortOrder: map['sort_order'] as int? ?? 0,
    );
  }

  Map<String, Object?> toMap() {
    return {
      'id': id,
      'name': name,
      'color': color,
      'duration_minutes': durationMinutes,
      'sort_order': sortOrder,
    };
  }
}

/// Paleta de colores para elegir al crear/editar una actividad — mismos
/// tonos usados en el resto de la app para que combinen.
const List<String> kActivityColorOptions = [
  '#2e9e77', '#d9536a', '#3e7fc1', '#d98a2b', '#8a63d9', '#34c274', '#c9497a', '#6f7580',
];
