import 'package:flutter/material.dart';
import 'package:platform_v2/config/enums.dart';
import 'package:platform_v2/dataClasses/blockData.dart';

class BlockDataViewOverlay extends StatelessWidget {
  final BlockData blockData;
  final Map<Benchmark, double>? benchmarks;
  final VoidCallback? onClose;

  const BlockDataViewOverlay({
    super.key,
    required this.blockData,
    this.benchmarks,
    this.onClose,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Positioned(
          right: 20,
          bottom: 80,
          child: Material(
            elevation: 8,
            borderRadius: BorderRadius.circular(12),
            child: Container(
              width: 320,
              height: MediaQuery.of(context).size.height * 0.7,
              padding: const EdgeInsets.all(20),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildHeader(),
                    const SizedBox(height: 16),
                    _buildRawResultsSection(),
                    if (benchmarks == null) ...[
                      const SizedBox(height: 20),
                      _buildNoDataSection(),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                blockData.name.isNotEmpty ? blockData.name : 'Unnamed Block',
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                overflow: TextOverflow.ellipsis,
              ),
              if (blockData.role.isNotEmpty || blockData.department.isNotEmpty) ...[
                const SizedBox(height: 4),
                Text(
                  [blockData.role, blockData.department].where((s) => s.isNotEmpty).join(' • '),
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ],
          ),
        ),
        IconButton(
          onPressed: onClose,
          icon: const Icon(Icons.close),
          iconSize: 20,
          constraints: const BoxConstraints(),
          padding: EdgeInsets.zero,
        ),
      ],
    );
  }

  Widget _buildRawResultsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Raw Results (Q1-Q37)',
          style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        if (blockData.rawResults.isNotEmpty == true)
          _buildRawResultsContent()
        else
          _buildEmptyState(
            icon: Icons.assignment_outlined,
            message: 'No assessment results',
          ),
      ],
    );
  }

  Widget _buildRawResultsContent() {
    final results = blockData.rawResults!;
    final stats = _calculateResultStats(results);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: _cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Stats header with IQR, Max, Min
          Row(
            children: [
              Expanded(
                child: _buildStatChip('Max', '${stats.max}', _getResultColor(stats.max)),
              ),
              const SizedBox(width: 6),
              Expanded(
                child: _buildStatChip('Min', '${stats.min}', _getResultColor(stats.min)),
              ),
              const SizedBox(width: 6),
              Expanded(
                child: _buildStatChip('IQR', stats.iqr.toStringAsFixed(1), _getIQRColor(stats.iqr)),
              ),
            ],  
          ),
          const SizedBox(height: 8),

          // Index Score (if available)
          if (benchmarks != null && benchmarks!.containsKey(Benchmark.orgIndex))
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: _getScoreColor(benchmarks![Benchmark.orgIndex]!).withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: _getScoreColor(benchmarks![Benchmark.orgIndex]!).withOpacity(0.3)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.star, color: _getScoreColor(benchmarks![Benchmark.orgIndex]!), size: 16),
                  const SizedBox(width: 6),
                  Text(
                    'Index: ${(benchmarks![Benchmark.orgIndex]! * 100).toInt()}%',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: _getScoreColor(benchmarks![Benchmark.orgIndex]!),
                    ),
                  ),
                ],
              ),
            ),
          const SizedBox(height: 16),

          // Split layout: Left (Raw Q&A) | Right (Indicator Scores)
          IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
              // Left side - Raw Questions & Answers
              Expanded(
                
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Raw Q&A',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey.shade700,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Column(
                      children: [
                        for (int i = 0; i < results.length; i++)
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 2),
                            child: Row(
                              children: [
                                SizedBox(
                                  width: 30,
                                  child: Text(
                                    'Q${i + 1}:',
                                    style: const TextStyle(
                                      fontSize: 10,
                                      fontFamily: 'monospace',
                                    ),
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: _getResultColor(results[i]),
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: Text(
                                    '${results[i]}',
                                    style: const TextStyle(
                                      fontSize: 9,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
              ),

              // Vertical divider
              Container(
                width: 1,
                height: double.infinity,
                color: Colors.grey.shade300,
                margin: const EdgeInsets.symmetric(horizontal: 12),
              ),

              // Right side - All Scores (Indicators, Pillars, Finals)
              Expanded(
                flex: 3,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Scores',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey.shade700,
                      ),
                    ),
                    const SizedBox(height: 8),
                    if (benchmarks != null)
                      SingleChildScrollView(
                        child: _buildAllScoresList(),
                      )
                    else
                      Center(
                        child: Text(
                          'No benchmark data',
                          style: TextStyle(
                            fontSize: 10,
                            color: Colors.grey.shade500,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAllScoresList() {
    final indicators = [
      (Benchmark.growthAlign, 'Growth Align'),
      (Benchmark.orgAlign, 'Org Align'),
      (Benchmark.collabKPIs, 'Collab KPIs'),
      (Benchmark.crossFuncComms, 'Cross-Func Comms'),
      (Benchmark.crossFuncAcc, 'Cross-Func Acc'),
      (Benchmark.engagedCommunity, 'Engaged Community'),
      (Benchmark.collabProcesses, 'Collab Processes'),
      (Benchmark.alignedTech, 'Aligned Tech'),
      (Benchmark.meetingEfficacy, 'Meeting Efficacy'),
      (Benchmark.empoweredLeadership, 'Empowered Leadership'),
      (Benchmark.purposeDriven, 'Purpose Driven'),
      (Benchmark.engagement, 'Engagement'),
      (Benchmark.productivity, 'Productivity'),
    ];

    final pillars = [
      (Benchmark.alignP, 'Alignment'),
      (Benchmark.processP, 'Process'),
      (Benchmark.peopleP, 'People'),
      (Benchmark.leadershipP, 'Leadership'),
    ];

    final finals = [
      (Benchmark.workforce, 'Workforce'),
      (Benchmark.operations, 'Operations'),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Indicators section
        _buildScoreSubsection('INDICATORS', indicators, Colors.blue.shade100),
        const SizedBox(height: 12),

        // Pillars section
        _buildScoreSubsection('PILLARS', pillars, Colors.orange.shade100),
        const SizedBox(height: 12),

        // Final scores section
        _buildScoreSubsection('FINAL', finals, Colors.green.shade100),
      ],
    );
  }

  Widget _buildScoreSubsection(String title, List<(Benchmark, String)> items, Color backgroundColor) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
          decoration: BoxDecoration(
            color: backgroundColor,
            borderRadius: BorderRadius.circular(3),
          ),
          child: Text(
            title,
            style: const TextStyle(
              fontSize: 9,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
        ),
        const SizedBox(height: 4),
        for (final item in items)
          if (benchmarks!.containsKey(item.$1))
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 2),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      item.$2,
                      style: const TextStyle(fontSize: 10),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: _getScoreColor(benchmarks![item.$1]!),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      '${(benchmarks![item.$1]! * 100).toInt()}%',
                      style: const TextStyle(
                        fontSize: 9,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
            ),
      ],
    );
  }

  Widget _buildStatChip(String label, String value, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Text(
            value,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          Text(
            label,
            style: TextStyle(
              fontSize: 9,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Color _getResultColor(int value) {
    // 1-7 Likert scale color coding
    switch (value) {
      case 1:
        return Colors.red.shade600;
      case 2:
        return Colors.red.shade600;
      case 3:
        return Colors.yellow.shade600;
      case 4:
        return Colors.orange.shade600;
      case 5:
        return Colors.green.shade600;
      case 6:
        return Colors.green.shade600;
      case 7:
        return Colors.green.shade700;
      default:
        return Colors.grey.shade400;
    }
  }

  Color _getIQRColor(double iqr) {
    // IQR color coding - lower IQR (more consistent) is better
    if (iqr <= 1.0) return Colors.green.shade600;
    if (iqr <= 2.0) return Colors.lime.shade600;
    if (iqr <= 3.0) return Colors.amber.shade600;
    if (iqr <= 4.0) return Colors.orange.shade600;
    return Colors.red.shade400;
  }

  ({int min, int max, double average, double iqr}) _calculateResultStats(List<int> results) {
    if (results.isEmpty) return (min: 0, max: 0, average: 0.0, iqr: 0.0);

    final min = results.reduce((a, b) => a < b ? a : b);
    final max = results.reduce((a, b) => a > b ? a : b);
    final average = results.reduce((a, b) => a + b) / results.length;
    final iqr = _calculateIQR(results);

    return (min: min, max: max, average: average, iqr: iqr);
  }

  double _calculateIQR(List<int> results) {
    if (results.isEmpty) return 0.0;

    final sorted = List<int>.from(results)..sort();
    final n = sorted.length;

    double q1, q3;

    if (n % 4 == 0) {
      final q1Index = (n / 4).floor() - 1;
      final q3Index = (3 * n / 4).floor() - 1;
      q1 = (sorted[q1Index] + sorted[q1Index + 1]) / 2.0;
      q3 = (sorted[q3Index] + sorted[q3Index + 1]) / 2.0;
    } else {
      final q1Index = (n / 4).floor();
      final q3Index = (3 * n / 4).floor();
      q1 = sorted[q1Index].toDouble();
      q3 = sorted[q3Index].toDouble();
    }

    return q3 - q1;
  }

  Widget _buildNoDataSection() {
    return _buildEmptyState(
      icon: Icons.analytics_outlined,
      message: 'No benchmark data',
      subtitle: 'Assessment results need processing',
      size: 32,
    );
  }

  Widget _buildEmptyState({
    required IconData icon,
    required String message,
    String? subtitle,
    double size = 20,
  }) {
    return Container(
      padding: EdgeInsets.all(subtitle != null ? 20 : 16),
      decoration: _cardDecoration(),
      child: subtitle != null
          ? Center(
              child: Column(
                children: [
                  Icon(icon, size: size, color: Colors.grey.shade400),
                  const SizedBox(height: 12),
                  Text(
                    message,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: Colors.grey.shade600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: TextStyle(fontSize: 11, color: Colors.grey.shade500),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            )
          : Row(
              children: [
                Icon(icon, color: Colors.grey.shade400, size: size),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    message,
                    style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                  ),
                ),
              ],
            ),
    );
  }

  BoxDecoration _cardDecoration() {
    return BoxDecoration(
      color: Colors.grey.shade50,
      borderRadius: BorderRadius.circular(6),
      border: Border.all(color: Colors.grey.shade300),
    );
  }

  Color _getScoreColor(double score) {
    final percentage = score * 100;
    if (percentage >= 60) return Colors.green.shade600;
    if (percentage >= 40) return Colors.orange.shade600;
    return Colors.red.shade600;
  }
}
