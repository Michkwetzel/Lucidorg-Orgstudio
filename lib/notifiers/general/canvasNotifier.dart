import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:platform_v2/services/firestoreIdGenerator.dart';

class Connection {
  final String fromBlockId;
  final String toBlockId;

  Connection({required this.fromBlockId, required this.toBlockId});
}

class CanvasState {
  final Set<String> blockIds;
  final List<Connection> connections;

  CanvasState({
    required this.blockIds,
    required this.connections,
  });

  CanvasState copyWith({
    Set<String>? blockIds,
    List<Connection>? connections,
  }) {
    return CanvasState(
      blockIds: blockIds ?? this.blockIds,
      connections: connections ?? this.connections,
    );
  }
}

class CanvasNotifier extends StateNotifier<CanvasState> {
  CanvasNotifier() : super(_createInitialState());

  static CanvasState _createInitialState() {
    final block1Id = FirestoreIdGenerator.generate();
    final block2Id = FirestoreIdGenerator.generate();
    final block3Id = FirestoreIdGenerator.generate();

    return CanvasState(
      blockIds: {block1Id, block2Id, block3Id},
      connections: [],
    );
  }

  void addBlock(String blockId) {
    state = state.copyWith(
      blockIds: {...state.blockIds, blockId},
    );
  }

  void deleteBlock(String blockId) {
    final newBlockIds = Set<String>.from(state.blockIds)..remove(blockId);
    final newConnections = state.connections.where((conn) => conn.fromBlockId != blockId && conn.toBlockId != blockId).toList();

    state = state.copyWith(
      blockIds: newBlockIds,
      connections: newConnections,
    );
  }

  void addConnection(String fromBlockId, String toBlockId) {
    if (state.blockIds.contains(fromBlockId) && state.blockIds.contains(toBlockId)) {
      final newConnection = Connection(fromBlockId: fromBlockId, toBlockId: toBlockId);
      state = state.copyWith(
        connections: [...state.connections, newConnection],
      );
    }
  }

  void removeConnection(String fromBlockId, String toBlockId) {
    final newConnections = state.connections.where((conn) => !(conn.fromBlockId == fromBlockId && conn.toBlockId == toBlockId)).toList();

    state = state.copyWith(connections: newConnections);
  }

  void saveToDB() {
    for (var blockId in state.blockIds) {
      print(blockId);
    }
  }

  List<String> get blockIds => state.blockIds.toList();
  List<Connection> get connections => state.connections;
}
