import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:platform_v2/notifiers/general/appStateNotifier.dart';
import 'package:platform_v2/services/firestoreService.dart';

class GroupData {
  final String id;
  final String groupName;
  final List<String> dataDocIds;
  final List<String> blockIds;
  final List<double> averagedRawResults;
  final String createdAt;

  const GroupData({
    required this.id,
    required this.groupName,
    required this.dataDocIds,
    required this.blockIds,
    required this.averagedRawResults,
    required this.createdAt,
  });

  factory GroupData.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return GroupData(
      id: doc.id,
      groupName: data['groupName'] ?? '',
      dataDocIds: (data['dataDocIds'] as List?)?.cast<String>() ?? [],
      blockIds: (data['blockIds'] as List?)?.cast<String>() ?? [],
      averagedRawResults: (data['averagedRawResults'] as List?)?.cast<double>() ?? [],
      createdAt: data['createdAt'] ?? '',
    );
  }
}

class GroupsNotifier extends ChangeNotifier {
  bool _dataLoaded = false;
  List<GroupData> _groups = [];
  AppStateNotifier appState;
  StreamSubscription<QuerySnapshot>? _groupsStreamSub;

  GroupsNotifier({required this.appState}) {
    _subscribeToGroups();
  }

  void _subscribeToGroups() {
    final stream = FirestoreService.getGroupsStream(
      orgId: appState.orgId, 
      assessmentId: appState.assessmentId
    );

    _groupsStreamSub = stream.listen((snapshot) {
      _groups = snapshot.docs.map((doc) => GroupData.fromFirestore(doc)).toList();
      _dataLoaded = true;
      notifyListeners();
    });
  }

  // Getters
  bool get dataLoaded => _dataLoaded;
  List<GroupData> get groups => _groups;

  @override
  void dispose() {
    _groupsStreamSub?.cancel();
    super.dispose();
  }
}