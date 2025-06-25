import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:platform_v2/services/firestoreService.dart';
import 'dart:async';

class CanvasState {
  final Set<String> blockIds;

  CanvasState({
    required this.blockIds,
  });

  CanvasState copyWith({
    Set<String>? blockIds,
  }) {
    return CanvasState(
      blockIds: blockIds ?? this.blockIds,
    );
  }
}

class CanvasNotifier extends StateNotifier<CanvasState> {
  final String? orgId;
  StreamSubscription? _blocksSubscription;

  CanvasNotifier({required this.orgId}) : super(CanvasState(blockIds: {})) {
    _subscribeToBlocks();
  }

  void _subscribeToBlocks() {
    print("Subscribing to orgId: $orgId");
    if (orgId != null) {
      _blocksSubscription = FirestoreService.getBlocksStream(orgId!).listen((snapshot) {
        final blockIds = snapshot.docs.map((doc) => doc.id).toSet();
        state = state.copyWith(blockIds: blockIds);
      });
    }
  }

  @override
  void dispose() {
    _blocksSubscription?.cancel();
    super.dispose();
  }

  void addBlock(String blockId) {
    state = state.copyWith(
      blockIds: {...state.blockIds, blockId},
    );
  }

  void deleteBlock(String blockId) {
    final newBlockIds = Set<String>.from(state.blockIds)..remove(blockId);
    state = state.copyWith(blockIds: newBlockIds);
  }

  void saveToDB() {
    for (var blockId in state.blockIds) {
      print(blockId);
    }
  }

  List<String> get blockIds => state.blockIds.toList();
}
