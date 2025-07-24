import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:logging/logging.dart';
import 'package:platform_v2/config/enums.dart';
import 'package:platform_v2/dataClasses/blockData.dart';
import 'package:platform_v2/dataClasses/firestoreContext.dart';
import 'package:platform_v2/services/firestoreService.dart';

// Individual block notifier. Responsible for block state: position, data and selection
class BlockNotifier extends ChangeNotifier {
  Logger logger = Logger('BlockNotifier');

  final String blockID;
  final FirestoreContext context;
  late Offset _position;
  Set<String> _descendants = {};
  bool positionLoaded = false;
  BlockData? _blockData;
  bool _selected = false;
  Map<Benchmark, double>? _benchmarks;

  // Add StreamSubscription to track subscription to the blocks doc
  StreamSubscription<DocumentSnapshot<Map<String, dynamic>>>? _blockDocStreamSub;
  late final Stream<DocumentSnapshot<Map<String, dynamic>>> blockDocStream;

  StreamSubscription<QuerySnapshot<Map<String, dynamic>>>? _blockResultStreamSub;
  late final Stream<QuerySnapshot<Map<String, dynamic>>> blockResultStream;

  // Timers for debouncing
  Timer? _debounceTimer;
  Timer? _batchDebounceTimer;
  static const Duration _debounceDuration = Duration(milliseconds: 500);

  BlockNotifier({
    required this.blockID,
    required this.context,
  }) {
    // Get Block doc stream and listen to fields
    blockDocStream = FirestoreService.getBlockStream(context, blockID);
    _blockDocStreamSub = blockDocStream.listen(
      (snapshot) {
        DocumentSnapshot<Map<String, dynamic>> doc = snapshot;
        // Check if document exists before accessing data
        if (doc.exists && doc.data() != null) {
          final data = doc.data()!;

          // Get new position from Firestore
          Offset newPosition = Offset(data['position']['x'] ?? 0, data['position']['y'] ?? 0);

          // Check if position has changed (only if position was previously loaded)
          bool positionChanged = positionLoaded && (_position != newPosition);

          // Check if block data has changed
          String name = data['name'] ?? '';
          String role = data['role'] ?? '';
          String department = data['department'] ?? '';
          List<String> emails = List<String>.from(data['emails'] ?? []);
          BlockData newBlockData = BlockData(name: name, role: role, department: department, emails: emails);
          bool dataChanged = _blockData != null && (_blockData != newBlockData);

          // Update if something actually changed or if this is the first load
          if (positionChanged || dataChanged || !positionLoaded) {
            if (!positionLoaded || positionChanged) {
              _position = newPosition;
              // print("Position for block $blockID updated");
            }

            if (_blockData == null || dataChanged) {
              _blockData = newBlockData;
              // print("Data for block $blockID updated");
            }

            if (!positionLoaded) {
              positionLoaded = true;
              // print("Initial load completed for block $blockID");
            }
            logger.info("Block update state");
            notifyListeners();
          } else {
            // print("No changes detected for block $blockID - skipping update");
          }
        }
      },
      onError: (error) {
        debugPrint('BlockNotifier stream error: $error');
      },
    );

    // Only set up result stream if we're in an assessment context
    if (context.assessmentId != null) {
      blockResultStream = FirestoreService.getBlockResultStream(context, blockID);

      _blockResultStreamSub = blockResultStream.listen(
        (event) {
          QuerySnapshot<Map<String, dynamic>> snapshot = event;
          if (snapshot.docs.isNotEmpty) {
            DocumentSnapshot<Map<String, dynamic>> doc = snapshot.docs.first;
            if (doc.exists && doc.data() != null) {
              final data = doc.data()!;
              final rawResults = data['rawResults'] as List<dynamic>?;
              if (rawResults != null) {
                final rawResultsInt = rawResults.cast<int>();
                _blockData =
                    _blockData?.copyWith(rawResults: rawResultsInt) ??
                    BlockData(
                      name: '',
                      role: '',
                      department: '',
                      emails: [],
                      rawResults: rawResultsInt,
                    );

                // Calculate benchmarks when rawResults are available
                try {
                  _benchmarks = _calculateBenchmarks(rawResultsInt);
                  print("Calculated benchmarks for block $blockID: ${_benchmarks?.length} benchmarks");
                } catch (e) {
                  print("Error calculating benchmarks for block $blockID: $e");
                  _benchmarks = null;
                }

                notifyListeners();
              }
            }
          }
        },
        onError: (error) {
          debugPrint('BlockNotifier result stream error: $error');
        },
      );
    }
  }

  // Getters with proper encapsulation
  Offset get position => _position;
  BlockData? get blockData => _blockData;
  bool get selected => _selected;
  Set<String> get descendants => _descendants;
  Map<Benchmark, double>? get benchmarks => _benchmarks;

  void updateDescendants(Map<String, Set<String>> parentAndChildren) {
    //Finds all decendants of current block and adds to internal state map
    Set<String> allDescendants = {};
    Set<String> visited = {};

    // recursive function to get all descendants
    void collectDescendants(String currentBlockID) {
      if (visited.contains(currentBlockID)) return; // Prevent circular references
      visited.add(currentBlockID);

      Set<String> descendants = parentAndChildren[currentBlockID] ?? {};
      for (var descendant in descendants) {
        allDescendants.add(descendant);
        collectDescendants(descendant);
      }
    }

    collectDescendants(blockID);
    print("updating descendants: $allDescendants");
    _descendants = allDescendants;
  }

  void updatePosition(Offset newPosition) async {
    if (!positionLoaded || _position != newPosition) {
      _position = newPosition;
      notifyListeners();

      _debounceTimer?.cancel();

      // Debounce before saving to firestore
      _debounceTimer = Timer(_debounceDuration, () async {
        print("Single doc upload");

        await FirestoreService.updatePosition(context, blockID, {'x': newPosition.dx, 'y': newPosition.dy});
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
      await FirestoreService.batchUpdatePositions(context, positions);
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
      notifyListeners();
      FirestoreService.updateData(
        context,
        blockID,
        newData,
      );
    }
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    _batchDebounceTimer?.cancel();
    _blockDocStreamSub?.cancel();
    _blockResultStreamSub?.cancel();
    _blockDocStreamSub = null;
    _blockResultStreamSub = null;
    super.dispose();
  }
}
