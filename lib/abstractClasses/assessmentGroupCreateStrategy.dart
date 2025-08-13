import 'package:flutter/material.dart';
import 'package:platform_v2/abstractClasses/blockBehaviourStrategy.dart';
import 'package:platform_v2/abstractClasses/blockContext.dart';
import 'package:platform_v2/config/constants.dart';
import 'package:platform_v2/config/enums.dart';
import 'package:platform_v2/config/provider.dart';

class AssessmentGroupCreateStrategy extends BlockBehaviorStrategy {
  @override
  Widget getBlockWidget(BlockContext context) {
    return SizedBox(
      width: context.hitboxWidth,
      height: context.hitboxHeight,
      child: Stack(
        children: [
          Positioned(
            left: context.hitboxOffset,
            top: context.hitboxOffset,
            child: Container(
              width: kBlockWidth,
              height: kBlockHeight,
              decoration: blockDecoration(context),
              child: blockData(context),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget blockData(BlockContext context) {
    final blockData = context.blockNotifier.blockData;
    final benchmarks = context.blockNotifier.benchmarks;
    
    // Get selected display option for consistent data display with dataView
    final selectedOption = context.ref.watch(selectedDisplayOptionProvider);
    
    // Extract data based on option type (same logic as dataView)
    String? displayText;
    if (selectedOption.isQuestion) {
      // Question mode
      final hasRawResults = blockData?.rawResults.isNotEmpty == true;
      if (hasRawResults && selectedOption.questionNumber! <= blockData!.rawResults.length) {
        final answer = blockData.rawResults[selectedOption.questionNumber! - 1];
        displayText = 'Q${selectedOption.questionNumber}: $answer';
      }
    } else {
      // Benchmark mode
      final benchmarkValue = benchmarks?[selectedOption.benchmark!];
      if (benchmarkValue != null) {
        final percent = (benchmarkValue * 100).round();
        displayText = '$percent%';
      }
    }

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Text(
          blockData?.name ?? '',
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: Colors.black87,
          ),
          textAlign: TextAlign.center,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        const SizedBox(height: 2),
        Text(
          blockData?.role ?? '',
          style: const TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w400,
            color: Colors.black54,
          ),
          textAlign: TextAlign.center,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        const SizedBox(height: 4),
        // Display the extracted data
        if (displayText != null) ...[
          Text(
            displayText,
            style: TextStyle(
              fontSize: selectedOption.isQuestion ? 12 : 14,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ],
    );
  }

  @override
  BoxDecoration blockDecoration(BlockContext context) {
    final blockData = context.blockNotifier.blockData;
    final benchmarks = context.blockNotifier.benchmarks;
    
    // Get selected display option for consistent coloring with dataView
    final selectedOption = context.ref.watch(selectedDisplayOptionProvider);

    // Default color when no data available
    Color performanceColor = Colors.grey[300]!;

    // Color coding based on option type (same logic as dataView)
    if (selectedOption.isQuestion) {
      // Question mode
      final hasRawResults = blockData?.rawResults.isNotEmpty == true;
      if (hasRawResults && selectedOption.questionNumber! <= blockData!.rawResults.length) {
        final answer = blockData.rawResults[selectedOption.questionNumber! - 1];
        performanceColor = _getQuestionColor(answer);
      }
    } else {
      // Benchmark mode
      if (benchmarks != null) {
        final benchmarkValue = benchmarks[selectedOption.benchmark!];
        if (benchmarkValue != null) {
          final percentage = benchmarkValue * 100;
          performanceColor = _getBenchmarkColor(percentage);
        }
      }
    }

    // Check if block is selected for group creation
    Set<String> selectedBlocks = context.ref.watch(selectedBlocksProvider);
    if (selectedBlocks.contains(context.blockId)) {
      return BoxDecoration(
        color: performanceColor,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.blue, width: 3),
        boxShadow: const [
          BoxShadow(
            color: Colors.black26,
            blurRadius: 2,
            offset: Offset(0, 1),
          ),
        ],
      );
    } else {
      return BoxDecoration(
        color: performanceColor,
        borderRadius: BorderRadius.circular(8),
        boxShadow: const [
          BoxShadow(
            color: Colors.black26,
            blurRadius: 2,
            offset: Offset(0, 1),
          ),
        ],
      );
    }
  }

  // Color helpers (copied from dataView strategy)
  Color _getBenchmarkColor(double percentage) {
    if (percentage < 40) {
      return Colors.red[400]!;
    } else if (percentage < 50) {
      return Colors.orange[400]!;
    } else if (percentage < 60) {
      return Colors.yellow[600]!; // Darker yellow for better visibility
    } else {
      return Colors.green[400]!;
    }
  }

  Color _getQuestionColor(int answer) {
    // Question answer color coding (1-7 scale)
    switch (answer) {
      case 1:
      case 2:
        return Colors.red.shade600;
      case 3:
        return Colors.yellow.shade600;
      case 4:
        return Colors.orange.shade600;
      case 5:
      case 6:
        return Colors.green.shade600;
      case 7:
        return Colors.green.shade700;
      default:
        return Colors.grey.shade400;
    }
  }

  @override
  void onTap(BlockContext context) {
    // Handle block selection for group creation
    final selectedBlocks = context.ref.read(selectedBlocksProvider);

    if (selectedBlocks.contains(context.blockId)) {
      // Remove from group selection
      context.ref.read(selectedBlocksProvider.notifier).state = Set.from(selectedBlocks)..remove(context.blockId);
    } else {
      // Add to group selection
      context.ref.read(selectedBlocksProvider.notifier).state = Set.from(selectedBlocks)..add(context.blockId);
    }
  }

  @override
  void onDoubleTapDown(BlockContext context) {
    // No double tap behavior in group creation mode
  }

  @override
  void onPanUpdate(BlockContext context, DragUpdateDetails details, double hitboxOffset) {
    // No pan behavior in group creation mode - blocks should not be draggable during selection
  }
}