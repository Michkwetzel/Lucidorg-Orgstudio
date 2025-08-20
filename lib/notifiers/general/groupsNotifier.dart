import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:platform_v2/notifiers/general/appStateNotifier.dart';
import 'package:platform_v2/services/firestoreService.dart';
import 'package:platform_v2/services/analysisDataService.dart';
import 'package:logging/logging.dart';

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
  static final Logger _logger = Logger('GroupsNotifier');
  
  bool _dataLoaded = false;
  List<GroupData> _groups = [];
  AppStateNotifier appState;
  StreamSubscription<QuerySnapshot>? _groupsStreamSub;
  
  // Email data caching for analysis mode
  Map<String, CachedEmailData> _emailCache = {}; // docId -> email data
  Set<String> _cachedDocIds = {}; // Track what's already cached
  bool _isAnalysisModeActive = false;
  bool _emailDataLoading = false;
  String? _emailDataError;

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
      
      // If analysis mode is active, update email cache with new/changed groups
      if (_isAnalysisModeActive) {
        _updateEmailCache(newGroups);
      }
      
      notifyListeners();
    });
  }

  // Getters
  bool get dataLoaded => _dataLoaded;
  List<GroupData> get groups => _groups;
  bool get isAnalysisModeActive => _isAnalysisModeActive;
  bool get emailDataLoading => _emailDataLoading;
  String? get emailDataError => _emailDataError;

  // Initialize analysis mode - lazy load all email data
  Future<void> initializeAnalysisMode() async {
    _logger.info('Initializing analysis mode - loading email data cache');
    _isAnalysisModeActive = true;
    
    // Check if we need to refresh the cache due to new groups
    bool needsRefresh = false;
    if (_emailCache.isEmpty) {
      needsRefresh = true;
      _logger.info('Cache is empty, needs initial load');
    } else {
      // Check if current groups match cached groups
      final currentGroupIds = _groups.map((g) => g.id).toSet();
      final cachedGroupIds = _emailCache.values.map((e) => e.groupId).toSet();
      
      if (!currentGroupIds.containsAll(cachedGroupIds) || !cachedGroupIds.containsAll(currentGroupIds)) {
        needsRefresh = true;
        _logger.info('Group mismatch detected - Current: $currentGroupIds, Cached: $cachedGroupIds');
      }
    }
    
    if (needsRefresh || _emailDataLoading || _emailDataError != null) {
      await _initializeEmailCache();
    } else {
      _logger.info('Cache is already up to date with ${_emailCache.length} documents');
    }
  }

  // Force refresh of email data cache
  Future<void> refreshEmailCache() async {
    if (!_isAnalysisModeActive) return;
    
    _logger.info('Refreshing email data cache');
    // Clear existing cache to force reload
    _emailCache.clear();
    _cachedDocIds.clear();
    await _initializeEmailCache();
  }

  // Exit analysis mode - keep cache for quick re-entry
  void exitAnalysisMode() {
    _logger.info('Exiting analysis mode - keeping email data cache');
    _isAnalysisModeActive = false;
    // Don't clear cache - keep it for quick re-entry
    notifyListeners();
  }

  // Force clear cache (for memory management)
  void clearAnalysisCache() {
    _logger.info('Clearing email data cache');
    _emailCache.clear();
    _cachedDocIds.clear();
    _emailDataLoading = false;
    _emailDataError = null;
    _isAnalysisModeActive = false;
    notifyListeners();
  }

  // Get email data for specific groups (main public API)
  Map<String, List<EmailDataPoint>> getEmailDataForGroups(List<String> groupIds) {
    final result = <String, List<EmailDataPoint>>{};
    
    for (final groupId in groupIds) {
      final emailsInGroup = _emailCache.values
          .where((email) => email.groupId == groupId)
          .map((cachedEmail) => cachedEmail.toEmailDataPoint())
          .toList();
      
      result[groupId] = emailsInGroup;
    }
    
    return result;
  }

  // Initialize email cache with all assessment data
  Future<void> _initializeEmailCache() async {
    if (_emailDataLoading) return;
    
    _emailDataLoading = true;
    _emailDataError = null;
    notifyListeners();

    try {
      final allDataDocIds = <String>[];
      final docIdToGroupId = <String, String>{};

      // Collect all dataDocIds from all groups
      for (final group in _groups) {
        for (final docId in group.dataDocIds) {
          allDataDocIds.add(docId);
          docIdToGroupId[docId] = group.id;
        }
      }

      _logger.info('Loading ${allDataDocIds.length} email documents for analysis cache');

      // Batch fetch all email data
      final emailDataPoints = await AnalysisDataService.fetchGroupRawData(
        orgId: appState.orgId!,
        assessmentId: appState.assessmentId!,
        dataDocIds: allDataDocIds,
      );

      // Build cache with group mappings
      _emailCache.clear();
      _cachedDocIds.clear();

      for (int i = 0; i < emailDataPoints.length; i++) {
        final emailData = emailDataPoints[i];
        final docId = allDataDocIds[i];
        final groupId = docIdToGroupId[docId];

        if (groupId == null) {
          _logger.warning('No group ID found for document $docId, skipping');
          continue;
        }

        final cachedEmail = CachedEmailData.fromEmailDataPoint(
          emailData,
          docId,
          groupId,
        );

        _emailCache[docId] = cachedEmail;
        _cachedDocIds.add(docId);
      }

      _logger.info('Email data cache initialized with ${_emailCache.length} documents');
      _emailDataLoading = false;
      _emailDataError = null;
    } catch (e) {
      _logger.severe('Failed to initialize email data cache: $e');
      _emailDataLoading = false;
      _emailDataError = e.toString();
    }

    notifyListeners();
  }

  // Update cache when groups change (incremental updates)
  Future<void> _updateEmailCache(List<GroupData> newGroups) async {
    if (_emailDataLoading) return;

    try {
      final newDataDocIds = <String>[];
      final newDocIdToGroupId = <String, String>{};
      final updatedGroupMappings = <String, String>{};

      // Find new dataDocIds and update group mappings
      for (final group in newGroups) {
        for (final docId in group.dataDocIds) {
          updatedGroupMappings[docId] = group.id;
          
          if (!_cachedDocIds.contains(docId)) {
            newDataDocIds.add(docId);
            newDocIdToGroupId[docId] = group.id;
          }
        }
      }

      // Update existing cached emails with new group mappings
      for (final docId in updatedGroupMappings.keys) {
        if (_emailCache.containsKey(docId)) {
          final newGroupId = updatedGroupMappings[docId];
          if (_emailCache[docId]!.groupId != newGroupId) {
            _emailCache[docId] = _emailCache[docId]!.copyWith(groupId: newGroupId);
          }
        }
      }

      // Fetch new email data if any
      if (newDataDocIds.isNotEmpty) {
        _logger.info('Fetching ${newDataDocIds.length} new email documents');
        
        final newEmailDataPoints = await AnalysisDataService.fetchGroupRawData(
          orgId: appState.orgId!,
          assessmentId: appState.assessmentId!,
          dataDocIds: newDataDocIds,
        );

        // Add new emails to cache
        for (int i = 0; i < newEmailDataPoints.length; i++) {
          final emailData = newEmailDataPoints[i];
          final docId = newDataDocIds[i];
          final groupId = newDocIdToGroupId[docId];

          if (groupId == null) {
            _logger.warning('No group ID found for document $docId during update, skipping');
            continue;
          }

          final cachedEmail = CachedEmailData.fromEmailDataPoint(
            emailData,
            docId,
            groupId,
          );

          _emailCache[docId] = cachedEmail;
          _cachedDocIds.add(docId);
        }

        _logger.info('Added ${newDataDocIds.length} new emails to cache');
        notifyListeners();
      }
    } catch (e) {
      _logger.warning('Failed to update email cache: $e');
    }
  }

  @override
  void dispose() {
    _groupsStreamSub?.cancel();
    super.dispose();
  }
}