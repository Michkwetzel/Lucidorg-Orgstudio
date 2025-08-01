import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:platform_v2/config/enums.dart';
import 'package:platform_v2/config/provider.dart';

class DataViewOptionsHud extends ConsumerStatefulWidget {
  const DataViewOptionsHud({super.key});

  @override
  ConsumerState<DataViewOptionsHud> createState() => _DataViewOptionsHudState();
}

class _DataViewOptionsHudState extends ConsumerState<DataViewOptionsHud> {
  bool _isExpanded = false;

  @override
  Widget build(BuildContext context) {
    final appMode = ref.watch(appStateProvider).displayContext.appMode;
    // Only show in AssessmentDataViewx
    if (appMode != AppMode.assessmentDataView) {
      return const SizedBox.shrink();
    }

    final selectedBenchmark = ref.watch(selectedBenchmarkProvider);
    final availableBenchmarks = Benchmark.values;

    return Positioned(
      left: 20,
      top: 70,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'Benchmark Display',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(width: 8),
                InkWell(
                  onTap: () => setState(() => _isExpanded = !_isExpanded),
                  child: Icon(
                    _isExpanded ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
                    size: 16,
                    color: Colors.black87,
                  ),
                ),
              ],
            ),
            if (_isExpanded) ...[
              const SizedBox(height: 8),
              ...availableBenchmarks.map((benchmark) {
                final isSelected = selectedBenchmark == benchmark;
                return _buildBenchmarkButton(
                  benchmark,
                  isSelected,
                  () => ref.read(selectedBenchmarkProvider.notifier).state = benchmark,
                );
              }),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildBenchmarkButton(Benchmark benchmark, bool isSelected, VoidCallback onTap) {
    return Container(
      margin: const EdgeInsets.only(bottom: 4),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(6),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
          decoration: BoxDecoration(
            color: isSelected ? Colors.blue[50] : Colors.transparent,
            borderRadius: BorderRadius.circular(6),
            border: Border.all(
              color: isSelected ? Colors.blue[300]! : Colors.grey[300]!,
              width: 1,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  color: isSelected ? Colors.blue[600] : Colors.grey[400],
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                _getBenchmarkLabel(benchmark),
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                  color: isSelected ? Colors.blue[700] : Colors.black87,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _getBenchmarkLabel(Benchmark benchmark) {
    switch (benchmark) {
      case Benchmark.orgAlign:
        return 'Org Alignment';
      case Benchmark.growthAlign:
        return 'Growth Alignment';
      case Benchmark.collabKPIs:
        return 'Collab KPIs';
      case Benchmark.engagedCommunity:
        return 'Engaged Community';
      case Benchmark.crossFuncComms:
        return 'Cross-Func Comms';
      case Benchmark.crossFuncAcc:
        return 'Cross-Func Acc';
      case Benchmark.alignedTech:
        return 'Aligned Tech';
      case Benchmark.collabProcesses:
        return 'Collab Processes';
      case Benchmark.meetingEfficacy:
        return 'Meeting Efficacy';
      case Benchmark.purposeDriven:
        return 'Purpose Driven';
      case Benchmark.empoweredLeadership:
        return 'Empowered Leadership';
      case Benchmark.engagement:
        return 'Engagement';
      case Benchmark.productivity:
        return 'Productivity';
      case Benchmark.orgIndex:
        return 'Index';
      case Benchmark.workforce:
        return 'Workforce';
      case Benchmark.operations:
        return 'Operations';
      case Benchmark.alignP:
        return 'Alignment P';
      case Benchmark.processP:
        return 'Process P';
      case Benchmark.leadershipP:
        return 'Leadership P';
      case Benchmark.peopleP:
        return 'People P';
    }
  }
}
