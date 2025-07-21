import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:platform_v2/dataClasses/blockData.dart';
import 'package:platform_v2/dataClasses/connection.dart';
import 'package:platform_v2/dataClasses/firestoreContext.dart';

class FirestoreService {
  static late final FirebaseFirestore _instance;

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

  // Helper method to get the blocks collection based on context
  static CollectionReference<Map<String, dynamic>> _getBlocksCollection(FirestoreContext context) {
    if (context.assessmentId != null) {
      return _instance.collection('orgs').doc(context.orgId).collection('assessments').doc(context.assessmentId).collection('blocks');
    }
    return _instance.collection('orgs').doc(context.orgId).collection('blocks');
  }

  // Helper method to get the connections collection based on context
  static CollectionReference<Map<String, dynamic>> _getConnectionsCollection(FirestoreContext context) {
    if (context.assessmentId != null) {
      return _instance.collection('orgs').doc(context.orgId).collection('assessments').doc(context.assessmentId).collection('connections');
    }
    return _instance.collection('orgs').doc(context.orgId).collection('connections');
  }

  static Future<void> addBlock(FirestoreContext context, Map<String, dynamic> blockData) async {
    final collection = _getBlocksCollection(context);
    await collection.doc(blockData['blockID']).set({
      ...blockData,
    });
  }

  static Future<void> deleteBlock(FirestoreContext context, String blockID) async {
    final collection = _getBlocksCollection(context);
    await collection.doc(blockID).delete();
  }

  static Future<void> updatePosition(FirestoreContext context, String blockID, Map<String, double> position) async {
    final collection = _getBlocksCollection(context);
    await collection.doc(blockID).update({
      'position': position,
    });
  }

  static Future<void> updateData(FirestoreContext context, String blockID, BlockData blockData) async {
    final collection = _getBlocksCollection(context);
    await collection.doc(blockID).update({
      'name': blockData.name,
      'role': blockData.role,
      'department': blockData.department,
      'emails': blockData.emails,
    });
  }

  // 1 Block. BlockNotifier subscribes to this
  static Stream<DocumentSnapshot<Map<String, dynamic>>> getBlockStream(FirestoreContext context, String blockID) {
    final collection = _getBlocksCollection(context);
    return collection.doc(blockID).snapshots();
  }

  // All blocks in Collection
  static Stream<QuerySnapshot> getBlocksStream(FirestoreContext context) {
    final CollectionReference collection = _getBlocksCollection(context);
    return collection.snapshots();
  }

  // All connections in Collection
  static Stream<QuerySnapshot> getConnectionsStream(FirestoreContext context) {
    final collection = _getConnectionsCollection(context);
    return collection.snapshots();
  }

  static Future<void> addConnection(FirestoreContext context, Connection connection) async {
    final collection = _getConnectionsCollection(context);
    await collection.doc(connection.id).set({
      'id': connection.id,
      'parentID': connection.parentId,
      'childID': connection.childId,
    });
  }

  static Future<void> deleteConnection(FirestoreContext context, String connectionId) async {
    final collection = _getConnectionsCollection(context);
    await collection.doc(connectionId).delete();
  }

  static Future<void> batchUpdatePositions(FirestoreContext context, Map<String, Offset> positions) async {
    print("Do batch update to Firestore!!");
    WriteBatch batch = _instance.batch();

    final collection = _getBlocksCollection(context);
    for (String blockID in positions.keys) {
      final docRef = collection.doc(blockID);
      batch.update(docRef, {
        'position': {'x': positions[blockID]!.dx, 'y': positions[blockID]!.dy},
      });
    }

    await batch.commit();
  }

  static Future<String> createAssessment(String orgId, String assessmentName) async {
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

      return assessmentsRef.id;
    } catch (e) {
      // Rethrow with more context for debugging
      throw Exception('Failed to create assessment "$assessmentName": $e');
    }
  }

  static Future<void> createOrg(String orgName) async {
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
