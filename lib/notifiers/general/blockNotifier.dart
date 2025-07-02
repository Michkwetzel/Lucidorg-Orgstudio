import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:platform_v2/dataClasses/blockData.dart';
import 'package:platform_v2/services/firestoreService.dart';

// Individual block notifier. Responsible for block state: position, data and connections
class BlockNotifier extends ChangeNotifier {
  final String blockID;
  final String? orgId;
  Offset _position;
  BlockData? _blockData;
  bool _connectionMode = false;
  final Function(String blockID, Offset position) onPositionChanged;

  // Add StreamSubscription to track subscription to the blocks doc
  StreamSubscription<DocumentSnapshot<Map<String, dynamic>>>? _streamSubscription;
  late final Stream<DocumentSnapshot<Map<String, dynamic>>> blockStream;

  // Timers for debouncing
  Timer? _debounceTimer;
  static const Duration _debounceDuration = Duration(milliseconds: 500);

  BlockNotifier({
    required this.blockID,
    required this.orgId,
    required Offset initialPosition,
    required this.onPositionChanged,
  }) : _position = initialPosition {
    // Get Block doc stream and listen to fields
    if (orgId != null) {
      blockStream = FirestoreService.getBlockStream(orgId!, blockID);

      _streamSubscription = blockStream.listen(
        (snapshot) {
          DocumentSnapshot<Map<String, dynamic>> doc = snapshot;
          // Check if document exists before accessing data
          if (doc.exists && doc.data() != null) {
            final data = doc.data()!;
            // Update Position
            if (data['position'] != null) {
              updatePositionFromStream(Offset(data['position']['x'], data['position']['y']));
            }
            // Update block data
            String name = data['name'] ?? '';
            String role = data['role'] ?? '';
            String department = data['department'] ?? '';
            List<String> emails = List<String>.from(data['emails'] ?? []);
            BlockData blockData = BlockData(name: name, role: role, department: department, emails: emails);
            updateDataFromStream(blockData);
          }
        },
        onError: (error) {
          debugPrint('BlockNotifier stream error: $error');
        },
      );
    }
  }

  // Getters with proper encapsulation
  Offset get position => _position;
  BlockData? get blockData => _blockData;
  bool get connectionMode => _connectionMode;

  void updatePosition(Offset newPosition) async {
    if (_position != newPosition) {
      _position = newPosition;
      notifyListeners();

      // call ConnectionManager
      onPositionChanged?.call(blockID, newPosition);

      _debounceTimer?.cancel();

      // Debounce before saving to firestore
      _debounceTimer = Timer(_debounceDuration, () async {
        if (orgId != null) {
          await FirestoreService.updatePosition(orgId!, blockID, {'x': newPosition.dx, 'y': newPosition.dy});
        }
      });
    }
  }

  void connectionModeEnable() {
    debugPrint('BlockNotifier: Enabling connection mode for $blockID');
    _connectionMode = true;
    notifyListeners();
  }

  void connectionModeDisable() {
    debugPrint('BlockNotifier: Disabling connection mode for $blockID');
    _connectionMode = false;
    notifyListeners();
  }

  void updatePositionFromStream(Offset newPosition) {
    // UI update only. Otherwise forever loop
    if (_position != newPosition) {
      _position = newPosition;
      notifyListeners();

      // call ConnectionManager
      onPositionChanged?.call(blockID, newPosition);
    }
  }

  void updateDataFromStream(BlockData blockData) {
    // UI update only
    if (_blockData != blockData) {
      _blockData = blockData;
      notifyListeners();
    }
  }

  void updateData(BlockData newData) {
    if (_blockData != newData) {
      _blockData = newData;
      notifyListeners();
      if (orgId != null) {
        FirestoreService.updateData(
          orgId!,
          blockID,
          newData,
        );
      }
    }
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    _streamSubscription?.cancel();
    _streamSubscription = null;
    super.dispose();
  }
}
