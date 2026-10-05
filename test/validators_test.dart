import 'package:flutter_test/flutter_test.dart';
import 'package:voya/core/utils/username_rules.dart';
import 'package:voya/core/utils/validators.dart';

void main() {
  group('Validators', () {
    test('email', () {
      expect(Validators.email('a@b.co'), isNull);
      expect(Validators.email('  a@b.co  '), isNull);
      expect(Validators.email(''), isNotNull);
      expect(Validators.email('abc'), isNotNull);
      expect(Validators.email('a@b'), isNotNull);
    });

    test('password needs at least 8 characters', () {
      expect(Validators.password('12345678'), isNull);
      expect(Validators.password('1234567'), isNotNull);
      expect(Validators.password(''), isNotNull);
    });

    test('confirmPassword must match', () {
      expect(Validators.confirmPassword('secret123', 'secret123'), isNull);
      expect(Validators.confirmPassword('secret124', 'secret123'), isNotNull);
    });
  });

  group('UsernameRules', () {
    test('accepts valid usernames', () {
      expect(UsernameRules.validate('tracey_k'), isNull);
      expect(UsernameRules.validate('abc'), isNull);
      expect(UsernameRules.validate('a' * 20), isNull);
    });

    test('rejects bad usernames', () {
      expect(UsernameRules.validate(''), isNotNull);
      expect(UsernameRules.validate('ab'), isNotNull);
      expect(UsernameRules.validate('a' * 21), isNotNull);
      expect(UsernameRules.validate('Tracey'), isNotNull);
      expect(UsernameRules.validate('tra cey'), isNotNull);
      expect(UsernameRules.validate('tracey!'), isNotNull);
    });

    test('rejects reserved names', () {
      expect(UsernameRules.validate('admin'), isNotNull);
      expect(UsernameRules.validate('voya'), isNotNull);
    });
  });
}
