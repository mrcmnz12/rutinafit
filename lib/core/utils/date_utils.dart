/// Todas las fechas de dominio se guardan y comparan como texto ISO
/// (yyyy-MM-dd): comparables con < > == directamente como strings, sin
/// ambigüedad de zona horaria dentro del mismo dispositivo.
String isoDate(DateTime d) {
  final y = d.year.toString().padLeft(4, '0');
  final m = d.month.toString().padLeft(2, '0');
  final day = d.day.toString().padLeft(2, '0');
  return '$y-$m-$day';
}

String todayIso() => isoDate(DateTime.now());

const List<String> _dowKeys = ['mon', 'tue', 'wed', 'thu', 'fri', 'sat', 'sun'];

String dowKeyOf(String iso) {
  final d = DateTime.parse(iso);
  return _dowKeys[d.weekday - 1]; // DateTime.weekday: 1=lunes..7=domingo
}

const List<String> _monthsEs = [
  'ene', 'feb', 'mar', 'abr', 'may', 'jun', 'jul', 'ago', 'sep', 'oct', 'nov', 'dic',
];

/// Ej. "21 sep" — sin depender de datos de localización de `intl`.
String formatShort(String iso) {
  final d = DateTime.parse(iso);
  return '${d.day} ${_monthsEs[d.month - 1]}';
}

int daysBetween(String isoA, String isoB) {
  final a = DateTime.parse(isoA);
  final b = DateTime.parse(isoB);
  return b.difference(a).inDays;
}

const List<String> _monthsEsFull = [
  'enero', 'febrero', 'marzo', 'abril', 'mayo', 'junio',
  'julio', 'agosto', 'septiembre', 'octubre', 'noviembre', 'diciembre',
];

/// Nombre completo del mes en español, con la primera letra en
/// mayúscula (ej. "Septiembre"). `month` es 1-12.
String monthNameEs(int month) {
  final n = _monthsEsFull[month - 1];
  return n[0].toUpperCase() + n.substring(1);
}
