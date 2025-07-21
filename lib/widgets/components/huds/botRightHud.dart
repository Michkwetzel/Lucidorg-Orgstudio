import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:platform_v2/config/enums.dart';
import 'package:platform_v2/config/provider.dart';
import 'package:platform_v2/services/uiServices/overLayService.dart';

class BotRightHud extends ConsumerWidget {
  const BotRightHud({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final appView = ref.watch(appStateProvider).displayContext.appView;

    if (appView != AppView.assessmentBuild) return SizedBox.shrink();

    return Tooltip(
      message: 'Send Assessment',
      child: FilledButton.tonal(
        onPressed: () {
          // unselect a block if it was selected.
          ref.read(selectedBlockProvider.notifier).state = null;
          // chnage mode to assessmentSendSelectBlocks
          ref.read(appStateProvider.notifier).setAppMode(AppMode.assessmentSendSelectBlocks);
          _openSendAssessmentOverlay(context, ref);
        },
        child: Icon(Icons.add),
      ),
    );
  }

  void _openSendAssessmentOverlay(BuildContext context, WidgetRef ref) {
    OverlayService.openSendAssessmentOverlay(
      context,
      onSend: (selectionType, textData) {
        print('Sending assessment with selection: $selectionType, text: $textData');
      },
      onClose: () {
        // Clear AssessmentSend Blocks
        ref.read(selectedBlocksProvider.notifier).state = {};
        ref.read(appStateProvider.notifier).setAppMode(AppMode.assessmentBuild);
      },
    );
  }
}
