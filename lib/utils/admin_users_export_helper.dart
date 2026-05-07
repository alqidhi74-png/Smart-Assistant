import 'package:intl/intl.dart';

import 'admin_pdf_io.dart';

/// Pure data carrier used by the admin Users PDF export logic.
class UserExportEntry {
  final String fullName;
  final String email;
  final String phone;
  final bool isBlocked;
  final bool isAdmin;

  /// Milliseconds since epoch; null when not available.
  final int? createdAt;

  const UserExportEntry({
    required this.fullName,
    required this.email,
    required this.phone,
    required this.isBlocked,
    required this.isAdmin,
    required this.createdAt,
  });
}

/// Header row used at the top of the admin Users export table.
const List<String> kUsersExportHeader = <String>[
  'User Name',
  'Email',
  'Phone',
  'Status',
  'Role',
  'Joined',
];

/// Format a "joined" timestamp for the export table.
/// Returns "-" when [timestampMs] is null.
String formatJoinedDateTime(int? timestampMs) {
  if (timestampMs == null) return '-';
  final date = DateTime.fromMillisecondsSinceEpoch(timestampMs);
  return DateFormat('yyyy-MM-dd hh:mm a').format(date);
}

/// Build the rows for the admin Users PDF table (header included).
List<List<String>> buildUsersExportRows(List<UserExportEntry> users) {
  return <List<String>>[
    kUsersExportHeader,
    for (final user in users)
      <String>[
        user.fullName.isEmpty ? 'Unknown User' : user.fullName,
        user.email,
        user.phone,
        user.isBlocked ? 'Blocked' : 'Active',
        user.isAdmin ? 'Admin' : 'User',
        formatJoinedDateTime(user.createdAt),
      ],
  ];
}

/// Build the file name used when exporting users.
///
/// - When [baseName] sanitizes to "all_users" the file is named
///   `Users-Export_<stamp>.pdf`.
/// - Otherwise it is named `User-Export_<sanitizedBase>_<stamp>.pdf`.
String buildUsersExportFileName(String baseName, DateTime now) {
  final stamp =
      '${now.year.toString().padLeft(4, '0')}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}_'
      '${now.hour.toString().padLeft(2, '0')}-${now.minute.toString().padLeft(2, '0')}';
  final normalizedBase = safeExportFileName(baseName);
  return normalizedBase == 'all_users'
      ? 'Users-Export_$stamp.pdf'
      : 'User-Export_${normalizedBase}_$stamp.pdf';
}
