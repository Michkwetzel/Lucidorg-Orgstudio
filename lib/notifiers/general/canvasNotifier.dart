import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:platform_v2/dataClasses/connection.dart';
import 'package:platform_v2/notifiers/general/connectionsManager.dart';
import 'package:platform_v2/services/firestoreService.dart';
import 'package:platform_v2/config/provider.dart';
import 'dart:async';

// Takes care of What blocks are being built and displayed on canvas.
// Responsible for add and delete functions
class CanvasNotifier extends StateNotifier<Set<String>> {
  String? orgId;
  Map<String, Offset> initialPositions = {}; //This is a workaround to get over some issues haha
  StreamSubscription? _blocksSubscription;
  ConnectionManager connectionManager;

  CanvasNotifier({required this.orgId, required this.connectionManager}) : super({}) {
    subscribeToBlocks();
  }

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
            Map<String, Offset> initialPositionsT = {};
            for (final doc in snapshot.docs) {
              initialPositionsT[doc.id] = Offset(doc['position']['x'], doc['position']['y']);
              ids.add(doc.id);
            }
            initialPositions = initialPositionsT;
            state = ids;

            // Initialize block positions for connectionManager. This should always be up to date
            connectionManager.setBlockPositions(initialPositionsT);
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

  void addBlock(String blockId, Offset position) async {
    await FirestoreService.addBlock(orgId!, {
      'blockId': blockId,
      'position': {'x': position.dx, 'y': position.dy},
    });
    state = {...state, blockId}; //Add Id to state
    initialPositions[blockId] = position; //Add initial position
  }

  void deleteBlock(String blockId) async {
    if (orgId != null) {
      await FirestoreService.deleteBlock(orgId!, blockId); //Delete from Firestore first.
    }
    state = Set<String>.from(state)..remove(blockId);
    initialPositions.remove(blockId);
  }
}
