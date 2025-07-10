import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:logging/logging.dart';
import 'package:platform_v2/notifiers/general/connectionsManager.dart';
import 'package:platform_v2/services/firestoreService.dart';
import 'dart:async';

// Takes care of What blocks are being built and displayed on canvas.
// Responsible for add and delete functions
// Canvas does not watch Block position. BlockNotifier does

class OrgCanvasNotifier extends StateNotifier<Set<String>> {
  final Logger logger = Logger('CanvasNotifier');
  final String orgId;
  Map<String, Offset> _initialPositions = {}; //This is a workaround to get over some issues haha
  StreamSubscription? _blocksSubscription;
  ConnectionManager connectionManager;
  bool _isInitialLoadComplete = false;

  OrgCanvasNotifier({required this.orgId, required this.connectionManager}) : super({}) {
    subscribeToBlocks();
  }

  bool get isInitialLoadComplete => _isInitialLoadComplete;
  Map<String, Offset> get initialPositions => _initialPositions;

  // Track pending operations to avoid duplicate updates
  Set<String> _pendingAdditions = {};
  Set<String> _pendingDeletions = {};

  void subscribeToBlocks() {
    _blocksSubscription?.cancel();

    _blocksSubscription = FirestoreService.getBlocksStream(orgId).listen(
      (snapshot) {
        bool hasAdditionsOrDeletions = false;

        for (final change in snapshot.docChanges) {
          if (change.type == DocumentChangeType.added) {
            // Skip if this was a local addition we're expecting
            if (_pendingAdditions.contains(change.doc.id)) {
              _pendingAdditions.remove(change.doc.id);
              continue;
            }
            hasAdditionsOrDeletions = true;
          } else if (change.type == DocumentChangeType.removed) {
            // Skip if this was a local deletion we're expecting
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
      },
      onError: (error) {
        logger.severe("Error subscribing to blocks: $error");
      },
    );
    _isInitialLoadComplete = true;
  }

  @override
  void dispose() {
    _blocksSubscription?.cancel();
    super.dispose();
  }

  Future<void> addBlock(String blockID, Offset position) async {
    // Mark as pending addition
    _pendingAdditions.add(blockID);

    // Update UI immediately
    state = {...state, blockID};
    _initialPositions[blockID] = position;

    try {
      await FirestoreService.addBlock(orgId, {
        'blockID': blockID,
        'position': {'x': position.dx, 'y': position.dy},
      });
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
      await FirestoreService.deleteBlock(orgId, blockID);
    } catch (e) {
      // If Firestore operation fails, revert UI changes
      _pendingDeletions.remove(blockID);
      state = {...state, blockID};
      // Note: You'd need to restore the position too
      rethrow;
    }
  }
}
