import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:platform_v2/config/enums.dart';
import 'package:platform_v2/dataClasses/analysisBlockData.dart';
import 'package:platform_v2/notifiers/general/appStateNotifier.dart';
import 'package:platform_v2/services/firestoreService.dart';

class AnalysisBlockNotifer extends ChangeNotifier {
  final String blockID;
  bool _dataLoaded = false;
  Offset _position = const Offset(0, 0);
  List<double> _averagedRawResults = [];
  AnalysisBlockData blockData = AnalysisBlockData.empty();

  AppStateNotifier appState;
  StreamSubscription<DocumentSnapshot<Map<String, dynamic>>>? _blockDataDocStreamSub;

  Timer? _debounceTimer;
  Timer? _groupsDebounceTimer;
  static const Duration _debounceDuration = Duration(milliseconds: 2000);

  AnalysisBlockNotifer({required this.blockID, required this.appState}) {
    final stream = FirestoreService.getAnalysisBlockStream(orgId: appState.orgId, assessmentId: appState.assessmentId, blockId: blockID);

    _blockDataDocStreamSub = stream.listen((snapshot) {
      if (snapshot.exists && snapshot.data() != null) {
        final data = snapshot.data()!;
        // Extract position with fallbacks
        final positionMap = data['position'] as Map<String, dynamic>?;
        _position = Offset(
          (positionMap?['x'] as num?)?.toDouble() ?? 0.0,
          (positionMap?['y'] as num?)?.toDouble() ?? 0.0,
        );

        blockData = AnalysisBlockData.fromMap(data);
        _dataLoaded = true;
        notifyListeners();
      }
    });
  }

  void updatePosition(Offset newPosition) async {
    if (!dataLoaded || _position != newPosition) {
      _position = newPosition;
      notifyListeners();

      _debounceTimer?.cancel();

      // Debounce before saving to firestore
      _debounceTimer = Timer(_debounceDuration, () async {
        print("Single doc upload");

        await FirestoreService.updateAnalysisBlockPosition(orgId: appState.orgId, assessmentId: appState.assessmentId, blockID: blockID, position: {'x': newPosition.dx, 'y': newPosition.dy});
      });
    }
  }

  void changeBlockType(AnalysisBlockType newType) async {
    if (blockData.analysisBlockType != newType) {
      blockData = blockData.copyWith(analysisBlockType: newType);
      notifyListeners();

      await FirestoreService.updateAnalysisBlockData(
        orgId: appState.orgId,
        assessmentId: appState.assessmentId,
        blockID: blockID,
        blockData: blockData,
      );
    }
  }

  void addGroup(String groupId) {
    if (!blockData.groupIds.contains(groupId)) {
      final updatedGroupIds = [...blockData.groupIds, groupId];
      blockData = blockData.copyWith(groupIds: updatedGroupIds);
      notifyListeners();
      _debouncedGroupUpdate();
    }
  }

  void removeGroup(String groupId) {
    if (blockData.groupIds.contains(groupId)) {
      final updatedGroupIds = blockData.groupIds.where((id) => id != groupId).toList();
      blockData = blockData.copyWith(groupIds: updatedGroupIds);
      notifyListeners();
      _debouncedGroupUpdate();
    }
  }

  void updateGroups(List<String> newGroupIds) {
    if (!_listEquals(blockData.groupIds, newGroupIds)) {
      blockData = blockData.copyWith(groupIds: newGroupIds);
      notifyListeners();
      _debouncedGroupUpdate();
    }
  }

  void _debouncedGroupUpdate() {
    _groupsDebounceTimer?.cancel();

    _groupsDebounceTimer = Timer(_debounceDuration, () async {
      await FirestoreService.updateAnalysisBlockData(
        orgId: appState.orgId,
        assessmentId: appState.assessmentId,
        blockID: blockID,
        blockData: blockData,
      );
    });
  }

  // Helper method to compare lists
  bool _listEquals<T>(List<T> a, List<T> b) {
    if (a.length != b.length) return false;
    for (int i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }

  // Getters
  bool get dataLoaded => _dataLoaded;
  Offset get position => _position;
  List<double> get averagedRawResults => _averagedRawResults;
  String get blockName => blockData.blockName;
  AnalysisBlockType get analysisBlockType => blockData.analysisBlockType;
  List<String> get groupIds => blockData.groupIds;

  @override
  void dispose() {
    _blockDataDocStreamSub?.cancel();
    _debounceTimer?.cancel();
    _groupsDebounceTimer?.cancel();
    super.dispose();
  }
}
