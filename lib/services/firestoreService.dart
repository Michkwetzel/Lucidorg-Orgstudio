import 'dart:async';
import 'dart:math';
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
    );
    _instance.settings = const Settings(
      persistenceEnabled: true,
      cacheSizeBytes: Settings.CACHE_SIZE_UNLIMITED,
    );
  }

  static FirebaseFirestore get instance => _instance;

  /// Logs guest access to the demo application
  /// Records timestamp, user agent, and attempts to capture location
  static Future<void> logGuestAccess() async {
    try {
      final accessCollection = _instance.collection('accessed');

      // Get user agent from web platform
      final userAgent = 'Web Browser'; // Basic user agent info

      final accessData = {
        'timestamp': FieldValue.serverTimestamp(),
        'userAgent': userAgent,
        'platform': 'web',
        // Location would need additional packages/permissions
        // For now we'll just mark it as guest access
        'accessType': 'guest',
      };

      await accessCollection.add(accessData);
    } catch (e) {
      // Silently fail - don't block user access if logging fails
      print('Failed to log guest access: $e');
    }
  }

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

  static Future<void> deleteBlock({required String? orgId, String? assessmentId, required String blockId}) async {
    final collection = _getBlocksCollection(orgId: orgId, assessmentId: assessmentId);
    await collection.doc(blockId).delete();
  }

  static Future<void> deleteAnalysisBlock({required String? orgId, String? assessmentId, required String blockId}) async {
    final collection = _instance.collection('orgs').doc(orgId).collection('assessments').doc(assessmentId).collection('analysisBlocks');
    await collection.doc(blockId).delete();
  }

  static Future<void> deleteBlockDataDocs({required String? orgId, required String? assessmentId, required String blockId}) async {
    final collection = _instance.collection('orgs').doc(orgId).collection('assessments').doc(assessmentId).collection('data');

    // Query all data docs for this block
    final querySnapshot = await collection.where('blockId', isEqualTo: blockId).get();

    if (querySnapshot.docs.isEmpty) {
      return; // No data docs to delete
    }

    // Use batch to delete all data docs efficiently
    final batch = _instance.batch();
    for (final doc in querySnapshot.docs) {
      batch.delete(doc.reference);
    }

    await batch.commit();
  }

  static Future<void> updateBlockPosition({required String? orgId, String? assessmentId, required String blockId, required Map<String, double> position}) async {
    final collection = _getBlocksCollection(orgId: orgId, assessmentId: assessmentId);
    await collection.doc(blockId).update({
      'position': position,
    });
  }

  static Future<void> updateAnalysisBlockPosition({required String? orgId, String? assessmentId, required String blockId, required Map<String, double> position}) async {
    final collection = _instance.collection('orgs').doc(orgId).collection('assessments').doc(assessmentId).collection('analysisBlocks');
    await collection.doc(blockId).update({
      'position': position,
    });
  }

  static Future<void> updateAnalysisBlockData({required String? orgId, String? assessmentId, required String blockId, required AnalysisBlockData blockData}) async {
    final collection = _instance.collection('orgs').doc(orgId).collection('assessments').doc(assessmentId).collection('analysisBlocks');
    await collection.doc(blockId).update({
      'blockName': blockData.blockName,
      'analysisBlockType': blockData.analysisBlockType.name,
      'analysisSubType': blockData.analysisSubType.name,
      'groupIds': blockData.groupIds,
    });
  }

  static Future<void> updateData({required String? orgId, String? assessmentId, required String blockId, required BlockData blockData}) async {
    final collection = _getBlocksCollection(orgId: orgId, assessmentId: assessmentId);
    await collection.doc(blockId).update({
      'name': blockData.name,
      'role': blockData.role,
      'department': blockData.department,
      'hierarchy': blockData.hierarchy.name,
      'emails': blockData.emails,
      'region': blockData.region,
      'subOffice': blockData.subOffice,
    });
  }

  // For now just 1 email doc per block.
  static Stream<QuerySnapshot<Map<String, dynamic>>> getBlockResultStream({required String? orgId, required String? assessmentId, required String blockId}) {
    // final collectionPath = 'orgs/$orgId/assessments/$assessmentId/data';
    // print('Block result stream collection path: $collectionPath (where blockId == $blockId)');

    final collection = _instance.collection('orgs').doc(orgId).collection('assessments').doc(assessmentId).collection('data');
    return collection.where('blockId', isEqualTo: blockId).limit(1).snapshots();
  }

  // Get ALL data docs for a block (for multi-email blocks)
  static Stream<QuerySnapshot<Map<String, dynamic>>> getAllBlockResultsStream({required String? orgId, required String? assessmentId, required String blockId}) {
    // final collectionPath = 'orgs/$orgId/assessments/$assessmentId/data';
    // print('All block results stream collection path: $collectionPath (where blockId == $blockId)');

    final collection = _instance.collection('orgs').doc(orgId).collection('assessments').doc(assessmentId).collection('data');
    return collection.where('blockId', isEqualTo: blockId).snapshots();
  }

  // 1 Block. BlockNotifier subscribes to this
  static Stream<DocumentSnapshot<Map<String, dynamic>>> getBlockStream({required String? orgId, String? assessmentId, required String blockId}) {
    final collection = _getBlocksCollection(orgId: orgId, assessmentId: assessmentId);
    return collection.doc(blockId).snapshots();
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
      'parentId': connection.parentId,
      'childId': connection.childId,
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
    for (String blockId in positions.keys) {
      final docRef = collection.doc(blockId);
      batch.update(docRef, {
        'position': {'x': positions[blockId]!.dx, 'y': positions[blockId]!.dy},
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
      'parentId': docRef1.id,
      'childId': docRef2.id,
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

  /// Copies all blocks from a source region to a target region, including their connections
  ///
  /// Parameters:
  /// - [orgId]: Organization ID
  /// - [assessmentId]: Optional assessment ID (if null, uses org-level blocks)
  /// - [sourceRegion]: Source region number (default: '1')
  /// - [targetRegion]: Target region number (e.g., '2', '3', etc.)
  /// - [xOffset]: Horizontal offset for positioning new blocks (default: 2000.0)
  ///
  /// Returns a map containing:
  /// - 'blocksCreated': Number of blocks copied
  /// - 'connectionsCreated': Number of connections copied
  static Future<Map<String, int>> copyRegionBlocksAndConnections({
    required String orgId,
    String? assessmentId,
    String sourceRegion = '1',
    required String targetRegion,
    double xOffset = 2000.0,
  }) async {
    try {
      final blocksCollection = _getBlocksCollection(orgId: orgId, assessmentId: assessmentId);
      final connectionsCollection = _getConnectionsCollection(orgId: orgId, assessmentId: assessmentId);

      // PHASE 1: Query and copy blocks
      final blocksQuery = await blocksCollection
          .where('region', isEqualTo: sourceRegion)
          .get();

      // Filter blocks with department == 'Office' (case-insensitive)
      final sourceBlocks = blocksQuery.docs.where((doc) {
        final data = doc.data();
        final department = (data['department'] as String? ?? '').toLowerCase();
        return department == 'office';
      }).toList();

      if (sourceBlocks.isEmpty) {
        return {'blocksCreated': 0, 'connectionsCreated': 0};
      }

      // Create mapping from old block IDs to new block IDs
      final Map<String, String> oldIdToNewId = {};
      WriteBatch batch = _instance.batch();
      int batchCount = 0;
      const int maxBatchSize = 500;

      // Create new blocks with updated region and position
      for (final blockDoc in sourceBlocks) {
        final oldBlockId = blockDoc.id;
        final newBlockId = blocksCollection.doc().id; // Generate new ID
        oldIdToNewId[oldBlockId] = newBlockId;

        final blockData = blockDoc.data();
        final position = blockData['position'] as Map<String, dynamic>?;
        final oldX = (position?['x'] as num?)?.toDouble() ?? 0.0;
        final oldY = (position?['y'] as num?)?.toDouble() ?? 0.0;

        // Copy all block data with updates
        final newBlockData = {
          ...blockData,
          'blockId': newBlockId, // Set blockId to match the new document ID
          'region': targetRegion,
          'position': {
            'x': oldX + xOffset,
            'y': oldY,
          },
        };

        batch.set(blocksCollection.doc(newBlockId), newBlockData);
        batchCount++;

        // Commit and start new batch if we hit the limit
        if (batchCount >= maxBatchSize) {
          await batch.commit();
          batch = _instance.batch(); // Create new batch
          batchCount = 0;
        }
      }

      // PHASE 2: Query and copy connections
      final sourceBlockIds = oldIdToNewId.keys.toList();

      // Get all connections where both parent and child are in source blocks
      final connectionsQuery = await connectionsCollection.get();
      final relevantConnections = connectionsQuery.docs.where((doc) {
        final data = doc.data();
        final parentId = data['parentId'] as String?;
        final childId = data['childId'] as String?;

        // Only include if both endpoints are in the source region blocks
        return parentId != null &&
               childId != null &&
               sourceBlockIds.contains(parentId) &&
               sourceBlockIds.contains(childId);
      }).toList();

      int connectionsCreated = 0;
      for (final connectionDoc in relevantConnections) {
        final data = connectionDoc.data();
        final oldParentId = data['parentId'] as String;
        final oldChildId = data['childId'] as String;

        // Map to new block IDs
        final newParentId = oldIdToNewId[oldParentId];
        final newChildId = oldIdToNewId[oldChildId];

        if (newParentId != null && newChildId != null) {
          final newConnectionId = connectionsCollection.doc().id;

          batch.set(connectionsCollection.doc(newConnectionId), {
            'id': newConnectionId,
            'parentId': newParentId,
            'childId': newChildId,
          });

          connectionsCreated++;
          batchCount++;

          // Commit and start new batch if we hit the limit
          if (batchCount >= maxBatchSize) {
            await batch.commit();
            batch = _instance.batch(); // Create new batch
            batchCount = 0;
          }
        }
      }

      // Commit any remaining operations
      if (batchCount > 0) {
        await batch.commit();
      }

      return {
        'blocksCreated': sourceBlocks.length,
        'connectionsCreated': connectionsCreated,
      };
    } catch (e) {
      throw Exception('Failed to copy region blocks and connections: $e');
    }
  }

  // ============================================================================
  // MOCK DATA GENERATION - DLA Piper Scenario
  // ============================================================================

  /// Region performance profiles (pillar score ranges 0-100)
  static const Map<String, Map<String, Map<String, double>>> _regionProfiles = {
    '1': {
      'alignment': {'min': 70.0, 'max': 75.0},
      'process': {'min': 62.0, 'max': 68.0},
      'people': {'min': 68.0, 'max': 73.0},
      'leadership': {'min': 70.0, 'max': 75.0},
    },
    '2': {
      'alignment': {'min': 65.0, 'max': 70.0},
      'process': {'min': 58.0, 'max': 64.0},
      'people': {'min': 62.0, 'max': 68.0},
      'leadership': {'min': 62.0, 'max': 68.0},
    },
    '3': {
      'alignment': {'min': 38.0, 'max': 45.0},
      'process': {'min': 45.0, 'max': 52.0},
      'people': {'min': 48.0, 'max': 55.0},
      'leadership': {'min': 45.0, 'max': 52.0},
    },
    '4': {
      'alignment': {'min': 55.0, 'max': 62.0},
      'process': {'min': 50.0, 'max': 58.0},
      'people': {'min': 52.0, 'max': 60.0},
      'leadership': {'min': 55.0, 'max': 62.0},
    },
    '5': {
      'alignment': {'min': 52.0, 'max': 60.0},
      'process': {'min': 58.0, 'max': 65.0},
      'people': {'min': 62.0, 'max': 68.0},
      'leadership': {'min': 60.0, 'max': 66.0},
    },
    '6': {
      'alignment': {'min': 56.0, 'max': 64.0},
      'process': {'min': 60.0, 'max': 67.0},
      'people': {'min': 65.0, 'max': 72.0},
      'leadership': {'min': 62.0, 'max': 68.0},
    },
    '7': {
      'alignment': {'min': 50.0, 'max': 58.0},
      'process': {'min': 35.0, 'max': 45.0},
      'people': {'min': 42.0, 'max': 50.0},
      'leadership': {'min': 45.0, 'max': 52.0},
    },
  };

  /// Hierarchy modifiers (added to base pillar scores)
  static const Map<String, Map<String, double>> _hierarchyModifiers = {
    'regionalDirector': {'min': 8.0, 'max': 12.0},
    'partner': {'min': 10.0, 'max': 15.0},
    'officeDirector': {'min': 6.0, 'max': 10.0},
    'officeManager': {'min': 2.0, 'max': 5.0},
    'teamLead': {'min': -2.0, 'max': 2.0},
    'team': {'min': -12.0, 'max': -8.0},
    'none': {'min': 0.0, 'max': 0.0},
  };

  /// Generates mock assessment data for a specific region
  ///
  /// Creates realistic data docs based on DLA Piper regional performance patterns.
  /// Blocks with hierarchy 'team' get 10 data docs, others get 1.
  ///
  /// Parameters:
  /// - [orgId]: Organization ID
  /// - [assessmentId]: Assessment ID
  /// - [region]: Target region ('1' through '7')
  /// - [department]: Optional department filter (e.g., 'Office')
  /// - [variationLevel]: How much individual responses vary (0-3)
  ///
  /// Returns: {'dataDocsCreated': count, 'blocksProcessed': count}
  static Future<Map<String, int>> generateMockAssessmentData({
    required String orgId,
    required String assessmentId,
    required String region,
    String? department,
    int variationLevel = 2,
  }) async {
    try {
      final blocksCollection = _getBlocksCollection(orgId: orgId, assessmentId: assessmentId);
      final dataCollection = _instance.collection('orgs').doc(orgId).collection('assessments').doc(assessmentId).collection('data');

      // Query blocks for this region
      var query = blocksCollection.where('region', isEqualTo: region);
      final blocksQuery = await query.get();

      // Filter by department if provided
      final blocks = department != null
          ? blocksQuery.docs.where((doc) {
              final data = doc.data();
              final dept = (data['department'] as String? ?? '').toLowerCase();
              return dept == department.toLowerCase();
            }).toList()
          : blocksQuery.docs.toList();

      if (blocks.isEmpty) {
        return {'dataDocsCreated': 0, 'blocksProcessed': 0};
      }

      WriteBatch batch = _instance.batch();
      int batchCount = 0;
      int dataDocsCreated = 0;
      const int maxBatchSize = 500;

      // Process each block
      for (final blockDoc in blocks) {
        final blockId = blockDoc.id;
        final blockData = blockDoc.data();

        final name = blockData['name'] as String? ?? '';
        final role = blockData['role'] as String? ?? '';
        final dept = blockData['department'] as String? ?? '';
        final hierarchyStr = blockData['hierarchy'] as String? ?? 'none';
        final regionStr = blockData['region'] as String? ?? '';
        final subOffice = blockData['subOffice'] as String? ?? '';

        // Determine number of data docs to create
        final numDataDocs = hierarchyStr == 'team' ? 10 : 1;

        // Generate data docs for this block
        for (int personIndex = 0; personIndex < numDataDocs; personIndex++) {
          final rawResults = _generateRawResults(
            region: region,
            hierarchy: hierarchyStr,
            personIndex: personIndex,
            variationLevel: variationLevel,
          );

          final dataDocId = dataCollection.doc().id;

          batch.set(dataCollection.doc(dataDocId), {
            'email': '',
            'name': '',
            'blockId': blockId,
            'submitted': true,
            'started': true,
            'sentAssessment': true,
            'rawResults': rawResults,
            'department': dept,
            'role': role,
            'hierarchy': hierarchyStr,
            'region': regionStr,
            'subOffice': subOffice,
          });

          dataDocsCreated++;
          batchCount++;

          // Commit and start new batch if we hit the limit
          if (batchCount >= maxBatchSize) {
            await batch.commit();
            batch = _instance.batch();
            batchCount = 0;
          }
        }
      }

      // Commit any remaining operations
      if (batchCount > 0) {
        await batch.commit();
      }

      return {
        'dataDocsCreated': dataDocsCreated,
        'blocksProcessed': blocks.length,
      };
    } catch (e) {
      throw Exception('Failed to generate mock assessment data: $e');
    }
  }

  /// Generates 37 raw results (question scores 1-7) based on regional patterns
  ///
  /// Works backwards from target pillar scores to individual questions while
  /// maintaining the mathematical relationships defined in the benchmark formulas.
  static List<int> _generateRawResults({
    required String region,
    required String hierarchy,
    required int personIndex,
    required int variationLevel,
  }) {
    final random = Random(DateTime.now().millisecondsSinceEpoch + personIndex);

    // Get base pillar scores for this region (0-100 scale)
    final profile = _regionProfiles[region];
    if (profile == null) {
      // Fallback to random if region not found
      return List.generate(37, (_) => random.nextInt(7) + 1);
    }

    // Apply hierarchy modifier
    final modifier = _hierarchyModifiers[hierarchy] ?? {'min': 0.0, 'max': 0.0};
    final modifierValue = modifier['min']! + random.nextDouble() * (modifier['max']! - modifier['min']!);

    // Calculate modified pillar scores (0-100)
    final alignmentScore = (profile['alignment']!['min']! + random.nextDouble() * (profile['alignment']!['max']! - profile['alignment']!['min']!)) + modifierValue;
    final processScore = (profile['process']!['min']! + random.nextDouble() * (profile['process']!['max']! - profile['process']!['min']!)) + modifierValue;
    final peopleScore = (profile['people']!['min']! + random.nextDouble() * (profile['people']!['max']! - profile['people']!['min']!)) + modifierValue;
    final leadershipScore = (profile['leadership']!['min']! + random.nextDouble() * (profile['leadership']!['max']! - profile['leadership']!['min']!)) + modifierValue;

    // Convert pillar scores (0-100) to 0-1 scale (as used in formulas)
    final alignment01 = (alignmentScore / 100.0).clamp(0.0, 1.0);
    final process01 = (processScore / 100.0).clamp(0.0, 1.0);
    final people01 = (peopleScore / 100.0).clamp(0.0, 1.0);
    final leadership01 = (leadershipScore / 100.0).clamp(0.0, 1.0);

    // Reverse engineer from pillars to indicators
    // Alignment pillar = (growthAlign * 0.3) + (orgAlign * 0.2) + (collabKPIs * 0.5)
    // Each indicator should be close to the pillar value with small variations
    final alignmentVariation = (random.nextDouble() - 0.5) * 0.15; // ±7.5%
    final growthAlign = (alignment01 * (1 + alignmentVariation)).clamp(0.0, 1.0);
    final orgAlign = (alignment01 * (1 - alignmentVariation * 0.3)).clamp(0.0, 1.0);
    final collabKPIs = (alignment01 * (1 + alignmentVariation * 0.5)).clamp(0.0, 1.0);

    // Process pillar = (alignedTech * 0.4) + (collabProcesses * 0.4) + (meetingEfficacy * 0.2)
    final processVariation = (random.nextDouble() - 0.5) * 0.15;
    final alignedTech = (process01 * (1 + processVariation)).clamp(0.0, 1.0);
    final collabProcesses = (process01 * (1 - processVariation * 0.3)).clamp(0.0, 1.0);
    final meetingEfficacy = (process01 * (1 + processVariation * 0.5)).clamp(0.0, 1.0);

    // People pillar = (crossFuncComms * 0.3) + (crossFuncAcc * 0.3) + (engagedCommunity * 0.4)
    final peopleVariation = (random.nextDouble() - 0.5) * 0.15;
    final crossFuncComms = (people01 * (1 + peopleVariation)).clamp(0.0, 1.0);
    final crossFuncAcc = (people01 * (1 - peopleVariation * 0.3)).clamp(0.0, 1.0);
    final engagedCommunity = (people01 * (1 + peopleVariation * 0.5)).clamp(0.0, 1.0);

    // Leadership pillar = (empoweredLeadership * 0.6) + (purposeDriven * 0.4)
    final leadershipVariation = (random.nextDouble() - 0.5) * 0.15;
    final empoweredLeadership = (leadership01 * (1 + leadershipVariation)).clamp(0.0, 1.0);
    final purposeDriven = (leadership01 * (1 - leadershipVariation * 0.3)).clamp(0.0, 1.0);

    // Symptom indicators (separate, not from pillars)
    final engagement = people01 * (0.8 + random.nextDouble() * 0.4); // Loosely correlated with people
    final productivity = process01 * (0.8 + random.nextDouble() * 0.4); // Loosely correlated with process

    // Generate questions from indicators
    // Each indicator = (q1 + q2 + q3) / 21 for main indicators
    // Each symptom = (q1 + q2) / 14 for symptoms

    final List<int> rawResults = [];

    // Helper to generate 3 questions from an indicator value (0-1 scale)
    List<int> questionsFromIndicator(double indicatorValue) {
      // indicator = (q1 + q2 + q3) / 21
      // So: q1 + q2 + q3 = indicator * 21
      final targetSum = (indicatorValue * 21.0).clamp(3.0, 21.0); // Min 3 (all 1s), max 21 (all 7s)

      // Distribute across 3 questions with variation
      final baseValue = targetSum / 3.0;
      final variation = variationLevel / 3.0;

      return List.generate(3, (_) {
        final value = baseValue + (random.nextDouble() - 0.5) * 2 * variation;
        return value.round().clamp(1, 7);
      });
    }

    // Helper for 2-question symptoms
    List<int> questionsFromSymptom(double symptomValue) {
      // symptom = (q1 + q2) / 14
      // So: q1 + q2 = symptom * 14
      final targetSum = (symptomValue * 14.0).clamp(2.0, 14.0);

      final baseValue = targetSum / 2.0;
      final variation = variationLevel / 2.0;

      return List.generate(2, (_) {
        final value = baseValue + (random.nextDouble() - 0.5) * 2 * variation;
        return value.round().clamp(1, 7);
      });
    }

    // Generate all 37 questions in order
    rawResults.addAll(questionsFromIndicator(growthAlign)); // Q0-2: Growth Alignment
    rawResults.addAll(questionsFromIndicator(orgAlign)); // Q3-5: Org Alignment
    rawResults.addAll(questionsFromIndicator(collabKPIs)); // Q6-8: Collab KPIs
    rawResults.addAll(questionsFromIndicator(crossFuncComms)); // Q9-11: Cross-Func Comms
    rawResults.addAll(questionsFromIndicator(crossFuncAcc)); // Q12-14: Cross-Func Accountability
    rawResults.addAll(questionsFromIndicator(engagedCommunity)); // Q15-17: Engaged Community
    rawResults.addAll(questionsFromIndicator(alignedTech)); // Q18-20: Aligned Tech
    rawResults.addAll(questionsFromIndicator(collabProcesses)); // Q21-23: Collab Processes
    rawResults.addAll(questionsFromIndicator(meetingEfficacy)); // Q24-26: Meeting Efficacy
    rawResults.addAll(questionsFromIndicator(empoweredLeadership)); // Q27-29: Empowered Leadership
    rawResults.addAll(questionsFromIndicator(purposeDriven)); // Q30-32: Purpose Driven
    rawResults.addAll(questionsFromSymptom(engagement)); // Q33-34: Engagement
    rawResults.addAll(questionsFromSymptom(productivity)); // Q35-36: Productivity

    return rawResults;
  }

  /// Fixes blockId fields to match document IDs
  ///
  /// Scans through org-level blocks (org/orgId/blocks) and assessment-level blocks
  /// (org/orgId/assessments/assessmentId/blocks) and updates the blockId field
  /// to equal the document ID.
  ///
  /// Parameters:
  /// - [orgId]: Organization ID
  /// - [assessmentId]: Optional assessment ID (if null, only fixes org-level blocks)
  ///
  /// Returns: {'blocksFixed': count}
  static Future<Map<String, int>> fixBlockIds({
    required String orgId,
    String? assessmentId,
  }) async {
    try {
      WriteBatch batch = _instance.batch();
      int batchCount = 0;
      int blocksFixed = 0;
      const int maxBatchSize = 500;

      // Fix org-level blocks
      final orgBlocksCollection = _instance.collection('orgs').doc(orgId).collection('blocks');
      final orgBlocksQuery = await orgBlocksCollection.get();

      for (final blockDoc in orgBlocksQuery.docs) {
        batch.update(blockDoc.reference, {'blockId': blockDoc.id});
        blocksFixed++;
        batchCount++;

        if (batchCount >= maxBatchSize) {
          await batch.commit();
          batch = _instance.batch();
          batchCount = 0;
        }
      }

      // Fix assessment-level blocks if assessmentId provided
      if (assessmentId != null) {
        final assessmentBlocksCollection = _instance
            .collection('orgs')
            .doc(orgId)
            .collection('assessments')
            .doc(assessmentId)
            .collection('blocks');
        final assessmentBlocksQuery = await assessmentBlocksCollection.get();

        for (final blockDoc in assessmentBlocksQuery.docs) {
          batch.update(blockDoc.reference, {'blockId': blockDoc.id});
          blocksFixed++;
          batchCount++;

          if (batchCount >= maxBatchSize) {
            await batch.commit();
            batch = _instance.batch();
            batchCount = 0;
          }
        }
      }

      // Commit any remaining operations
      if (batchCount > 0) {
        await batch.commit();
      }

      return {'blocksFixed': blocksFixed};
    } catch (e) {
      throw Exception('Failed to fix block IDs: $e');
    }
  }
}
