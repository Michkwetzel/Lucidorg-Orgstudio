import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:platform_v2/abstractClasses/assessmentBuildStrategy.dart';
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
    const dotOverhang = 38.0;
    final hitboxOffset = ref.read(blockNotifierProvider(blockId).notifier).selected ? dotOverhang : 0.0;

    BlockContext blockContext = BlockContext(
      ref: ref,
      blockId: blockId,
      buildContext: context,
      hitboxOffset: hitboxOffset,
    );

    BlockBehaviorStrategy strategy = OrgBuildStrategy();
    AssessmentMode? assessmentMode = ref.watch(appStateProvider).displayContext.assessmentMode;
    AppView appView = ref.watch(appStateProvider).displayContext.appView;

    if (appView == AppView.orgBuild) {
      strategy = OrgBuildStrategy();
    } else {
      if (assessmentMode == AssessmentMode.assessmentSend) {
        strategy = AssessmentSendStrategy();
      } else if (assessmentMode == AssessmentMode.assessmentDataView) {
        strategy = AssessmentDataViewStrategy();
      } else if (assessmentMode == AssessmentMode.assessmentBuild) {
        strategy = AssessmentBuildStrategy();
      }
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

    final result = Positioned(
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

    return result;
  }
}
