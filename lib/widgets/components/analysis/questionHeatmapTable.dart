import 'package:flutter/material.dart';
import 'package:data_table_2/data_table_2.dart';
import 'package:platform_v2/services/analysisDataService.dart';

class QuestionHeatmapTable extends StatelessWidget {
  final List<EmailDataPoint> dataPoints;
  final bool isCompact;
  
  // Pre-calculated display data for performance
  final int? maxQuestions;
  final List<String>? processedEmails;
  final List<List<Color>>? heatmapColors;
  final List<Map<String, double>>? questionStatistics;

  const QuestionHeatmapTable({
    super.key,
    required this.dataPoints,
    this.isCompact = true,
    this.maxQuestions,
    this.processedEmails,
    this.heatmapColors,
    this.questionStatistics,
  });

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

    // Use pre-calculated maxQuestions if available, otherwise calculate
    final maxQuestionsCount = maxQuestions ?? dataPoints
        .map((dp) => dp.rawResults.length)
        .fold<int>(0, (max, length) => length > max ? length : max);

    if (maxQuestionsCount == 0) {
      return const Center(
        child: Text(
          'No question data available',
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
        maxWidth: isCompact ? 300 : double.infinity,
      ),
      child: DataTable2(
        horizontalMargin: 8,
        columnSpacing: 2,
        minWidth: isCompact ? 250 : 600,
        fixedLeftColumns: 1, // Fix the email column
        headingRowHeight: isCompact ? 30 : 40,
        dataRowHeight: isCompact ? 25 : 35,
        headingTextStyle: TextStyle(
          fontSize: isCompact ? 10 : 12,
          fontWeight: FontWeight.bold,
        ),
        dataTextStyle: TextStyle(
          fontSize: isCompact ? 8 : 10,
          fontWeight: FontWeight.w500,
        ),
        columns: [
          // Email column
          DataColumn2(
            label: Text('Email'),
            size: isCompact ? ColumnSize.S : ColumnSize.M,
          ),
          // Question columns (Q1, Q2, ..., Q37)
          ...List.generate(maxQuestionsCount, (index) {
            final questionNumber = index + 1;
            return DataColumn2(
              label: Text('Q$questionNumber'),
              size: ColumnSize.S,
            );
          }),
        ],
        rows: [
          // Data rows
          ...List.generate(dataPoints.length, (rowIndex) {
            final dataPoint = dataPoints[rowIndex];
            return DataRow2(
              cells: [
                // Email cell - use pre-calculated email if available
                DataCell(
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(2),
                    child: Text(
                      processedEmails != null && rowIndex < processedEmails!.length
                          ? processedEmails![rowIndex]
                          : _truncateEmail(dataPoint.email, isCompact ? 15 : 25),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ),
                // Question value cells with pre-calculated colors
                ...List.generate(maxQuestionsCount, (colIndex) {
                  int? value;
                  Color cellColor;
                  
                  if (colIndex < dataPoint.rawResults.length) {
                    value = dataPoint.rawResults[colIndex];
                  }

                  // Use pre-calculated color if available
                  if (heatmapColors != null && rowIndex < heatmapColors!.length && colIndex < heatmapColors![rowIndex].length) {
                    cellColor = heatmapColors![rowIndex][colIndex].withValues(alpha: 0.7);
                  } else {
                    cellColor = value != null 
                        ? AnalysisDataService.getHeatmapColor(value).withValues(alpha: 0.7)
                        : Colors.grey.withValues(alpha: 0.2);
                  }

                  return DataCell(
                    Container(
                      width: double.infinity,
                      height: double.infinity,
                      decoration: BoxDecoration(
                        color: cellColor,
                        borderRadius: BorderRadius.circular(2),
                      ),
                      child: Center(
                        child: Text(
                          value?.toString() ?? '-',
                          style: TextStyle(
                            color: Colors.black,
                            fontWeight: FontWeight.normal,
                          ),
                        ),
                      ),
                    ),
                  );
                }),
              ],
            );
          }),
          // Separator row before statistics
          if (questionStatistics != null && !isCompact) _buildSeparatorRow(maxQuestionsCount),
          // Statistics rows
          if (questionStatistics != null && !isCompact) ..._buildStatisticsRows(maxQuestionsCount),
        ],
      ),
    );
  }

  List<DataRow2> _buildStatisticsRows(int maxQuestionsCount) {
    if (questionStatistics == null) return [];
    
    final statsLabels = ['AVG', 'HIGH', 'LOW', 'IQR'];
    final statRows = <DataRow2>[];
    
    for (final label in statsLabels) {
      statRows.add(DataRow2(
        decoration: BoxDecoration(
          color: Colors.grey.shade50,
          border: Border(
            top: BorderSide(color: Colors.grey.shade300, width: 1),
          ),
        ),
        cells: [
          // Label cell
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
          // Statistics for each question column
          ...List.generate(maxQuestionsCount, (colIndex) {
            String displayValue = '-';
            Color cellColor = Colors.grey.shade100;
            
            if (colIndex < questionStatistics!.length) {
              final stats = questionStatistics![colIndex];
              final value = stats[label.toLowerCase()];
              
              if (value != null) {
                // Format numbers: integers for HIGH, LOW, IQR; decimal for AVG
                if (label == 'AVG') {
                  displayValue = value.toStringAsFixed(1);
                } else {
                  displayValue = value.round().toString();
                }
                
                // Apply heatmap color based on value (treating as question response 1-7)
                final colorValue = value.round().clamp(1, 7);
                cellColor = AnalysisDataService.getHeatmapColor(colorValue).withValues(alpha: 0.7);
              }
            }
            
            return DataCell(
              Container(
                width: double.infinity,
                height: double.infinity,
                decoration: BoxDecoration(
                  color: cellColor,
                  borderRadius: BorderRadius.circular(2),
                ),
                child: Center(
                  child: Text(
                    displayValue,
                    style: TextStyle(
                      fontSize: 9,
                      fontWeight: FontWeight.normal,
                      color: Colors.black,
                    ),
                  ),
                ),
              ),
            );
          }),
        ],
      ));
    }
    
    return statRows;
  }

  DataRow2 _buildSeparatorRow(int maxQuestionsCount) {
    return DataRow2(
      decoration: BoxDecoration(
        border: Border(
          top: BorderSide(color: Colors.grey.shade400, width: 2),
        ),
      ),
      cells: List.generate(maxQuestionsCount + 1, (index) {
        return DataCell(
          SizedBox(
            width: double.infinity,
            height: 5,
          ),
        );
      }),
    );
  }

  String _truncateEmail(String email, int maxLength) {
    if (email.length <= maxLength) return email;
    
    // Try to show the part before @ and truncate if needed
    final atIndex = email.indexOf('@');
    if (atIndex != -1 && atIndex <= maxLength - 3) {
      return '${email.substring(0, atIndex)}...';
    }
    
    return '${email.substring(0, maxLength - 3)}...';
  }
}

/// Compact version for displaying in the analysis block
class CompactQuestionHeatmap extends StatelessWidget {
  final List<EmailDataPoint> dataPoints;

  const CompactQuestionHeatmap({
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
            Icon(Icons.grid_on, size: 24, color: Colors.grey),
            SizedBox(height: 4),
            Text(
              'No Data',
              style: TextStyle(fontSize: 10, color: Colors.grey),
            ),
          ],
        ),
      );
    }

    // Show a mini preview - just first few emails and questions
    final previewEmails = dataPoints.take(3).toList();
    final maxQuestions = previewEmails
        .map((dp) => dp.rawResults.length)
        .fold(0, (max, length) => length > max ? length : max);
    final previewQuestions = (maxQuestions > 8) ? 8 : maxQuestions;

    return Container(
      padding: const EdgeInsets.all(4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              Icon(Icons.grid_on, size: 12, color: Colors.blue),
              SizedBox(width: 4),
              Text(
                'Questions Heatmap',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  color: Colors.blue.shade700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          // Mini grid
          Column(
            children: previewEmails.map((dataPoint) {
              return Container(
                margin: const EdgeInsets.only(bottom: 1),
                height: 12,
                child: Row(
                  children: [
                    // Email indicator
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
                    // Question value squares
                    ...List.generate(previewQuestions, (index) {
                      int? value;
                      if (index < dataPoint.rawResults.length) {
                        value = dataPoint.rawResults[index];
                      }

                      return Container(
                        width: 8,
                        height: 8,
                        margin: const EdgeInsets.only(right: 1),
                        decoration: BoxDecoration(
                          color: value != null 
                              ? AnalysisDataService.getHeatmapColor(value)
                              : Colors.grey.withValues(alpha: 0.3),
                          borderRadius: BorderRadius.circular(1),
                        ),
                      );
                    }),
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