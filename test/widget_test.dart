import 'package:flutter_test/flutter_test.dart';

import 'package:solar_erp_app/features/auth/presentation/providers/auth_state.dart';
import 'package:solar_erp_app/shared/utils/validators.dart';

void main() {
  group('AppValidators', () {
    test('email validates correctly', () {
      expect(AppValidators.email(null), isNotNull);
      expect(AppValidators.email('bad'), isNotNull);
      expect(AppValidators.email('user@example.com'), isNull);
    });

    test('phone accepts 10 digit Indian numbers', () {
      expect(AppValidators.phone('9876543210'), isNull);
      expect(AppValidators.phone('123'), isNotNull);
    });

    test('gstNumber optional when empty', () {
      expect(AppValidators.gstNumber(null), isNull);
      expect(AppValidators.gstNumber(''), isNull);
    });

    test('password min length', () {
      expect(AppValidators.password('short'), isNotNull);
      expect(AppValidators.password('longenough'), isNull);
    });

    test('confirmPassword matches', () {
      expect(AppValidators.confirmPassword('abc', 'abc'), isNull);
      expect(AppValidators.confirmPassword('abc', 'xyz'), isNotNull);
    });
  });

  group('AuthState', () {
    test('permission helpers', () {
      const state = AuthState(
        isInitializing: false,
        permissions: ['customer.read', 'quotation.create'],
      );
      expect(state.hasPermission('customer.read'), isTrue);
      expect(state.hasPermission('invoice.read'), isFalse);
      expect(state.hasAny(['invoice.read', 'quotation.create']), isTrue);
    });

    test('copyWith clearUser', () {
      const state = AuthState(
        isInitializing: false,
        permissions: ['a'],
      );
      final cleared = state.copyWith(clearUser: true);
      expect(cleared.permissions, isEmpty);
      expect(cleared.profile, isNull);
    });
  });
}
