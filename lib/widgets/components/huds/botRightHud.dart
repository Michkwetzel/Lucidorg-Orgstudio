import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:platform_v2/config/enums.dart';
import 'package:platform_v2/config/provider.dart';
import 'package:platform_v2/services/httpService.dart';
import 'package:platform_v2/services/uiServices/overLayService.dart';

class BotRightHud extends ConsumerWidget {
  const BotRightHud({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final appView = ref.watch(appStateProvider).appView;
    final assessmentMode = ref.watch(appStateProvider).assessmentMode;

    if (appView != AppView.assessmentBuild || assessmentMode != AssessmentMode.assessmentBuild) return SizedBox.shrink();

    return Tooltip(
      message: 'Send Assessment',
      child: FilledButton.tonal(
        onPressed: () {
          // unselect a block if it was selected.
          ref.read(selectedBlockProvider.notifier).state = null;
          // change mode to assessmentSendSelectBlocks
          ref.read(appStateProvider.notifier).setAssessmentMode(AssessmentMode.assessmentSend);
          _openSendAssessmentOverlay(context, ref);
        },
        child: Icon(Icons.add),
      ),
    );
  }

  void _openSendAssessmentOverlay(BuildContext context, WidgetRef ref) {
    OverlayService.showSendAssessment(
      context,
      onSend: (selectionType, textData) {
        // Open the confirmation Overlay
        OverlayService.showAssessmentSendConfirmation(
          context,
          onSend: () {
            final blockIds = ref.read(selectedBlocksProvider);
            final assessmentId = ref.read(appStateProvider).assessmentId;
            final orgId = ref.read(appStateProvider).orgId;
            final request = {
              'assessmentId': assessmentId,
              'orgId': orgId,
              'blockIds': blockIds.toList(),
            };

            HttpService.postRequest(path: 'http://127.0.0.1:5001/efficiency-1st/us-central1/sendAssessmentToBlockIds', request: request);
          },
          onCancel: () {},
        );
      },
      onCancel: () {
        // Clear AssessmentSend Blocks
        ref.read(selectedBlocksProvider.notifier).state = {};
        ref.read(appStateProvider.notifier).setAssessmentMode(AssessmentMode.assessmentBuild);
      },
    );
  }
}
