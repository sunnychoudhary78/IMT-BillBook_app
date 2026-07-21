import 'package:flutter_test/flutter_test.dart';
import 'package:solar_erp_app/shared/utils/gst_breakdown.dart';
import 'package:solar_erp_app/shared/utils/validators.dart';

void main() {
  group('AppValidators — web parity', () {
    test('aadharNumber accepts blank or 12 digits', () {
      expect(AppValidators.aadharNumber(null), isNull);
      expect(AppValidators.aadharNumber(''), isNull);
      expect(AppValidators.aadharNumber('123456789012'), isNull);
      expect(AppValidators.aadharNumber('12345'), isNotNull);
    });

    test('gstNumber allows partial and strict at 15', () {
      expect(AppValidators.gstNumber('1'), isNull);
      expect(AppValidators.gstNumber('ABC'), isNull);
      expect(AppValidators.gstNumber('22AAAAA0000A1Z5'), isNull);
      expect(AppValidators.gstNumber('INVALIDGSTIN123'), isNotNull);
    });

    test('optionalPhone accepts Indian and international', () {
      expect(AppValidators.optionalPhone('9876543210'), isNull);
      expect(AppValidators.optionalPhone('+919876543210'), isNull);
      expect(AppValidators.optionalPhone('123'), isNotNull);
    });

    test('duplicateLineItems detects duplicates', () {
      expect(
        AppValidators.duplicateLineItems(['a', 'b', 'a']),
        isNotNull,
      );
      expect(
        AppValidators.duplicateLineItems(['a', 'b', 'c']),
        isNull,
      );
    });
  });

  group('GstBreakdown — web parity', () {
    test('splitCgstSgst halves GST for display', () {
      final result = splitCgstSgst(36, 200);
      expect(result.cgstAmount, 18);
      expect(result.sgstAmount, 18);
      expect(result.gstAmount, 36);
    });

    test('calcDocumentTotals sums lines', () {
      final totals = calcDocumentTotals([
        const LineTotalsInput(quantity: 2, unitPrice: 100, gstPercent: 18),
      ]);
      expect(totals.subtotal, 200);
      expect(totals.gstAmount, 36);
      expect(totals.totalAmount, 236);
      expect(totals.breakdown.cgstAmount, 18);
    });
  });
}
