import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:platform_v2/dataClasses/blockData.dart';

class FirestoreService {
  static late final FirebaseFirestore _instance;
  static final List<StreamSubscription> _subscriptions = [];

  static void initialize() {
    _instance = FirebaseFirestore.instanceFor(
      app: Firebase.app(),
      databaseId: 'platform-v2',
    );
    _instance.settings = const Settings(
      persistenceEnabled: true,
      cacheSizeBytes: Settings.CACHE_SIZE_UNLIMITED, // Optional: unlimited cache
    );
  }

  static FirebaseFirestore get instance => _instance;

  static Future<void> addBlock(String orgId, Map<String, dynamic> blockData) async {
    await _instance.collection('orgs').doc(orgId).collection('blocks').doc(blockData['blockId']).set({
      ...blockData,
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  static Future<void> deleteBlock(String orgId, String blockId) async {
    await _instance.collection('orgs').doc(orgId).collection('blocks').doc(blockId).delete();
  }

  static Future<void> updatePosition(String orgId, String blockId, Map<String, double> position) async {
    await _instance.collection('orgs').doc(orgId).collection('blocks').doc(blockId).update({
      'position': position,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  static Future<void> updateData(String orgId, String blockId, BlockData blockData) async {
    await _instance.collection('orgs').doc(orgId).collection('blocks').doc(blockId).update({
      'name' : blockData.name,
      'role' : blockData.role,
      'department' : blockData.department,
      'emails' : blockData.emails,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  // 1 Block. BlockNotifier subscribes to this
  static Stream<DocumentSnapshot<Map<String, dynamic>>> getBlockStream(String orgId, String blockId) {
    return _instance.collection('orgs').doc(orgId).collection('blocks').doc(blockId).snapshots();
  }

  // All blocks in Collection
  static Stream<QuerySnapshot> getBlocksStream(String orgId) {
    return _instance.collection('orgs').doc(orgId).collection('blocks').snapshots();
  }

  static Future<void> dispose() async {
    for (final subscription in _subscriptions) {
      await subscription.cancel();
    }
    _subscriptions.clear();
  }
}
