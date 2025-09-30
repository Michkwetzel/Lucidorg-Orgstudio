import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:platform_v2/config/enums.dart';
import 'package:platform_v2/dataClasses/analysisBlockData.dart';
import 'package:platform_v2/notifiers/general/appStateNotifier.dart';
import 'package:platform_v2/notifiers/general/groupsNotifier.dart';
import 'package:platform_v2/notifiers/general/blockNotifier.dart';
import 'package:platform_v2/services/firestoreService.dart';

class AnalysisBlockNotifer extends ChangeNotifier {
  final String blockID;
  final GroupsNotifier groupsNotifier;
  bool _dataLoaded = false;
  bool _isDragging = false;
  Offset _position = const Offset(0, 0);
  AnalysisBlockData blockData = AnalysisBlockData.empty();

  AppStateNotifier appState;
  StreamSubscription<DocumentSnapshot<Map<String, dynamic>>>? _blockDataDocStreamSub;

  Timer? _debounceTimer;
  Timer? _groupsDebounceTimer;
  Timer? _filtersDebounceTimer;
  static const Duration _debounceDuration = Duration(milliseconds: 2000);
  static const Duration _filtersDebounceDuration = Duration(milliseconds: 10000);

  AnalysisBlockNotifer({required this.blockID, required this.appState, required this.groupsNotifier}) {
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

  /// Simple method to get group data for this analysis block
  List<GroupData> getSelectedGroups() {
    return blockData.groupIds
        .map((groupId) => groupsNotifier.getGroup(groupId))
        .where((group) => group != null)
        .cast<GroupData>()
        .toList();
  }

  /// Get analysis data from BlockNotifiers (for Group Analysis mode)  
  List<Map<String, dynamic>> getIndividualEmailData(Map<String, BlockNotifier> blockNotifiers) {
    final emailData = <Map<String, dynamic>>[];
    
    final groups = getSelectedGroups();
    for (final group in groups) {
      for (final blockId in group.blockIds) {
        final blockNotifier = blockNotifiers[blockId];
        if (blockNotifier != null) {
          // For multi-email blocks: get individual email data
          if (blockNotifier.blockData?.hasMultipleEmails == true) {
            for (final docData in blockNotifier.allDataDocs) {
              final rawResults = docData['rawResults'] as List<dynamic>?;
              if (rawResults != null && rawResults.length == 37) {
                emailData.add({
                  'email': docData['email'] ?? 'Unknown',
                  'rawResults': rawResults.cast<int>(),
                  'groupId': group.id,
                  'groupName': group.groupName,
                });
              }
            }
          } 
          // For single-email blocks: get single email data
          else if (blockNotifier.blockData?.rawResults.length == 37) {
            final email = blockNotifier.blockData!.emails.isNotEmpty 
                ? blockNotifier.blockData!.emails.first 
                : 'Unknown';
            emailData.add({
              'email': email,
              'rawResults': blockNotifier.blockData!.rawResults,
              'groupId': group.id,
              'groupName': group.groupName,
            });
          }
        }
      }
    }
    
    return emailData;
  }

  /// Get averaged group data (for Group Comparison mode)
  List<Map<String, dynamic>> getGroupComparisonData() {
    final groups = getSelectedGroups();
    return groups.map((group) => {
      'groupId': group.id,
      'groupName': group.groupName,
      'averagedRawResults': group.averagedRawResults,
    }).toList();
  }

  void updatePosition(Offset newPosition) async {
    if (!dataLoaded || _position != newPosition) {
      _position = newPosition;
      
      // Set dragging state to trigger lightweight rendering
      if (!_isDragging) {
        _isDragging = true;
      }
      
      notifyListeners();

      _debounceTimer?.cancel();

      // Debounce before saving to firestore AND ending drag state
      _debounceTimer = Timer(_debounceDuration, () async {
        // print("Single doc upload");

        await FirestoreService.updateAnalysisBlockPosition(orgId: appState.orgId, assessmentId: appState.assessmentId, blockID: blockID, position: {'x': newPosition.dx, 'y': newPosition.dy});
        
        // End drag state to restore full table rendering
        if (_isDragging) {
          _isDragging = false;
          notifyListeners(); // Trigger rebuild to show full table again
        }
      });
    }
  }

  void changeBlockType(AnalysisBlockType newType) async {
    if (blockData.analysisBlockType != newType) {
      // When changing main block type, reset sub type and potentially adjust groups
      AnalysisSubType newSubType = blockData.analysisSubType;
      List<String> newGroupIds = blockData.groupIds;
      
      // If switching to groupAnalysis and multiple groups selected, keep only first one
      if (newType == AnalysisBlockType.groupAnalysis && blockData.groupIds.length > 1) {
        newGroupIds = [blockData.groupIds.first];
      }
      
      blockData = blockData.copyWith(
        analysisBlockType: newType,
        analysisSubType: newSubType,
        groupIds: newGroupIds,
      );
      notifyListeners();

      await FirestoreService.updateAnalysisBlockData(
        orgId: appState.orgId,
        assessmentId: appState.assessmentId,
        blockID: blockID,
        blockData: blockData,
      );
    }
  }

  void changeSubType(AnalysisSubType newSubType) async {
    if (blockData.analysisSubType != newSubType) {
      blockData = blockData.copyWith(analysisSubType: newSubType);
      notifyListeners();

      await FirestoreService.updateAnalysisBlockData(
        orgId: appState.orgId,
        assessmentId: appState.assessmentId,
        blockID: blockID,
        blockData: blockData,
      );
    }
  }

  void changeChartType(ChartType newChartType) async {
    if (blockData.chartType != newChartType) {
      blockData = blockData.copyWith(chartType: newChartType);
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
      List<String> updatedGroupIds;
      
      // For group analysis, replace existing group (only allow 1)
      if (blockData.isGroupAnalysis) {
        updatedGroupIds = [groupId];
      } else {
        // For group comparison, add to existing groups
        updatedGroupIds = [...blockData.groupIds, groupId];
      }
      
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

  void _debouncedFiltersUpdate() {
    _filtersDebounceTimer?.cancel();

    _filtersDebounceTimer = Timer(_filtersDebounceDuration, () async {
      await FirestoreService.updateAnalysisBlockData(
        orgId: appState.orgId,
        assessmentId: appState.assessmentId,
        blockID: blockID,
        blockData: blockData,
      );
    });
  }

  // Filter management methods
  void toggleQuestion(int questionNumber) {
    if (questionNumber < 1 || questionNumber > 37) return;
    
    final updatedQuestions = Set<int>.from(blockData.selectedQuestions);
    if (updatedQuestions.contains(questionNumber)) {
      updatedQuestions.remove(questionNumber);
    } else {
      updatedQuestions.add(questionNumber);
    }
    
    blockData = blockData.copyWith(selectedQuestions: updatedQuestions);
    notifyListeners();
    _debouncedFiltersUpdate();
  }

  void toggleIndicator(Benchmark indicator) {
    final updatedIndicators = Set<Benchmark>.from(blockData.selectedIndicators);
    if (updatedIndicators.contains(indicator)) {
      updatedIndicators.remove(indicator);
    } else {
      updatedIndicators.add(indicator);
    }
    
    blockData = blockData.copyWith(selectedIndicators: updatedIndicators);
    notifyListeners();
    _debouncedFiltersUpdate();
  }

  void selectAllQuestions() {
    final allQuestions = Set<int>.from(List.generate(37, (i) => i + 1));
    if (!_setEquals(blockData.selectedQuestions, allQuestions)) {
      blockData = blockData.copyWith(selectedQuestions: allQuestions);
      notifyListeners();
      _debouncedFiltersUpdate();
    }
  }

  void deselectAllQuestions() {
    if (blockData.selectedQuestions.isNotEmpty) {
      blockData = blockData.copyWith(selectedQuestions: <int>{});
      notifyListeners();
      _debouncedFiltersUpdate();
    }
  }

  void selectAllIndicators() {
    final allIndicators = Set<Benchmark>.from(indicators());
    if (!_setEquals(blockData.selectedIndicators, allIndicators)) {
      blockData = blockData.copyWith(selectedIndicators: allIndicators);
      notifyListeners();
      _debouncedFiltersUpdate();
    }
  }

  void deselectAllIndicators() {
    if (blockData.selectedIndicators.isNotEmpty) {
      blockData = blockData.copyWith(selectedIndicators: <Benchmark>{});
      notifyListeners();
      _debouncedFiltersUpdate();
    }
  }

  void updateSelectedQuestions(Set<int> selectedQuestions) {
    if (!_setEquals(blockData.selectedQuestions, selectedQuestions)) {
      blockData = blockData.copyWith(selectedQuestions: selectedQuestions);
      notifyListeners();
      _debouncedFiltersUpdate();
    }
  }

  void updateSelectedIndicators(Set<Benchmark> selectedIndicators) {
    if (!_setEquals(blockData.selectedIndicators, selectedIndicators)) {
      blockData = blockData.copyWith(selectedIndicators: selectedIndicators);
      notifyListeners();
      _debouncedFiltersUpdate();
    }
  }

  // Helper method to compare lists
  bool _listEquals<T>(List<T> a, List<T> b) {
    if (a.length != b.length) return false;
    for (int i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }

  // Helper method to compare sets
  bool _setEquals<T>(Set<T> a, Set<T> b) {
    return a.length == b.length && a.containsAll(b);
  }

  // Simple getters
  bool get dataLoaded => _dataLoaded;
  bool get isDragging => _isDragging;
  Offset get position => _position;
  String get blockName => blockData.blockName;
  AnalysisBlockType get analysisBlockType => blockData.analysisBlockType;
  AnalysisSubType get analysisSubType => blockData.analysisSubType;
  List<String> get groupIds => blockData.groupIds;

  // Delete the analysis block from UI and Firestore
  Future<void> deleteBlock() async {
    try {
      await FirestoreService.deleteAnalysisBlock(
        orgId: appState.orgId,
        assessmentId: appState.assessmentId,
        blockID: blockID,
      );
      // The block will be removed from UI automatically through the stream subscription
    } catch (e) {
      // print("Error deleting analysis block $blockID: $e");
      rethrow; // Let the UI handle the error
    }
  }

  @override
  void dispose() {
    _blockDataDocStreamSub?.cancel();
    _debounceTimer?.cancel();
    _groupsDebounceTimer?.cancel();
    _filtersDebounceTimer?.cancel();
    super.dispose();
  }
}