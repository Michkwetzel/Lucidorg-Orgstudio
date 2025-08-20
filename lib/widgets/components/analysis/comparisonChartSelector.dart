import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:platform_v2/config/enums.dart';
import 'package:platform_v2/config/provider.dart';
import 'package:platform_v2/services/analysisDataService.dart';
import 'package:platform_v2/widgets/components/analysis/comparisonBarChart.dart';
import 'package:platform_v2/widgets/components/analysis/comparisonRadarChart.dart';

class ComparisonChartSelector extends ConsumerWidget {
  final Map<String, List<EmailDataPoint>> groupedDataPoints;
  final AnalysisSubType analysisSubType;
  final Map<String, String> groupIdToNameMap;
  final Set<int> selectedQuestions;
  final Set<Benchmark> selectedIndicators;
  final Function(int) onToggleQuestion;
  final Function(Benchmark) onToggleIndicator;
  final VoidCallback onSelectAllQuestions;
  final VoidCallback onDeselectAllQuestions;
  final VoidCallback onSelectAllIndicators;
  final VoidCallback onDeselectAllIndicators;
  final ChartType chartType;
  final Function(ChartType) onChartTypeChanged;

  const ComparisonChartSelector({
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
    required this.chartType,
    required this.onChartTypeChanged,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (groupedDataPoints.isEmpty) {
      return const Center(
        child: Text('No data available for comparison'),
      );
    }

    return Container(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          _buildHeaderWithControls(ref),
          const SizedBox(height: 16),
          Expanded(
            child: _buildChartContent(ref),
          ),
        ],
      ),
    );
  }

  Widget _buildHeaderWithControls(WidgetRef ref) {
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
              const SizedBox(width: 16),
              _buildChartTypeSelector(),
            ],
          ),
        ),
        if (chartType != ChartType.radar) _buildGroupLegend(ref),
      ],
    );
  }

  Widget _buildChartTypeSelector() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildChartTypeButton(ChartType.bar, Icons.bar_chart, 'Bar'),
          _buildChartTypeButton(ChartType.radar, Icons.radar, 'Radar'),
          _buildChartTypeButton(ChartType.both, Icons.dashboard, 'Both'),
        ],
      ),
    );
  }

  Widget _buildChartTypeButton(ChartType type, IconData icon, String label) {
    final isSelected = chartType == type;

    return InkWell(
      onTap: () => onChartTypeChanged(type),
      borderRadius: BorderRadius.circular(4),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? Colors.blue.shade600 : Colors.transparent,
          borderRadius: BorderRadius.circular(4),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 16,
              color: isSelected ? Colors.white : Colors.grey.shade600,
            ),
            const SizedBox(width: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                color: isSelected ? Colors.white : Colors.grey.shade700,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterDropdown() {
    final filterCount = analysisSubType == AnalysisSubType.questions ? selectedQuestions.length : selectedIndicators.length;
    final totalCount = analysisSubType == AnalysisSubType.questions ? 37 : indicators().length;

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

  Widget _buildGroupLegend(WidgetRef ref) {
    final groupsNotifier = ref.watch(groupsProvider);

    final groupNames = groupedDataPoints.keys.map((groupId) {
      if (groupsNotifier.groups.isNotEmpty) {
        try {
          final group = groupsNotifier.groups.firstWhere((g) => g.id == groupId);
          return group.groupName;
        } catch (e) {
          return groupIdToNameMap[groupId] ?? groupId;
        }
      }
      return groupIdToNameMap[groupId] ?? groupId;
    }).toList();

    return Wrap(
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
    );
  }

  Widget _buildChartContent(WidgetRef ref) {
    switch (chartType) {
      case ChartType.bar:
        return ComparisonBarChart(
          groupedDataPoints: groupedDataPoints,
          analysisSubType: analysisSubType,
          groupIdToNameMap: groupIdToNameMap,
          selectedQuestions: selectedQuestions,
          selectedIndicators: selectedIndicators,
          onToggleQuestion: onToggleQuestion,
          onToggleIndicator: onToggleIndicator,
          onSelectAllQuestions: onSelectAllQuestions,
          onDeselectAllQuestions: onDeselectAllQuestions,
          onSelectAllIndicators: onSelectAllIndicators,
          onDeselectAllIndicators: onDeselectAllIndicators,
          showHeader: false, // Hide header since we have our own
        );
      case ChartType.radar:
        return ComparisonRadarChart(
          groupedDataPoints: groupedDataPoints,
          analysisSubType: analysisSubType,
          selectedQuestions: selectedQuestions,
          selectedIndicators: selectedIndicators,
          showHeader: false, // Hide header since we have our own
        );
      case ChartType.both:
        return Row(
          children: [
            Expanded(
              child: Column(
                children: [
                  Text(
                    'Bar Chart',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey.shade700,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Expanded(
                    child: ComparisonBarChart(
                      groupedDataPoints: groupedDataPoints,
                      analysisSubType: analysisSubType,
                      groupIdToNameMap: groupIdToNameMap,
                      selectedQuestions: selectedQuestions,
                      selectedIndicators: selectedIndicators,
                      onToggleQuestion: onToggleQuestion,
                      onToggleIndicator: onToggleIndicator,
                      onSelectAllQuestions: onSelectAllQuestions,
                      onDeselectAllQuestions: onDeselectAllQuestions,
                      onSelectAllIndicators: onSelectAllIndicators,
                      onDeselectAllIndicators: onDeselectAllIndicators,
                      showHeader: false,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 20),
            Expanded(
              child: Column(
                children: [
                  Text(
                    'Radar Chart',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey.shade700,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Expanded(
                    child: ComparisonRadarChart(
                      groupedDataPoints: groupedDataPoints,
                      analysisSubType: analysisSubType,
                      selectedQuestions: selectedQuestions,
                      selectedIndicators: selectedIndicators,
                      showHeader: false,
                    ),
                  ),
                ],
              ),
            ),
          ],
        );
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

  @override
  void didUpdateWidget(_FilterDropdownButton oldWidget) {
    super.didUpdateWidget(oldWidget);

    // Update the overlay if it's open and the selections have changed
    if (_isOpen && _overlayEntry != null) {
      final bool selectionsChanged = widget.analysisSubType == AnalysisSubType.questions
          ? !_setsEqual(widget.selectedQuestions, oldWidget.selectedQuestions)
          : !_setsEqual(widget.selectedIndicators, oldWidget.selectedIndicators);

      if (selectionsChanged) {
        _updateOverlay();
      }
    }
  }

  bool _setsEqual<T>(Set<T> set1, Set<T> set2) {
    if (set1.length != set2.length) return false;
    return set1.containsAll(set2) && set2.containsAll(set1);
  }

  void _updateOverlay() {
    if (_overlayEntry != null && _isOpen) {
      // Defer the update until after the current build cycle
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (_overlayEntry != null && _isOpen) {
          _overlayEntry!.markNeedsBuild();
        }
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
