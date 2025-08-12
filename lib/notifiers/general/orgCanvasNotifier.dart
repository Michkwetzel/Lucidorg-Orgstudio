import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:logging/logging.dart';
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
        logger.info("Deletion detected");
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
    print("******Getting blocks for orgId: ${appState.orgId} and assessmentId: ${appState.assessmentId}");
    _subscribeToStream(FirestoreService.getBlocksStream(orgId: appState.orgId, assessmentId: appState.assessmentId));
  }

  void subscribeToAnalysisBlocks() {
    state = {};
    print("******Getting Analysis blocks for orgId: ${appState.orgId} and assessmentId: ${appState.assessmentId}");
    _subscribeToStream(FirestoreService.getAnalysisBlocksStream(orgId: appState.orgId, assessmentId: appState.assessmentId));
  }

  @override
  void dispose() {
    logger.info("OrgCanvasNotifier disposed - orgId: ${appState.orgId}");
    _blocksSubscription?.cancel();
    super.dispose();
  }

  Future<void> addBlock(String blockID, Offset position, {String? department}) async {
    // Mark as pending addition
    _pendingAdditions.add(blockID);

    // Update UI immediately
    state = {...state, blockID};
    _initialPositions[blockID] = position;

    try {
      await FirestoreService.addBlock(
        orgId: appState.orgId,
        assessmentId: appState.assessmentId,
        blockData: {
          'blockID': blockID,
          'position': {'x': position.dx, 'y': position.dy},
          if (department != null) 'department': department,
        },
      );
    } catch (e) {
      // If Firestore operation fails, revert UI changes
      _pendingAdditions.remove(blockID);
      state = Set<String>.from(state)..remove(blockID);
      _initialPositions.remove(blockID);
      rethrow;
    }
  }

  void deleteBlock(String blockID) async {
    // Mark as pending deletion
    _pendingDeletions.add(blockID);

    // Update UI immediately
    state = Set<String>.from(state)..remove(blockID);
    _initialPositions.remove(blockID);
    connectionManager.onBlockDelete(blockID);

    try {
      await FirestoreService.deleteBlock(orgId: appState.orgId, assessmentId: appState.assessmentId, blockID: blockID);
    } catch (e) {
      // If Firestore operation fails, revert UI changes
      _pendingDeletions.remove(blockID);
      state = {...state, blockID};
      // Note: You'd need to restore the position too
      rethrow;
    }
  }
}
