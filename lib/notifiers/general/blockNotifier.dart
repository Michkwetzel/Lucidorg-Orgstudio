import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:logging/logging.dart';
import 'package:platform_v2/config/enums.dart';
import 'package:platform_v2/dataClasses/blockData.dart';
import 'package:platform_v2/notifiers/general/appStateNotifier.dart';
import 'package:platform_v2/services/firestoreService.dart';

// Individual block notifier. Responsible for block state: position, data and selection
class BlockNotifier extends ChangeNotifier {
  Logger logger = Logger('BlockNotifier');

  final String blockId;
  String blockResultDocId = '';
  Set<String> _descendants = {};
  bool positionLoaded = false;
  BlockData? _blockData;
  bool _selected = false;
  Map<Benchmark, double>? _benchmarks;
  Offset _position = const Offset(0, 0);
  AppStateNotifier appState;

  // Add StreamSubscription to track subscription to the blocks doc
  StreamSubscription<DocumentSnapshot<Map<String, dynamic>>>? _blockDataDocStreamSub;
  late final Stream<DocumentSnapshot<Map<String, dynamic>>> _blockDataDocStream;

  // from Data Doc
  StreamSubscription<QuerySnapshot<Map<String, dynamic>>>? _blockResultStreamSub;
  late final Stream<QuerySnapshot<Map<String, dynamic>>> blockResultStream;

  // Multi-email tracking
  List<Map<String, dynamic>> _allDataDocs = [];
  int _sentCount = 0;
  int _submittedCount = 0;

  // Timers for debouncing
  Timer? _debounceTimer;
  Timer? _batchDebounceTimer;
  static const Duration _debounceDuration = Duration(milliseconds: 500);

  BlockNotifier({
    required this.blockId,
    required this.appState,
  }) {
    // Get Block doc stream and listen to fields
    _blockDataDocStream = FirestoreService.getBlockStream(orgId: appState.orgId, assessmentId: appState.assessmentId, blockId: blockId);
    _blockDataDocStreamSub = _blockDataDocStream.listen(
      (snapshot) {
        // print("Updating block data");
        DocumentSnapshot<Map<String, dynamic>> doc = snapshot;
        // Check if document exists before accessing data
        if (doc.exists && doc.data() != null) {
          final data = doc.data()!;

          // Create new BlockData with all fields from Firestore
          String name = data['name'] ?? '';
          String role = data['role'] ?? '';
          String department = data['department'] ?? '';
          String region = data['region'] ?? '';
          String subOffice = data['subOffice'] ?? '';
          List<String> emails = List<String>.from(data['emails'] ?? []);
          Offset position = Offset(data['position']['x'] ?? 0, data['position']['y'] ?? 0);
          Hierarchy hierarchy = Hierarchy.none;
          switch (data['hierarchy'] ?? 'none') {
            case 'ceo':
              hierarchy = Hierarchy.ceo;
              break;
            case 'cSuite':
              hierarchy = Hierarchy.cSuite;
              break;
            case 'regionalDirector':
              hierarchy = Hierarchy.regionalDirector;
              break;
            case 'officeDirector':
              hierarchy = Hierarchy.officeDirector;
              break;
            case 'officeManager':
              hierarchy = Hierarchy.officeManager;
              break;
            case 'partner':
              hierarchy = Hierarchy.partner;
              break;
            case 'teamLead':
              hierarchy = Hierarchy.teamLead;
              break;
            case 'team':
              hierarchy = Hierarchy.team;
              break;
            default:
              hierarchy = Hierarchy.none;
              break;
          }
          // print("blockId: $blockId, hierarchy: ${data['hierarchy']}");

          BlockData newBlockData = BlockData(
            name: name,
            role: role,
            department: department,
            emails: emails,
            hierarchy: hierarchy,
            region: region,
            subOffice: subOffice,
            // Keep existing rawResults, sent, submitted if they exist
            rawResults: _blockData?.rawResults ?? [],
            sent: _blockData?.sent ?? false,
            submitted: _blockData?.submitted ?? false,
          );

          bool dataChanged = _blockData != newBlockData;

          // Update if something actually changed or if this is the first load
          if (dataChanged || !positionLoaded) {
            bool isFirstLoad = !positionLoaded;
            bool emailCountChanged = _blockData?.emails.length != newBlockData.emails.length;

            _blockData = newBlockData;
            _position = position;

            if (!positionLoaded) {
              positionLoaded = true;
              // print("Initial load completed for block $blockId");
            }

            // Set up result stream on first load or if email count changed
            if (appState.appView == AppView.assessmentBuild && (isFirstLoad || emailCountChanged)) {
              _blockResultStreamSub?.cancel();
              _setupResultStream();
            }

            // //logger.info("Block update state");
            notifyListeners();
          } else {
            // print("No changes detected for block $blockId - skipping update");
          }
        }
      },
      onError: (error) {
        debugPrint('BlockNotifier stream error: $error');
      },
    );
  }

  // Getters with proper encapsulation
  Offset get position => _position;
  BlockData? get blockData => _blockData;
  bool get selected => _selected;
  Set<String> get descendants => _descendants;
  Map<Benchmark, double>? get benchmarks => _benchmarks;
  bool get sent => _blockData?.sent ?? false;
  bool get submitted => _blockData?.submitted ?? false;

  // Multi-email getters
  List<Map<String, dynamic>> get allDataDocs => _allDataDocs;
  int get sentCount => _sentCount;
  int get submittedCount => _submittedCount;
  String get emailStatusRatio {
    // For team hierarchy, use data doc count instead of email count
    if (_blockData?.hierarchy == Hierarchy.team) {
      final totalDataDocs = _allDataDocs.length;
      if (totalDataDocs == 0) return '';
      return '$_submittedCount/$totalDataDocs';
    }

    final totalEmails = _blockData?.totalEmailCount ?? 0;
    if (totalEmails <= 1) return '';
    return '$_submittedCount/$totalEmails';
  }

  bool get allEmailsSubmitted {
    // For team hierarchy, check against data doc count
    if (_blockData?.hierarchy == Hierarchy.team) {
      final totalDataDocs = _allDataDocs.length;
      return totalDataDocs > 0 && _submittedCount == totalDataDocs;
    }

    final totalEmails = _blockData?.totalEmailCount ?? 0;
    return totalEmails > 1 && _submittedCount == totalEmails;
  }

  bool get partialEmailsSubmitted {
    // For team hierarchy, check against data doc count
    if (_blockData?.hierarchy == Hierarchy.team) {
      final totalDataDocs = _allDataDocs.length;
      return totalDataDocs > 0 && _submittedCount > 0 && _submittedCount < totalDataDocs;
    }

    final totalEmails = _blockData?.totalEmailCount ?? 0;
    return totalEmails > 1 && _submittedCount > 0 && _submittedCount < totalEmails;
  }

  // Data doc tracking for deletion warnings
  bool get hasDataDocs => _allDataDocs.isNotEmpty || (_blockData?.sent ?? false);

  int get dataDocsCount => _allDataDocs.isNotEmpty ? _allDataDocs.length : (_blockData?.sent ?? false ? 1 : 0);

  int get dataDocsWithResultsCount {
    if (_allDataDocs.isEmpty) {
      // Single email mode - check if submitted
      return (_blockData?.submitted ?? false) ? 1 : 0;
    } else {
      // Multi-email mode - count submitted docs
      return _allDataDocs.where((doc) => doc['submitted'] == true).length;
    }
  }

  void _setupResultStream() {
    print('=== Setting up result stream for block $blockId ===');
    print('Block name: ${_blockData?.name}');
    print('Hierarchy: ${_blockData?.hierarchy}');
    print('Has multiple emails: ${_blockData?.hasMultipleEmails}');
    print('Email count: ${_blockData?.emails.length}');
    print('Emails: ${_blockData?.emails}');

    // Determine if this block should use multi-email stream
    // Team hierarchy always uses multi-email stream (for mock data support)
    // Otherwise, use multi-email stream only if block has multiple emails
    final shouldUseMultiEmailStream = _blockData?.hierarchy == Hierarchy.team ||
                                      _blockData?.hasMultipleEmails == true;

    // Reset multi-email state when switching to single email mode
    if (!shouldUseMultiEmailStream) {
      _allDataDocs = [];
      _sentCount = 0;
      _submittedCount = 0;
    }

    // Use conditional logic based on hierarchy or email count
    if (shouldUseMultiEmailStream) {
      print('Setting up MULTI-EMAIL result stream (team hierarchy or multiple emails)');
      _setupMultiEmailResultStream();
    } else {
      print('Setting up SINGLE-EMAIL result stream');
      _setupSingleEmailResultStream();
    }
    print('==========================================');
  }

  void _setupSingleEmailResultStream() {
    blockResultStream = FirestoreService.getBlockResultStream(orgId: appState.orgId, assessmentId: appState.assessmentId, blockId: blockId);

    _blockResultStreamSub = blockResultStream.listen(
      (event) {
        // print("Updating block results");

        QuerySnapshot<Map<String, dynamic>> snapshot = event;
        if (snapshot.docs.isNotEmpty) {
          DocumentSnapshot<Map<String, dynamic>> doc = snapshot.docs.first;
          if (doc.exists && doc.data() != null) {
            blockResultDocId = doc.id;
            final data = doc.data()!;
            final rawResults = data['rawResults'] as List<dynamic>?;
            final sent = data['sentAssessment'] as bool? ?? false;
            final submitted = data['submitted'] ?? false;

            // Update BlockData with assessment data
            final rawResultsInt = rawResults?.cast<int>() ?? [];

            _blockData =
                _blockData?.copyWith(
                  rawResults: rawResultsInt,
                  sent: sent,
                  submitted: submitted,
                ) ??
                BlockData(
                  name: '',
                  role: '',
                  department: '',
                  emails: [],
                  rawResults: rawResultsInt,
                  sent: sent,
                  submitted: submitted,
                );

            // Calculate benchmarks when rawResults are available
            if (rawResultsInt.isNotEmpty) {
              try {
                _benchmarks = _calculateBenchmarks(rawResultsInt);
                // print("Calculated benchmarks for block $blockId: ${_benchmarks?.length} benchmarks");
              } catch (e) {
                print("Error calculating benchmarks for block $blockId: $e");
                _benchmarks = null;
              }
            }

            notifyListeners();
          }
        }
      },
      onError: (error) {
        debugPrint('BlockNotifier result stream error: $error');
      },
    );
  }

  void _setupMultiEmailResultStream() {
    blockResultStream = FirestoreService.getAllBlockResultsStream(orgId: appState.orgId, assessmentId: appState.assessmentId, blockId: blockId);

    _blockResultStreamSub = blockResultStream.listen(
      (event) {
        QuerySnapshot<Map<String, dynamic>> snapshot = event;
        _allDataDocs = snapshot.docs.map((doc) => {'id': doc.id, ...doc.data()}).toList();

        print('Multi-email stream update for block $blockId (${_blockData?.name}):');
        print('  Received ${_allDataDocs.length} data docs from Firestore');
        for (var i = 0; i < _allDataDocs.length; i++) {
          final doc = _allDataDocs[i];
          print('    [$i] Email: ${doc['email']}, Sent: ${doc['sentAssessment']}, Submitted: ${doc['submitted']}');
        }

        _processMultiEmailData();
        notifyListeners();
      },
      onError: (error) {
        debugPrint('BlockNotifier multi-email result stream error: $error');
      },
    );
  }

  void _processMultiEmailData() {
    if (_allDataDocs.isEmpty) {
      _sentCount = 0;
      _submittedCount = 0;
      return;
    }

    int sentCount = 0;
    int submittedCount = 0;
    List<List<int>> allRawResultsLists = [];

    for (final docData in _allDataDocs) {
      final sent = docData['sentAssessment'] as bool? ?? false;
      final submitted = docData['submitted'] as bool? ?? false;
      final rawResults = docData['rawResults'] as List<dynamic>?;

      if (sent) sentCount++;
      if (submitted) submittedCount++;

      // Collect all rawResults that have data
      if (rawResults != null && rawResults.isNotEmpty) {
        try {
          final resultsList = rawResults.cast<int>();
          if (resultsList.length == 37) {
            // Ensure we have complete data
            allRawResultsLists.add(resultsList);
          }
        } catch (e) {
          print("Error casting rawResults for block $blockId: $e");
        }
      }
    }

    // Average all available rawResults
    List<int> averagedRawResults = _calculateAveragedResults(allRawResultsLists);

    _sentCount = sentCount;
    _submittedCount = submittedCount;

    // Update BlockData with aggregated status
    final overallSent = sentCount > 0;
    final overallSubmitted = submittedCount == (_blockData?.totalEmailCount ?? 0);

    _blockData = _blockData?.copyWith(
      rawResults: averagedRawResults,
      sent: overallSent,
      submitted: overallSubmitted,
    );

    // Calculate benchmarks when rawResults are available
    if (averagedRawResults.isNotEmpty) {
      try {
        _benchmarks = _calculateBenchmarks(averagedRawResults);
        // print("Calculated benchmarks for multi-email block $blockId: ${_benchmarks?.length} benchmarks from ${allRawResultsLists.length} submissions");
      } catch (e) {
        print("Error calculating benchmarks for multi-email block $blockId: $e");
        _benchmarks = null;
      }
    }
  }

  List<int> _calculateAveragedResults(List<List<int>> allRawResultsLists) {
    if (allRawResultsLists.isEmpty) {
      return [];
    }

    // If only one set of results, return it as-is
    if (allRawResultsLists.length == 1) {
      return allRawResultsLists.first;
    }

    // Calculate averages for each question (assuming 37 questions)
    List<int> averagedResults = [];

    for (int questionIndex = 0; questionIndex < 37; questionIndex++) {
      double sum = 0;
      int count = 0;

      for (final resultsList in allRawResultsLists) {
        if (questionIndex < resultsList.length) {
          sum += resultsList[questionIndex];
          count++;
        }
      }

      if (count > 0) {
        // Round to nearest integer
        averagedResults.add((sum / count).round());
      } else {
        // Fallback to 0 if no data available for this question
        averagedResults.add(0);
      }
    }

    return averagedResults;
  }

  void updateDescendants(Map<String, Set<String>> parentAndChildren) {
    //Finds all decendants of current block and adds to internal state map
    Set<String> allDescendants = {};
    Set<String> visited = {};

    // recursive function to get all descendants
    void collectDescendants(String currentBlockId) {
      if (visited.contains(currentBlockId)) return; // Prevent circular references
      visited.add(currentBlockId);

      Set<String> descendants = parentAndChildren[currentBlockId] ?? {};
      for (var descendant in descendants) {
        allDescendants.add(descendant);
        collectDescendants(descendant);
      }
    }

    collectDescendants(blockId);
    // print("updating descendants: $allDescendants");
    _descendants = allDescendants;
  }

  void updatePosition(Offset newPosition) async {
    if (!positionLoaded || _position != newPosition) {
      _position = newPosition;
      notifyListeners();

      _debounceTimer?.cancel();

      // Debounce before saving to firestore
      _debounceTimer = Timer(_debounceDuration, () async {
        // print("Single doc upload");

        await FirestoreService.updateBlockPosition(orgId: appState.orgId, assessmentId: appState.assessmentId, blockId: blockId, position: {'x': newPosition.dx, 'y': newPosition.dy});
      });
    }
  }

  void updatePositionWithoutFirestore(Offset newPosition) {
    if (!positionLoaded || _position != newPosition) {
      _position = newPosition;
      notifyListeners();
    }
  }

  void batchUpdateDescendantPositions(Map<String, Offset> positions) {
    _batchDebounceTimer?.cancel();

    _batchDebounceTimer = Timer(_debounceDuration, () async {
      await FirestoreService.batchUpdatePositions(orgId: appState.orgId, assessmentId: appState.assessmentId, positions: positions);
    });
  }

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

  void onSelect() {
    _selected = true;
    notifyListeners();
  }

  void onDeSelect() {
    _selected = false;
    notifyListeners();
  }

  void updateData(BlockData newData) {
    if (_blockData != newData) {
      _blockData = newData;
      FirestoreService.updateData(
        orgId: appState.orgId,
        assessmentId: appState.assessmentId,
        blockId: blockId,
        blockData: newData,
      );
      notifyListeners();
    }
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    _batchDebounceTimer?.cancel();
    _blockDataDocStreamSub?.cancel();
    _blockResultStreamSub?.cancel();
    _blockDataDocStreamSub = null;
    _blockResultStreamSub = null;
    super.dispose();
  }
}
