import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:logging/logging.dart';
import 'package:platform_v2/dataClasses/blockData.dart';
import 'package:platform_v2/services/firestoreService.dart';

// Individual block notifier. Responsible for block state: position, data and selection
class BlockNotifier extends ChangeNotifier {
  Logger logger = Logger('BlockNotifier');

  final String blockID;
  final String orgId;
  late Offset _position;
  Set<String> _descendants = {};
  bool positionLoaded = false;
  BlockData? _blockData;
  bool _selectionMode = false;

  // Add StreamSubscription to track subscription to the blocks doc
  StreamSubscription<DocumentSnapshot<Map<String, dynamic>>>? _streamSubscription;
  late final Stream<DocumentSnapshot<Map<String, dynamic>>> blockStream;

  // Timers for debouncing
  Timer? _debounceTimer;
  Timer? _batchDebounceTimer;
  static const Duration _debounceDuration = Duration(milliseconds: 500);

  BlockNotifier({
    required this.blockID,
    required this.orgId,
  }) {
    // Get Block doc stream and listen to fields
    blockStream = FirestoreService.getBlockStream(orgId, blockID);

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
            logger.info("Block update state");
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

  // Getters with proper encapsulation
  Offset get position => _position;
  BlockData? get blockData => _blockData;
  bool get selectionMode => _selectionMode;
  Set<String> get descendants => _descendants;

  void updateDescendants(Set<String> descendants) {
    _descendants = descendants;
  }

  void updatePosition(Offset newPosition) async {
    if (!positionLoaded || _position != newPosition) {
      _position = newPosition;
      notifyListeners();

      _debounceTimer?.cancel();

      // Debounce before saving to firestore
      _debounceTimer = Timer(_debounceDuration, () async {
        await FirestoreService.updatePosition(orgId, blockID, {'x': newPosition.dx, 'y': newPosition.dy});
      });
    }
  }

  void updatePositionWithoutFirestore(Offset newPosition) {
    if (!positionLoaded || _position != newPosition) {
      _position = newPosition;
      notifyListeners();
    }
  }

  void batchUpdateDescendantPositions(Map<String, Offset> positions) {
    _batchDebounceTimer?.cancel();

    _batchDebounceTimer = Timer(_debounceDuration, () async {
      await FirestoreService.batchUpdatePositions(orgId, positions);
    });
  }

  void selectionModeEnable() {
    _selectionMode = true;
    notifyListeners();
  }

  void selectionModeDisable() {
    _selectionMode = false;
    notifyListeners();
  }

  void updateData(BlockData newData) {
    if (_blockData != newData) {
      _blockData = newData;
      notifyListeners();
      FirestoreService.updateData(
        orgId,
        blockID,
        newData,
      );
    }
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    _batchDebounceTimer?.cancel();
    _streamSubscription?.cancel();
    _streamSubscription = null;
    super.dispose();
  }
}
