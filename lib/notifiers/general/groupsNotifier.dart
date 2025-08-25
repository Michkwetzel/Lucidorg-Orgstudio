import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:platform_v2/notifiers/general/appStateNotifier.dart';
import 'package:platform_v2/services/firestoreService.dart';
import 'package:logging/logging.dart';

class GroupData {
  final String id;
  final String groupName;
  final List<String> blockIds;
  final List<double> averagedRawResults;
  final String createdAt;

  const GroupData({
    required this.id,
    required this.groupName,
    required this.blockIds,
    required this.averagedRawResults,
    required this.createdAt,
  });

  factory GroupData.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return GroupData(
      id: doc.id,
      groupName: data['groupName'] ?? '',
      blockIds: (data['blockIds'] as List?)?.cast<String>() ?? [],
      averagedRawResults: (data['averagedRawResults'] as List?)?.cast<double>() ?? [],
      createdAt: data['createdAt'] ?? '',
    );
  }
}

class GroupsNotifier extends ChangeNotifier {
  static final Logger _logger = Logger('GroupsNotifier');
  
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
      final newGroups = snapshot.docs.map((doc) => GroupData.fromFirestore(doc)).toList();
      _groups = newGroups;
      _dataLoaded = true;
      _logger.info('Loaded ${_groups.length} groups');
      notifyListeners();
    });
  }

  // Getters
  bool get dataLoaded => _dataLoaded;
  List<GroupData> get groups => _groups;

  /// Get a specific group by ID
  GroupData? getGroup(String groupId) {
    try {
      return _groups.firstWhere((group) => group.id == groupId);
    } catch (e) {
      _logger.warning('Group $groupId not found');
      return null;
    }
  }

  /// Simple method to reload groups from Firestore
  Future<void> loadGroups() async {
    try {
      _logger.info('Loading groups from Firestore');
      final snapshot = await FirestoreService.instance
          .collection('orgs')
          .doc(appState.orgId)
          .collection('assessments')
          .doc(appState.assessmentId)
          .collection('groups')
          .get();
      
      _groups = snapshot.docs.map((doc) => GroupData.fromFirestore(doc)).toList();
      _dataLoaded = true;
      _logger.info('Loaded ${_groups.length} groups');
      notifyListeners();
    } catch (e) {
      _logger.severe('Failed to load groups: $e');
      rethrow;
    }
  }

  @override
  void dispose() {
    _groupsStreamSub?.cancel();
    super.dispose();
  }
}