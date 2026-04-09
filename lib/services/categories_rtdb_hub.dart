import 'dart:async';

import 'package:firebase_database/firebase_database.dart';

/// One RTDB listener on `categories` shared by home, My Bills filters, admin dashboards.
final class CategoriesRtdbHub {
  CategoriesRtdbHub._();
  static final CategoriesRtdbHub instance = CategoriesRtdbHub._();

  static final DatabaseReference _ref =
      FirebaseDatabase.instance.ref('categories');

  StreamSubscription<DatabaseEvent>? _firebaseSub;
  DatabaseEvent? _latestEvent;
  final StreamController<DatabaseEvent> _controller =
      StreamController<DatabaseEvent>.broadcast();

  /// Last event received from RTDB, if any.
  DatabaseEvent? get latestEvent => _latestEvent;

  /// Broadcast stream; first listener attaches the underlying [onValue] subscription.
  /// New listeners receive the cached latest event immediately when available.
  Stream<DatabaseEvent> get stream async* {
    _ensureAttached();
    final cached = _latestEvent;
    if (cached != null) {
      yield cached;
    }
    yield* _controller.stream;
  }

  void _ensureAttached() {
    if (_firebaseSub != null) return;
    _firebaseSub = _ref.onValue.listen(
      (e) {
        _latestEvent = e;
        if (!_controller.isClosed) _controller.add(e);
      },
      onError: (Object error, StackTrace stackTrace) {
        if (!_controller.isClosed) {
          _controller.addError(error, stackTrace);
        }
      },
    );
  }
}
