import 'package:flutter/material.dart';
import 'package:platform_v2/abstractClasses/blockBehaviourStrategy.dart';
import 'package:platform_v2/abstractClasses/blockContext.dart';
import 'package:platform_v2/config/constants.dart';

//Class encapsulating Block behaviour and appearance in AssessmentBuild mode
class AssessmentBuildStrategy extends BlockBehaviorStrategy {
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
    return Column(
      spacing: 4,
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Text(context.blockNotifier.blockData?.name ?? ""),
        Text(context.blockNotifier.blockData?.role ?? ""),
        Text(context.blockNotifier.blockData?.department ?? ""),
      ],
    );
  }

  @override
  BoxDecoration blockDecoration(BlockContext context) {
    final sent = context.blockNotifier.sent;
    final submitted = context.blockNotifier.submitted;

    print(sent);
    print(submitted);
    // Color based on explicit assessment status flags
    Color blockColor;

    if (!sent) {
      // White - Assessment not sent yet (same as orgBuild)
      return kboxShadowNormal;
    } else if (sent && !submitted) {
      // Amber - Assessment sent but not submitted
      blockColor = Colors.amber[300]!;
    } else {
      // Green - Assessment submitted
      blockColor = Colors.green[300]!;
    }

    return kboxShadowNormal.copyWith(color: blockColor);
  }

  @override
  void onTap(BlockContext context) {
    // Simple tap - no selection behavior needed for assessment build mode
    // Could potentially show assessment details or status in the future
  }

  @override
  void onDoubleTapDown(BlockContext context) {
    // No double-tap functionality needed for assessment build mode
    // Assessment building doesn't require editing block data
  }

  @override
  void onPanUpdate(BlockContext context, DragUpdateDetails details, double hitboxOffset) {
    // No dragging allowed in assessment build mode
    // Blocks should remain in their fixed positions during assessment building
  }
}
