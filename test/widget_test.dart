// Placeholder: el test original venía de la plantilla de `flutter
// create` (referenciaba `MyApp`, una clase que nunca existió en este
// proyecto — la app se llama `RutinaFitApp`) y probaba un contador que
// RutinaFit no tiene.
//
// Levantar `RutinaFitApp` de verdad en un test requiere los mismos
// providers que arma `main.dart` (incluida la base SQLite), y eso
// todavía no tiene fakes/mocks preparados para tests — así que por
// ahora este archivo solo evita el error de compilación y deja el
// placeholder documentado en vez de fingir una cobertura que no existe.
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('el proyecto compila', () {
    expect(1 + 1, 2);
  });
}
