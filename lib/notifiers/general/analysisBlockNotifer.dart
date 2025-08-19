import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:platform_v2/config/enums.dart';
import 'package:platform_v2/dataClasses/analysisBlockData.dart';
import 'package:platform_v2/notifiers/general/appStateNotifier.dart';
import 'package:platform_v2/services/firestoreService.dart';
import 'package:platform_v2/services/analysisDataService.dart';

class AnalysisBlockNotifer extends ChangeNotifier {
  final String blockID;
  bool _dataLoaded = false;
  bool _isDragging = false;
  Offset _position = const Offset(0, 0);
  List<double> _averagedRawResults = [];
  AnalysisBlockData blockData = AnalysisBlockData.empty();

  AppStateNotifier appState;
  StreamSubscription<DocumentSnapshot<Map<String, dynamic>>>? _blockDataDocStreamSub;
  
  // Analysis data management
  List<EmailDataPoint> _analysisData = [];
  Map<String, List<EmailDataPoint>> _groupedAnalysisData = {}; // For group comparison
  bool _analysisDataLoading = false;
  String? _analysisDataError;
  String _lastDataConfigHash = '';
  
  // Pre-calculated display data (like BlockNotifier's _benchmarks)
  int _maxQuestions = 0;
  List<String> _processedEmails = [];
  List<List<Color>> _heatmapColors = [];
  List<Map<Benchmark, double>> _indicatorBenchmarks = [];
  List<Map<String, double>> _questionStatistics = []; // IQR, AVG, HIGH, LOW per question
  List<Map<String, double>> _indicatorStatistics = []; // IQR, AVG, HIGH, LOW per indicator

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

        final newBlockData = AnalysisBlockData.fromMap(data);
        final dataConfigChanged = _hasDataConfigChanged(newBlockData);
        
        blockData = newBlockData;
        _dataLoaded = true;
        
        // If data-relevant configuration changed, fetch analysis data
        if (dataConfigChanged) {
          _fetchAnalysisData();
        }
        
        notifyListeners();
      }
    });
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
        print("Single doc upload");

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

  // Helper method to compare lists
  bool _listEquals<T>(List<T> a, List<T> b) {
    if (a.length != b.length) return false;
    for (int i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }

  // Check if data-relevant configuration has changed
  // NOTE: analysisSubType is NOT included - both Questions and Indicators use same raw data
  bool _hasDataConfigChanged(AnalysisBlockData newBlockData) {
    final newConfigHash = '${newBlockData.analysisBlockType.name}_${newBlockData.groupIds.join(',')}';
    final changed = _lastDataConfigHash != newConfigHash;
    _lastDataConfigHash = newConfigHash;
    return changed;
  }

  // Fetch analysis data based on current configuration
  void _fetchAnalysisData() async {
    // Only fetch if block is properly configured
    if (blockData.analysisBlockType == AnalysisBlockType.none ||
        blockData.analysisSubType == AnalysisSubType.none ||
        blockData.groupIds.isEmpty) {
      _analysisData = [];
      _analysisDataLoading = false;
      _analysisDataError = null;
      notifyListeners();
      return;
    }

    _analysisDataLoading = true;
    _analysisDataError = null;
    notifyListeners();

    try {
      // For Group Comparison: fetch data per group separately to maintain grouping
      // For Group Analysis: fetch all data together (existing behavior)
      if (blockData.isGroupComparison) {
        _groupedAnalysisData = {};
        _analysisData = [];
        
        // Fetch data for each group separately
        for (final groupId in blockData.groupIds) {
          final groupDoc = await FirestoreService.instance
              .collection('orgs')
              .doc(appState.orgId)
              .collection('assessments')
              .doc(appState.assessmentId)
              .collection('groups')
              .doc(groupId)
              .get();
              
          if (groupDoc.exists && groupDoc.data() != null) {
            final groupData = groupDoc.data()!;
            final dataDocIds = (groupData['dataDocIds'] as List?)?.cast<String>() ?? [];
            
            if (dataDocIds.isNotEmpty) {
              final groupAnalysisData = await AnalysisDataService.fetchGroupRawData(
                orgId: appState.orgId!,
                assessmentId: appState.assessmentId!,
                dataDocIds: dataDocIds,
              );
              
              _groupedAnalysisData[groupId] = groupAnalysisData;
              _analysisData.addAll(groupAnalysisData); // Keep combined data for other uses
            } else {
              _groupedAnalysisData[groupId] = [];
            }
          } else {
            _groupedAnalysisData[groupId] = [];
          }
        }
      } else {
        // Original behavior for Group Analysis or single group
        final allDataDocIds = <String>[];
        _groupedAnalysisData = {};
        
        for (final groupId in blockData.groupIds) {
          final groupDoc = await FirestoreService.instance
              .collection('orgs')
              .doc(appState.orgId)
              .collection('assessments')
              .doc(appState.assessmentId)
              .collection('groups')
              .doc(groupId)
              .get();
              
          if (groupDoc.exists && groupDoc.data() != null) {
            final groupData = groupDoc.data()!;
            final dataDocIds = (groupData['dataDocIds'] as List?)?.cast<String>() ?? [];
            allDataDocIds.addAll(dataDocIds);
          }
        }
        
        if (allDataDocIds.isEmpty) {
          _analysisData = [];
          _analysisDataLoading = false;
          _analysisDataError = null;
          notifyListeners();
          return;
        }
        
        final analysisData = await AnalysisDataService.fetchGroupRawData(
          orgId: appState.orgId!,
          assessmentId: appState.assessmentId!,
          dataDocIds: allDataDocIds,
        );

        _analysisData = analysisData;
      }

      _analysisDataLoading = false;
      _analysisDataError = null;
      
      // Pre-calculate display data (like BlockNotifier's benchmark calculation)
      _calculateDisplayData();
      
      // Populate benchmarks in the data points for IndicatorTable
      _populateBenchmarks();
      
    } catch (e) {
      _analysisData = [];
      _analysisDataLoading = false;
      _analysisDataError = e.toString();
      print("Error fetching analysis data for block $blockID: $e");
    }
    
    notifyListeners();
  }

  // Pre-calculate expensive display data (like BlockNotifier's _calculateBenchmarks)
  void _calculateDisplayData() {
    if (_analysisData.isEmpty) {
      _maxQuestions = 0;
      _processedEmails = [];
      _heatmapColors = [];
      _indicatorBenchmarks = [];
      _questionStatistics = [];
      _indicatorStatistics = [];
      return;
    }

    // Calculate max questions across all data points
    _maxQuestions = _analysisData
        .map((dp) => dp.rawResults.length)
        .fold(0, (max, length) => length > max ? length : max);

    // Pre-process emails (truncation logic)
    _processedEmails = _analysisData.map((dp) {
      return _truncateEmail(dp.email, 25);
    }).toList();

    // Pre-calculate all heatmap colors for the table
    _heatmapColors = _analysisData.map((dataPoint) {
      return List.generate(_maxQuestions, (index) {
        if (index < dataPoint.rawResults.length) {
          return AnalysisDataService.getHeatmapColor(dataPoint.rawResults[index]);
        }
        return Colors.grey.withValues(alpha: 0.2);
      });
    }).toList();

    // Pre-calculate indicator benchmarks for each data point
    _indicatorBenchmarks = _analysisData.map((dataPoint) {
      try {
        return _calculateBenchmarks(dataPoint.rawResults);
      } catch (e) {
        // If calculation fails (e.g., wrong number of questions), return empty map
        return <Benchmark, double>{};
      }
    }).toList();

    // Calculate statistics for questions
    _calculateQuestionStatistics();
    
    // Calculate statistics for indicators
    _calculateIndicatorStatistics();
  }

  // Copy of BlockNotifier's benchmark calculation logic
  Map<Benchmark, double> _calculateBenchmarks(List<int> rawResults) {
    // Validate input
    if (rawResults.length != 37) {
      throw ArgumentError('rawResults must contain exactly 37 values');
    }

    Map<Benchmark, double> benchmarks = {};

    // Indicator Calculations (Q1-Q37)
    benchmarks[Benchmark.growthAlign] = (rawResults[0] + rawResults[1] + rawResults[2]) / 21.0;
    benchmarks[Benchmark.orgAlign] = (rawResults[3] + rawResults[4] + rawResults[5]) / 21.0;
    benchmarks[Benchmark.collabKPIs] = (rawResults[6] + rawResults[7] + rawResults[8]) / 21.0;
    benchmarks[Benchmark.crossFuncComms] = (rawResults[9] + rawResults[10] + rawResults[11]) / 21.0;
    benchmarks[Benchmark.crossFuncAcc] = (rawResults[12] + rawResults[13] + rawResults[14]) / 21.0;
    benchmarks[Benchmark.engagedCommunity] = (rawResults[15] + rawResults[16] + rawResults[17]) / 21.0;
    benchmarks[Benchmark.collabProcesses] = (rawResults[18] + rawResults[19] + rawResults[20]) / 21.0;
    benchmarks[Benchmark.alignedTech] = (rawResults[21] + rawResults[22] + rawResults[23]) / 21.0;
    benchmarks[Benchmark.meetingEfficacy] = (rawResults[24] + rawResults[25] + rawResults[26]) / 21.0;
    benchmarks[Benchmark.empoweredLeadership] = (rawResults[27] + rawResults[28] + rawResults[29]) / 21.0;
    benchmarks[Benchmark.purposeDriven] = (rawResults[30] + rawResults[31] + rawResults[32]) / 21.0;
    benchmarks[Benchmark.engagement] = (rawResults[33] + rawResults[34]) / 14.0;
    benchmarks[Benchmark.productivity] = (rawResults[35] + rawResults[36]) / 14.0;

    // Pilar Calculations
    double growthAlign = benchmarks[Benchmark.growthAlign]!;
    double orgAlign = benchmarks[Benchmark.orgAlign]!;
    double collabKPIs = benchmarks[Benchmark.collabKPIs]!;
    double alignedTech = benchmarks[Benchmark.alignedTech]!;
    double collabProcesses = benchmarks[Benchmark.collabProcesses]!;
    double meetingEfficacy = benchmarks[Benchmark.meetingEfficacy]!;
    double crossFuncComms = benchmarks[Benchmark.crossFuncComms]!;
    double crossFuncAcc = benchmarks[Benchmark.crossFuncAcc]!;
    double engagedCommunity = benchmarks[Benchmark.engagedCommunity]!;
    double empoweredLeadership = benchmarks[Benchmark.empoweredLeadership]!;
    double purposeDriven = benchmarks[Benchmark.purposeDriven]!;
    double engagement = benchmarks[Benchmark.engagement]!;
    double productivity = benchmarks[Benchmark.productivity]!;

    benchmarks[Benchmark.alignP] = (growthAlign * 0.3) + (orgAlign * 0.2) + (collabKPIs * 0.5);
    benchmarks[Benchmark.processP] = (alignedTech * 0.4) + (collabProcesses * 0.4) + (meetingEfficacy * 0.2);
    benchmarks[Benchmark.peopleP] = (crossFuncComms * 0.3) + (crossFuncAcc * 0.3) + (engagedCommunity * 0.4);
    benchmarks[Benchmark.leadershipP] = (empoweredLeadership * 0.6) + (purposeDriven * 0.4);

    // Final Calculations
    double alignP = benchmarks[Benchmark.alignP]!;
    double processP = benchmarks[Benchmark.processP]!;
    double peopleP = benchmarks[Benchmark.peopleP]!;
    double leadershipP = benchmarks[Benchmark.leadershipP]!;

    benchmarks[Benchmark.workforce] = (alignP * 0.4) + (productivity * 0.2) + (processP * 0.4);
    benchmarks[Benchmark.operations] = (peopleP * 0.4) + (engagement * 0.2) + (leadershipP * 0.4);
    benchmarks[Benchmark.orgIndex] = (alignP * 0.2) + (processP * 0.25) + (peopleP * 0.25) + (leadershipP * 0.3);

    return benchmarks;
  }

  // Calculate statistics for each question column
  void _calculateQuestionStatistics() {
    _questionStatistics = [];
    
    for (int questionIndex = 0; questionIndex < _maxQuestions; questionIndex++) {
      // Collect all values for this question across all data points
      final values = <int>[];
      
      for (final dataPoint in _analysisData) {
        if (questionIndex < dataPoint.rawResults.length) {
          values.add(dataPoint.rawResults[questionIndex]);
        }
      }
      
      if (values.isNotEmpty) {
        _questionStatistics.add(_calculateColumnStats(values.map((v) => v.toDouble()).toList()));
      } else {
        _questionStatistics.add({'avg': 0.0, 'high': 0.0, 'low': 0.0, 'iqr': 0.0});
      }
    }
  }

  // Calculate statistics for each indicator
  void _calculateIndicatorStatistics() {
    _indicatorStatistics = [];
    
    // Get all unique benchmarks from all data points
    final allBenchmarks = <Benchmark>{};
    for (final benchmarks in _indicatorBenchmarks) {
      allBenchmarks.addAll(benchmarks.keys);
    }
    
    // Calculate stats for each benchmark
    for (final benchmark in allBenchmarks) {
      final values = <double>[];
      
      for (final benchmarks in _indicatorBenchmarks) {
        if (benchmarks.containsKey(benchmark)) {
          values.add(benchmarks[benchmark]!);
        }
      }
      
      if (values.isNotEmpty) {
        final stats = _calculateColumnStats(values);
        stats['benchmark'] = benchmark.index.toDouble(); // Store benchmark type
        _indicatorStatistics.add(stats);
      }
    }
  }

  // Helper method to calculate statistics for a column
  Map<String, double> _calculateColumnStats(List<double> values) {
    if (values.isEmpty) {
      return {'avg': 0.0, 'high': 0.0, 'low': 0.0, 'iqr': 0.0};
    }
    
    values.sort();
    
    final avg = values.reduce((a, b) => a + b) / values.length;
    final high = values.last;
    final low = values.first;
    
    // Calculate IQR (Interquartile Range)
    final q1Index = (values.length * 0.25).floor();
    final q3Index = (values.length * 0.75).floor();
    final q1 = values[q1Index];
    final q3 = values[q3Index];
    final iqr = q3 - q1;
    
    return {
      'avg': avg,
      'high': high,
      'low': low,
      'iqr': iqr,
    };
  }

  // Populate benchmarks in EmailDataPoint objects
  void _populateBenchmarks() {
    if (_analysisData.length != _indicatorBenchmarks.length) return;
    
    for (int i = 0; i < _analysisData.length; i++) {
      // Create new EmailDataPoint with benchmarks populated
      _analysisData[i] = EmailDataPoint(
        email: _analysisData[i].email,
        rawResults: _analysisData[i].rawResults,
        benchmarks: _indicatorBenchmarks[i],
      );
    }
  }

  String _truncateEmail(String email, int maxLength) {
    if (email.length <= maxLength) return email;
    
    final atIndex = email.indexOf('@');
    if (atIndex != -1 && atIndex <= maxLength - 3) {
      return '${email.substring(0, atIndex)}...';
    }
    
    return '${email.substring(0, maxLength - 3)}...';
  }

  // Getters
  bool get dataLoaded => _dataLoaded;
  bool get isDragging => _isDragging;
  Offset get position => _position;
  List<double> get averagedRawResults => _averagedRawResults;
  String get blockName => blockData.blockName;
  AnalysisBlockType get analysisBlockType => blockData.analysisBlockType;
  AnalysisSubType get analysisSubType => blockData.analysisSubType;
  List<String> get groupIds => blockData.groupIds;
  
  // Analysis data getters
  List<EmailDataPoint> get analysisData => _analysisData;
  Map<String, List<EmailDataPoint>> get groupedAnalysisData => _groupedAnalysisData;
  bool get analysisDataLoading => _analysisDataLoading;
  String? get analysisDataError => _analysisDataError;
  
  // Pre-calculated display data getters
  int get maxQuestions => _maxQuestions;
  List<String> get processedEmails => _processedEmails;
  List<List<Color>> get heatmapColors => _heatmapColors;
  List<Map<Benchmark, double>> get indicatorBenchmarks => _indicatorBenchmarks;
  List<Map<String, double>> get questionStatistics => _questionStatistics;
  List<Map<String, double>> get indicatorStatistics => _indicatorStatistics;

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
      print("Error deleting analysis block $blockID: $e");
      rethrow; // Let the UI handle the error
    }
  }

  @override
  void dispose() {
    _blockDataDocStreamSub?.cancel();
    _debounceTimer?.cancel();
    _groupsDebounceTimer?.cancel();
    super.dispose();
  }
}
