import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:platform_v2/abstractClasses/assessmentDataViewStrategy.dart';
import 'package:platform_v2/abstractClasses/assessmentSendStrategy.dart';
import 'package:platform_v2/abstractClasses/blockBehaviourStrategy.dart';
import 'package:platform_v2/abstractClasses/blockContext.dart';
import 'package:platform_v2/abstractClasses/orgBuildStrategy.dart';
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

    const dotOverhang = 38.0;
    final hitboxOffset = ref.read(blockNotifierProvider(blockId).notifier).selected ? dotOverhang : 0.0;

    BlockContext blockContext = BlockContext(
      ref: ref,
      blockId: blockId,
      buildContext: context,
      hitboxOffset: hitboxOffset,
    );

    BlockBehaviorStrategy strategy = OrgBuildStrategy();

    // Get strategy
    AppMode appMode = ref.watch(appStateProvider).displayContext.appMode;
    if (appMode == AppMode.assessmentSend) {
      strategy = AssessmentSendStrategy();
    } else if (appMode == AppMode.assessmentDataView) {
      strategy = AssessmentDataViewStrategy();
    }

    final blockState = ref.watch(blockNotifierProvider(blockId));
    final blockNotifier = ref.read(blockNotifierProvider(blockId).notifier);

    ref.listen<String?>(selectedBlockProvider, (previous, next) {
      if (next != blockId && blockState.selected) {
        blockNotifier.onDeSelect();
      }
    });

    if (blockState.positionLoaded == false) {
      return const SizedBox.shrink();
    }

    return Positioned(
      left: blockState.position.dx - hitboxOffset,
      top: blockState.position.dy - hitboxOffset,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () => strategy.onTap(blockContext),
        onDoubleTapDown: (details) => strategy.onDoubleTapDown(blockContext),
        onPanUpdate: (details) => strategy.onPanUpdate(blockContext, details, hitboxOffset),
        child: strategy.getBlockWidget(blockContext),
      ),
    );
  }
}
