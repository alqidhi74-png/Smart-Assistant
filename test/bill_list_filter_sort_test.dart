import 'package:flutter_test/flutter_test.dart';
import 'package:smart_assistant/models/bill_summary.dart';
import 'package:smart_assistant/utils/bill_list_query.dart';

BillSummary _bill({
  required String id,
  required String type,
  required int createdAt,
  String dateText = '',
}) {
  return BillSummary(
    id: id,
    type: type,
    dateText: dateText,
    totalAmount: 10,
    createdAt: createdAt,
  );
}

void main() {
  group('BillListQuery — filter & sort', () {
    late BillSummary e1;
    late BillSummary e2;
    late BillSummary w1;
    late List<BillSummary> all;

    setUpAll(() {
      e1 = _bill(
        id: '1',
        type: 'Electricity',
        createdAt: 100,
        dateText: '2025-01-01',
      );
      e2 = _bill(
        id: '2',
        type: 'Electricity',
        createdAt: 300,
        dateText: '2025-03-01',
      );
      w1 = _bill(
        id: '3',
        type: 'Water',
        createdAt: 200,
        dateText: '2025-02-01',
      );
      all = [e1, e2, w1];
    });

    test('filter electricity keeps only electricity bills', () {
      final onlyElec = BillListQuery.applyFilter(
        all,
        BillFilterMode.electricity,
      );
      expect(onlyElec.length, 2);
      expect(onlyElec.every((b) => b.type.contains('Electric')), isTrue);
      print('Filter electricity test passed');
    });

    test('filter water keeps only water bills', () {
      final onlyWater = BillListQuery.applyFilter(all, BillFilterMode.water);
      expect(onlyWater.length, 1);
      expect(onlyWater.single.type, 'Water');
      print('Filter water test passed');
    });

    test('sort by date newest first', () {
      final onlyElec = BillListQuery.applyFilter(
        all,
        BillFilterMode.electricity,
      );
      final sortedNewest = BillListQuery.applySort(
        onlyElec,
        BillSortOrder.newestFirst,
      );
      expect(sortedNewest.map((b) => b.id).toList(), ['2', '1']);
      print('Sort newest first test passed');
    });

    test('sort by date oldest first', () {
      final onlyElec = BillListQuery.applyFilter(
        all,
        BillFilterMode.electricity,
      );
      final sortedOldest = BillListQuery.applySort(
        onlyElec,
        BillSortOrder.oldestFirst,
      );
      expect(sortedOldest.map((b) => b.id).toList(), ['1', '2']);
      print('Sort oldest first test passed');
    });

    tearDownAll(() {
      print('All bill filter & sort tests passed successfully!');
    });
  });
}
