import 'package:board_game_library/util/parsing.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Parsing.parseNullableInt', () {
    test('returns null for empty or whitespace', () {
      expect(Parsing.parseNullableInt(''), isNull);
      expect(Parsing.parseNullableInt('   '), isNull);
    });

    test('parses valid integer strings', () {
      expect(Parsing.parseNullableInt('42'), 42);
      expect(Parsing.parseNullableInt('  7  '), 7);
    });

    test('returns null for invalid integer strings', () {
      expect(Parsing.parseNullableInt('abc'), isNull);
    });
  });

  group('Parsing.toInt', () {
    test('handles null and int values', () {
      expect(Parsing.toInt(null), isNull);
      expect(Parsing.toInt(5), 5);
    });

    test('converts num and string values', () {
      expect(Parsing.toInt(4.9), 4);
      expect(Parsing.toInt('12'), 12);
      expect(Parsing.toInt(' 8 '), 8);
    });

    test('returns null for unsupported or invalid values', () {
      expect(Parsing.toInt('bad'), isNull);
      expect(Parsing.toInt(Object()), isNull);
    });
  });

  group('Parsing.toBool', () {
    test('handles bool and null values', () {
      expect(Parsing.toBool(true), isTrue);
      expect(Parsing.toBool(false), isFalse);
      expect(Parsing.toBool(null), isFalse);
    });

    test('converts numeric values', () {
      expect(Parsing.toBool(1), isTrue);
      expect(Parsing.toBool(-3), isTrue);
      expect(Parsing.toBool(0), isFalse);
    });

    test('converts known string values', () {
      expect(Parsing.toBool('1'), isTrue);
      expect(Parsing.toBool('true'), isTrue);
      expect(Parsing.toBool(' YES '), isTrue);
      expect(Parsing.toBool('false'), isFalse);
      expect(Parsing.toBool('0'), isFalse);
      expect(Parsing.toBool('no'), isFalse);
    });
  });
}
