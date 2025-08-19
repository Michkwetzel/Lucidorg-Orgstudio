import 'package:flutter/material.dart';
import 'package:platform_v2/abstractClasses/analysisBlockBehaviorStrategy.dart';
import 'package:platform_v2/abstractClasses/analysisBlockContext.dart';
import 'package:platform_v2/config/enums.dart';
import 'package:platform_v2/services/analysisDataService.dart';
import 'package:platform_v2/widgets/components/analysis/questionHeatmapTable.dart';
import 'package:platform_v2/widgets/components/analysis/indicatorTable.dart';
import 'package:platform_v2/widgets/components/analysis/comparisonBarChart.dart';

/// Strategy for analysis blocks that display internal statistics with data visualization
class AnalysisInternalStatsStrategy extends AnalysisBlockBehaviorStrategy {
  @override
  Widget getBlockWidget(AnalysisBlockContext context) {
    // Larger block size for actual data tables
    final analysisNotifier = context.analysisBlockNotifier;

    final blockWidth = analysisNotifier.blockData.analysisSubType == AnalysisSubType.questions ? 1500.0 : 1500.0;
    const blockHeight = 500.0; // Increased height to accommodate configuration header

    return SizedBox(
      width: blockWidth + (context.hitboxOffset * 2),
      height: blockHeight + (context.hitboxOffset * 2),
      child: Container(
        margin: EdgeInsets.all(context.hitboxOffset),
        width: blockWidth,
        height: blockHeight,
        decoration: blockDecoration(context),
        child: blockData(context),
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

    // Show loading state
    if (analysisNotifier.analysisDataLoading) {
      return _buildLoadingState();
    }

    // Show error state
    if (analysisNotifier.analysisDataError != null) {
      return _buildErrorState('Error loading data: ${analysisNotifier.analysisDataError}');
    }

    // Show empty state
    if (analysisNotifier.analysisData.isEmpty) {
      return _buildEmptyState('No data available for selected group(s)');
    }

    // Show lightweight placeholder during drag, full table when not dragging
    if (analysisNotifier.isDragging) {
      return _buildDragPlaceholder(blockData, analysisNotifier.analysisData);
    }

    // Show data visualization
    return _buildDataVisualization(blockData, analysisNotifier.analysisData, analysisNotifier);
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

  Widget _buildLoadingState() {
    return const Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        CircularProgressIndicator(),
        SizedBox(height: 8),
        Text(
          'Loading data...',
          style: TextStyle(fontSize: 12, color: Colors.grey),
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

  Widget _buildDragPlaceholder(blockData, List<EmailDataPoint> dataPoints) {
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
            '${dataPoints.length} responses • Dragging...',
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey.shade500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDataVisualization(blockData, List<EmailDataPoint> dataPoints, analysisNotifier) {
    // Check if this is group comparison - show bar chart for any number of groups
    if (blockData.isGroupComparison) {
      return _buildComparisonChart(blockData, dataPoints, analysisNotifier);
    }

    // Wrap in RepaintBoundary to isolate from position changes during dragging
    return RepaintBoundary(
      child: blockData.analysisSubType == AnalysisSubType.questions
          ? QuestionHeatmapTable(
              dataPoints: dataPoints,
              isCompact: false, // Use full table view
              // Pass pre-calculated data to avoid expensive calculations on rebuild
              maxQuestions: analysisNotifier.maxQuestions,
              processedEmails: analysisNotifier.processedEmails,
              heatmapColors: analysisNotifier.heatmapColors,
              questionStatistics: analysisNotifier.questionStatistics,
            )
          : blockData.analysisSubType == AnalysisSubType.indicators
          ? IndicatorTable(
              dataPoints: dataPoints,
              isCompact: false, // Use full table view
              indicatorStatistics: analysisNotifier.indicatorStatistics,
            )
          : _buildErrorState('Unknown analysis sub-type'),
    );
  }

  Widget _buildComparisonChart(blockData, List<EmailDataPoint> dataPoints, analysisNotifier) {
    // Use the properly grouped data from the notifier
    final Map<String, List<EmailDataPoint>> groupedDataPoints = analysisNotifier.groupedAnalysisData;
    
    if (groupedDataPoints.isEmpty) {
      return const Center(
        child: Text('No grouped data available for comparison'),
      );
    }

    return RepaintBoundary(
      child: ComparisonBarChart(
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
}
