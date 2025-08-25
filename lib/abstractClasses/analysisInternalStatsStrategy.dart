import 'package:flutter/material.dart';
import 'package:platform_v2/abstractClasses/analysisBlockBehaviorStrategy.dart';
import 'package:platform_v2/abstractClasses/analysisBlockContext.dart';
import 'package:platform_v2/config/enums.dart';
import 'package:platform_v2/config/provider.dart';
import 'package:platform_v2/notifiers/general/blockNotifier.dart';
import 'package:platform_v2/services/analysisDataService.dart';
import 'package:platform_v2/widgets/components/analysis/questionHeatmapTable.dart';
import 'package:platform_v2/widgets/components/analysis/indicatorTable.dart';
import 'package:platform_v2/widgets/components/analysis/comparisonChartSelector.dart';

/// Strategy for analysis blocks that display internal statistics with data visualization
class AnalysisInternalStatsStrategy extends AnalysisBlockBehaviorStrategy {
  @override
  Widget getBlockWidget(AnalysisBlockContext context) {
    // Larger block size for actual data tables
    final analysisNotifier = context.analysisBlockNotifier;
    final blockData = analysisNotifier.blockData;

    // Adjust size based on chart type for group comparison blocks
    double blockWidth = 1500.0;
    double blockHeight = 500.0;
    
    if (blockData.isGroupComparison) {
      switch (blockData.chartType) {
        case ChartType.bar:
          blockWidth = 1500.0;
          blockHeight = 500.0;
          break;
        case ChartType.radar:
          blockWidth = 900.0; // Good width for radar
          blockHeight = 750.0; // Much taller for radar
          break;
        case ChartType.both:
          blockWidth = 2500.0; // Much wider for both
          blockHeight = 750.0; // Taller for both
          break;
      }
    }

    return SizedBox(
      width: blockWidth + (context.hitboxOffset * 2),
      height: blockHeight + (context.hitboxOffset * 2),
      child: Container(
        margin: EdgeInsets.all(context.hitboxOffset),
        width: blockWidth,
        height: blockHeight,
        decoration: blockDecoration(context),
        child: this.blockData(context),
      ),
    );
  }

  @override
  Widget blockData(AnalysisBlockContext context) {
    final analysisNotifier = context.analysisBlockNotifier;
    final blockData = analysisNotifier.blockData;

    // Check if block is properly configured
    if (blockData.analysisBlockType == AnalysisBlockType.none || blockData.analysisSubType == AnalysisSubType.none || blockData.groupIds.isEmpty) {
      return _buildConfigurationPrompt(blockData);
    }

    // For Group Analysis, we should have exactly 1 group
    if (blockData.isGroupAnalysis && blockData.groupIds.length != 1) {
      return _buildErrorState('Group Analysis requires exactly 1 group');
    }

    // Show lightweight placeholder during drag
    if (analysisNotifier.isDragging) {
      return _buildDragPlaceholder(blockData);
    }

    // Show data visualization
    return _buildDataVisualization(blockData, analysisNotifier, context);
  }

  Widget _buildConfigurationPrompt(blockData) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(
          Icons.settings,
          size: 40,
          color: Colors.orange.shade600,
        ),
        const SizedBox(height: 8),
        Text(
          blockData.blockName.isNotEmpty ? blockData.blockName : 'Internal Stats',
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.all(8),
          margin: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            color: Colors.orange.shade50,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.orange.shade300),
          ),
          child: Text(
            'Configure analysis type and select groups',
            style: TextStyle(
              fontSize: 12,
              color: Colors.orange.shade700,
            ),
            textAlign: TextAlign.center,
          ),
        ),
      ],
    );
  }


  Widget _buildErrorState(String message) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(
          Icons.error_outline,
          size: 40,
          color: Colors.red.shade600,
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.all(8),
          margin: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            color: Colors.red.shade50,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.red.shade300),
          ),
          child: Text(
            message,
            style: TextStyle(
              fontSize: 11,
              color: Colors.red.shade700,
            ),
            textAlign: TextAlign.center,
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyState(String message) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(
          Icons.inbox_outlined,
          size: 40,
          color: Colors.grey.shade600,
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.all(8),
          margin: const EdgeInsets.symmetric(horizontal: 16),
          child: Text(
            message,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey.shade600,
            ),
            textAlign: TextAlign.center,
          ),
        ),
      ],
    );
  }

  Widget _buildDragPlaceholder(blockData) {
    return Container(
      width: 1000,
      height: 400,
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            blockData.analysisSubType == AnalysisSubType.questions ? Icons.grid_on : Icons.analytics,
            size: 48,
            color: Colors.grey.shade400,
          ),
          const SizedBox(height: 12),
          Text(
            blockData.analysisSubType == AnalysisSubType.questions ? 'Questions Heatmap' : 'Indicators Table',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.grey.shade600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Dragging...',
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey.shade500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDataVisualization(blockData, analysisNotifier, context) {
    // Check if this is group comparison - show bar chart for any number of groups
    if (blockData.isGroupComparison) {
      return _buildComparisonChart(blockData, analysisNotifier, context);
    }

    // For Group Analysis, get individual email data from the notifier
    // Build blockNotifiers map from the selected groups
    final selectedGroups = analysisNotifier.getSelectedGroups();
    final Map<String, BlockNotifier> blockNotifiers = {};
    
    for (final group in selectedGroups) {
      for (final blockId in group.blockIds) {
        if (!blockNotifiers.containsKey(blockId)) {
          blockNotifiers[blockId] = context.ref.read(blockNotifierProvider(blockId));
        }
      }
    }
    
    final emailData = analysisNotifier.getIndividualEmailData(blockNotifiers);
    
    if (emailData.isEmpty) {
      return _buildEmptyState('No data available for selected group(s)');
    }

    // Convert to EmailDataPoint format for the tables
    final List<EmailDataPoint> dataPoints = <EmailDataPoint>[];
    
    for (final data in emailData) {
      try {
        final rawResultsList = data['rawResults'] as List;
        final List<int> intResults = [];
        
        // Safely convert each element to int
        for (final result in rawResultsList) {
          if (result is int) {
            intResults.add(result);
          } else if (result is double) {
            intResults.add(result.round());
          } else if (result is num) {
            intResults.add(result.toInt());
          } else {
            intResults.add(0); // fallback
          }
        }
        
        // Calculate benchmarks for indicator display
        Map<Benchmark, double>? benchmarks;
        try {
          if (intResults.length == 37) {
            benchmarks = _calculateBenchmarks(intResults);
          }
        } catch (e) {
          // If calculation fails, leave benchmarks as null
          benchmarks = null;
        }
        
        dataPoints.add(EmailDataPoint(
          email: data['email'] as String,
          rawResults: intResults,
          benchmarks: benchmarks,
        ));
      } catch (e) {
        // Skip this data point if conversion fails
        continue;
      }
    }

    // Wrap in RepaintBoundary to isolate from position changes during dragging
    return RepaintBoundary(
      child: blockData.analysisSubType == AnalysisSubType.questions
          ? QuestionHeatmapTable(
              dataPoints: dataPoints,
              isCompact: false, // Use full table view
            )
          : blockData.analysisSubType == AnalysisSubType.indicators
          ? IndicatorTable(
              dataPoints: dataPoints,
              isCompact: false, // Use full table view
            )
          : _buildErrorState('Unknown analysis sub-type'),
    );
  }

  Widget _buildComparisonChart(blockData, analysisNotifier, context) {
    // For Group Comparison, get group data from the notifier
    final groupData = analysisNotifier.getGroupComparisonData();
    
    if (groupData.isEmpty) {
      return const Center(
        child: Text('No group data available for comparison'),
      );
    }

    // Convert group data to the format expected by ComparisonChartSelector
    final Map<String, List<EmailDataPoint>> groupedDataPoints = {};
    for (final group in groupData) {
      final groupId = group['groupId'] as String;
      final groupName = group['groupName'] as String;
      final averagedResults = group['averagedRawResults'] as List<double>;
      final List<int> intResults = averagedResults.map((e) => e.round()).toList();
      
      // Calculate benchmarks for the group averages
      Map<Benchmark, double>? benchmarks;
      try {
        benchmarks = _calculateBenchmarks(intResults);
      } catch (e) {
        // If calculation fails, leave benchmarks as null
        benchmarks = null;
      }
      
      // Create a single EmailDataPoint representing the group average
      groupedDataPoints[groupId] = [
        EmailDataPoint(
          email: groupName,
          rawResults: intResults,
          benchmarks: benchmarks,
        )
      ];
    }

    return RepaintBoundary(
      child: ComparisonChartSelector(
        groupedDataPoints: groupedDataPoints,
        analysisSubType: blockData.analysisSubType,
        groupIdToNameMap: const {}, // Chart will handle group name resolution internally
        selectedQuestions: blockData.selectedQuestions,
        selectedIndicators: blockData.selectedIndicators,
        onToggleQuestion: analysisNotifier.toggleQuestion,
        onToggleIndicator: analysisNotifier.toggleIndicator,
        onSelectAllQuestions: analysisNotifier.selectAllQuestions,
        onDeselectAllQuestions: analysisNotifier.deselectAllQuestions,
        onSelectAllIndicators: analysisNotifier.selectAllIndicators,
        onDeselectAllIndicators: analysisNotifier.deselectAllIndicators,
        chartType: blockData.chartType,
        onChartTypeChanged: analysisNotifier.changeChartType,
      ),
    );
  }

  @override
  BoxDecoration blockDecoration(AnalysisBlockContext context) {
    return BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(8),
      border: Border.all(color: Colors.purple.shade300, width: 2),
      boxShadow: const [
        BoxShadow(
          color: Colors.black26,
          blurRadius: 4,
          offset: Offset(0, 2),
        ),
      ],
    );
  }

  @override
  void onTap(AnalysisBlockContext context) {
    // Single tap can be used for selection or other interactions
    // For now, just basic feedback
    ScaffoldMessenger.of(context.buildContext).showSnackBar(
      SnackBar(
        content: Text('Analysis Block Selected'),
        duration: Duration(seconds: 1),
        backgroundColor: Colors.purple.shade600,
      ),
    );
  }


  @override
  void onDoubleTapDown(AnalysisBlockContext context) {
    // Double tap could be used for editing configuration
    // For now, just indicate functionality
    ScaffoldMessenger.of(context.buildContext).showSnackBar(
      SnackBar(
        content: Text('Use configuration panel to modify analysis settings'),
        duration: Duration(seconds: 2),
        backgroundColor: Colors.blue.shade600,
      ),
    );
  }

  @override
  void onPanUpdate(AnalysisBlockContext context, DragUpdateDetails details, double hitboxOffset) {
    // Handle block dragging
    final RenderBox? canvasBox = context.buildContext.findAncestorRenderObjectOfType<RenderBox>();
    if (canvasBox == null) return;

    final localPosition = canvasBox.globalToLocal(details.globalPosition);
    final newPosition = Offset(
      localPosition.dx - hitboxOffset,
      localPosition.dy - hitboxOffset,
    );

    context.analysisBlockNotifier.updatePosition(newPosition);
  }

  /// Calculate benchmarks from raw results (same logic as BlockNotifier)
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
    // Pillar Calculations
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
    
    // Calculate final indices
    double workforce = benchmarks[Benchmark.workforce]!;
    double operations = benchmarks[Benchmark.operations]!;
    benchmarks[Benchmark.orgIndex] = (workforce * 0.5) + (operations * 0.5);
    
    return benchmarks;
  }
}
