import 'package:flutter/material.dart';
import 'package:platform_v2/abstractClasses/blockBehaviourStrategy.dart';
import 'package:platform_v2/abstractClasses/blockContext.dart';
import 'package:platform_v2/config/constants.dart';
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
    Set<String> selectedBlocks = context.ref.watch(selectedBlocksProvider);
    if (selectedBlocks.contains(context.blockId)) {
      return kboxShadowNormal.copyWith(border: Border.all(color: Colors.blue, width: 6));
    } else {
      return kboxShadowNormal;
    }
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
