import 'dart:math';

class FirestoreIdGenerator {
  static const String _charset =
      'abcdefghijklmnopqrstuvwxyz'
      'ABCDEFGHIJKLMNOPQRSTUVWXYZ'
      '0123456789';

  static final Random _random = Random();
  static String generate() {
    return String.fromCharCodes(
      Iterable.generate(
        20,
        (_) => _charset.codeUnitAt(_random.nextInt(_charset.length)),
      ),
    );
  }
}
