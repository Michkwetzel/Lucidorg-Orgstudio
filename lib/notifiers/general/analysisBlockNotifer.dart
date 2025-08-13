import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:platform_v2/notifiers/general/appStateNotifier.dart';
import 'package:platform_v2/services/firestoreService.dart';

class AnalysisBlockNotifer extends ChangeNotifier {
  final String blockID;
  bool positionLoaded = false;
  Offset _position = const Offset(0, 0);
  AppStateNotifier appState;
  // Add StreamSubscription to track subscription to the blocks doc
  StreamSubscription<DocumentSnapshot<Map<String, dynamic>>>? _blockDataDocStreamSub;
  late final Stream<DocumentSnapshot<Map<String, dynamic>>> _blockDataDocStream;

  AnalysisBlockNotifer({required this.blockID, required this.appState}) {
    _blockDataDocStream = FirestoreService.getAnalysisBlockStream(orgId: appState.orgId, assessmentId: appState.assessmentId, blockId: blockID);
    _blockDataDocStreamSub = _blockDataDocStream.listen(
      (snapshot) {
        DocumentSnapshot<Map<String, dynamic>> doc = snapshot;
        // Check if document exists before accessing data
        if (doc.exists && doc.data() != null) {
          final data = doc.data()!;
          Offset position = Offset(data['position']['x'] ?? 0, data['position']['y'] ?? 0);
          String blockName = data['blockName'] ?? '';
          String analysisBlockType = data['analysisBlockType'] ?? '';
        }
      },
    );
  }
}
