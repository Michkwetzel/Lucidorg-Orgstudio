import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:platform_v2/config/enums.dart';
import 'package:platform_v2/config/provider.dart';
import 'package:platform_v2/dataClasses/displayOption.dart';

class DataViewOptionsHud extends ConsumerStatefulWidget {
  const DataViewOptionsHud({super.key});

  @override
  ConsumerState<DataViewOptionsHud> createState() => _DataViewOptionsHudState();
}

class _DataViewOptionsHudState extends ConsumerState<DataViewOptionsHud> {
  String? _expandedSection; // null, 'benchmark', or 'question'

  @override
  Widget build(BuildContext context) {
    final appMode = ref.watch(appStateProvider).displayContext.appMode;
    // Only show in AssessmentDataViewx
    if (appMode != AppMode.assessmentDataView) {
      return const SizedBox.shrink();
    }

    final selectedOption = ref.watch(selectedDisplayOptionProvider);
    final availableBenchmarks = Benchmark.values;

    return Positioned(
      left: 20,
      top: 70,
      child: Container(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height - 200, // Leave space for top/bottom HUDs
          maxWidth: 300, // Reasonable max width
        ),
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
                  onTap: () => setState(() => 
                    _expandedSection = _expandedSection == 'benchmark' ? null : 'benchmark'
                  ),
                  child: Icon(
                    _expandedSection == 'benchmark' ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
                    size: 16,
                    color: Colors.black87,
                  ),
                ),
              ],
            ),
            if (_expandedSection == 'benchmark') ...[
              const SizedBox(height: 8),
              Flexible(
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: availableBenchmarks.map((benchmark) {
                      final benchmarkOption = DisplayOption.benchmark(benchmark);
                      final isSelected = selectedOption == benchmarkOption;
                      return _buildBenchmarkButton(
                        benchmark,
                        isSelected,
                        () => ref.read(selectedDisplayOptionProvider.notifier).state = benchmarkOption,
                      );
                    }).toList(),
                  ),
                ),
              ),
            ],
            if (_expandedSection != 'benchmark') const SizedBox(height: 16),
            
            // Question Number Dropdown
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'Question Number',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(width: 8),
                InkWell(
                  onTap: () => setState(() => 
                    _expandedSection = _expandedSection == 'question' ? null : 'question'
                  ),
                  child: Icon(
                    _expandedSection == 'question' ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
                    size: 16,
                    color: Colors.black87,
                  ),
                ),
              ],
            ),
            if (_expandedSection == 'question') ...[
              const SizedBox(height: 8),
              Flexible(
                child: SingleChildScrollView(
                  child: Column(
                    children: [
                      for (int i = 1; i <= 37; i++)
                        _buildQuestionButton(
                          i,
                          selectedOption == DisplayOption.question(i),
                          () => ref.read(selectedDisplayOptionProvider.notifier).state = DisplayOption.question(i),
                        ),
                    ],
                  ),
                ),
              ),
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
                DisplayOption.benchmark(benchmark).label,
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

  Widget _buildQuestionButton(int questionNumber, bool isSelected, VoidCallback onTap) {
    return Container(
      margin: const EdgeInsets.only(bottom: 4),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(6),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
          decoration: BoxDecoration(
            color: isSelected ? Colors.green[50] : Colors.transparent,
            borderRadius: BorderRadius.circular(6),
            border: Border.all(
              color: isSelected ? Colors.green[300]! : Colors.grey[300]!,
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
                  color: isSelected ? Colors.green[600] : Colors.grey[400],
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                'Q$questionNumber',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                  color: isSelected ? Colors.green[700] : Colors.black87,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

}
