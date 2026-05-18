import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/foundation.dart';
import '../models/bill_summary.dart';
import '../utils/app_error_reporter.dart';
import 'notification_store.dart';

class BillStore {
  BillStore._();

  static final BillStore instance = BillStore._();

  final ValueNotifier<List<BillSummary>> bills = ValueNotifier([]);
  final ValueNotifier<bool> initialLoading = ValueNotifier(true);
  bool _listening = false;
  StreamSubscription<DatabaseEvent>? _subscription;

  /// Stop RTDB listener and clear bills (e.g. user switch / logout).
  void resetForUserSwitch() {
    _subscription?.cancel();
    _subscription = null;
    _listening = false;
    bills.value = [];
    initialLoading.value = true;
  }

  Future<void> ensureListening() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      initialLoading.value = false;
      return;
    }

    void stopLoading() {
      if (initialLoading.value) {
        initialLoading.value = false;
      }
    }

    // Never leave the home screen spinner running indefinitely.
    Future.delayed(const Duration(seconds: 8), stopLoading);

    if (_listening) {
      if (initialLoading.value) {
        unawaited(
          refresh()
              .then((_) => stopLoading())
              .catchError((Object e, StackTrace st) {
                AppErrorReporter.debug('BillStore refresh while loading', e, st);
                stopLoading();
              }),
        );
      }
      return;
    }

    _listening = true;
    final ref = FirebaseDatabase.instance.ref('my_bills/${user.uid}');

    ref
        .get()
        .timeout(const Duration(seconds: 12))
        .then((snapshot) {
          bills.value = _mapBills(snapshot.value);
          stopLoading();
        })
        .catchError((Object e, StackTrace st) {
          AppErrorReporter.debug('BillStore initial get', e, st);
          stopLoading();
        });

    _subscription = ref.onValue.listen(
      (event) {
        try {
          bills.value = _mapBills(event.snapshot.value);
          stopLoading();
        } catch (e, st) {
          AppErrorReporter.debug('BillStore onValue map', e, st);
          stopLoading();
        }
      },
      onError: (e, st) {
        AppErrorReporter.debug('BillStore onValue', e, st);
        stopLoading();
      },
    );
  }

  Future<void> refresh() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    final snapshot =
        await FirebaseDatabase.instance.ref('my_bills/${user.uid}').get();
    if (snapshot.exists && snapshot.value != null) {
      bills.value = _mapBills(snapshot.value);
    }
  }

  Future<bool> saveBill(BillSummary bill) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      return _upsertBillLocal(bill);
    }
    final ref = FirebaseDatabase.instance.ref('my_bills/${user.uid}');
    final existingId = await _findExistingBillId(
      ref: ref,
      type: bill.type,
      billingMonthKey: bill.billingMonthKey,
    );
    final targetId = existingId ?? bill.id;

    await ref.child(targetId).set({
      'type': bill.type,
      'dateText': bill.dateText,
      'consumptionValue': bill.consumptionValue,
      'consumptionUnit': bill.consumptionUnit,
      'totalAmount': bill.totalAmount,
      'accountNumber': bill.accountNumber,
      'invoiceNumber': bill.invoiceNumber,
      'billingMonthText': bill.billingMonthText,
      'billingMonthKey': bill.billingMonthKey,
      'currentMonthAmount': bill.currentMonthAmount,
      'consumptionDays': bill.consumptionDays,
      'createdAt': bill.createdAt,
    });
    await ensureListening();
    
    NotificationStore.instance.addNotification(
      title: existingId != null ? 'Bill Updated' : 'New Bill Added',
      body: '${bill.type} bill for ${bill.billingMonthText ?? 'this month'} has been ${existingId != null ? 'updated' : 'saved'} successfully.',
      type: NotificationType.success,
    );
    
    return existingId != null;
  }

  void addBillLocal(BillSummary bill) {
    bills.value = [bill, ...bills.value];
  }

  bool _upsertBillLocal(BillSummary bill) {
    final normalizedType = _normalizeType(bill.type);
    final normalizedKey = _normalizeMonthKey(bill.billingMonthKey);
    if (normalizedKey == null) {
      addBillLocal(bill);
      return false;
    }
    final current = [...bills.value];
    final existingIndex = current.indexWhere((it) {
      return _normalizeType(it.type) == normalizedType &&
          _normalizeMonthKey(it.billingMonthKey) == normalizedKey;
    });
    if (existingIndex >= 0) {
      final existing = current[existingIndex];
      current[existingIndex] = BillSummary(
        id: existing.id,
        type: bill.type,
        dateText: bill.dateText,
        consumptionValue: bill.consumptionValue,
        consumptionUnit: bill.consumptionUnit,
        totalAmount: bill.totalAmount,
        accountNumber: bill.accountNumber,
        invoiceNumber: bill.invoiceNumber,
        billingMonthText: bill.billingMonthText,
        billingMonthKey: bill.billingMonthKey,
        currentMonthAmount: bill.currentMonthAmount,
        consumptionDays: bill.consumptionDays,
        createdAt: bill.createdAt,
      );
      current.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      bills.value = current;
      return true;
    }
    addBillLocal(bill);
    return false;
  }

  Future<void> deleteBill(String billId) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      bills.value = bills.value.where((bill) => bill.id != billId).toList();
      return;
    }
    await FirebaseDatabase.instance
        .ref('my_bills/${user.uid}/$billId')
        .remove();
        
    NotificationStore.instance.addNotification(
      title: 'Bill Deleted',
      body: 'The bill has been removed from your history.',
      type: NotificationType.warning,
    );
  }

  List<BillSummary> _mapBills(Object? data) {
    final items = <BillSummary>[];
    if (data is Map) {
      data.forEach((key, value) {
        if (value is Map) {
          final createdAt =
              int.tryParse(value['createdAt']?.toString() ?? '') ?? 0;
          items.add(
            BillSummary(
              id: key.toString(),
              type: value['type']?.toString() ?? 'Electricity',
              dateText: value['dateText']?.toString() ?? '',
              consumptionValue: (value['consumptionValue'] as num?)?.toDouble(),
              consumptionUnit: value['consumptionUnit']?.toString(),
              totalAmount: (value['totalAmount'] as num?)?.toDouble(),
              accountNumber: value['accountNumber']?.toString(),
              invoiceNumber: value['invoiceNumber']?.toString(),
              billingMonthText: value['billingMonthText']?.toString(),
              billingMonthKey: value['billingMonthKey']?.toString(),
              currentMonthAmount:
                  (value['currentMonthAmount'] as num?)?.toDouble(),
              consumptionDays: (value['consumptionDays'] as num?)?.toInt(),
              createdAt: createdAt,
            ),
          );
        }
      });
    }
    items.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return items;
  }

  Future<String?> _findExistingBillId({
    required DatabaseReference ref,
    required String type,
    required String? billingMonthKey,
  }) async {
    final normalizedKey = _normalizeMonthKey(billingMonthKey);
    if (normalizedKey == null) return null;
    final normalizedType = _normalizeType(type);
    final snapshot = await ref.get();
    final data = snapshot.value;
    if (data is! Map) return null;

    String? latestMatchingId;
    var latestCreatedAt = -1;
    data.forEach((key, value) {
      if (value is! Map) return;
      final rowType = _normalizeType(value['type']?.toString() ?? '');
      final rowKey = _normalizeMonthKey(value['billingMonthKey']?.toString());
      if (rowType != normalizedType || rowKey != normalizedKey) return;
      final createdAt = int.tryParse(value['createdAt']?.toString() ?? '') ?? 0;
      if (createdAt >= latestCreatedAt) {
        latestCreatedAt = createdAt;
        latestMatchingId = key.toString();
      }
    });
    return latestMatchingId;
  }

  String _normalizeType(String type) => type.trim().toLowerCase();

  String? _normalizeMonthKey(String? key) {
    final t = key?.trim() ?? '';
    if (t.isEmpty) return null;
    return t.toLowerCase();
  }
}
