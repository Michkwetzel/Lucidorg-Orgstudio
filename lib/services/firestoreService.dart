import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';

class FirestoreService {
  static late final FirebaseFirestore _instance;

  static void initialize() {
    _instance = FirebaseFirestore.instanceFor(
      app: Firebase.app(),
      databaseId: 'platform-v2',
    );
  }

  static FirebaseFirestore get instance => _instance;

  static Future<void> saveBlock(String orgId, String blockId, Offset position) async {
    await _instance.collection('companies').doc(orgId).collection('blocks').doc(blockId).set({
      'id': blockId,
      'position': {'x': position.dx, 'y': position.dy},
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  static Future<void> deleteBlock(String orgID, String blockId) async {
    await _instance.collection('companies').doc(orgID).collection('blocks').doc(blockId).delete();
  }
}
