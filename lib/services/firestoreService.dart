import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:platform_v2/dataClasses/blockData.dart';
import 'package:platform_v2/dataClasses/connection.dart';

class FirestoreService {
  static late final FirebaseFirestore _instance;

  // Set the collection. These are set whenever you change from OrgBuilder to Assessment
  static late CollectionReference<Map<String, dynamic>> _blocksCollection;
  static late CollectionReference<Map<String, dynamic>> _connectionsCollection;

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

  static void setFirestorePathOrgBuilder(String orgId) {
    _blocksCollection = _instance.collection('orgs').doc(orgId).collection('blocks');
    _connectionsCollection = _instance.collection('orgs').doc(orgId).collection('connections');
  }

  static void setFirestorePathAssessment(String orgId, String assessmentId) {
    _blocksCollection = _instance.collection('orgs').doc(orgId).collection('assessments').doc(assessmentId).collection('blocks');
    _connectionsCollection = _instance.collection('orgs').doc(orgId).collection('assessments').doc(assessmentId).collection('connections');
  }

  static Future<void> addBlock(String orgId, Map<String, dynamic> blockData) async {
    await _blocksCollection.doc(blockData['blockID']).set({
      ...blockData,
    });
  }

  static Future<void> deleteBlock(String orgId, String blockID) async {
    await _blocksCollection.doc(blockID).delete();
  }

  static Future<void> updatePosition(String orgId, String blockID, Map<String, double> position) async {
    await _blocksCollection.doc(blockID).update({
      'position': position,
    });
  }

  static Future<void> updateData(String orgId, String blockID, BlockData blockData) async {
    await _blocksCollection.doc(blockID).update({
      'name': blockData.name,
      'role': blockData.role,
      'department': blockData.department,
      'emails': blockData.emails,
    });
  }

  // 1 Block. BlockNotifier subscribes to this
  static Stream<DocumentSnapshot<Map<String, dynamic>>> getBlockStream(String orgId, String blockID) {
    return _blocksCollection.doc(blockID).snapshots();
  }

  // All blocks
  static Stream<QuerySnapshot> getBlocksStream(String orgId) {
    return _blocksCollection.snapshots();
  }

  // All Connections
  static Stream<QuerySnapshot> getConnectionsStream(String orgId) {
    return _connectionsCollection.snapshots();
  }

  static Future<void> addConnection(String orgId, Connection connection) async {
    await _connectionsCollection.doc(connection.id).set({
      'id': connection.id,
      'parentID': connection.parentId,
      'childID': connection.childId,
    });
  }

  static Future<void> deleteConnection(String orgId, String connectionId) async {
    await _connectionsCollection.doc(connectionId).delete();
  }

  //Function used when moving multiple blocks at the same time
  static Future<void> batchUpdatePositions(String orgId, Map<String, Offset> positions) async {
    print("Do batch update to Firestore!!");
    WriteBatch batch = _instance.batch();

    for (String blockID in positions.keys) {
      final docRef = _blocksCollection.doc(blockID);
      batch.update(docRef, {
        'position': {'x': positions[blockID]!.dx, 'y': positions[blockID]!.dy},
      });
    }

    await batch.commit();
  }

  static Future<void> createOrg(String orgName) async {
    final orgref = _instance.collection('orgs').doc();
    orgref.set({
      'orgName': orgName,
      'dateCreated': FieldValue.serverTimestamp(),
    });

    // Create org collection and then create 2 blocks and 1 connection as starting point
    final docRef1 = _instance.collection('orgs').doc(orgref.id).collection('blocks').doc();
    await docRef1.set({
      'position': {'x': 200, 'y': 200},
    });

    final docRef2 = _instance.collection('orgs').doc(orgref.id).collection('blocks').doc();
    await docRef2.set({
      'position': {'x': 200, 'y': 500},
    });

    await _instance.collection('orgs').doc(orgref.id).collection('connections').doc().set({
      'parentID': docRef1.id,
      'childID': docRef2.id,
    });
  }
}
