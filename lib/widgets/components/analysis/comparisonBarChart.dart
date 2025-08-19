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
  final Set<int> selectedQuestions;
  final Set<Benchmark> selectedIndicators;
  final Function(int) onToggleQuestion;
  final Function(Benchmark) onToggleIndicator;
  final VoidCallback onSelectAllQuestions;
  final VoidCallback onDeselectAllQuestions;
  final VoidCallback onSelectAllIndicators;
  final VoidCallback onDeselectAllIndicators;

  const ComparisonBarChart({
    super.key,
    required this.groupedDataPoints,
    required this.analysisSubType,
    required this.groupIdToNameMap,
    required this.selectedQuestions,
    required this.selectedIndicators,
    required this.onToggleQuestion,
    required this.onToggleIndicator,
    required this.onSelectAllQuestions,
    required this.onDeselectAllQuestions,
    required this.onSelectAllIndicators,
    required this.onDeselectAllIndicators,
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
      height: 460, // Back to original height
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          _buildHeaderWithFilters(ref),
          const SizedBox(height: 16),
          Expanded(
            child: analysisSubType == AnalysisSubType.questions ? _buildQuestionsChart(ref) : _buildIndicatorsChart(ref),
          ),
        ],
      ),
    );
  }

  Widget _buildHeaderWithFilters(WidgetRef ref) {
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
        Expanded(
          child: Row(
            children: [
              Text(
                analysisSubType == AnalysisSubType.questions ? 'Questions Comparison (1-7 Scale)' : 'Indicators Comparison (0-100%)',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(width: 16),
              _buildFilterDropdown(),
            ],
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

  Widget _buildFilterDropdown() {
    final filterCount = analysisSubType == AnalysisSubType.questions ? selectedQuestions.length : selectedIndicators.length;
    final totalCount = analysisSubType == AnalysisSubType.questions ? 37 : indicators().length;

    return _CustomFilterDropdown(
      filterCount: filterCount,
      totalCount: totalCount,
      analysisSubType: analysisSubType,
      selectedQuestions: selectedQuestions,
      selectedIndicators: selectedIndicators,
      onToggleQuestion: onToggleQuestion,
      onToggleIndicator: onToggleIndicator,
      onSelectAllQuestions: onSelectAllQuestions,
      onDeselectAllQuestions: onDeselectAllQuestions,
      onSelectAllIndicators: onSelectAllIndicators,
      onDeselectAllIndicators: onDeselectAllIndicators,
    );
  }

  Widget _buildQuestionsChart(WidgetRef ref) {
    final allGroupData = _calculateQuestionsAverages();
    final filteredGroupData = _filterQuestionsData(allGroupData);
    if (filteredGroupData.isEmpty) {
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

              final selectedQuestionsList = selectedQuestions.toList()..sort();
              final questionIndex = group.x;
              final questionNumber = questionIndex < selectedQuestionsList.length ? selectedQuestionsList[questionIndex] : group.x + 1;

              return BarTooltipItem(
                '$groupName\nQ$questionNumber: ${rod.toY.toStringAsFixed(2)}',
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
                final selectedQuestionsList = selectedQuestions.toList()..sort();
                final index = value.toInt();
                if (index >= selectedQuestionsList.length) return const Text('');
                final questionNumber = selectedQuestionsList[index];
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
        barGroups: filteredGroupData,
      ),
    );
  }

  Widget _buildIndicatorsChart(WidgetRef ref) {
    final allGroupData = _calculateIndicatorAverages();
    final filteredGroupData = _filterIndicatorsData(allGroupData);
    if (filteredGroupData.isEmpty) {
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

              final availableIndicators = indicators();
              final selectedIndicatorsList = selectedIndicators.where((ind) => availableIndicators.contains(ind)).toList();

              if (group.x >= selectedIndicatorsList.length) return null;

              final indicatorName = _getIndicatorDisplayName(selectedIndicatorsList[group.x]);
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
              reservedSize: 30,
              showTitles: true,
              getTitlesWidget: (double value, TitleMeta meta) {
                final availableIndicators = indicators();
                final selectedIndicatorsList = selectedIndicators.where((ind) => availableIndicators.contains(ind)).toList();

                final index = value.toInt();
                if (index >= selectedIndicatorsList.length) return const Text('');

                return Padding(
                  padding: const EdgeInsets.only(top: 4.0),
                  child: Text(
                    _getIndicatorShortName(selectedIndicatorsList[index]),
                    style: const TextStyle(fontSize: 9),
                    textAlign: TextAlign.center,
                    maxLines: 2,
                  ),
                );
              },
            ),
          ),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 30,
              getTitlesWidget: (double value, TitleMeta meta) {
                return Padding(
                  padding: const EdgeInsets.only(right: 4.0),
                  child: Text(
                    '${value.toInt()}%',
                    style: const TextStyle(fontSize: 10),
                    textAlign: TextAlign.right,
                  ),
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
        barGroups: filteredGroupData,
      ),
    );
  }

  List<BarChartGroupData> _filterQuestionsData(List<BarChartGroupData> allData) {
    if (selectedQuestions.isEmpty) return [];

    final selectedQuestionsList = selectedQuestions.toList()..sort();
    final filteredData = <BarChartGroupData>[];

    for (int i = 0; i < selectedQuestionsList.length; i++) {
      final questionIndex = selectedQuestionsList[i] - 1; // Convert to 0-based index
      if (questionIndex < allData.length) {
        final originalGroup = allData[questionIndex];
        filteredData.add(
          BarChartGroupData(
            x: i, // Use new sequential index
            barRods: originalGroup.barRods,
            barsSpace: originalGroup.barsSpace,
          ),
        );
      }
    }

    return filteredData;
  }

  List<BarChartGroupData> _filterIndicatorsData(List<BarChartGroupData> allData) {
    if (selectedIndicators.isEmpty) return [];

    final availableIndicators = indicators();
    final selectedIndicatorsList = selectedIndicators.where((ind) => availableIndicators.contains(ind)).toList();
    final filteredData = <BarChartGroupData>[];

    for (int i = 0; i < selectedIndicatorsList.length; i++) {
      final indicatorIndex = availableIndicators.indexOf(selectedIndicatorsList[i]);
      if (indicatorIndex != -1 && indicatorIndex < allData.length) {
        final originalGroup = allData[indicatorIndex];
        filteredData.add(
          BarChartGroupData(
            x: i, // Use new sequential index
            barRods: originalGroup.barRods,
            barsSpace: originalGroup.barsSpace,
          ),
        );
      }
    }

    return filteredData;
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
          rods.add(
            BarChartRodData(
              toY: 0,
              color: _getGroupColor(groupIndex),
              width: 8,
            ),
          );
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

        rods.add(
          BarChartRodData(
            toY: average.toDouble(),
            color: _getGroupColor(groupIndex),
            width: 8,
          ),
        );
      }

      barGroups.add(
        BarChartGroupData(
          x: questionIndex,
          barRods: rods,
          barsSpace: 2,
        ),
      );
    }

    return barGroups;
  }

  List<BarChartGroupData> _calculateIndicatorAverages() {
    if (groupedDataPoints.isEmpty) return [];

    final groupIds = groupedDataPoints.keys.toList();
    final List<BarChartGroupData> barGroups = [];

    // Get indicators excluding pillar calculations
    final indicators = Benchmark.values.where((b) => b != Benchmark.alignP && b != Benchmark.processP && b != Benchmark.peopleP && b != Benchmark.leadershipP).toList();

    // Process each indicator
    for (int indicatorIndex = 0; indicatorIndex < indicators.length; indicatorIndex++) {
      final indicator = indicators[indicatorIndex];
      final List<BarChartRodData> rods = [];

      // Calculate average for each group
      for (int groupIndex = 0; groupIndex < groupIds.length; groupIndex++) {
        final groupId = groupIds[groupIndex];
        final dataPoints = groupedDataPoints[groupId] ?? [];

        if (dataPoints.isEmpty) {
          rods.add(
            BarChartRodData(
              toY: 0,
              color: _getGroupColor(groupIndex),
              width: 12,
            ),
          );
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
        rods.add(
          BarChartRodData(
            toY: (average * 100).toDouble(),
            color: _getGroupColor(groupIndex),
            width: 12,
          ),
        );
      }

      barGroups.add(
        BarChartGroupData(
          x: indicatorIndex,
          barRods: rods,
          barsSpace: 4,
        ),
      );
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

class _CustomFilterDropdown extends StatelessWidget {
  final int filterCount;
  final int totalCount;
  final AnalysisSubType analysisSubType;
  final Set<int> selectedQuestions;
  final Set<Benchmark> selectedIndicators;
  final Function(int) onToggleQuestion;
  final Function(Benchmark) onToggleIndicator;
  final VoidCallback onSelectAllQuestions;
  final VoidCallback onDeselectAllQuestions;
  final VoidCallback onSelectAllIndicators;
  final VoidCallback onDeselectAllIndicators;

  const _CustomFilterDropdown({
    required this.filterCount,
    required this.totalCount,
    required this.analysisSubType,
    required this.selectedQuestions,
    required this.selectedIndicators,
    required this.onToggleQuestion,
    required this.onToggleIndicator,
    required this.onSelectAllQuestions,
    required this.onDeselectAllQuestions,
    required this.onSelectAllIndicators,
    required this.onDeselectAllIndicators,
  });

  @override
  Widget build(BuildContext context) {
    return _FilterDropdownButton(
      filterCount: filterCount,
      totalCount: totalCount,
      analysisSubType: analysisSubType,
      selectedQuestions: selectedQuestions,
      selectedIndicators: selectedIndicators,
      onToggleQuestion: onToggleQuestion,
      onToggleIndicator: onToggleIndicator,
      onSelectAllQuestions: onSelectAllQuestions,
      onDeselectAllQuestions: onDeselectAllQuestions,
      onSelectAllIndicators: onSelectAllIndicators,
      onDeselectAllIndicators: onDeselectAllIndicators,
    );
  }
}

class _FilterDropdownButton extends StatefulWidget {
  final int filterCount;
  final int totalCount;
  final AnalysisSubType analysisSubType;
  final Set<int> selectedQuestions;
  final Set<Benchmark> selectedIndicators;
  final Function(int) onToggleQuestion;
  final Function(Benchmark) onToggleIndicator;
  final VoidCallback onSelectAllQuestions;
  final VoidCallback onDeselectAllQuestions;
  final VoidCallback onSelectAllIndicators;
  final VoidCallback onDeselectAllIndicators;

  const _FilterDropdownButton({
    required this.filterCount,
    required this.totalCount,
    required this.analysisSubType,
    required this.selectedQuestions,
    required this.selectedIndicators,
    required this.onToggleQuestion,
    required this.onToggleIndicator,
    required this.onSelectAllQuestions,
    required this.onDeselectAllQuestions,
    required this.onSelectAllIndicators,
    required this.onDeselectAllIndicators,
  });

  @override
  State<_FilterDropdownButton> createState() => _FilterDropdownButtonState();
}

class _FilterDropdownButtonState extends State<_FilterDropdownButton> {
  OverlayEntry? _overlayEntry;
  final LayerLink _layerLink = LayerLink();
  bool _isOpen = false;

  @override
  void dispose() {
    _overlayEntry?.remove();
    super.dispose();
  }

  // Close dropdown when widget is rebuilt with new data
  @override
  void didUpdateWidget(_FilterDropdownButton oldWidget) {
    super.didUpdateWidget(oldWidget);

    // If selections changed, rebuild the overlay after the current build cycle
    if (_isOpen && (oldWidget.selectedQuestions != widget.selectedQuestions || oldWidget.selectedIndicators != widget.selectedIndicators)) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _updateOverlay();
      });
    }
  }

  void _toggleDropdown() {
    if (_isOpen) {
      _closeDropdown();
    } else {
      _openDropdown();
    }
  }

  void _openDropdown() {
    _overlayEntry = _createOverlayEntry();
    Overlay.of(context).insert(_overlayEntry!);
    setState(() => _isOpen = true);
  }

  void _closeDropdown() {
    _overlayEntry?.remove();
    _overlayEntry = null;
    setState(() => _isOpen = false);
  }

  void _updateOverlay() {
    if (_overlayEntry != null) {
      _overlayEntry!.remove();
      _overlayEntry = _createOverlayEntry();
      Overlay.of(context).insert(_overlayEntry!);
    }
  }

  OverlayEntry _createOverlayEntry() {
    final RenderBox renderBox = context.findRenderObject() as RenderBox;
    final size = renderBox.size;

    return OverlayEntry(
      builder: (context) => Positioned(
        width: 400,
        child: CompositedTransformFollower(
          link: _layerLink,
          showWhenUnlinked: false,
          offset: Offset(0.0, size.height + 5.0),
          child: Material(
            elevation: 8.0,
            color: Colors.white,
            borderRadius: BorderRadius.circular(8),
            child: Container(
              constraints: const BoxConstraints(maxHeight: 300),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.grey.shade300),
              ),
              child: widget.analysisSubType == AnalysisSubType.questions ? _buildQuestionsContent() : _buildIndicatorsContent(),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildQuestionsContent() {
    final allSelected = widget.selectedQuestions.length == 37;
    final noneSelected = widget.selectedQuestions.isEmpty;

    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Text(
                'Questions (${widget.selectedQuestions.length}/37)',
                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
              ),
              const Spacer(),
              _buildActionButton('All', allSelected, () {
                widget.onSelectAllQuestions();
              }),
              const SizedBox(width: 8),
              _buildActionButton('None', noneSelected, () {
                widget.onDeselectAllQuestions();
              }, isDestructive: true),
            ],
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 200,
            child: SingleChildScrollView(
              child: Wrap(
                spacing: 4,
                runSpacing: 4,
                children: List.generate(37, (index) {
                  final questionNumber = index + 1;
                  final isSelected = widget.selectedQuestions.contains(questionNumber);

                  return InkWell(
                    onTap: () {
                      widget.onToggleQuestion(questionNumber);
                    },
                    borderRadius: BorderRadius.circular(4),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: isSelected ? Colors.blue.shade600 : Colors.grey.shade200,
                        borderRadius: BorderRadius.circular(4),
                        border: Border.all(
                          color: isSelected ? Colors.blue.shade700 : Colors.grey.shade400,
                          width: 0.5,
                        ),
                      ),
                      child: Text(
                        'Q$questionNumber',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w500,
                          color: isSelected ? Colors.white : Colors.grey.shade700,
                        ),
                      ),
                    ),
                  );
                }),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildIndicatorsContent() {
    final availableIndicators = indicators();
    final allSelected = widget.selectedIndicators.length == availableIndicators.length;
    final noneSelected = widget.selectedIndicators.isEmpty;

    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Text(
                'Indicators (${widget.selectedIndicators.length}/${availableIndicators.length})',
                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
              ),
              const Spacer(),
              _buildActionButton('All', allSelected, () {
                widget.onSelectAllIndicators();
              }),
              const SizedBox(width: 8),
              _buildActionButton('None', noneSelected, () {
                widget.onDeselectAllIndicators();
              }, isDestructive: true),
            ],
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 200,
            child: SingleChildScrollView(
              child: Column(
                children: availableIndicators.map((indicator) {
                  final isSelected = widget.selectedIndicators.contains(indicator);

                  return InkWell(
                    onTap: () {
                      widget.onToggleIndicator(indicator);
                    },
                    borderRadius: BorderRadius.circular(4),
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                      margin: const EdgeInsets.only(bottom: 2),
                      decoration: BoxDecoration(
                        color: isSelected ? Colors.blue.shade50 : Colors.transparent,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 18,
                            height: 18,
                            decoration: BoxDecoration(
                              color: isSelected ? Colors.blue.shade600 : Colors.white,
                              borderRadius: BorderRadius.circular(3),
                              border: Border.all(
                                color: isSelected ? Colors.blue.shade600 : Colors.grey.shade400,
                                width: 1.5,
                              ),
                            ),
                            child: isSelected
                                ? Icon(
                                    Icons.check,
                                    size: 13,
                                    color: Colors.white,
                                  )
                                : null,
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              _getIndicatorDisplayName(indicator),
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey.shade800,
                                fontWeight: isSelected ? FontWeight.w500 : FontWeight.normal,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton(String text, bool isDisabled, VoidCallback onTap, {bool isDestructive = false}) {
    return InkWell(
      onTap: isDisabled ? null : onTap,
      borderRadius: BorderRadius.circular(4),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: isDisabled
              ? Colors.grey.shade200
              : isDestructive
              ? Colors.red.shade50
              : Colors.blue.shade50,
          borderRadius: BorderRadius.circular(4),
        ),
        child: Text(
          text,
          style: TextStyle(
            fontSize: 11,
            color: isDisabled
                ? Colors.grey.shade500
                : isDestructive
                ? Colors.red.shade700
                : Colors.blue.shade700,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    );
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

  @override
  Widget build(BuildContext context) {
    return CompositedTransformTarget(
      link: _layerLink,
      child: GestureDetector(
        onTap: _toggleDropdown,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: _isOpen ? Colors.blue.shade50 : Colors.grey.shade100,
            borderRadius: BorderRadius.circular(6),
            border: Border.all(
              color: _isOpen ? Colors.blue.shade300 : Colors.grey.shade300,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.filter_list,
                size: 16,
                color: _isOpen ? Colors.blue.shade600 : Colors.grey.shade600,
              ),
              const SizedBox(width: 6),
              Text(
                'Filters (${widget.filterCount}/${widget.totalCount})',
                style: TextStyle(
                  fontSize: 12,
                  color: _isOpen ? Colors.blue.shade700 : Colors.grey.shade700,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(width: 4),
              Icon(
                _isOpen ? Icons.arrow_drop_up : Icons.arrow_drop_down,
                size: 16,
                color: _isOpen ? Colors.blue.shade600 : Colors.grey.shade600,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
