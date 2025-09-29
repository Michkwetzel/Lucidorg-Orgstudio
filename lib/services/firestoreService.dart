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
    await collection.doc(blockData['blockId']).set({
      ...blockData,
    });
  }

  static Future<void> addAnalysisBlock({required String? orgId, String? assessmentId, required Map<String, dynamic> blockData}) async {
    final collection = _instance.collection('orgs').doc(orgId).collection('assessments').doc(assessmentId).collection('analysisBlocks');
    await collection.doc(blockData['blockId']).set({
      ...blockData,
    });
  }

  static Future<void> deleteBlock({required String? orgId, String? assessmentId, required String blockID}) async {
    final collection = _getBlocksCollection(orgId: orgId, assessmentId: assessmentId);
    await collection.doc(blockID).delete();
  }

  static Future<void> deleteAnalysisBlock({required String? orgId, String? assessmentId, required String blockID}) async {
    final collection = _instance.collection('orgs').doc(orgId).collection('assessments').doc(assessmentId).collection('analysisBlocks');
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
    final collection = _instance.collection('orgs').doc(orgId).collection('assessments').doc(assessmentId).collection('analysisBlocks');
    await collection.doc(blockID).update({
      'blockName': blockData.blockName,
      'analysisBlockType': blockData.analysisBlockType.name,
      'analysisSubType': blockData.analysisSubType.name,
      'groupIds': blockData.groupIds,
    });
  }

  static Future<void> updateData({required String? orgId, String? assessmentId, required String blockID, required BlockData blockData}) async {
    final collection = _getBlocksCollection(orgId: orgId, assessmentId: assessmentId);
    await collection.doc(blockID).update({
      'name': blockData.name,
      'role': blockData.role,
      'department': blockData.department,
      'hierarchy': blockData.hierarchy.name,
      'emails': blockData.emails,
    });
  }

  // For now just 1 email doc per block.
  static Stream<QuerySnapshot<Map<String, dynamic>>> getBlockResultStream({required String? orgId, required String? assessmentId, required String blockID}) {
    // final collectionPath = 'orgs/$orgId/assessments/$assessmentId/data';
    // print('Block result stream collection path: $collectionPath (where blockId == $blockID)');

    final collection = _instance.collection('orgs').doc(orgId).collection('assessments').doc(assessmentId).collection('data');
    return collection.where('blockId', isEqualTo: blockID).limit(1).snapshots();
  }

  // Get ALL data docs for a block (for multi-email blocks)
  static Stream<QuerySnapshot<Map<String, dynamic>>> getAllBlockResultsStream({required String? orgId, required String? assessmentId, required String blockID}) {
    // final collectionPath = 'orgs/$orgId/assessments/$assessmentId/data';
    // print('All block results stream collection path: $collectionPath (where blockId == $blockID)');

    final collection = _instance.collection('orgs').doc(orgId).collection('assessments').doc(assessmentId).collection('data');
    return collection.where('blockId', isEqualTo: blockID).snapshots();
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

  // All groups in Collection
  static Stream<QuerySnapshot> getGroupsStream({required String? orgId, String? assessmentId}) {
    final collection = _instance.collection('orgs').doc(orgId).collection('assessments').doc(assessmentId).collection('groups');
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
    // print("Do batch update to Firestore!!");
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

  static Map<String, Map<String, dynamic>> createQuestionFieldMap() {
    return {
      'q0': {
        'index': 0,
        'textHeading': "Our organization clearly communicates the 2-3 year growth strategy",
      },
      'q1': {
        'index': 1,
        'textHeading': "Teams coordinate their objectives to achieve the organization's roadmap for growth",
      },
      'q2': {
        'index': 2,
        'textHeading': "I understand how my role contributes to the organization's strategic objectives",
      },
      'q3': {
        'index': 3,
        'textHeading': "Our organization has systems that make key resources easily accessible",
      },
      'q4': {
        'index': 4,
        'textHeading': "Teams effectively navigate across departments for cross-functional work",
      },
      'q5': {
        'index': 5,
        'textHeading': "I can easily access the information I need to do my work effectively",
      },
      'q6': {
        'index': 6,
        'textHeading': "Our organization tracks shared performance metrics across departments",
      },
      'q7': {
        'index': 7,
        'textHeading': "Teams execute effectively around shared performance metrics",
      },
      'q8': {
        'index': 8,
        'textHeading': "My performance metrics connect to shared business objectives",
      },
      'q9': {
        'index': 9,
        'textHeading': "Our organization uses structured communication systems that help departments collaborate",
      },
      'q10': {
        'index': 10,
        'textHeading': "Teams communicate effectively to deliver on shared initiatives",
      },
      'q11': {
        'index': 11,
        'textHeading': "People I work with ensure relevant information reaches the right teams across the organization",
      },
      'q12': {
        'index': 12,
        'textHeading': "Our organization has processes for employees to hold leadership accountable",
      },
      'q13': {
        'index': 13,
        'textHeading': "Teams are accountable to each other for delivering on cross-functional initiatives",
      },
      'q14': {
        'index': 14,
        'textHeading': "I am able to hold people accountable regardless of their role or level",
      },
      'q15': {
        'index': 15,
        'textHeading': "Our organization uses systems that promote community participation across departments",
      },
      'q16': {
        'index': 16,
        'textHeading': "People across teams actively engage with each other regardless of role or level",
      },
      'q17': {
        'index': 17,
        'textHeading': "I take active responsibility for contributing to our workplace community",
      },
      'q18': {
        'index': 18,
        'textHeading': "Our organization clearly communicates how its technology strategy supports the business objectives",
      },
      'q19': {
        'index': 19,
        'textHeading': "Technology systems are integrated across departments, enabling teams to execute on shared objectives",
      },
      'q20': {
        'index': 20,
        'textHeading': "I am periodically asked to provide input and feedback on technology that affects shared work",
      },
      'q21': {
        'index': 21,
        'textHeading': "Our organization uses documented processes that effectively guide how teams work together on shared projects",
      },
      'q22': {
        'index': 22,
        'textHeading': "Teams effectively use collaborative processes to achieve shared goals",
      },
      'q23': {
        'index': 23,
        'textHeading': "It is clear how my role supports the objectives of cross-team initiatives",
      },
      'q24': {
        'index': 24,
        'textHeading': "Our organization follows effective processes for running meetings",
      },
      'q25': {
        'index': 25,
        'textHeading': "Teams effectively follow through on action items made during meetings",
      },
      'q26': {
        'index': 26,
        'textHeading': "I am able to participate meaningfully in the meetings I attend",
      },
      'q27': {
        'index': 27,
        'textHeading': "Our organization develops leadership capabilities in employees at all levels",
      },
      'q28': {
        'index': 28,
        'textHeading': "Teams execute on initiatives with different people taking the lead based on their expertise",
      },
      'q29': {
        'index': 29,
        'textHeading': "I make decisions in my role without constantly seeking approval from others",
      },
      'q30': {
        'index': 30,
        'textHeading': "Purpose is incorporated across the organization from onboarding to exit",
      },
      'q31': {
        'index': 31,
        'textHeading': "Teams execute initiatives in ways that directly support our organization's purpose",
      },
      'q32': {
        'index': 32,
        'textHeading': "I can explain how my work contributes to our organization's overall purpose",
      },
      'q33': {
        'index': 33,
        'textHeading': "Our organization regularly acts on feedback about employee experience",
      },
      'q34': {
        'index': 34,
        'textHeading': "I can raise concerns at work without fear of negative consequences",
      },
      'q35': {
        'index': 35,
        'textHeading': "Our organizations workflows minimize wasted time & effort",
      },
      'q36': {
        'index': 36,
        'textHeading': "Our team's workload is sustainable and lets us deliver high-quality work without feeling overwhelmed",
      },
    };
  }

  // Usage example with set():
  static void addQuestiontoDB() async {
    Map<String, Map<String, dynamic>> multipleChoiceQuestions = createQuestionFieldMap();

    await _instance.collection('questions').doc('v.2025-08-22').set(multipleChoiceQuestions);
  }
}
