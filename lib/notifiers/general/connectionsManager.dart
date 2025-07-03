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
  late ConnectionType _firstSelectedBlockType;
  late String _initiatingBlockID;
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
    print("Getting Connections from Firestore");
    _connectionSubscription?.cancel();
    if (orgId != null) {
      _connectionSubscription = FirestoreService.getConnectionsStream(orgId!).listen(
        (snapshot) {
          List<Connection> updatedConnections = [];
          for (final doc in snapshot.docs) {
            updatedConnections.add(Connection.fromFirestore(doc));
          }

          // Check if the connections have actually changed before updating state
          if (_connectionsHaveChanged(state.connections, updatedConnections)) {
            state = state.copyWith(connections: updatedConnections);
          }
        },
        onError: (error) {
          print("Error subscribing to connections: $error");
        },
      );
    }
  }

  bool _connectionsHaveChanged(List<Connection> current, List<Connection> updated) {
    // Quick length check first
    if (current.length != updated.length) {
      return true;
    }

    // If lengths are the same, create a Set from current IDs for O(1) lookups
    final currentIds = <String>{};
    for (final connection in current) {
      currentIds.add(connection.id);
    }

    // Check if all updated IDs exist in current - early exit on first difference
    for (final connection in updated) {
      if (!currentIds.contains(connection.id)) {
        return true;
      }
    }

    return false;
  }

  bool get connectionMode => _connectionMode;
  String get initiatingBlockID => _initiatingBlockID;

  void connectionModeEnable(String initiatingBlockId, ConnectionType firstSelectedBlockType) {
    _firstSelectedBlockType = firstSelectedBlockType;
    _initiatingBlockID = initiatingBlockId;
    _connectionMode = true;
  }

  void connectionModeDisable() {
    _connectionMode = false;
  }

  void createConnection(String toBlockId) {
    if (_connectionMode) {
      Connection newConnection;
      if (_firstSelectedBlockType == ConnectionType.parent) {
        newConnection = Connection(FirestoreIdGenerator.generate(), parentId: _initiatingBlockID, childId: toBlockId);
      } else {
        newConnection = Connection(FirestoreIdGenerator.generate(), parentId: toBlockId, childId: _initiatingBlockID);
      }
      connectionModeDisable();

      FirestoreService.addConnection(orgId!, newConnection);
      state = state.copyWith(connections: [...state.connections, newConnection]);
    }
  }

  void addConnection(Connection newConnection) {
    state = state.copyWith(connections: [...state.connections, newConnection]);
  }

  void onBlockDelete(String blockID) {
    //Check if block has a connection if yes then delete
    for (var connection in state.connections) {
      if (connection.parentId == blockID || connection.childId == blockID) {
        removeConnection(connection.id);
      }
    }
  }

  void removeConnection(String connectionId) {
    FirestoreService.deleteConnection(orgId!, connectionId);
    state = state.copyWith(
      connections: state.connections.where((conn) => conn.id != connectionId).toList(),
    );
  }

  void updateBlockPosition(String blockID, Offset newPosition) {
    final updatedPositions = Map<String, Offset>.from(state.blockPositions);
    updatedPositions[blockID] = newPosition;
    state = state.copyWith(blockPositions: updatedPositions);
  }

  void setBlockPositions(Map<String, Offset> positions) {
    state = state.copyWith(blockPositions: positions);
  }
}
