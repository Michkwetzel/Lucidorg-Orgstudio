import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:platform_v2/dataClasses/analysisBlockData.dart';
import 'package:platform_v2/dataClasses/blockData.dart';
import 'package:platform_v2/dataClasses/connection.dart';

class FirestoreService {
  static late final FirebaseFirestore _instance;

  static void initialize() {
    _instance = FirebaseFirestore.instanceFor(
      app: Firebase.app(),
      databaseId: 'platform-v2',
    );
    _instance.settings = const Settings(
      persistenceEnabled: true,
      cacheSizeBytes: Settings.CACHE_SIZE_UNLIMITED,
    );
  }

  static FirebaseFirestore get instance => _instance;

  // Helper method to get the blocks collection based on orgId, assessmentId
  static CollectionReference<Map<String, dynamic>> _getBlocksCollection({required String? orgId, String? assessmentId}) {
    if (assessmentId != null) {
      return _instance.collection('orgs').doc(orgId).collection('assessments').doc(assessmentId).collection('blocks');
    }
    return _instance.collection('orgs').doc(orgId).collection('blocks');
  }

  // Helper method to get the connections collection based on orgId, assessmentId
  static CollectionReference<Map<String, dynamic>> _getConnectionsCollection({required String? orgId, String? assessmentId}) {
    if (assessmentId != null) {
      return _instance.collection('orgs').doc(orgId).collection('assessments').doc(assessmentId).collection('connections');
    }
    return _instance.collection('orgs').doc(orgId).collection('connections');
  }

  // Create Group for analysis
  static Future<void> createGroup({required String? orgId, String? assessmentId, required Map<String, dynamic> groupData}) async {
    final collection = _instance.collection('orgs').doc(orgId).collection('assessments').doc(assessmentId).collection('groups');
    await collection.doc().set({
      ...groupData,
    });
  }

  static Future<void> addBlock({required String? orgId, String? assessmentId, required Map<String, dynamic> blockData}) async {
    final collection = _getBlocksCollection(orgId: orgId, assessmentId: assessmentId);
    await collection.doc(blockData['blockID']).set({
      ...blockData,
    });
  }

  static Future<void> deleteBlock({required String? orgId, String? assessmentId, required String blockID}) async {
    final collection = _getBlocksCollection(orgId: orgId, assessmentId: assessmentId);
    await collection.doc(blockID).delete();
  }

  static Future<void> updateBlockPosition({required String? orgId, String? assessmentId, required String blockID, required Map<String, double> position}) async {
    final collection = _getBlocksCollection(orgId: orgId, assessmentId: assessmentId);
    await collection.doc(blockID).update({
      'position': position,
    });
  }

  static Future<void> updateAnalysisBlockPosition({required String? orgId, String? assessmentId, required String blockID, required Map<String, double> position}) async {
    final collection = _instance.collection('orgs').doc(orgId).collection('assessments').doc(assessmentId).collection('analysisBlocks');
    await collection.doc(blockID).update({
      'position': position,
    });
  }

  static Future<void> updateAnalysisBlockData({required String? orgId, String? assessmentId, required String blockID, required AnalysisBlockData blockData}) async {
    final collection = _getBlocksCollection(orgId: orgId, assessmentId: assessmentId);
    await collection.doc(blockID).update({
      'blockName': blockData.blockName,
      'analysisBlockType': blockData.analysisBlockType,
      'groupIds': blockData.groupIds,
    });
  }

  

  static Future<void> updateData({required String? orgId, String? assessmentId, required String blockID, required BlockData blockData}) async {
    final collection = _getBlocksCollection(orgId: orgId, assessmentId: assessmentId);
    await collection.doc(blockID).update({
      'name': blockData.name,
      'role': blockData.role,
      'department': blockData.department,
      'emails': blockData.emails,
    });
  }

  // For now just 1 email doc per block.
  static Stream<QuerySnapshot<Map<String, dynamic>>> getBlockResultStream({required String? orgId, required String? assessmentId, required String blockID}) {
    final collectionPath = 'orgs/$orgId/assessments/$assessmentId/data';
    print('Block result stream collection path: $collectionPath (where blockId == $blockID)');

    final collection = _instance.collection('orgs').doc(orgId).collection('assessments').doc(assessmentId).collection('data');
    return collection.where('blockId', isEqualTo: blockID).limit(1).snapshots();
  }

  // 1 Block. BlockNotifier subscribes to this
  static Stream<DocumentSnapshot<Map<String, dynamic>>> getBlockStream({required String? orgId, String? assessmentId, required String blockID}) {
    final collection = _getBlocksCollection(orgId: orgId, assessmentId: assessmentId);
    return collection.doc(blockID).snapshots();
  }

  // All blocks in Collection
  static Stream<DocumentSnapshot<Map<String, dynamic>>> getAnalysisBlockStream({required String? orgId, String? assessmentId, required String blockId}) {
    final collection = _instance.collection('orgs').doc(orgId).collection('assessments').doc(assessmentId).collection('analysisBlocks');
    return collection.doc(blockId).snapshots();
  }

  // All blocks in Collection
  static Stream<QuerySnapshot> getBlocksStream({required String? orgId, String? assessmentId}) {
    final CollectionReference collection = _getBlocksCollection(orgId: orgId, assessmentId: assessmentId);
    return collection.snapshots();
  }

  // All blocks in Collection
  static Stream<QuerySnapshot> getAnalysisBlocksStream({required String? orgId, String? assessmentId}) {
    final collection = _instance.collection('orgs').doc(orgId).collection('assessments').doc(assessmentId).collection('analysisBlocks');
    return collection.snapshots();
  }

  // All connections in Collection
  static Stream<QuerySnapshot> getConnectionsStream({required String? orgId, String? assessmentId}) {
    final collection = _getConnectionsCollection(orgId: orgId, assessmentId: assessmentId);
    return collection.snapshots();
  }

  static Future<void> addConnection({required String? orgId, String? assessmentId, required Connection connection}) async {
    final collection = _getConnectionsCollection(orgId: orgId, assessmentId: assessmentId);
    await collection.doc(connection.id).set({
      'id': connection.id,
      'parentID': connection.parentId,
      'childID': connection.childId,
    });
  }

  static Future<void> deleteConnection({required String? orgId, String? assessmentId, required String connectionId}) async {
    final collection = _getConnectionsCollection(orgId: orgId, assessmentId: assessmentId);
    await collection.doc(connectionId).delete();
  }

  static Future<void> batchUpdatePositions({required String? orgId, String? assessmentId, required Map<String, Offset> positions}) async {
    print("Do batch update to Firestore!!");
    WriteBatch batch = _instance.batch();

    final collection = _getBlocksCollection(orgId: orgId, assessmentId: assessmentId);
    for (String blockID in positions.keys) {
      final docRef = collection.doc(blockID);
      batch.update(docRef, {
        'position': {'x': positions[blockID]!.dx, 'y': positions[blockID]!.dy},
      });
    }

    await batch.commit();
  }

  static Future<String> createAssessment({required String orgId, required String assessmentName}) async {
    try {
      final assessmentsRef = _instance.collection('orgs').doc(orgId).collection('assessments');

      // Check for existing assessment
      final existingQuery = await assessmentsRef.where('assessmentName', isEqualTo: assessmentName).get();

      if (existingQuery.docs.isNotEmpty) {
        throw Exception('Assessment with name "$assessmentName" already exists');
      }

      // Create assessment document
      final assessmentDoc = assessmentsRef.doc();
      await assessmentDoc.set({
        'assessmentName': assessmentName,
      });

      // Helper function to copy collection with same IDs
      Future<void> copyCollection({required CollectionReference sourceCollection, required CollectionReference targetCollection}) async {
        final sourceDocs = await sourceCollection.get();

        // Use batch for better performance
        final batch = _instance.batch();

        for (final doc in sourceDocs.docs) {
          // Use same document ID
          final targetDoc = targetCollection.doc(doc.id);
          batch.set(targetDoc, doc.data());
        }

        await batch.commit();
      }

      // Copy blocks collection
      await copyCollection(
        sourceCollection: _instance.collection('orgs').doc(orgId).collection('blocks'),
        targetCollection: assessmentDoc.collection('blocks'),
      );

      // Copy connections collection
      await copyCollection(
        sourceCollection: _instance.collection('orgs').doc(orgId).collection('connections'),
        targetCollection: assessmentDoc.collection('connections'),
      );

      return assessmentDoc.id;
    } catch (e) {
      // Rethrow with more orgId, assessmentId for debugging
      throw Exception('Failed to create assessment "$assessmentName": $e');
    }
  }

  static Future<void> createOrg({required String orgName}) async {
    final orgref = _instance.collection('orgs').doc();
    orgref.set({
      'orgName': orgName,
      'dateCreated': FieldValue.serverTimestamp(),
    });

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
