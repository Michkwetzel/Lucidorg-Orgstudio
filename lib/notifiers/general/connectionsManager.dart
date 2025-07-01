import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:platform_v2/dataClasses/connection.dart';

class ConnectionsState {
  final List<Connection> connections;
  final Map<String, Offset> blockPositions;

  ConnectionsState({this.connections = const [], this.blockPositions = const {}});

  ConnectionsState copyWith({
    List<Connection>? connections,
    Map<String, Offset>? blockPositions,
  }) {
    return ConnectionsState(
      connections: connections ?? this.connections,
      blockPositions: blockPositions ?? this.blockPositions,
    );
  }
}

class ConnectionManager extends StateNotifier<ConnectionsState> {
  ConnectionManager() : super(ConnectionsState());

  void addConnection(Connection newConnection) {
    state = state.copyWith(connections: [...state.connections, newConnection]);
  }

  void removeConnection(String connectionId) {
    state = state.copyWith(
      connections: state.connections.where((conn) => conn.id != connectionId).toList(),
    );
  }

  void updateBlockPosition(String blockId, Offset newPosition) {
    final updatedPositions = Map<String, Offset>.from(state.blockPositions);
    updatedPositions[blockId] = newPosition;
    state = state.copyWith(blockPositions: updatedPositions);
  }

  void setBlockPositions(Map<String, Offset> positions) {
    state = state.copyWith(blockPositions: positions);
  }
}
