import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:platform_v2/dataClasses/blockParam.dart';
import 'package:platform_v2/notifiers/general/appStateNotifier.dart';
import 'package:platform_v2/services/firestoreService.dart';
import 'package:platform_v2/config/enums.dart';
import 'dart:async';

// class CanvasState {
//   final Set<BlockParams> blocks;

//   CanvasState({
//     required this.blocks,
//   });

//   CanvasState copyWith({
//     Set<BlockParams>? blocks,
//   }) {
//     return CanvasState(
//       blocks: blocks ?? this.blocks,
//     );
//   }
// }

class CanvasNotifier extends StateNotifier<Map<String, BlockParams>> {
  AppStateNotifier appStateNotifier;
  StreamSubscription? _blocksSubscription;

  CanvasNotifier({required this.appStateNotifier}) : super({});

  void subscribeToBlocks(String? orgId) {
    if (orgId != null) {
      _blocksSubscription = FirestoreService.getBlocksStream(orgId).listen((snapshot) {
        final blocks = Map<String, BlockParams>.fromEntries(
          snapshot.docs.map(
            (doc) => MapEntry(
              doc.id,
              BlockParams(blockId: doc.id, position: Offset(doc['position']['x'], doc['position']['y'])),
            ),
          ),
        );
        state = blocks;
      });
    }
  }

  @override
  void dispose() {
    _blocksSubscription?.cancel();
    super.dispose();
  }

  void addBlock(String blockId, Offset position) {
    state = {...state, blockId: BlockParams(blockId: blockId, position: position)};

    // String? orgId = appStateNotifier.orgId;
    //if add block then add doc to db
    //orgId ?? FirestoreService.addBlock(orgId!, {'blockId': blockId});
  }

  void deleteBlock(String blockId) {
    state = Map.from(state)..remove(blockId);
  }

  // void saveToDB() {
  //   for (var blockId in state.blockIds) {
  //     print(blockId);
  //   }
  // }
}
