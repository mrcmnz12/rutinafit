enum MeasureType { repsWeight, time }

/// Un ejercicio del catálogo. Es compartido entre rutinas: el mismo
/// ejercicio puede aparecer en más de un día (ej. press pecho en Torso A y B).
class Exercise {
  final String id;
  final String name;
  final String muscleGroup;
  final MeasureType measureType;
  final String setsLabel; // texto libre: "3", "3–4"
  final int repLow;
  final int repHigh;
  final String restLabel; // texto libre: "90 s"
  final bool isBodyweight;
  final String suffix; // ej. "/lado"
  final bool hasPainNote;
  final double? baseWeight;
  final int? baseSeconds;
  final String? image1Path;
  final String? image2Path;
  final String? videoUrl;

  const Exercise({
    required this.id,
    required this.name,
    required this.muscleGroup,
    required this.measureType,
    required this.setsLabel,
    required this.repLow,
    required this.repHigh,
    required this.restLabel,
    this.isBodyweight = false,
    this.suffix = '',
    this.hasPainNote = false,
    this.baseWeight,
    this.baseSeconds,
    this.image1Path,
    this.image2Path,
    this.videoUrl,
  });

  /// Ej. "8–12 reps" o "20–40 s".
  String get repsLabel {
    final range = repHigh != repLow ? '$repLow–$repHigh' : '$repLow';
    final unit = measureType == MeasureType.time ? ' s' : ' reps';
    return '$range$unit$suffix';
  }

  Exercise copyWith({
    String? setsLabel,
    int? repLow,
    int? repHigh,
    String? restLabel,
    Object? image1Path = _unset,
    Object? image2Path = _unset,
    Object? videoUrl = _unset,
  }) {
    return Exercise(
      id: id,
      name: name,
      muscleGroup: muscleGroup,
      measureType: measureType,
      setsLabel: setsLabel ?? this.setsLabel,
      repLow: repLow ?? this.repLow,
      repHigh: repHigh ?? this.repHigh,
      restLabel: restLabel ?? this.restLabel,
      isBodyweight: isBodyweight,
      suffix: suffix,
      hasPainNote: hasPainNote,
      baseWeight: baseWeight,
      baseSeconds: baseSeconds,
      image1Path: identical(image1Path, _unset) ? this.image1Path : image1Path as String?,
      image2Path: identical(image2Path, _unset) ? this.image2Path : image2Path as String?,
      videoUrl: identical(videoUrl, _unset) ? this.videoUrl : videoUrl as String?,
    );
  }

  static const _unset = Object();

  factory Exercise.fromMap(Map<String, Object?> map) {
    return Exercise(
      id: map['id'] as String,
      name: map['name'] as String,
      muscleGroup: map['muscle_group'] as String,
      measureType: (map['measure_type'] as String) == 'time' ? MeasureType.time : MeasureType.repsWeight,
      setsLabel: map['sets_label'] as String,
      repLow: map['rep_low'] as int,
      repHigh: map['rep_high'] as int,
      restLabel: map['rest_label'] as String,
      isBodyweight: (map['is_bodyweight'] as int) == 1,
      suffix: map['suffix'] as String? ?? '',
      hasPainNote: (map['has_pain_note'] as int? ?? 0) == 1,
      baseWeight: (map['base_weight'] as num?)?.toDouble(),
      baseSeconds: map['base_seconds'] as int?,
      image1Path: map['image1_path'] as String?,
      image2Path: map['image2_path'] as String?,
      videoUrl: map['video_url'] as String?,
    );
  }

  Map<String, Object?> toMap() {
    return {
      'id': id,
      'name': name,
      'muscle_group': muscleGroup,
      'measure_type': measureType == MeasureType.time ? 'time' : 'reps_weight',
      'sets_label': setsLabel,
      'rep_low': repLow,
      'rep_high': repHigh,
      'rest_label': restLabel,
      'is_bodyweight': isBodyweight ? 1 : 0,
      'suffix': suffix,
      'has_pain_note': hasPainNote ? 1 : 0,
      'base_weight': baseWeight,
      'base_seconds': baseSeconds,
      'image1_path': image1Path,
      'image2_path': image2Path,
      'video_url': videoUrl,
    };
  }
}
