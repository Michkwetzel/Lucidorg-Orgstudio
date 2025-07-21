import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:platform_v2/abstractClasses/assessmentSendStrategy.dart';
import 'package:platform_v2/abstractClasses/blockBehaviourStrategy.dart';
import 'package:platform_v2/abstractClasses/blockContext.dart';
import 'package:platform_v2/abstractClasses/orgBuildStrategy.dart';
import 'package:platform_v2/config/constants.dart';
import 'package:platform_v2/config/enums.dart';
import 'package:platform_v2/config/provider.dart';

class Block extends ConsumerWidget {
  final String blockId;

  const Block({
    super.key,
    required this.blockId,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    print("Build block $blockId");
    BlockBehaviorStrategy strategy = OrgBuildStrategy();

    AppMode appMode = ref.watch(appStateProvider).displayContext.appMode;
    if (appMode == AppMode.assessmentSendSelectBlocks) {
      strategy = AssessmentSendStrategy();
    }

    BlockContext blockContext = BlockContext(
      ref: ref,
      blockId: blockId,
      buildContext: context,
      dotOverhang: 38, //How far the dot extends beyond the block
    );

    const dotOverhang = 38.0;
    final hitboxOffset = ref.read(blockNotifierProvider(blockId).notifier).selectionMode ? dotOverhang : 0.0;
    final hitboxWidth = kBlockWidth + (hitboxOffset * 2);
    final hitboxHeight = kBlockHeight + (hitboxOffset * 2);

    final blockState = ref.watch(blockNotifierProvider(blockId));
    final blockNotifier = ref.read(blockNotifierProvider(blockId).notifier);

    ref.listen<String?>(selectedBlockProvider, (previous, next) {
      if (next != blockId && blockState.selectionMode) {
        blockNotifier.selectionModeDisable();
      }
    });

    if (blockState.positionLoaded == false) {
      return const SizedBox.shrink();
    }

    // strategy.getBlockDataDisplay(blockContext, hitboxOffset),

    return Positioned(
      left: blockState.position.dx - hitboxOffset,
      top: blockState.position.dy - hitboxOffset,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () => strategy.onTap(blockContext),
        onDoubleTapDown: (details) => strategy.onDoubleTapDown(blockContext),
        onPanUpdate: (details) => strategy.onPanUpdate(blockContext, details, hitboxOffset),
        child: SizedBox(
          width: hitboxWidth,
          height: hitboxHeight,
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              // Main block container - positioned at the center of the hitbox area
              strategy.getBlockDataDisplay(blockContext, hitboxOffset),

              if (blockState.selectionMode) ...strategy.getSideDotWidgets(blockContext, hitboxWidth, hitboxHeight),
            ],
          ),
        ),
      ),
    );
  }
}
