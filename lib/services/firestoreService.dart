import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:platform_v2/dataClasses/blockData.dart';
import 'package:platform_v2/dataClasses/connection.dart';

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
    await _instance.collection('orgs').doc(orgId).collection('blocks').doc(blockData['blockID']).set({
      ...blockData,
    });
  }

  static Future<void> deleteBlock(String orgId, String blockID) async {
    await _instance.collection('orgs').doc(orgId).collection('blocks').doc(blockID).delete();
  }

  static Future<void> updatePosition(String orgId, String blockID, Map<String, double> position) async {
    await _instance.collection('orgs').doc(orgId).collection('blocks').doc(blockID).update({
      'position': position,
    });
  }

  static Future<void> updateData(String orgId, String blockID, BlockData blockData) async {
    await _instance.collection('orgs').doc(orgId).collection('blocks').doc(blockID).update({
      'name': blockData.name,
      'role': blockData.role,
      'department': blockData.department,
      'emails': blockData.emails,
    });
  }

  // 1 Block. BlockNotifier subscribes to this
  static Stream<DocumentSnapshot<Map<String, dynamic>>> getBlockStream(String orgId, String blockID) {
    return _instance.collection('orgs').doc(orgId).collection('blocks').doc(blockID).snapshots();
  }

  // All blocks in Collection
  static Stream<QuerySnapshot> getBlocksStream(String orgId) {
    return _instance.collection('orgs').doc(orgId).collection('blocks').snapshots();
  }

  // All blocks in Collection
  static Stream<QuerySnapshot> getConnectionsStream(String orgId) {
    return _instance.collection('orgs').doc(orgId).collection('connections').snapshots();
  }

  static Future<void> addConnection(String orgId, Connection connection) async {
    await _instance.collection('orgs').doc(orgId).collection('connections').doc(connection.id).set({
      'id': connection.id,
      'parentID': connection.parentId,
      'childID': connection.childId,
    });
  }

  static Future<void> deleteConnection(String orgId, String connectionId) async {
    await _instance.collection('orgs').doc(orgId).collection('connections').doc(connectionId).delete();
  }

  static Future<void> batchUpdatePositions(String orgId, Map<String, Offset> positions) async {
    print("Do batch update to Firestore!!");
    WriteBatch batch = _instance.batch();

    for (String blockID in positions.keys) {
      final docRef = _instance.collection('orgs').doc(orgId).collection('blocks').doc(blockID);
      batch.update(docRef, {
        'position': {'x': positions[blockID]!.dx, 'y': positions[blockID]!.dy},
      });
    }

    await batch.commit();
  }

  static Future<void> dispose() async {
    for (final subscription in _subscriptions) {
      await subscription.cancel();
    }
    _subscriptions.clear();
  }
}
