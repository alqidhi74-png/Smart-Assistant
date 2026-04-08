import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/foundation.dart';
import '../models/bill_summary.dart';
import '../core/utils.dart';

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
    if (_listening) return;
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      initialLoading.value = false;
      return;
    }
    _listening = true;
    final ref = FirebaseDatabase.instance.ref('my_bills/${user.uid}');

    void stopLoading() {
      if (initialLoading.value) {
        initialLoading.value = false;
      }
    }

    ref
        .get()
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

    Future.delayed(const Duration(seconds: 10), stopLoading);
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

  Future<void> saveBill(BillSummary bill) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      addBillLocal(bill);
      return;
    }
    await FirebaseDatabase.instance.ref('my_bills/${user.uid}/${bill.id}').set({
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
  }

  void addBillLocal(BillSummary bill) {
    bills.value = [bill, ...bills.value];
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
}
