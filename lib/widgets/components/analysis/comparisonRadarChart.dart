import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:platform_v2/config/enums.dart';
import 'package:platform_v2/config/provider.dart';
import 'package:platform_v2/services/analysisDataService.dart';

class ComparisonRadarChart extends ConsumerWidget {
  final Map<String, List<EmailDataPoint>> groupedDataPoints;
  final AnalysisSubType analysisSubType;
  final Set<int> selectedQuestions;
  final Set<Benchmark> selectedIndicators;
  final bool showHeader;

  const ComparisonRadarChart({
    super.key,
    required this.groupedDataPoints,
    required this.analysisSubType,
    required this.selectedQuestions,
    required this.selectedIndicators,
    this.showHeader = true,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (groupedDataPoints.isEmpty) {
      return const Center(
        child: Text('No data available for comparison'),
      );
    }

    return Container(
      width: showHeader ? 1460 : null, // Only constrain width when showing header
      height: 460,
      padding: EdgeInsets.all(showHeader ? 20 : 10), // Less padding when side-by-side
      child: Column(
        children: [
          if (showHeader) ...[
            _buildHeader(ref),
            const SizedBox(height: 16),
          ],
          Expanded(
            child: Row(
              children: [
                Expanded(
                  flex: 3,
                  child: _buildRadarChart(ref),
                ),
                const SizedBox(width: 20),
                SizedBox(
                  width: 200,
                  child: _buildLegend(ref),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(WidgetRef ref) {
    return Row(
      children: [
        Text(
          analysisSubType == AnalysisSubType.questions 
              ? 'Questions Comparison - Radar Chart (1-7 Scale)' 
              : 'Indicators Comparison - Radar Chart (0-100%)',
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Widget _buildLegend(WidgetRef ref) {
    final groupsNotifier = ref.watch(groupsProvider);
    final groupNames = <String>[];
    
    for (String groupId in groupedDataPoints.keys) {
      if (groupsNotifier.groups.isNotEmpty) {
        try {
          final group = groupsNotifier.groups.firstWhere((g) => g.id == groupId);
          groupNames.add(group.groupName);
        } catch (e) {
          groupNames.add(groupId);
        }
      } else {
        groupNames.add(groupId);
      }
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Groups',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: Colors.grey.shade700,
          ),
        ),
        const SizedBox(height: 12),
        ...groupNames.asMap().entries.map((entry) {
          final index = entry.key;
          final groupName = entry.value;
          return Padding(
            padding: const EdgeInsets.only(bottom: 8.0),
            child: Row(
              children: [
                Container(
                  width: 12,
                  height: 12,
                  decoration: BoxDecoration(
                    color: _getGroupColor(index),
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    groupName,
                    style: const TextStyle(fontSize: 12),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ],
    );
  }

  Widget _buildRadarChart(WidgetRef ref) {
    final radarDataSets = _buildRadarDataSets();
    
    if (radarDataSets.isEmpty) {
      return const Center(
        child: Text('No data available for radar chart'),
      );
    }

    final dataLabels = _getDataLabels();
    
    return RadarChart(
      RadarChartData(
        dataSets: radarDataSets,
        radarBackgroundColor: Colors.transparent,
        borderData: FlBorderData(show: false),
        radarBorderData: const BorderSide(color: Colors.grey, width: 1),
        titlePositionPercentageOffset: 0.2,
        titleTextStyle: const TextStyle(
          color: Colors.black87,
          fontSize: 10,
        ),
        getTitle: (index, angle) {
          if (index >= dataLabels.length) return RadarChartTitle(text: '');
          return RadarChartTitle(
            text: dataLabels[index],
            angle: 0, // Always horizontal
          );
        },
        tickCount: analysisSubType == AnalysisSubType.questions ? 7 : 5,
        ticksTextStyle: const TextStyle(
          color: Colors.grey,
          fontSize: 8,
        ),
        tickBorderData: const BorderSide(color: Colors.grey, width: 1),
        gridBorderData: const BorderSide(color: Colors.grey, width: 0.5),
      ),
    );
  }

  List<RadarDataSet> _buildRadarDataSets() {
    final dataSets = <RadarDataSet>[];
    final groupIds = groupedDataPoints.keys.toList();

    for (int groupIndex = 0; groupIndex < groupIds.length; groupIndex++) {
      final groupId = groupIds[groupIndex];
      final dataPoints = groupedDataPoints[groupId] ?? [];
      
      print('DEBUG RADAR: Group $groupId (index $groupIndex) has ${dataPoints.length} data points');
      
      if (dataPoints.isEmpty) {
        print('DEBUG RADAR: Group $groupId has no data points - skipping');
        continue;
      }

      final radarEntries = analysisSubType == AnalysisSubType.questions 
          ? _buildQuestionRadarEntries(dataPoints, groupId)
          : _buildIndicatorRadarEntries(dataPoints, groupId);

      print('DEBUG RADAR: Group $groupId has ${radarEntries.length} radar entries');

      if (radarEntries.isNotEmpty) {
        dataSets.add(
          RadarDataSet(
            fillColor: _getGroupColor(groupIndex).withOpacity(0.1),
            borderColor: _getGroupColor(groupIndex),
            entryRadius: 3,
            dataEntries: radarEntries,
            borderWidth: 2,
          ),
        );
        print('DEBUG RADAR: Added radar dataset for group $groupId');
      } else {
        print('DEBUG RADAR: Group $groupId has no valid radar entries - skipping');
      }
    }

    return dataSets;
  }

  List<RadarEntry> _buildQuestionRadarEntries(List<EmailDataPoint> dataPoints, String groupId) {
    final selectedQuestionsList = selectedQuestions.toList()..sort();
    final entries = <RadarEntry>[];

    for (int questionIndex = 0; questionIndex < selectedQuestionsList.length; questionIndex++) {
      final questionNumber = selectedQuestionsList[questionIndex];
      final actualQuestionIndex = questionNumber - 1; // Convert to 0-based index
      
      double sum = 0;
      int count = 0;

      for (final dataPoint in dataPoints) {
        if (dataPoint.rawResults.length > actualQuestionIndex) {
          sum += dataPoint.rawResults[actualQuestionIndex];
          count++;
        } else {
          print('DEBUG RADAR: Group $groupId - DataPoint has rawResults length ${dataPoint.rawResults.length}, needed $actualQuestionIndex for Q$questionNumber');
        }
      }

      final average = count > 0 ? sum / count : 1.0;
      
      if (count == 0) {
        print('DEBUG RADAR: Group $groupId Q$questionNumber has no valid data - using default 1.0');
      } else {
        print('DEBUG RADAR: Group $groupId Q$questionNumber average: $average (from $count data points)');
      }
      
      entries.add(RadarEntry(value: average));
    }

    return entries;
  }

  List<RadarEntry> _buildIndicatorRadarEntries(List<EmailDataPoint> dataPoints, String groupId) {
    final availableIndicators = indicators();
    final selectedIndicatorsList = selectedIndicators.where((ind) => availableIndicators.contains(ind)).toList();
    final entries = <RadarEntry>[];

    for (final indicator in selectedIndicatorsList) {
      double sum = 0;
      int count = 0;

      for (final dataPoint in dataPoints) {
        if (dataPoint.benchmarks != null && dataPoint.benchmarks!.containsKey(indicator)) {
          sum += dataPoint.benchmarks![indicator]!;
          count++;
        } else {
          print('DEBUG RADAR: Group $groupId - DataPoint missing benchmark ${indicator.name}');
        }
      }

      final average = count > 0 ? sum / count : 0.0;
      
      if (count == 0) {
        print('DEBUG RADAR: Group $groupId ${indicator.name} has no valid benchmark data - using 5.0%');
        entries.add(RadarEntry(value: 5.0)); // Show at 5% to make it visible
      } else {
        final percentage = average * 100;
        print('DEBUG RADAR: Group $groupId ${indicator.name} average: ${percentage.toStringAsFixed(1)}% (from $count data points)');
        entries.add(RadarEntry(value: percentage));
      }
    }

    return entries;
  }

  List<String> _getDataLabels() {
    if (analysisSubType == AnalysisSubType.questions) {
      final selectedQuestionsList = selectedQuestions.toList()..sort();
      return selectedQuestionsList.map((q) => 'Q$q').toList();
    } else {
      final availableIndicators = indicators();
      final selectedIndicatorsList = selectedIndicators.where((ind) => availableIndicators.contains(ind)).toList();
      return selectedIndicatorsList.map((indicator) => _getIndicatorShortName(indicator)).toList();
    }
  }

  Color _getGroupColor(int index) {
    final colors = [
      Colors.blue.shade600,
      Colors.green.shade600,
      Colors.orange.shade600,
      Colors.purple.shade600,
      Colors.red.shade600,
      Colors.teal.shade600,
      Colors.amber.shade600,
      Colors.indigo.shade600,
    ];
    return colors[index % colors.length];
  }

  String _getIndicatorShortName(Benchmark indicator) {
    switch (indicator) {
      case Benchmark.growthAlign:
        return 'Growth\nAlign';
      case Benchmark.orgAlign:
        return 'Org\nAlign';
      case Benchmark.collabKPIs:
        return 'Collab\nKPIs';
      case Benchmark.crossFuncComms:
        return 'Cross\nComms';
      case Benchmark.crossFuncAcc:
        return 'Cross\nAcc';
      case Benchmark.engagedCommunity:
        return 'Engaged\nComm';
      case Benchmark.collabProcesses:
        return 'Collab\nProc';
      case Benchmark.alignedTech:
        return 'Aligned\nTech';
      case Benchmark.meetingEfficacy:
        return 'Meeting\nEff';
      case Benchmark.empoweredLeadership:
        return 'Emp\nLead';
      case Benchmark.purposeDriven:
        return 'Purpose\nDriven';
      case Benchmark.engagement:
        return 'Engage';
      case Benchmark.productivity:
        return 'Product';
      case Benchmark.orgIndex:
        return 'Org\nIndex';
      case Benchmark.workforce:
        return 'Work\nforce';
      case Benchmark.operations:
        return 'Operations';
      default:
        return indicator.toString();
    }
  }
}