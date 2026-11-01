import 'package:flutter_test/flutter_test.dart';
// Replace `glowai` with the `name:` in your pubspec.yaml if it differs.
import 'package:glowai/core/utils/validators.dart';

void main() {
  group('Validators.fullName', () {
    test('rejects empty and whitespace', () {
      expect(Validators.fullName(null), isNotNull);
      expect(Validators.fullName('   '), isNotNull);
    });
    test('accepts a name', () {
      expect(Validators.fullName('Layla Haddad'), isNull);
    });
  });

  group('Validators.email', () {
    test('rejects empty and malformed emails', () {
      expect(Validators.email(''), isNotNull);
      expect(Validators.email('layla'), isNotNull);
      expect(Validators.email('layla@'), isNotNull);
      expect(Validators.email('layla@example'), isNotNull);
      expect(Validators.email('layla @example.com'), isNotNull);
    });
    test('accepts valid emails (with surrounding spaces)', () {
      expect(Validators.email('layla@example.com'), isNull);
      expect(Validators.email('  layla.h+glow@mail.example.co  '), isNull);
    });
  });

  group('Validators.password', () {
    test('rejects empty and short passwords', () {
      expect(Validators.password(''), isNotNull);
      expect(Validators.password('1234567'), isNotNull);
    });
    test('accepts 8+ characters', () {
      expect(Validators.password('12345678'), isNull);
    });
  });

  group('Validators.requiredPassword', () {
    test('rejects empty', () {
      expect(Validators.requiredPassword(null), isNotNull);
      expect(Validators.requiredPassword(''), isNotNull);
    });
    test('accepts any non-empty value, even a short one', () {
      expect(Validators.requiredPassword('a'), isNull);
    });
  });

  group('Validators.confirmPassword', () {
    test('rejects empty and mismatched values', () {
      expect(Validators.confirmPassword('', 'abcdefgh'), isNotNull);
      expect(Validators.confirmPassword('abcdefgx', 'abcdefgh'), isNotNull);
    });
    test('accepts a match', () {
      expect(Validators.confirmPassword('abcdefgh', 'abcdefgh'), isNull);
    });
  });
}
