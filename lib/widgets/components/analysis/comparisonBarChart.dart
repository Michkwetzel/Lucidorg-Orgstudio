import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:platform_v2/config/enums.dart';
import 'package:platform_v2/config/provider.dart';
import 'package:platform_v2/services/analysisDataService.dart';

class ComparisonBarChart extends ConsumerWidget {
  final Map<String, List<EmailDataPoint>> groupedDataPoints;
  final AnalysisSubType analysisSubType;
  final Map<String, String> groupIdToNameMap; // Kept for backward compatibility, but will use GroupsNotifier

  const ComparisonBarChart({
    super.key,
    required this.groupedDataPoints,
    required this.analysisSubType,
    required this.groupIdToNameMap,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (groupedDataPoints.isEmpty) {
      return const Center(
        child: Text('No data available for comparison'),
      );
    }

    return Container(
      width: 1460,
      height: 460,
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          _buildHeader(ref),
          const SizedBox(height: 16),
          Expanded(
            child: analysisSubType == AnalysisSubType.questions
                ? _buildQuestionsChart(ref)
                : _buildIndicatorsChart(ref),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(WidgetRef ref) {
    final groupsNotifier = ref.watch(groupsProvider);
    
    final groupNames = groupedDataPoints.keys.map((groupId) {
      if (groupsNotifier.groups.isNotEmpty) {
        try {
          final group = groupsNotifier.groups.firstWhere((g) => g.id == groupId);
          return group.groupName;
        } catch (e) {
          // Group not found, use fallback
          return groupIdToNameMap[groupId] ?? groupId;
        }
      }
      return groupIdToNameMap[groupId] ?? groupId;
    }).toList();
    
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          analysisSubType == AnalysisSubType.questions
              ? 'Questions Comparison (1-7 Scale)'
              : 'Indicators Comparison (0-100%)',
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        Wrap(
          spacing: 16,
          children: groupNames.asMap().entries.map((entry) {
            final index = entry.key;
            final groupName = entry.value;
            return Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 12,
                  height: 12,
                  decoration: BoxDecoration(
                    color: _getGroupColor(index),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(width: 4),
                Text(
                  groupName,
                  style: const TextStyle(fontSize: 12),
                ),
              ],
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildQuestionsChart(WidgetRef ref) {
    final groupData = _calculateQuestionsAverages();
    if (groupData.isEmpty) {
      return const Center(child: Text('No question data available'));
    }

    return BarChart(
      BarChartData(
        alignment: BarChartAlignment.spaceAround,
        maxY: 7.0,
        minY: 1.0,
        barTouchData: BarTouchData(
          enabled: true,
          touchTooltipData: BarTouchTooltipData(
            getTooltipItem: (group, groupIndex, rod, rodIndex) {
              final groupIds = groupedDataPoints.keys.toList();
              final groupsNotifier = ref.read(groupsProvider);
              String groupName = groupIds[rodIndex];
              
              if (groupsNotifier.groups.isNotEmpty) {
                try {
                  final groupData = groupsNotifier.groups.firstWhere((g) => g.id == groupIds[rodIndex]);
                  groupName = groupData.groupName;
                } catch (e) {
                  // Group not found, keep default
                }
              }
              
              return BarTooltipItem(
                '$groupName\nQ${group.x + 1}: ${rod.toY.toStringAsFixed(2)}',
                const TextStyle(color: Colors.white, fontSize: 12),
              );
            },
          ),
        ),
        titlesData: FlTitlesData(
          show: true,
          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (double value, TitleMeta meta) {
                final questionNumber = (value + 1).toInt();
                if (questionNumber > 37) return const Text('');
                return Padding(
                  padding: const EdgeInsets.only(top: 4.0),
                  child: Text(
                    'Q$questionNumber',
                    style: const TextStyle(fontSize: 10),
                  ),
                );
              },
            ),
          ),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (double value, TitleMeta meta) {
                return Text(
                  value.toInt().toString(),
                  style: const TextStyle(fontSize: 10),
                );
              },
            ),
          ),
        ),
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          horizontalInterval: 1,
          getDrawingHorizontalLine: (value) {
            return FlLine(
              color: Colors.grey.shade300,
              strokeWidth: 0.5,
            );
          },
        ),
        borderData: FlBorderData(
          show: true,
          border: Border.all(color: Colors.grey.shade300),
        ),
        barGroups: groupData,
      ),
    );
  }

  Widget _buildIndicatorsChart(WidgetRef ref) {
    final groupData = _calculateIndicatorAverages();
    if (groupData.isEmpty) {
      return const Center(child: Text('No indicator data available'));
    }

    return BarChart(
      BarChartData(
        alignment: BarChartAlignment.spaceAround,
        maxY: 100.0,
        minY: 0.0,
        barTouchData: BarTouchData(
          enabled: true,
          touchTooltipData: BarTouchTooltipData(
            getTooltipItem: (group, groupIndex, rod, rodIndex) {
              final groupIds = groupedDataPoints.keys.toList();
              final groupsNotifier = ref.read(groupsProvider);
              String groupName = groupIds[rodIndex];
              
              if (groupsNotifier.groups.isNotEmpty) {
                try {
                  final groupData = groupsNotifier.groups.firstWhere((g) => g.id == groupIds[rodIndex]);
                  groupName = groupData.groupName;
                } catch (e) {
                  // Group not found, keep default
                }
              }
              
              final indicators = Benchmark.values.where((b) => 
                b != Benchmark.alignP && 
                b != Benchmark.processP && 
                b != Benchmark.peopleP && 
                b != Benchmark.leadershipP
              ).toList();
              
              if (group.x >= indicators.length) return null;
              
              final indicatorName = _getIndicatorDisplayName(indicators[group.x]);
              return BarTooltipItem(
                '$groupName\n$indicatorName: ${rod.toY.toStringAsFixed(1)}%',
                const TextStyle(color: Colors.white, fontSize: 12),
              );
            },
          ),
        ),
        titlesData: FlTitlesData(
          show: true,
          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (double value, TitleMeta meta) {
                final indicators = Benchmark.values.where((b) => 
                  b != Benchmark.alignP && 
                  b != Benchmark.processP && 
                  b != Benchmark.peopleP && 
                  b != Benchmark.leadershipP
                ).toList();
                
                final index = value.toInt();
                if (index >= indicators.length) return const Text('');
                
                return Padding(
                  padding: const EdgeInsets.only(top: 4.0),
                  child: Text(
                    _getIndicatorShortName(indicators[index]),
                    style: const TextStyle(fontSize: 9),
                    textAlign: TextAlign.center,
                  ),
                );
              },
            ),
          ),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (double value, TitleMeta meta) {
                return Text(
                  '${value.toInt()}%',
                  style: const TextStyle(fontSize: 10),
                );
              },
            ),
          ),
        ),
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          horizontalInterval: 20,
          getDrawingHorizontalLine: (value) {
            return FlLine(
              color: Colors.grey.shade300,
              strokeWidth: 0.5,
            );
          },
        ),
        borderData: FlBorderData(
          show: true,
          border: Border.all(color: Colors.grey.shade300),
        ),
        barGroups: groupData,
      ),
    );
  }

  List<BarChartGroupData> _calculateQuestionsAverages() {
    if (groupedDataPoints.isEmpty) return [];

    final groupIds = groupedDataPoints.keys.toList();
    final List<BarChartGroupData> barGroups = [];

    // Process each question (Q1 to Q37)
    for (int questionIndex = 0; questionIndex < 37; questionIndex++) {
      final List<BarChartRodData> rods = [];

      // Calculate average for each group
      for (int groupIndex = 0; groupIndex < groupIds.length; groupIndex++) {
        final groupId = groupIds[groupIndex];
        final dataPoints = groupedDataPoints[groupId] ?? [];
        
        if (dataPoints.isEmpty) {
          rods.add(BarChartRodData(
            toY: 0,
            color: _getGroupColor(groupIndex),
            width: 8,
          ));
          continue;
        }

        double sum = 0;
        int count = 0;
        
        for (final dataPoint in dataPoints) {
          if (dataPoint.rawResults.length > questionIndex) {
            sum += dataPoint.rawResults[questionIndex];
            count++;
          }
        }

        final average = count > 0 ? sum / count : 0.0;
        
        rods.add(BarChartRodData(
          toY: average.toDouble(),
          color: _getGroupColor(groupIndex),
          width: 8,
        ));
      }

      barGroups.add(BarChartGroupData(
        x: questionIndex,
        barRods: rods,
        barsSpace: 2,
      ));
    }

    return barGroups;
  }

  List<BarChartGroupData> _calculateIndicatorAverages() {
    if (groupedDataPoints.isEmpty) return [];

    final groupIds = groupedDataPoints.keys.toList();
    final List<BarChartGroupData> barGroups = [];

    // Get indicators excluding pillar calculations
    final indicators = Benchmark.values.where((b) => 
      b != Benchmark.alignP && 
      b != Benchmark.processP && 
      b != Benchmark.peopleP && 
      b != Benchmark.leadershipP
    ).toList();

    // Process each indicator
    for (int indicatorIndex = 0; indicatorIndex < indicators.length; indicatorIndex++) {
      final indicator = indicators[indicatorIndex];
      final List<BarChartRodData> rods = [];

      // Calculate average for each group
      for (int groupIndex = 0; groupIndex < groupIds.length; groupIndex++) {
        final groupId = groupIds[groupIndex];
        final dataPoints = groupedDataPoints[groupId] ?? [];
        
        if (dataPoints.isEmpty) {
          rods.add(BarChartRodData(
            toY: 0,
            color: _getGroupColor(groupIndex),
            width: 12,
          ));
          continue;
        }

        double sum = 0;
        int count = 0;
        
        for (final dataPoint in dataPoints) {
          if (dataPoint.benchmarks != null && dataPoint.benchmarks!.containsKey(indicator)) {
            sum += dataPoint.benchmarks![indicator]!;
            count++;
          }
        }

        final average = count > 0 ? sum / count : 0.0;
        
        // Convert from 0-1 scale to 0-100 percentage
        rods.add(BarChartRodData(
          toY: (average * 100).toDouble(),
          color: _getGroupColor(groupIndex),
          width: 12,
        ));
      }

      barGroups.add(BarChartGroupData(
        x: indicatorIndex,
        barRods: rods,
        barsSpace: 4,
      ));
    }

    return barGroups;
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

  String _getIndicatorDisplayName(Benchmark indicator) {
    switch (indicator) {
      case Benchmark.growthAlign:
        return 'Growth Alignment';
      case Benchmark.orgAlign:
        return 'Org Alignment';
      case Benchmark.collabKPIs:
        return 'Collaborative KPIs';
      case Benchmark.crossFuncComms:
        return 'Cross-Functional Communications';
      case Benchmark.crossFuncAcc:
        return 'Cross-Functional Accountability';
      case Benchmark.engagedCommunity:
        return 'Engaged Community';
      case Benchmark.collabProcesses:
        return 'Collaborative Processes';
      case Benchmark.alignedTech:
        return 'Aligned Technology';
      case Benchmark.meetingEfficacy:
        return 'Meeting Efficacy';
      case Benchmark.empoweredLeadership:
        return 'Empowered Leadership';
      case Benchmark.purposeDriven:
        return 'Purpose Driven';
      case Benchmark.engagement:
        return 'Engagement';
      case Benchmark.productivity:
        return 'Productivity';
      case Benchmark.orgIndex:
        return 'Organization Index';
      case Benchmark.workforce:
        return 'Workforce';
      case Benchmark.operations:
        return 'Operations';
      default:
        return indicator.toString();
    }
  }
}