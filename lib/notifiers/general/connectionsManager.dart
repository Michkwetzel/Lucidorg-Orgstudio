import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:logging/logging.dart';
import 'package:platform_v2/config/provider.dart';
import 'package:platform_v2/dataClasses/connection.dart';
import 'package:platform_v2/dataClasses/firestoreContext.dart';
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
  final FirestoreContext context;

  // Track pending operations to avoid duplicate updates
  Set<String> _pendingAdditions = {};
  Set<String> _pendingDeletions = {};

  //Quick lookup for children
  Map<String, Set<String>> get parentAndChildren => _buildParentToChildrenMap(state.connections);

  ConnectionManager({required this.context}) : super(ConnectionsState()) {
    _subscribeToConnections();
  }

  @override
  void dispose() {
    _connectionSubscription?.cancel();
    super.dispose();
  }

  void _subscribeToConnections() {
    _connectionSubscription?.cancel();
    _connectionSubscription = FirestoreService.getConnectionsStream(context).listen(
      (snapshot) {
        bool hasRelevantChanges = false;

        // Process document changes efficiently
        for (final change in snapshot.docChanges) {
          final docId = change.doc.id;

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

  Map<String, Set<String>> _buildParentToChildrenMap(List<Connection> connections) {
    Map<String, Set<String>> parentToChildren = {};

    for (Connection conn in connections) {
      parentToChildren.putIfAbsent(conn.parentId, () => <String>{}).add(conn.childId);
    }

    return parentToChildren;
  }

  void createDirectConnection({required String childBlockID, required String parentBlockID}) {
    logger.info("Create Direct connection");
    Connection newConnection = Connection(FirestoreIdGenerator.generate(), parentId: parentBlockID, childId: childBlockID);

    // Track pending addition and update UI immediately
    _pendingAdditions.add(newConnection.id);
    state = state.copyWith(connections: [...state.connections, newConnection]);

    // Then update Firestore
    FirestoreService.addConnection(context, newConnection).catchError((error) {
      // If Firestore operation fails, revert UI changes

      _pendingAdditions.remove(newConnection.id);
      state = state.copyWith(
        connections: state.connections.where((conn) => conn.id != newConnection.id).toList(),
      );

      logger.severe("Failed to add direct connection: $error");
    });
  }

  void onBlockDelete(String blockID) {
    // Find connections to delete and then delete
    for (var connection in state.connections) {
      if (connection.parentId == blockID || connection.childId == blockID) {
        removeConnection(connection.id);
      }
    }
  }

  void removeConnection(String connectionId) {
    // Track pending deletion and update UI immediately
    _pendingDeletions.add(connectionId);
    state = state.copyWith(
      connections: state.connections.where((conn) => conn.id != connectionId).toList(),
    );

    // Then update Firestore
    FirestoreService.deleteConnection(context, connectionId).catchError((error) {
      // If Firestore operation fails, revert UI changes
      _pendingDeletions.remove(connectionId);
      // Note: Would need to restore the connection here - you'd need to keep a reference
      logger.severe("Failed to delete connection: $error");
    });
  }

  void setBlockPositions(Map<String, Offset> positions) {
    state = state.copyWith(blockPositions: positions);
  }
}
