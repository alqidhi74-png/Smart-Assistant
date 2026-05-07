// ignore_for_file: avoid_print

import 'package:flutter_test/flutter_test.dart';
import 'package:smart_assistant/models/bill_analysis.dart';
import 'package:smart_assistant/services/bill_analysis_service.dart';
import 'package:smart_assistant/services/category_policy_service.dart';
import 'package:smart_assistant/utils/bill_type_utils.dart';

BillAnalysisResult _result({
  String? billType,
  double? totalAmount,
  double? consumptionValue,
  String? invoiceNumber,
  String? accountNumber,
  String? billingMonthKey,
}) {
  return BillAnalysisResult(
    rawText: 'sample',
    billType: billType,
    totalAmount: totalAmount,
    consumptionValue: consumptionValue,
    invoiceNumber: invoiceNumber,
    accountNumber: accountNumber,
    billingMonthKey: billingMonthKey,
  );
}

void main() {
  tearDownAll(() {
    print('All upload bill logic tests passed successfully!');
  });

  group('Upload bill (PDF/Camera/Gallery) — utility acceptance', () {
    test('accepts a Water bill', () {
      expect(
        BillAnalysisService.isAcceptedUtilityBill(_result(billType: 'Water')),
        isTrue,
      );
      print('Accepts Water bill test passed');
    });

    test('accepts an Electricity bill', () {
      expect(
        BillAnalysisService.isAcceptedUtilityBill(
          _result(billType: 'Electricity'),
        ),
        isTrue,
      );
      print('Accepts Electricity bill test passed');
    });

    test('rejects when bill type cannot be detected', () {
      expect(
        BillAnalysisService.isAcceptedUtilityBill(_result()),
        isFalse,
      );
      print('Rejects unknown bill type test passed');
    });

    test('rejects unsupported types (e.g. Internet)', () {
      expect(
        BillAnalysisService.isAcceptedUtilityBill(
          _result(billType: 'Internet'),
        ),
        isFalse,
      );
      print('Rejects unsupported type test passed');
    });
  });

  group('Upload bill — admin category policy', () {
    test('Electricity is allowed when "electricity" kind is enabled', () {
      expect(
        CategoryPolicyService.isBillTypeAllowedByCategories(
          'Electricity',
          {'electricity'},
        ),
        isTrue,
      );
      print('Policy: electricity allowed test passed');
    });

    test('Water is allowed when "water" kind is enabled', () {
      expect(
        CategoryPolicyService.isBillTypeAllowedByCategories(
          'Water',
          {'water'},
        ),
        isTrue,
      );
      print('Policy: water allowed test passed');
    });

    test('Electricity is blocked when admin removed its category', () {
      expect(
        CategoryPolicyService.isBillTypeAllowedByCategories(
          'Electricity',
          {'water'},
        ),
        isFalse,
      );
      print('Policy: electricity blocked test passed');
    });

    test('null bill type is never allowed', () {
      expect(
        CategoryPolicyService.isBillTypeAllowedByCategories(
          null,
          {'electricity', 'water'},
        ),
        isFalse,
      );
      print('Policy: null type rejected test passed');
    });

    test('unknown type (e.g. Internet) is not allowed', () {
      expect(
        CategoryPolicyService.isBillTypeAllowedByCategories(
          'Internet',
          {'electricity', 'water'},
        ),
        isFalse,
      );
      print('Policy: unknown type rejected test passed');
    });
  });

  group('Upload bill — bill type detection', () {
    test('detects English Electricity', () {
      expect(BillTypeUtils.isElectricity('Electricity Bill'), isTrue);
      expect(BillTypeUtils.canonicalTypeKey('electricity'), 'Electricity');
      print('Detect English Electricity test passed');
    });

    test('detects Arabic كهرباء', () {
      expect(BillTypeUtils.isElectricity('فاتورة كهرباء'), isTrue);
      expect(BillTypeUtils.canonicalTypeKey('فاتورة كهرباء'), 'Electricity');
      print('Detect Arabic كهرباء test passed');
    });

    test('detects English Water', () {
      expect(BillTypeUtils.isWater('water services'), isTrue);
      expect(BillTypeUtils.canonicalTypeKey('water'), 'Water');
      print('Detect English Water test passed');
    });

    test('detects Arabic ماء / مياه', () {
      expect(BillTypeUtils.isWater('فاتورة ماء'), isTrue);
      expect(BillTypeUtils.canonicalTypeKey('فاتورة ماء'), 'Water');
      expect(BillTypeUtils.canonicalTypeKey('مياه'), 'Water');
      print('Detect Arabic ماء / مياه test passed');
    });

    test('returns trimmed input for unknown type', () {
      expect(BillTypeUtils.canonicalTypeKey('  custom-bill  '), 'custom-bill');
      print('Trims unknown type test passed');
    });
  });
}
