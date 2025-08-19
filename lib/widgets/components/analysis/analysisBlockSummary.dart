import 'package:flutter/material.dart';
import 'package:platform_v2/config/enums.dart';
import 'package:platform_v2/services/analysisDataService.dart';

class AnalysisBlockSummary extends StatelessWidget {
  final List<EmailDataPoint> dataPoints;
  final AnalysisSubType subType;
  final bool isGroupComparison;

  const AnalysisBlockSummary({
    super.key,
    required this.dataPoints,
    required this.subType,
    required this.isGroupComparison,
  });

  @override
  Widget build(BuildContext context) {
    if (dataPoints.isEmpty) {
      return _buildEmptyState();
    }

    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(),
          const SizedBox(height: 8),
          Expanded(
            child: subType == AnalysisSubType.questions
                ? _buildQuestionsSummary()
                : _buildIndicatorsSummary(),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      children: [
        Icon(
          subType == AnalysisSubType.questions ? Icons.quiz : Icons.analytics,
          size: 16,
          color: Colors.blue.shade600,
        ),
        const SizedBox(width: 4),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                subType == AnalysisSubType.questions ? 'Questions' : 'Indicators',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: Colors.blue.shade700,
                ),
              ),
              Text(
                '${dataPoints.length} response${dataPoints.length != 1 ? 's' : ''}',
                style: TextStyle(
                  fontSize: 10,
                  color: Colors.grey.shade600,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildQuestionsSummary() {
    // Calculate average scores across all questions
    final allScores = <int>[];
    for (final dp in dataPoints) {
      allScores.addAll(dp.rawResults);
    }

    if (allScores.isEmpty) {
      return const Center(
        child: Text(
          'No question data',
          style: TextStyle(fontSize: 10, color: Colors.grey),
        ),
      );
    }

    final avgScore = allScores.reduce((a, b) => a + b) / allScores.length;
    final minScore = allScores.reduce((a, b) => a < b ? a : b);
    final maxScore = allScores.reduce((a, b) => a > b ? a : b);

    return Column(
      children: [
        // Score summary
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: AnalysisDataService.getHeatmapColor(avgScore.round()).withOpacity(0.1),
            borderRadius: BorderRadius.circular(6),
            border: Border.all(
              color: AnalysisDataService.getHeatmapColor(avgScore.round()).withOpacity(0.3),
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildScoreStat('Avg', avgScore, true),
              _buildScoreStat('Min', minScore.toDouble(), false),
              _buildScoreStat('Max', maxScore.toDouble(), false),
            ],
          ),
        ),
        const SizedBox(height: 8),
        // Mini heatmap preview - show first few responses
        if (dataPoints.isNotEmpty) _buildMiniHeatmap(),
      ],
    );
  }

  Widget _buildIndicatorsSummary() {
    final validDataPoints = dataPoints.where((dp) => dp.benchmarks != null).toList();
    
    if (validDataPoints.isEmpty) {
      return const Center(
        child: Text(
          'No indicator data',
          style: TextStyle(fontSize: 10, color: Colors.grey),
        ),
      );
    }

    // Calculate average performance across key indicators
    final keyIndicators = [
      Benchmark.orgAlign,
      Benchmark.engagement,
      Benchmark.productivity,
    ];

    final indicatorAvgs = <Benchmark, double>{};
    for (final indicator in keyIndicators) {
      final values = validDataPoints
          .map((dp) => dp.benchmarks![indicator])
          .where((value) => value != null)
          .cast<double>()
          .toList();
      
      if (values.isNotEmpty) {
        indicatorAvgs[indicator] = values.reduce((a, b) => a + b) / values.length;
      }
    }

    return Column(
      children: [
        // Performance bars
        ...indicatorAvgs.entries.map((entry) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 6),
            child: _buildPerformanceBar(
              _getIndicatorShortName(entry.key),
              entry.value,
            ),
          );
        }).toList(),
        
        if (indicatorAvgs.isNotEmpty) const SizedBox(height: 8),
        
        // Overall performance indicator
        if (indicatorAvgs.isNotEmpty)
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: Colors.blue.shade50,
              borderRadius: BorderRadius.circular(4),
              border: Border.all(color: Colors.blue.shade200),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.trending_up,
                  size: 12,
                  color: Colors.blue.shade600,
                ),
                const SizedBox(width: 4),
                Text(
                  'Overall: ${_getOverallRating(indicatorAvgs.values.toList())}',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w500,
                    color: Colors.blue.shade700,
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }

  Widget _buildScoreStat(String label, double value, bool isMain) {
    return Column(
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 8,
            color: Colors.grey.shade600,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 2),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
          decoration: BoxDecoration(
            color: isMain ? AnalysisDataService.getHeatmapColor(value.round()) : Colors.grey.shade200,
            borderRadius: BorderRadius.circular(3),
          ),
          child: Text(
            value.toStringAsFixed(1),
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.bold,
              color: isMain ? Colors.white : Colors.grey.shade700,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildMiniHeatmap() {
    final previewCount = dataPoints.length > 3 ? 3 : dataPoints.length;
    final questionsToShow = 8; // Show first 8 questions

    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Column(
        children: dataPoints.take(previewCount).map((dp) {
          return Container(
            height: 12,
            margin: const EdgeInsets.only(bottom: 2),
            child: Row(
              children: [
                SizedBox(
                  width: 20,
                  child: Text(
                    _getEmailInitials(dp.email),
                    style: const TextStyle(fontSize: 6),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 4),
                ...List.generate(
                  questionsToShow.clamp(0, dp.rawResults.length),
                  (index) {
                    final value = dp.rawResults[index];
                    return Container(
                      width: 6,
                      height: 6,
                      margin: const EdgeInsets.only(right: 1),
                      decoration: BoxDecoration(
                        color: AnalysisDataService.getHeatmapColor(value),
                        borderRadius: BorderRadius.circular(1),
                      ),
                    );
                  },
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildPerformanceBar(String label, double value) {
    return Row(
      children: [
        SizedBox(
          width: 30,
          child: Text(
            label,
            style: const TextStyle(fontSize: 9, fontWeight: FontWeight.w500),
            overflow: TextOverflow.ellipsis,
          ),
        ),
        const SizedBox(width: 4),
        Expanded(
          child: Container(
            height: 8,
            decoration: BoxDecoration(
              color: Colors.grey.shade200,
              borderRadius: BorderRadius.circular(4),
            ),
            child: FractionallySizedBox(
              alignment: Alignment.centerLeft,
              widthFactor: value.clamp(0.0, 1.0),
              child: Container(
                decoration: BoxDecoration(
                  color: AnalysisDataService.getBenchmarkColor(value),
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            ),
          ),
        ),
        const SizedBox(width: 4),
        Text(
          '${(value * 100).round()}%',
          style: const TextStyle(fontSize: 8, fontWeight: FontWeight.w500),
        ),
      ],
    );
  }

  Widget _buildEmptyState() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.inbox_outlined, size: 32, color: Colors.grey),
          SizedBox(height: 4),
          Text(
            'No data available',
            style: TextStyle(fontSize: 10, color: Colors.grey),
          ),
        ],
      ),
    );
  }

  String _getEmailInitials(String email) {
    final atIndex = email.indexOf('@');
    if (atIndex == -1) return email.length >= 2 ? email.substring(0, 2).toUpperCase() : email.toUpperCase();
    
    final username = email.substring(0, atIndex);
    return username.length >= 2 ? username.substring(0, 2).toUpperCase() : username.toUpperCase();
  }

  String _getIndicatorShortName(Benchmark indicator) {
    switch (indicator) {
      case Benchmark.orgAlign:
        return 'Align';
      case Benchmark.engagement:
        return 'Engage';
      case Benchmark.productivity:
        return 'Product';
      default:
        return indicator.name.substring(0, 6);
    }
  }

  String _getOverallRating(List<double> values) {
    if (values.isEmpty) return 'N/A';
    
    final avg = values.reduce((a, b) => a + b) / values.length;
    if (avg >= 0.8) return 'Excellent';
    if (avg >= 0.6) return 'Good';
    if (avg >= 0.4) return 'Fair';
    return 'Needs Work';
  }
}