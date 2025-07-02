import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:platform_v2/notifiers/general/connectionsManager.dart';
import 'package:platform_v2/services/firestoreService.dart';
import 'dart:async';

// Takes care of What blocks are being built and displayed on canvas.
// Responsible for add and delete functions

class CanvasNotifier extends StateNotifier<Set<String>> {
  String? orgId;
  Map<String, Offset> _initialPositions = {}; //This is a workaround to get over some issues haha
  StreamSubscription? _blocksSubscription;
  ConnectionManager connectionManager;
  bool _isInitialLoadComplete = false;

  CanvasNotifier({required this.orgId, required this.connectionManager}) : super({}) {
    subscribeToBlocks();
  }

  bool get isInitialLoadComplete => _isInitialLoadComplete;
  Map<String, Offset> get initialPositions => _initialPositions;

  void subscribeToBlocks() {
    print("Subscribe to: $orgId");
    if (orgId != null) {
      _blocksSubscription?.cancel();

      _blocksSubscription = FirestoreService.getBlocksStream(orgId!).listen(
        (snapshot) {
          bool hasAdditionsOrDeletions = false;

          for (final change in snapshot.docChanges) {
            if (change.type == DocumentChangeType.added) {
              // print("Document added: ${change.doc.id}");
              hasAdditionsOrDeletions = true;
            } else if (change.type == DocumentChangeType.removed) {
              print("Document removed: ${change.doc.id}");
              hasAdditionsOrDeletions = true;
            }
            // Ignore DocumentChangeType.modified
          }

          // Only update state if there were additions or deletions. Not if there are changes to position
          if (hasAdditionsOrDeletions) {
            Set<String> ids = {};
            Map<String, Offset> initialPositions = {};
            for (final doc in snapshot.docs) {
              initialPositions[doc.id] = Offset(doc['position']['x'], doc['position']['y']);
              ids.add(doc.id);
            }
            _initialPositions = initialPositions;
            _isInitialLoadComplete = true;
            state = ids;

            // Initialize block positions for connectionManager. This should always be up to date
            // connectionManager.setBlockPositions(initialPositions);
          }
        },
        onError: (error) {
          print("Error subscribing to blocks: $error");
        },
      );
    }
  }

  @override
  void dispose() {
    _blocksSubscription?.cancel();
    super.dispose();
  }

  void addBlock(String blockID, Offset position) async {
    await FirestoreService.addBlock(orgId!, {
      'blockID': blockID,
      'position': {'x': position.dx, 'y': position.dy},
    });
    state = {...state, blockID}; //Add Id to state
    initialPositions[blockID] = position; //Add initial position
  }

  void deleteBlock(String blockID) async {
    if (orgId != null) {
      await FirestoreService.deleteBlock(orgId!, blockID); //Delete from Firestore first.
    }
    state = Set<String>.from(state)..remove(blockID);
    initialPositions.remove(blockID);
  }
}
