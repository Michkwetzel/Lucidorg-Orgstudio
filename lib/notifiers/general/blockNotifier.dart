import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:platform_v2/dataClasses/blockData.dart';
import 'package:platform_v2/services/firestoreService.dart';

// Individual block notifier. Responsible for block movements and data functions
class BlockNotifier extends ChangeNotifier {
  final String blockId;
  final String? orgId;
  Offset _position;
  BlockData? blockData;
  late final Stream<DocumentSnapshot<Map<String, dynamic>>> blockStream;
  Timer? _debounceTimer;
  static const Duration _debounceDuration = Duration(milliseconds: 500);

  // Add StreamSubscription to track the subscription
  StreamSubscription<DocumentSnapshot<Map<String, dynamic>>>? _streamSubscription;

  BlockNotifier({
    required this.blockId,
    required this.orgId,
    this.blockData,
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
            if (data['position'] != null) {
              updatePositionFromStream(Offset(data['position']['x'], data['position']['y']));
            }
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

    _debounceTimer?.cancel();

    // Debounce before saving to firestore
    _debounceTimer = Timer(_debounceDuration, () async {
      if (orgId != null) {
        await FirestoreService.updatePosition(orgId!, blockId, {'x': newPosition.dx, 'y': newPosition.dy});
      }
    });
  }

  void updatePositionFromStream(Offset newPosition) {
    _position = newPosition;
    notifyListeners();
  }

  void updateData(BlockData newData) {
    blockData = newData;
    notifyListeners();
    if (orgId != null) {
      FirestoreService.updateData(orgId!, blockId, {'name': newData.name, 'role': newData.role, 'department': newData.department, newData.isMultipleEmails ? 'email': newData.email : null, 'isMultipleEmails': newData.isMultipleEmails ? true : false, 'updatedAt': FieldValue.serverTimestamp()});
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
