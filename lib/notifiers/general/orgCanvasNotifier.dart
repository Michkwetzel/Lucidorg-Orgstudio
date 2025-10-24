import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:logging/logging.dart';
import 'package:platform_v2/config/enums.dart';
import 'package:platform_v2/dataClasses/analysisBlockData.dart';
import 'package:platform_v2/notifiers/general/appStateNotifier.dart';
import 'package:platform_v2/notifiers/general/connectionsManager.dart';
import 'package:platform_v2/services/firestoreService.dart';
import 'dart:async';

// Takes care of What blocks are being built and displayed on canvas.
// Responsible for add and delete functions
// Canvas does not watch Block position. BlockNotifier does
// BlockIds are all that matters. This determines which blocks are built. FiresStoreService takes care of the correct collections.

class OrgCanvasNotifier extends StateNotifier<Set<String>> {
  final Logger logger = Logger('OrgCanvasNotifier');
  AppStateNotifier appState;
  Map<String, Offset> _initialPositions = {}; //This is a workaround to get over some issues haha
  StreamSubscription? _blocksSubscription;
  ConnectionManager connectionManager;
  bool _isInitialLoadComplete = false;

  OrgCanvasNotifier({required this.appState, required this.connectionManager}) : super({}) {
    subscribeToBlocks();
  }

  bool get isInitialLoadComplete => _isInitialLoadComplete;
  Map<String, Offset> get initialPositions => _initialPositions;
  
  // Check if we're currently in analysis mode
  bool get _isAnalysisMode => appState.assessmentMode == AssessmentMode.assessmentAnalyze;

  // Track pending operations to avoid duplicate updates
  Set<String> _pendingAdditions = {};
  Set<String> _pendingDeletions = {};

  void _handleBlocksSnapshot(QuerySnapshot snapshot) {
    bool hasAdditionsOrDeletions = false;

    for (final change in snapshot.docChanges) {
      if (change.type == DocumentChangeType.added) {
        if (_pendingAdditions.contains(change.doc.id)) {
          _pendingAdditions.remove(change.doc.id);
          continue;
        }
        hasAdditionsOrDeletions = true;
      } else if (change.type == DocumentChangeType.removed) {
        if (_pendingDeletions.contains(change.doc.id)) {
          _pendingDeletions.remove(change.doc.id);
          continue;
        }
        // //logger.info("Deletion detected");
        hasAdditionsOrDeletions = true;
      }
    }

    if (hasAdditionsOrDeletions) {
      Set<String> ids = {};
      Map<String, Offset> initialPositions = {};
      for (final doc in snapshot.docs) {
        initialPositions[doc.id] = Offset(doc['position']['x'], doc['position']['y']);
        ids.add(doc.id);
      }
      _initialPositions = initialPositions;
      state = ids;
      connectionManager.setBlockPositions(initialPositions);
    }
  }

  // Generic subscription method
  void _subscribeToStream(Stream<QuerySnapshot> stream) {
    _blocksSubscription?.cancel();

    _blocksSubscription = stream.listen(
      _handleBlocksSnapshot,
      onError: (error) {
        logger.severe("Error subscribing to blocks: $error");
      },
    );
    _isInitialLoadComplete = true;
  }

  void subscribeToBlocks() {
    state = {};
    _subscribeToStream(FirestoreService.getBlocksStream(orgId: appState.orgId, assessmentId: appState.assessmentId));
  }

  void subscribeToAnalysisBlocks() {
    state = {};
    _subscribeToStream(FirestoreService.getAnalysisBlocksStream(orgId: appState.orgId, assessmentId: appState.assessmentId));
  }

  @override
  void dispose() {
    //logger.info("OrgCanvasNotifier disposed - orgId: ${appState.orgId}");
    _blocksSubscription?.cancel();
    super.dispose();
  }

  Future<void> addBlock(String blockId, Offset position, {String? department}) async {
    // Mark as pending addition
    _pendingAdditions.add(blockId);

    // Update UI immediately
    state = {...state, blockId};
    _initialPositions[blockId] = position;

    try {
      if (_isAnalysisMode) {
        // Create analysis block with default settings
        // Create default analysis block data
        final analysisBlockData = AnalysisBlockData(
          blockName: 'New Analysis Block',
          analysisBlockType: AnalysisBlockType.none, // Start unselected
          analysisSubType: AnalysisSubType.none,
          groupIds: [],
          selectedQuestions: Set<int>.from(List.generate(37, (i) => i + 1)),
          selectedIndicators: Set<Benchmark>.from(indicators()),
          chartType: ChartType.bar,
        );
        
        await FirestoreService.addAnalysisBlock(
          orgId: appState.orgId,
          assessmentId: appState.assessmentId,
          blockData: {
            'blockId': blockId,
            'position': {'x': position.dx, 'y': position.dy},
            ...analysisBlockData.toMap(),
          },
        );
      } else {
        // Create regular block
        await FirestoreService.addBlock(
          orgId: appState.orgId,
          assessmentId: appState.assessmentId,
          blockData: {
            'blockId': blockId,
            'position': {'x': position.dx, 'y': position.dy},
            if (department != null) 'department': department,
          },
        );
      }
    } catch (e) {
      // If Firestore operation fails, revert UI changes
      _pendingAdditions.remove(blockId);
      state = Set<String>.from(state)..remove(blockId);
      _initialPositions.remove(blockId);
      rethrow;
    }
  }

  void deleteBlock(String blockId) async {
    // Mark as pending deletion
    _pendingDeletions.add(blockId);

    // Update UI immediately
    state = Set<String>.from(state)..remove(blockId);
    _initialPositions.remove(blockId);

    // Only handle connections for regular blocks (analysis blocks don't use connections)
    if (!_isAnalysisMode) {
      connectionManager.onBlockDelete(blockId);
    }

    try {
      if (_isAnalysisMode) {
        await FirestoreService.deleteAnalysisBlock(orgId: appState.orgId, assessmentId: appState.assessmentId, blockId: blockId);
      } else {
        // Delete associated data docs if in assessmentBuild mode
        if (appState.assessmentMode == AssessmentMode.assessmentBuild && appState.assessmentId != null) {
          await FirestoreService.deleteBlockDataDocs(orgId: appState.orgId, assessmentId: appState.assessmentId, blockId: blockId);
        }

        await FirestoreService.deleteBlock(orgId: appState.orgId, assessmentId: appState.assessmentId, blockId: blockId);
      }
    } catch (e) {
      // If Firestore operation fails, revert UI changes
      _pendingDeletions.remove(blockId);
      state = {...state, blockId};
      // Note: You'd need to restore the position too
      rethrow;
    }
  }
}
