import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:platform_v2/dataClasses/blockData.dart';
import 'package:platform_v2/services/firestoreService.dart';

// Individual block notifier. Responsible for block state: position, data and selection
class BlockNotifier extends ChangeNotifier {
  final String blockID;
  final String? orgId;
  late Offset _position;
  bool positionLoaded = false;
  BlockData? _blockData;
  bool _selectionMode = false;
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
    required this.onPositionChanged,
  }) {
    // Get Block doc stream and listen to fields
    if (orgId != null) {
      blockStream = FirestoreService.getBlockStream(orgId!, blockID);

      _streamSubscription = blockStream.listen(
        (snapshot) {
          DocumentSnapshot<Map<String, dynamic>> doc = snapshot;
          // Check if document exists before accessing data
          if (doc.exists && doc.data() != null) {
            final data = doc.data()!;

            // Get new position from Firestore
            Offset newPosition = Offset(data['position']['x'] ?? 0, data['position']['y'] ?? 0);

            // Check if position has changed (only if position was previously loaded)
            bool positionChanged = positionLoaded && (_position != newPosition);

            // Check if block data has changed
            String name = data['name'] ?? '';
            String role = data['role'] ?? '';
            String department = data['department'] ?? '';
            List<String> emails = List<String>.from(data['emails'] ?? []);
            BlockData newBlockData = BlockData(name: name, role: role, department: department, emails: emails);
            bool dataChanged = _blockData != null && (_blockData != newBlockData);

            // Update if something actually changed or if this is the first load
            if (positionChanged || dataChanged || !positionLoaded) {
              if (!positionLoaded || positionChanged) {
                _position = newPosition;
                // print("Position for block $blockID updated");
              }

              if (_blockData == null || dataChanged) {
                _blockData = newBlockData;
                // print("Data for block $blockID updated");
              }

              if (!positionLoaded) {
                positionLoaded = true;
                // print("Initial load completed for block $blockID");
              }

              notifyListeners();
            } else {
              // print("No changes detected for block $blockID - skipping update");
            }
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
  bool get selectionMode => _selectionMode;

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

  void selectionModeEnable() {
    debugPrint('BlockNotifier: Enabling selection mode for $blockID');
    _selectionMode = true;
    notifyListeners();
  }

  void selectionModeDisable() {
    debugPrint('BlockNotifier: Disabling selection mode for $blockID');
    _selectionMode = false;
    notifyListeners();
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