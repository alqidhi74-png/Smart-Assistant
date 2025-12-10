import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:crypto/crypto.dart';
import 'dart:convert';
import 'package:flutter/foundation.dart';

class Database {


  final DatabaseReference db1 = FirebaseDatabase.instance.ref().child("users");
 // final DatabaseReference db2 = FirebaseDatabase.instance.ref().child("Games");


  Future<void> registerUser(String fullName, String email,String phone, String password, String admin) async {
    try {
      final userCredential = await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      final uid = userCredential.user!.uid;
      final DatabaseReference db1 = FirebaseDatabase.instance.ref().child('users');

      await db1.child(uid).set({
        'fullName': fullName,
        'email': email,
        'phone': phone,
        'admin': admin,
        'passwordHash': sha256.convert(utf8.encode(password)).toString(),
      });
    } catch (e) {
      if (kDebugMode) {
        print('Error registering user: $e');
      }
      rethrow;
    }
  }


  Future<void> updateUserProfile(String uid, Map<String, dynamic> updatedData) async {
    await db1.child(uid).update(updatedData);
  }

  // Fetch list of users
  Future<List<Map<String, dynamic>>> fetchUsers() async {
    final snapshot = await db1.get();
    if (snapshot.exists) {
      Map data = snapshot.value as Map;
      List<Map<String, dynamic>> userList = [];
      data.forEach((key, value) {
        userList.add({
          'uid': key,
          'fullName': value['fullName'] ?? '',
          'email': value['email'] ?? '',
          'admin': value['admin'] ?? 'N',
        });
      });
      return userList;
    } else {
      return [];
    }
  }

// Update admin status of a specific user
  Future<void> updateAdminStatus(String uid, String newValue) async {
    await db1.child(uid).update({'admin': newValue});
  }

  // Future<List<Map<String, dynamic>>> fetchGames() async {

  //   DataSnapshot snapshot = await db2.get();

  //   if (snapshot.value != null) {

  //     Map<String, dynamic> gamesMap = Map<String, dynamic>.from(snapshot.value as Map);

  //     return gamesMap.entries.map((entry) {

  //       var gam = Map<String, dynamic>.from(entry.value);

  //       gam['key'] = entry.key;

  //       return gam;
  //     }).toList();
  //   } else {

  //     return [];
  //   }
  // }

  // Future<void> delete(String key) async {

  //   await db2.child(key).remove();
  // }


  // Future<void> update(String key, Map<String, dynamic> pet) async {
  //   await db2.child(key).update(pet);
  // }
  
  // Future<void> Add(Map<String, dynamic> pet) async {

  //   await db2.push().set(pet);
  // }
}