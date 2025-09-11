import 'package:flutter/material.dart';
import 'package:platform_v2/abstractClasses/blockBehaviourStrategy.dart';
import 'package:platform_v2/abstractClasses/blockContext.dart';
import 'package:platform_v2/config/constants.dart';
import 'package:platform_v2/config/enums.dart';
import 'package:platform_v2/config/provider.dart';

class AssessmentSendStrategy extends BlockBehaviorStrategy {
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
    final hierarchy = blockData?.hierarchy;
    final showHierarchy = hierarchy != null && hierarchy != Hierarchy.none;
    
    return Column(
      spacing: 4,
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Text(blockData?.name ?? ""),
        Text(blockData?.role ?? ""),
        Text(blockData?.department ?? ""),
        if (showHierarchy)
          Text(
            hierarchy.name,
            style: const TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 11,
            ),
          ),
      ],
    );
  }

  @override
  BoxDecoration blockDecoration(BlockContext context) {
    final sent = context.blockNotifier.sent;
    final submitted = context.blockNotifier.submitted;

    // Color based on explicit assessment status flags
    Color blockColor = Colors.white;

    if (sent && !submitted) {
      // Amber - Assessment sent but not submitted
      blockColor = Colors.amber[300]!;
    } else if (submitted && sent) {
      // Green - Assessment submitted
      blockColor = Colors.green[300]!;
    }

    Set<String> selectedBlocks = context.ref.watch(selectedBlocksProvider);
    bool isSelected = selectedBlocks.contains(context.blockId);
    bool hasMultipleEmails = context.blockNotifier.blockData?.hasMultipleEmails ?? false;

    // Determine border based on selection and multiple emails
    Border? border;
    if (isSelected && hasMultipleEmails) {
      // Both selected and has multiple emails - use selection border (blue takes priority)
      border = Border.all(color: Colors.blue, width: 6);
    } else if (isSelected) {
      // Only selected
      border = Border.all(color: Colors.blue, width: 6);
    } else if (hasMultipleEmails) {
      // Only has multiple emails
      border = Border.all(color: Colors.black, width: 2);
    }

    return kboxShadowNormal.copyWith(
      border: border,
      color: blockColor,
    );
  }

  @override
  void onTap(BlockContext context) {
    print("Block tapped");
    final selectedBlocks = context.ref.read(selectedBlocksProvider);

    if (selectedBlocks.contains(context.blockId)) {
      context.ref.read(selectedBlocksProvider.notifier).state = Set.from(selectedBlocks)..remove(context.blockId);
    } else {
      context.ref.read(selectedBlocksProvider.notifier).state = Set.from(selectedBlocks)..add(context.blockId);
    }
  }

  @override
  void onDoubleTapDown(BlockContext context) {}

  @override
  void onPanUpdate(BlockContext context, DragUpdateDetails details, double hitboxOffset) {}
}
