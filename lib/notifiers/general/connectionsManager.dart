import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:logging/logging.dart';
import 'package:platform_v2/config/enums.dart';
import 'package:platform_v2/dataClasses/connection.dart';
import 'package:platform_v2/services/firestoreIDGenerator.dart';
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
  Logger logger = Logger('ConnectionManager');

  StreamSubscription? _connectionSubscription;
  String? orgId;
  late ConnectionType _firstSelectedBlockType;
  late String _initiatingBlockID;
  bool _connectionMode = false;

  // Track pending operations to avoid duplicate updates
  Set<String> _pendingAdditions = {};
  Set<String> _pendingDeletions = {};

  ConnectionManager({required this.orgId}) : super(ConnectionsState()) {
    _subscribeToConnections();
  }

  @override
  void dispose() {
    _connectionSubscription?.cancel();
    super.dispose();
  }

  void _subscribeToConnections() {
    logger.info("Subscribing to connections");
    _connectionSubscription?.cancel();
    if (orgId != null) {
      _connectionSubscription = FirestoreService.getConnectionsStream(orgId!).listen(
        (snapshot) {
          bool hasRelevantChanges = false;

          // Process document changes efficiently
          for (final change in snapshot.docChanges) {
            final docId = change.doc.id;
            logger.info("Doc change type: ${change.type} for doc: $docId");

            if (change.type == DocumentChangeType.added) {
              // Skip if this was a local addition we're expecting
              if (_pendingAdditions.contains(docId)) {
                _pendingAdditions.remove(docId);
                continue;
              }
              hasRelevantChanges = true;
            } else if (change.type == DocumentChangeType.removed) {
              // Skip if this was a local deletion we're expecting
              if (_pendingDeletions.contains(docId)) {
                _pendingDeletions.remove(docId);
                continue;
              }
              hasRelevantChanges = true;
            } else if (change.type == DocumentChangeType.modified) {
              // Handle modifications - these are real changes from other users
              hasRelevantChanges = true;
            }
          }

          // Only update state if there were relevant changes
          if (hasRelevantChanges) {
            logger.info("Updating connections state");
            List<Connection> updatedConnections = [];
            for (final doc in snapshot.docs) {
              updatedConnections.add(Connection.fromFirestore(doc));
            }
            state = state.copyWith(connections: updatedConnections);
          }
        },
        onError: (error) {
          logger.severe("Error subscribing to connections: $error");
        },
      );
    }
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

      // Track pending addition and update UI immediately
      _pendingAdditions.add(newConnection.id);
      state = state.copyWith(connections: [...state.connections, newConnection]);

      // Then update Firestore
      FirestoreService.addConnection(orgId!, newConnection).catchError((error) {
        // If Firestore operation fails, revert UI changes
        _pendingAdditions.remove(newConnection.id);
        state = state.copyWith(
          connections: state.connections.where((conn) => conn.id != newConnection.id).toList(),
        );
        logger.severe("Failed to add connection: $error");
      });
    }
  }

  void createDirectConnection({required String childBlockID, required String parentBlockID}) {
    logger.info("Create Direct connection");
    Connection newConnection = Connection(FirestoreIdGenerator.generate(), parentId: parentBlockID, childId: childBlockID);

    // Track pending addition and update UI immediately
    _pendingAdditions.add(newConnection.id);
    state = state.copyWith(connections: [...state.connections, newConnection]);

    // Then update Firestore
    FirestoreService.addConnection(orgId!, newConnection).catchError((error) {
      // If Firestore operation fails, revert UI changes
      _pendingAdditions.remove(newConnection.id);
      state = state.copyWith(
        connections: state.connections.where((conn) => conn.id != newConnection.id).toList(),
      );
      logger.severe("Failed to add direct connection: $error");
    });
  }

  void addConnection(Connection newConnection) {
    state = state.copyWith(connections: [...state.connections, newConnection]);
  }

  void onBlockDelete(String blockID) {
    // Find connections to delete
    List<String> connectionsToDelete = [];
    for (var connection in state.connections) {
      if (connection.parentId == blockID || connection.childId == blockID) {
        connectionsToDelete.add(connection.id);
      }
    }

    // Delete each connection
    for (String connectionId in connectionsToDelete) {
      removeConnection(connectionId);
    }
  }

  void removeConnection(String connectionId) {
    // Track pending deletion and update UI immediately
    _pendingDeletions.add(connectionId);
    state = state.copyWith(
      connections: state.connections.where((conn) => conn.id != connectionId).toList(),
    );

    // Then update Firestore
    FirestoreService.deleteConnection(orgId!, connectionId).catchError((error) {
      // If Firestore operation fails, revert UI changes
      _pendingDeletions.remove(connectionId);
      // Note: Would need to restore the connection here - you'd need to keep a reference
      logger.severe("Failed to delete connection: $error");
    });
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
