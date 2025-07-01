import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:platform_v2/dataClasses/blockData.dart';
import 'package:platform_v2/services/firestoreService.dart';

// Individual block notifier. Responsible for block state: position, data and connections
class BlockNotifier extends ChangeNotifier {
  final String blockId;
  final String? orgId;
  Offset _position;
  BlockData? blockData;
  final Function(String blockId, Offset position)? onPositionChanged;

  // Add StreamSubscription to track subscription tp the blocks doc
  StreamSubscription<DocumentSnapshot<Map<String, dynamic>>>? _streamSubscription;
  late final Stream<DocumentSnapshot<Map<String, dynamic>>> blockStream;

  //Timers for debouncing
  Timer? _debounceTimer;
  static const Duration _debounceDuration = Duration(milliseconds: 500);

  BlockNotifier({
    required this.blockId,
    required this.orgId,
    this.blockData,
    this.onPositionChanged,
    Offset position = Offset.zero,
    String name = '',
    String department = '',
  }) : _position = position {
    // Get Block doc stream and listen to fields
    if (orgId != null) {
      blockStream = FirestoreService.getBlockStream(orgId!, blockId);

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

  Offset get position => _position;

  void updatePosition(Offset newPosition) async {
    _position = newPosition;
    notifyListeners();

    // call ConnetionManager
    onPositionChanged?.call(blockId, newPosition);

    _debounceTimer?.cancel();

    // Debounce before saving to firestore
    _debounceTimer = Timer(_debounceDuration, () async {
      if (orgId != null) {
        await FirestoreService.updatePosition(orgId!, blockId, {'x': newPosition.dx, 'y': newPosition.dy});
      }
    });
  }

  void updatePositionFromStream(Offset newPosition) {
    //UI update only. Otherwise forever loop
    _position = newPosition;
    notifyListeners();

    // call ConnetionManager
    onPositionChanged?.call(blockId, newPosition);
  }

  void updateDataFromStream(BlockData blockData) {
    //UI update only
    this.blockData = blockData;
    notifyListeners();
  }

  void updateData(BlockData newData) {
    blockData = newData;
    notifyListeners();
    if (orgId != null) {
      FirestoreService.updateData(
        orgId!,
        blockId,
        newData,
      );
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
