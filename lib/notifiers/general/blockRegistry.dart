import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:platform_v2/notifiers/general/blockNotifier.dart';

//App wide access to each blocksNotifier. Keeps one source of thruth
class BlockRegistry extends StateNotifier<Map<String, BlockNotifier>> {
  BlockRegistry() : super({});

  void registerBlock(String blockID, BlockNotifier notifier) {
    state = {...state, blockID: notifier};
  }

  void unregisterBlock(String blockID) {
    final newState = Map<String, BlockNotifier>.from(state);
    newState.remove(blockID);
    state = newState;
  }
}
