import 'package:flutter/material.dart';
import 'package:logging/logging.dart';
import 'package:platform_v2/config/enums.dart';
import 'package:platform_v2/services/firestoreService.dart';

class EmailDataPoint {
  final String email;
  final List<int> rawResults;
  final Map<Benchmark, double>? benchmarks;

  EmailDataPoint({
    required this.email,
    required this.rawResults,
    this.benchmarks,
  });
}

class CachedEmailData {
  final String docId;
  final String email;
  final List<int> rawResults;
  final Map<Benchmark, double>? benchmarks;
  final String? groupId; // Which group this email belongs to (nullable for unassigned)

  CachedEmailData({
    required this.docId,
    required this.email,
    required this.rawResults,
    this.benchmarks,
    this.groupId,
  });

  // Create from EmailDataPoint
  factory CachedEmailData.fromEmailDataPoint(
    EmailDataPoint emailDataPoint,
    String docId,
    String? groupId,
  ) {
    return CachedEmailData(
      docId: docId,
      email: emailDataPoint.email,
      rawResults: emailDataPoint.rawResults,
      benchmarks: emailDataPoint.benchmarks,
      groupId: groupId,
    );
  }

  // Convert to EmailDataPoint for backward compatibility
  EmailDataPoint toEmailDataPoint() {
    return EmailDataPoint(
      email: email,
      rawResults: rawResults,
      benchmarks: benchmarks,
    );
  }

  // Copy with new groupId
  CachedEmailData copyWith({String? groupId}) {
    return CachedEmailData(
      docId: docId,
      email: email,
      rawResults: rawResults,
      benchmarks: benchmarks,
      groupId: groupId ?? this.groupId,
    );
  }
}

class AnalysisDataService {
  static final Logger _logger = Logger('AnalysisDataService');

  /// Fetches raw data for all emails in a group
  static Future<List<EmailDataPoint>> fetchGroupRawData({
    required String orgId,
    required String assessmentId,
    required List<String> dataDocIds,
  }) async {
    try {
      //logger.info('Fetching data for ${dataDocIds.length} documents');

      final List<EmailDataPoint> dataPoints = [];

      // Fetch each data document
      for (String docId in dataDocIds) {
        try {
          final docSnapshot = await FirestoreService.instance.collection('orgs').doc(orgId).collection('assessments').doc(assessmentId).collection('data').doc(docId).get();

          if (docSnapshot.exists && docSnapshot.data() != null) {
            final data = docSnapshot.data()!;
            final email = data['email'] as String? ?? 'Unknown';
            final rawResults = (data['rawResults'] as List<dynamic>?)?.cast<int>() ?? [];

            // Only include if we have valid raw results
            if (rawResults.isNotEmpty) {
              Map<Benchmark, double>? benchmarks;

              // Calculate benchmarks if we have complete data (37 values)
              if (rawResults.length == 37) {
                try {
                  benchmarks = _calculateBenchmarks(rawResults);
                } catch (e) {
                  _logger.warning('Failed to calculate benchmarks for $email: $e');
                }
              }

              dataPoints.add(
                EmailDataPoint(
                  email: email,
                  rawResults: rawResults,
                  benchmarks: benchmarks,
                ),
              );
            }
          }
        } catch (e) {
          _logger.warning('Failed to fetch document $docId: $e');
          // Continue with other documents even if one fails
        }
      }

      //logger.info('Successfully fetched ${dataPoints.length} data points');
      return dataPoints;
    } catch (e) {
      _logger.severe('Error fetching group raw data: $e');
      rethrow;
    }
  }

  /// Calculate benchmarks from raw results (copied from BlockNotifier)
  static Map<Benchmark, double> _calculateBenchmarks(List<int> rawResults) {
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

    benchmarks[Benchmark.orgIndex] = (alignP * 0.4) + (processP * 0.3) + (peopleP * 0.3);
    benchmarks[Benchmark.workforce] = (engagement + productivity) / 2.0;
    benchmarks[Benchmark.operations] = (leadershipP + benchmarks[Benchmark.orgIndex]!) / 2.0;

    return benchmarks;
  }

  /// Get color for heatmap based on question value (1-7 scale)
  /// 1-2: dark red, 3: red, 4: orange, 5: grey, 6: green, 7: green
  static Color getHeatmapColor(int value) {
    if (value < 1 || value > 7) return Colors.grey;

    switch (value) {
      case 1:
      case 2:
        return Colors.red.shade900; // Dark red
      case 3:
        return Colors.red.shade600; // Red
      case 4:
        return Colors.orange.shade600; // Orange
      case 5:
        return Colors.grey.shade500; // Grey
      case 6:
        return Colors.green.shade600; // Green
      case 7:
        return Colors.green.shade700; // Darker green
      default:
        return Colors.grey;
    }
  }

  /// Get color for benchmark indicators (0-1 scale, displayed as percentages)
  /// <30%: dark red, 30-40%: red, 40-50%: orange, 50-60%: grey, 60-70%: green, 70%+: dark green
  static Color getBenchmarkColor(double value) {
    if (value < 0 || value > 1) return Colors.grey;

    final percentage = value * 100;

    if (percentage < 30) {
      return Colors.red.shade900; // Dark red
    } else if (percentage < 40) {
      return Colors.red.shade600; // Red
    } else if (percentage < 50) {
      return Colors.orange.shade600; // Orange
    } else if (percentage < 60) {
      return Colors.grey.shade500; // Grey
    } else if (percentage < 70) {
      return Colors.green.shade600; // Green
    } else {
      return Colors.green.shade800; // Dark green
    }
  }

  static Color getIQRColor(double value) {
    if (value < 0 || value > 1) return Colors.grey;

    final percentage = value * 100;

    if (percentage < 30) {
      return Colors.red.shade900; // Dark red
    } else if (percentage < 40) {
      return Colors.red.shade600; // Red
    } else if (percentage < 50) {
      return Colors.orange.shade600; // Orange
    } else if (percentage < 60) {
      return Colors.grey.shade500; // Grey
    } else if (percentage < 70) {
      return Colors.green.shade600; // Green
    } else {
      return Colors.green.shade800; // Dark green
    }
  }
}
