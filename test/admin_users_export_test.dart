// ignore_for_file: avoid_print

import 'package:flutter_test/flutter_test.dart';
import 'package:smart_assistant/utils/admin_pdf_io.dart';
import 'package:smart_assistant/utils/admin_users_export_helper.dart';

void main() {
  tearDownAll(() {
    print('All admin users export tests passed successfully!');
  });

  group('safeExportFileName', () {
    test('lowercases ASCII input', () {
      expect(safeExportFileName('Mohammed'), 'mohammed');
      print('Lowercase ASCII test passed');
    });

    test('replaces spaces with underscore', () {
      expect(safeExportFileName('Mohammed Ali'), 'mohammed_ali');
      print('Replace spaces test passed');
    });

    test('collapses multiple non-alphanumeric chars to a single underscore', () {
      expect(safeExportFileName('a   b'), 'a_b');
      expect(safeExportFileName('John@Doe!'), 'john_doe_');
      print('Collapse non-alphanumeric test passed');
    });

    test('keeps digits as-is', () {
      expect(safeExportFileName('USER 123'), 'user_123');
      print('Keep digits test passed');
    });

    test('returns "export" for empty/whitespace input', () {
      expect(safeExportFileName(''), 'export');
      expect(safeExportFileName('   '), 'export');
      print('Empty input fallback test passed');
    });
  });

  group('buildUsersExportFileName', () {
    test('returns Users-Export_<stamp>.pdf when base is "all_users"', () {
      final now = DateTime(2026, 4, 25, 14, 30);
      expect(
        buildUsersExportFileName('all_users', now),
        'Users-Export_2026-04-25_14-30.pdf',
      );
      print('All users filename test passed');
    });

    test('returns User-Export_<base>_<stamp>.pdf for a single user', () {
      final now = DateTime(2026, 4, 25, 9, 5);
      expect(
        buildUsersExportFileName('Mohammed Ali', now),
        'User-Export_mohammed_ali_2026-04-25_09-05.pdf',
      );
      print('Single user filename test passed');
    });

    test('falls back to "export" base when name is empty', () {
      final now = DateTime(2026, 1, 1, 0, 0);
      expect(
        buildUsersExportFileName('', now),
        'User-Export_export_2026-01-01_00-00.pdf',
      );
      print('Empty base filename test passed');
    });
  });

  group('buildUsersExportRows', () {
    test('first row is the header', () {
      final rows = buildUsersExportRows([]);
      expect(rows, hasLength(1));
      expect(rows.first, kUsersExportHeader);
      expect(
        rows.first,
        ['User Name', 'Email', 'Phone', 'Status', 'Role', 'Joined'],
      );
      print('Header row test passed');
    });

    test('replaces empty fullName with "Unknown User"', () {
      final rows = buildUsersExportRows([
        const UserExportEntry(
          fullName: '',
          email: 'x@x.com',
          phone: '99000000',
          isBlocked: false,
          isAdmin: false,
          createdAt: null,
        ),
      ]);
      expect(rows[1][0], 'Unknown User');
      expect(rows[1][1], 'x@x.com');
      expect(rows[1][2], '99000000');
      print('Unknown User fallback test passed');
    });

    test('formats Status (Blocked/Active) and Role (Admin/User) correctly', () {
      final rows = buildUsersExportRows([
        const UserExportEntry(
          fullName: 'Sara Saif',
          email: 'sara@x.com',
          phone: '99000000',
          isBlocked: true,
          isAdmin: false,
          createdAt: null,
        ),
        const UserExportEntry(
          fullName: 'Ahmed K',
          email: 'ahmed@x.com',
          phone: '99111111',
          isBlocked: false,
          isAdmin: true,
          createdAt: null,
        ),
      ]);

      expect(rows[1][3], 'Blocked');
      expect(rows[1][4], 'User');
      expect(rows[2][3], 'Active');
      expect(rows[2][4], 'Admin');
      print('Status & role formatting test passed');
    });

    test('renders "-" when joined timestamp is missing', () {
      final rows = buildUsersExportRows([
        const UserExportEntry(
          fullName: 'X',
          email: 'x@x.com',
          phone: '',
          isBlocked: false,
          isAdmin: false,
          createdAt: null,
        ),
      ]);
      expect(rows[1][5], '-');
      print('Missing timestamp dash test passed');
    });

    test('keeps row ordering consistent with input ordering', () {
      final rows = buildUsersExportRows([
        const UserExportEntry(
          fullName: 'Alpha',
          email: 'a@x.com',
          phone: '',
          isBlocked: false,
          isAdmin: false,
          createdAt: null,
        ),
        const UserExportEntry(
          fullName: 'Beta',
          email: 'b@x.com',
          phone: '',
          isBlocked: false,
          isAdmin: false,
          createdAt: null,
        ),
      ]);
      expect(rows[1][0], 'Alpha');
      expect(rows[2][0], 'Beta');
      print('Row ordering test passed');
    });
  });

  group('formatJoinedDateTime', () {
    test('returns "-" for null', () {
      expect(formatJoinedDateTime(null), '-');
      print('Null timestamp returns dash test passed');
    });

    test('formats AM time as yyyy-MM-dd hh:mm AM', () {
      final ts = DateTime(2026, 4, 25, 9, 5).millisecondsSinceEpoch;
      expect(formatJoinedDateTime(ts), '2026-04-25 09:05 AM');
      print('AM formatting test passed');
    });

    test('formats PM time as yyyy-MM-dd hh:mm PM', () {
      final ts = DateTime(2026, 4, 25, 14, 30).millisecondsSinceEpoch;
      expect(formatJoinedDateTime(ts), '2026-04-25 02:30 PM');
      print('PM formatting test passed');
    });
  });
}
