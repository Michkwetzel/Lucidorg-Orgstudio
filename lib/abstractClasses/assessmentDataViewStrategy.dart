import 'package:flutter/material.dart';
import 'package:platform_v2/abstractClasses/blockBehaviourStrategy.dart';
import 'package:platform_v2/abstractClasses/blockContext.dart';
import 'package:platform_v2/config/constants.dart';
import 'package:platform_v2/config/enums.dart';
import 'package:platform_v2/config/provider.dart';
import 'package:platform_v2/dataClasses/displayOption.dart';
import 'package:platform_v2/services/uiServices/overLayService.dart';

// The rulebook for what functions a strategy can implement.
class AssessmentDataViewStrategy extends BlockBehaviorStrategy {
  // Final block Widget build by Block.
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
    final detailedBlocks = context.ref.watch(detailedViewBlocksProvider);
    final isDetailedView = detailedBlocks.contains(context.blockId);

    if (isDetailedView) {
      return _buildDetailedView(context);
    } else {
      return _buildBasicView(context);
    }
  }

  Widget _buildBasicView(BlockContext context) {
    final blockData = context.blockNotifier.blockData;
    final benchmarks = context.blockNotifier.benchmarks;

    // Get selected display option
    final selectedOption = context.ref.watch(selectedDisplayOptionProvider);

    // Extract data based on option type
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

  Widget _buildDetailedView(BlockContext context) {
    final benchmarks = context.blockNotifier.benchmarks;

    if (benchmarks == null) {
      return const Center(
        child: Text(
          'No Data',
          style: TextStyle(
            fontSize: 12,
            color: Colors.black54,
          ),
        ),
      );
    }

    // Get benchmark values and convert to percentages
    final orgIndex = ((benchmarks[Benchmark.orgIndex] ?? 0) * 100).round();
    final align = ((benchmarks[Benchmark.alignP] ?? 0) * 100).round();
    final process = ((benchmarks[Benchmark.processP] ?? 0) * 100).round();
    final people = ((benchmarks[Benchmark.peopleP] ?? 0) * 100).round();
    final leadership = ((benchmarks[Benchmark.leadershipP] ?? 0) * 100).round();

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        _buildBenchmarkRowWithColor('Index', orgIndex, benchmarks[Benchmark.orgIndex]),
        const SizedBox(height: 2),
        _buildBenchmarkRowWithColor('Align', align, benchmarks[Benchmark.alignP]),
        const SizedBox(height: 2),
        _buildBenchmarkRowWithColor('Process', process, benchmarks[Benchmark.processP]),
        const SizedBox(height: 2),
        _buildBenchmarkRowWithColor('People', people, benchmarks[Benchmark.peopleP]),
        const SizedBox(height: 2),
        _buildBenchmarkRowWithColor('Leadership', leadership, benchmarks[Benchmark.leadershipP]),
      ],
    );
  }

  Widget _buildBenchmarkRowWithColor(String label, int percentage, double? benchmarkValue) {
    final color = _getBenchmarkColor(percentage.toDouble());

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: Row(
        children: [
          // Label (left side)
          Expanded(
            flex: 2,
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w500,
                color: Colors.black87,
              ),
            ),
          ),
          // Percentage (right-aligned)
          Expanded(
            flex: 1,
            child: Text(
              '$percentage%',
              textAlign: TextAlign.right,
              style: const TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w600,
                color: Colors.black87,
              ),
            ),
          ),
          const SizedBox(width: 4),
          // Color indicator (right side)
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(2), // Small square
            ),
          ),
        ],
      ),
    );
  }

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
  BoxDecoration blockDecoration(BlockContext context) {
    final blockData = context.blockNotifier.blockData;
    final benchmarks = context.blockNotifier.benchmarks;
    final isSelected = context.blockNotifier.selected;
    final detailedBlocks = context.ref.watch(detailedViewBlocksProvider);
    final isDetailedView = detailedBlocks.contains(context.blockId);

    // Get selected display option
    final selectedOption = context.ref.watch(selectedDisplayOptionProvider);

    // Default color when no data available
    Color performanceColor = Colors.grey[300]!;

    // Color coding based on option type
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

    if (isDetailedView) {
      // Detailed view: white background with colored border
      return BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isSelected ? Colors.blue : performanceColor,
          width: isSelected ? 3 : 2,
        ),
        boxShadow: const [
          BoxShadow(
            color: Colors.black26,
            blurRadius: 2,
            offset: Offset(0, 1),
          ),
        ],
      );
    } else {
      // Basic view: colored background
      return BoxDecoration(
        color: performanceColor,
        borderRadius: BorderRadius.circular(8),
        border: isSelected ? Border.all(color: Colors.blue, width: 3) : null,
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

  // Toggle between basic and detailed view
  @override
  void onTap(BlockContext context) {
    final detailedBlocks = context.ref.read(detailedViewBlocksProvider.notifier);
    final currentDetailedBlocks = context.ref.read(detailedViewBlocksProvider);

    if (currentDetailedBlocks.contains(context.blockId)) {
      // Remove from detailed view (switch to basic)
      detailedBlocks.state = Set.from(currentDetailedBlocks)..remove(context.blockId);
    } else {
      // Add to detailed view
      detailedBlocks.state = Set.from(currentDetailedBlocks)..add(context.blockId);
    }
  }

  @override
  void onDoubleTapDown(BlockContext context) {
    OverlayService.showBlockDataView(context.buildContext, blockData: context.blockNotifier.blockData!, benchmarks: context.blockNotifier.benchmarks);
  }

  @override
  void onPanUpdate(BlockContext context, DragUpdateDetails details, double hitboxOffset) {
    // Convert global position to local canvas position
    final RenderBox? canvasBox = context.buildContext.findAncestorRenderObjectOfType<RenderBox>();
    if (canvasBox == null) return;
    final localPosition = canvasBox.globalToLocal(details.globalPosition);
    final newPosition = Offset(
      localPosition.dx - hitboxOffset,
      localPosition.dy - hitboxOffset,
    );

    // Check if block is selected and if it has any children. If yes then do batch move and batch firestore update
    // If not just move block and one doc update
    if (context.blockNotifier.selected && context.blockNotifier.descendants.isNotEmpty) {
      Set<String> descendants = context.blockNotifier.descendants;
      final currentPosition = context.blockNotifier.position;
      final delta = newPosition - currentPosition;

      // Update the main block position immediately as well
      context.blockNotifier.updatePositionWithoutFirestore(newPosition);

      // Update UI immediately for all descendants and also collect new positons.
      Map<String, Offset> positions = {context.blockId: newPosition};
      for (var descendant in descendants) {
        final descendantNotifier = context.ref.read(blockNotifierProvider(descendant).notifier);
        final currentPos = descendantNotifier.position;
        final newPosition = currentPos + delta;
        descendantNotifier.updatePositionWithoutFirestore(newPosition);
        positions[descendant] = newPosition;
      }

      //Batch Firestore update with debounce. Goes through BlockNotifier.
      context.blockNotifier.batchUpdateDescendantPositions(positions);
    } else {
      // Move single block
      context.blockNotifier.updatePosition(newPosition);
    }
  }
}
