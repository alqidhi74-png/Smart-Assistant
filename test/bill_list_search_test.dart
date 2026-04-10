// ignore_for_file: avoid_print

import 'package:flutter_test/flutter_test.dart';
import 'package:smart_assistant/models/bill_summary.dart';
import 'package:smart_assistant/utils/bill_list_query.dart';

BillSummary _bill({
  required String id,
  required String type,
  required int createdAt,
  String dateText = '',
  String? invoice,
  String? account,
  double? consumption,
}) {
  return BillSummary(
    id: id,
    type: type,
    dateText: dateText,
    consumptionValue: consumption,
    totalAmount: 10,
    invoiceNumber: invoice,
    accountNumber: account,
    createdAt: createdAt,
  );
}

void main() {
  group('BillListQuery — search', () {
    late BillSummary b;

    setUpAll(() {
      b = _bill(
        id: 'a',
        type: 'Electricity',
        createdAt: 1,
        dateText: '2025-06-15',
        invoice: 'INV-999',
        account: '4880123456',
        consumption: 150,
      );
    });

    test('matches bill type (electric)', () {
      expect(BillListQuery.applySearch([b], 'electric').length, 1);
      print('Search by type test passed');
    });

    test('matches date substring', () {
      expect(BillListQuery.applySearch([b], '2025-06').length, 1);
      print('Search by date test passed');
    });

    test('matches consumption value', () {
      expect(BillListQuery.applySearch([b], '150').length, 1);
      print('Search by consumption test passed');
    });

    test('matches consumption when query uses Arabic digits', () {
      expect(BillListQuery.applySearch([b], '١٥٠').length, 1);
      print('Search Arabic digits consumption test passed');
    });

    test('matches date when query uses Arabic digits', () {
      expect(BillListQuery.applySearch([b], '٢٠٢٥').length, 1);
      print('Search Arabic digits date test passed');
    });

    test('matches account number substring', () {
      expect(BillListQuery.applySearch([b], '488012').length, 1);
      print('Search by account test passed');
    });

    test('matches invoice (case-insensitive)', () {
      expect(BillListQuery.applySearch([b], 'inv-999').length, 1);
      print('Search by invoice test passed');
    });

    test('no match returns empty list', () {
      expect(BillListQuery.applySearch([b], 'nomatch').length, 0);
      print('Search no match test passed');
    });

    test('empty query returns all bills', () {
      expect(BillListQuery.applySearch([b], '').length, 1);
      print('Search empty query returns all test passed');
    });

    tearDownAll(() {
      print('All bill search tests passed successfully!');
    });
  });
}
