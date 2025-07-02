import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:platform_v2/config/enums.dart';
import 'package:platform_v2/dataClasses/connection.dart';
import 'package:platform_v2/services/firestoreIdGenerator.dart';
import 'package:platform_v2/services/firestoreService.dart';

class ConnectionsState {
  final List<Connection> connections;
  final Map<String, Offset> blockPositions;

  ConnectionsState({
    this.connections = const [],
    this.blockPositions = const {},
  });

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
  StreamSubscription? _connectionSubscription;
  String? orgId;
  late ConnectionType _connectionFrom;
  late String _fromBlockId;
  bool _connectionMode = false;

  ConnectionManager({required this.orgId}) : super(ConnectionsState()) {
    _subscribeToConnections();
  }

  @override
  void dispose() {
    _connectionSubscription?.cancel();
    super.dispose();
  }

  void _subscribeToConnections() {
    _connectionSubscription?.cancel();
    print("1");
    if (orgId != null) {
      _connectionSubscription = FirestoreService.getConnectionsStream(orgId!).listen(
        (snapshot) {
          print("2");
          List<Connection> updatedConnections = [];
          for (final doc in snapshot.docs) {
            print("3");
            updatedConnections.add(Connection.fromFirestore(doc));
          }
          print(updatedConnections);
          state = state.copyWith(connections: updatedConnections);
        },
        onError: (error) {
          print("Error subscribing to connections: $error");
        },
      );
    }
  }

  bool get connectionMode => _connectionMode;

  void connectionModeEnable(String blockId, ConnectionType connectionType) {
    _connectionFrom = connectionType;
    _fromBlockId = blockId;
    _connectionMode = true;
  }

  void connectionModeDisable() {
    _connectionMode = false;
  }

  void createConnection(String toBlockId) {
    if (_connectionMode) {
      Connection newConnection;
      if (_connectionFrom == ConnectionType.parent) {
        newConnection = Connection(FirestoreIdGenerator.generate(), parentId: _fromBlockId, childId: toBlockId);
      } else {
        newConnection = Connection(FirestoreIdGenerator.generate(), parentId: toBlockId, childId: _fromBlockId);
      }
      connectionModeDisable();
      state = state.copyWith(connections: [...state.connections, newConnection]);
    }
  }

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
