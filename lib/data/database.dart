import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:crypto/crypto.dart';
import 'dart:convert';
import 'package:flutter/foundation.dart';

class Database {
  final DatabaseReference db1 = FirebaseDatabase.instance.ref().child("users");

  Future<void> registerUser(
    String fullName,
    String email,
    String phone,
    String password,
    String admin,
  ) async {
    try {
      final userCredential = await FirebaseAuth.instance
          .createUserWithEmailAndPassword(email: email, password: password);

      final uid = userCredential.user!.uid;
      final DatabaseReference db1 = FirebaseDatabase.instance.ref().child(
        'users',
      );

      await db1.child(uid).set({
        'fullName': fullName,
        'email': email,
        'phone': phone,
        'admin': admin,
        'createdAt': ServerValue.timestamp,
        'passwordHash': sha256.convert(utf8.encode(password)).toString(),
      });
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Error registering user: $e');
      }
      rethrow;
    }
  }

  Future<void> updateUserProfile(
    String uid,
    Map<String, dynamic> updatedData,
  ) async {
    await db1.child(uid).update(updatedData);
  }
}
