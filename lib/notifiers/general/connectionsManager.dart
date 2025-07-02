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
  late String _initiatingBlockId;
  bool _isInConnectionMode = false;

  ConnectionManager({required this.orgId}) : super(ConnectionsState()) {
    _subscribeToConnections();
  }

  @override
  void dispose() {
    _connectionSubscription?.cancel();
    super.dispose();
  }

  void _subscribeToConnections() {
    print("Subscribe to connections coll");
    _connectionSubscription?.cancel();
    if (false) {
      _connectionSubscription = FirestoreService.getConnectionsStream(orgId!).listen(
        (snapshot) {
          List<Connection> updatedConnections = [];
          for (final doc in snapshot.docs) {
            updatedConnections.add(Connection.fromFirestore(doc));
          }
          state = state.copyWith(connections: updatedConnections);
        },
        onError: (error) {
          print("Error subscribing to connections: $error");
        },
      );
    }
  }

  bool get isInConnectionMode => _isInConnectionMode;
  String get initiatingBlockId => _initiatingBlockId;

  void connectionModeEnable(String initiatingBlockId, ConnectionType firstSelectedBlockType) {
    _firstSelectedBlockType = firstSelectedBlockType;
    _initiatingBlockId = initiatingBlockId;
    _isInConnectionMode = true;
  }

  void connectionModeDisable() {
    _isInConnectionMode = false;
  }

  void createConnection(String toBlockId) {
    if (_isInConnectionMode) {
      Connection newConnection;
      if (_firstSelectedBlockType == ConnectionType.parent) {
        newConnection = Connection(FirestoreIdGenerator.generate(), parentId: _initiatingBlockId, childId: toBlockId);
      } else {
        newConnection = Connection(FirestoreIdGenerator.generate(), parentId: toBlockId, childId: _initiatingBlockId);
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

  void updateBlockPosition(String blockID, Offset newPosition) {
    final updatedPositions = Map<String, Offset>.from(state.blockPositions);
    updatedPositions[blockID] = newPosition;
    state = state.copyWith(blockPositions: updatedPositions);
  }

  void setBlockPositions(Map<String, Offset> positions) {
    state = state.copyWith(blockPositions: positions);
  }
}
