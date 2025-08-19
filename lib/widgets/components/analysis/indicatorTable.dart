import 'package:flutter/material.dart';
import 'package:data_table_2/data_table_2.dart';
import 'package:platform_v2/config/enums.dart';
import 'package:platform_v2/services/analysisDataService.dart';

class IndicatorTable extends StatelessWidget {
  final List<EmailDataPoint> dataPoints;
  final bool isCompact;
  final List<Map<String, double>>? indicatorStatistics;

  const IndicatorTable({
    super.key,
    required this.dataPoints,
    this.isCompact = true,
    this.indicatorStatistics,
  });

  // Get the indicators to display (main indicators, not pilars or final calculations)
  List<Benchmark> get _displayIndicators => [
    Benchmark.orgIndex,
    Benchmark.growthAlign,
    Benchmark.orgAlign,
    Benchmark.collabKPIs,
    Benchmark.crossFuncComms,
    Benchmark.crossFuncAcc,
    Benchmark.engagedCommunity,
    Benchmark.collabProcesses,
    Benchmark.alignedTech,
    Benchmark.meetingEfficacy,
    Benchmark.empoweredLeadership,
    Benchmark.purposeDriven,
    Benchmark.processP,
    Benchmark.alignP,
    Benchmark.peopleP,
    Benchmark.leadershipP,
    Benchmark.engagement,
    Benchmark.productivity,
  ];

  @override
  Widget build(BuildContext context) {
    if (dataPoints.isEmpty) {
      return const Center(
        child: Text(
          'No data available',
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey,
          ),
        ),
      );
    }

    // Filter data points that have benchmark calculations
    final validDataPoints = dataPoints.where((dp) => dp.benchmarks != null).toList();

    if (validDataPoints.isEmpty) {
      return const Center(
        child: Text(
          'No complete indicator data available',
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey,
          ),
        ),
      );
    }

    return Container(
      constraints: BoxConstraints(
        maxHeight: isCompact ? 200 : double.infinity,
        maxWidth: isCompact ? 400 : double.infinity,
      ),
      child: DataTable2(
        horizontalMargin: 8,
        columnSpacing: 4,
        minWidth: isCompact ? 350 : 800,
        fixedLeftColumns: 1,
        headingRowHeight: isCompact ? 30 : 40,
        dataRowHeight: isCompact ? 25 : 35,
        headingTextStyle: TextStyle(
          fontSize: isCompact ? 9 : 11,
          fontWeight: FontWeight.normal,
        ),
        dataTextStyle: TextStyle(
          fontSize: isCompact ? 8 : 9,
          fontWeight: FontWeight.w500,
        ),
        columns: [
          DataColumn2(
            label: Text('Email'),
            size: isCompact ? ColumnSize.S : ColumnSize.M,
          ),
          ..._displayIndicators.asMap().entries.map((entry) {
            final indicator = entry.value;
            return DataColumn2(
              label: Text(
                _getShortIndicatorName(indicator),
                overflow: TextOverflow.ellipsis,
              ),
              size: ColumnSize.S,
            );
          }),
        ],
        rows: [
          ...validDataPoints.map((dataPoint) {
            return DataRow2(
              cells: [
                DataCell(
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(2),
                    child: Text(
                      _truncateEmail(dataPoint.email, isCompact ? 15 : 25),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ),
                ..._displayIndicators.asMap().entries.map((entry) {
                  final index = entry.key;
                  final indicator = entry.value;

                  final value = dataPoint.benchmarks![indicator];
                  String displayValue = value != null ? (value * 100).toStringAsFixed(0) : '-';

                  return DataCell(
                    Container(
                      width: double.infinity,
                      height: double.infinity,
                      decoration: BoxDecoration(
                        color: value != null ? AnalysisDataService.getBenchmarkColor(value).withOpacity(0.7) : Colors.grey.withOpacity(0.2),
                        border: (index == 1 || index == 12 || index == 16) ? const Border(left: BorderSide(color: Colors.black, width: 3)) : null,
                      ),
                      child: Center(
                        child: Text(
                          displayValue,
                          style: const TextStyle(color: Colors.black),
                        ),
                      ),
                    ),
                  );
                }),
              ],
            );
          }),
          if (indicatorStatistics != null && !isCompact) _buildSeparatorRow(),
          if (indicatorStatistics != null && !isCompact) ..._buildIndicatorStatisticsRows(),
        ],
      ),
    );
  }

  List<DataRow2> _buildIndicatorStatisticsRows() {
    if (indicatorStatistics == null) return [];

    final statsLabels = ['AVG', 'HIGH', 'LOW', 'IQR'];
    final statRows = <DataRow2>[];

    for (final label in statsLabels) {
      statRows.add(
        DataRow2(
          decoration: BoxDecoration(
            color: Colors.grey.shade50,
            border: Border(
              top: BorderSide(color: Colors.grey.shade300, width: 1),
            ),
          ),
          cells: [
            DataCell(
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(4),
                child: Text(
                  label,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 10,
                    color: Colors.grey.shade700,
                  ),
                ),
              ),
            ),
            ..._displayIndicators.asMap().entries.map((entry) {
              final index = entry.key;
              final indicator = entry.value;

              String displayValue = '-';
              Color cellColor = Colors.grey.shade100;

              for (final stats in indicatorStatistics!) {
                if (stats['benchmark'] != null && Benchmark.values[stats['benchmark']!.toInt()] == indicator) {
                  final value = stats[label.toLowerCase()];
                  if (value != null) {
                    if (label == 'AVG') {
                      displayValue = '${(value * 100).toStringAsFixed(1)}%';
                    } else {
                      displayValue = '${(value * 100).round()}%';
                    }
                    cellColor = AnalysisDataService.getBenchmarkColor(value).withOpacity(0.7);
                  }
                  break;
                }
              }

              return DataCell(
                Container(
                  width: double.infinity,
                  height: double.infinity,
                  decoration: BoxDecoration(
                    color: cellColor,
                    border: (index == 1 || index == 12 || index == 16) ? const Border(left: BorderSide(color: Colors.black, width: 3)) : null,
                  ),
                  child: Center(
                    child: Text(
                      displayValue,
                      style: const TextStyle(
                        fontSize: 9,
                        color: Colors.black,
                      ),
                    ),
                  ),
                ),
              );
            }),
          ],
        ),
      );
    }

    return statRows;
  }

  DataRow2 _buildSeparatorRow() {
    return DataRow2(
      decoration: BoxDecoration(
        border: Border(
          top: BorderSide(color: Colors.grey.shade400, width: 2),
        ),
      ),
      cells: [
        const DataCell(SizedBox(width: double.infinity, height: 5)),
        ..._displayIndicators.asMap().entries.map((entry) {
          return DataCell(
            SizedBox(
              width: double.infinity,
              height: 10,
              child: null,
            ),
          );
        }),
      ],
    );
  }

  String _getShortIndicatorName(Benchmark indicator) {
    switch (indicator) {
      case Benchmark.growthAlign:
        return 'Growth Align';
      case Benchmark.orgAlign:
        return 'Org Align';
      case Benchmark.collabKPIs:
        return 'KPIs';
      case Benchmark.crossFuncComms:
        return 'Cross Coms';
      case Benchmark.crossFuncAcc:
        return 'Cross Acc';
      case Benchmark.engagedCommunity:
        return 'Community';
      case Benchmark.collabProcesses:
        return 'Collab Processes';
      case Benchmark.alignedTech:
        return 'Aligned Tech';
      case Benchmark.meetingEfficacy:
        return 'Meeting Efficacy';
      case Benchmark.empoweredLeadership:
        return 'Leadership';
      case Benchmark.purposeDriven:
        return 'Purpose Driven';
      case Benchmark.engagement:
        return 'Engagement';
      case Benchmark.productivity:
        return 'Productivity';
      case Benchmark.processP:
        return 'Process';
      case Benchmark.alignP:
        return 'Align';
      case Benchmark.peopleP:
        return 'People';
      case Benchmark.leadershipP:
        return 'Leadership';
      case Benchmark.orgIndex:
        return 'Index';
      default:
        return indicator.name;
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
}

/// Compact version for displaying in the analysis block
class CompactIndicatorTable extends StatelessWidget {
  final List<EmailDataPoint> dataPoints;

  const CompactIndicatorTable({
    super.key,
    required this.dataPoints,
  });

  @override
  Widget build(BuildContext context) {
    if (dataPoints.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(8),
        child: const Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.analytics, size: 24, color: Colors.grey),
            SizedBox(height: 4),
            Text(
              'No Data',
              style: TextStyle(fontSize: 10, color: Colors.grey),
            ),
          ],
        ),
      );
    }

    final validDataPoints = dataPoints.where((dp) => dp.benchmarks != null).take(3).toList();

    if (validDataPoints.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(8),
        child: const Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.analytics_outlined, size: 24, color: Colors.orange),
            SizedBox(height: 4),
            Text(
              'Incomplete Data',
              style: TextStyle(fontSize: 10, color: Colors.orange),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    final keyIndicators = [
      Benchmark.growthAlign,
      Benchmark.orgAlign,
      Benchmark.engagement,
      Benchmark.productivity,
    ];

    return Container(
      padding: const EdgeInsets.all(4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.analytics, size: 12, color: Colors.purple),
              SizedBox(width: 4),
              Text(
                'Indicators',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  color: Colors.purple.shade700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Column(
            children: validDataPoints.map((dataPoint) {
              return Container(
                margin: const EdgeInsets.only(bottom: 1),
                height: 12,
                child: Row(
                  children: [
                    Container(
                      width: 30,
                      padding: const EdgeInsets.symmetric(horizontal: 2),
                      child: Text(
                        _getEmailInitials(dataPoint.email),
                        style: const TextStyle(fontSize: 6),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 2),
                    ...keyIndicators.map((indicator) {
                      final value = dataPoint.benchmarks![indicator];

                      return Container(
                        width: 8,
                        height: 8,
                        margin: const EdgeInsets.only(right: 1),
                        decoration: BoxDecoration(
                          color: value != null ? AnalysisDataService.getBenchmarkColor(value) : Colors.grey.withOpacity(0.3),
                          borderRadius: BorderRadius.circular(1),
                        ),
                      );
                    }).toList(),
                  ],
                ),
              );
            }).toList(),
          ),
          if (dataPoints.length > 3)
            Text(
              '+${dataPoints.length - 3} more',
              style: TextStyle(
                fontSize: 8,
                color: Colors.grey.shade600,
              ),
            ),
        ],
      ),
    );
  }

  String _getEmailInitials(String email) {
    final atIndex = email.indexOf('@');
    if (atIndex == -1) return email.substring(0, 2).toUpperCase();

    final username = email.substring(0, atIndex);
    if (username.isEmpty) return 'U';

    if (username.length >= 2) {
      return username.substring(0, 2).toUpperCase();
    }
    return username.toUpperCase();
  }
}
