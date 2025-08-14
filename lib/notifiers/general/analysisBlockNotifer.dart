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
  static const Duration _debounceDuration = Duration(milliseconds: 500);

  AnalysisBlockNotifer({required this.blockID, required this.appState}) {
    final stream = FirestoreService.getAnalysisBlockStream(orgId: appState.orgId, assessmentId: appState.assessmentId, blockId: blockID);

    _blockDataDocStreamSub = stream.listen((snapshot) {
      if (snapshot.exists && snapshot.data() != null) {
        final data = snapshot.data()!;
        final blockData = AnalysisBlockData.fromMap(data);
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

  void addGroup(){

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
    super.dispose();
  }
}
