import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:platform_v2/config/enums.dart';
import 'package:platform_v2/config/provider.dart';
import 'package:platform_v2/services/firestoreService.dart';
import 'package:platform_v2/services/uiServices/overLayService.dart';

class TopRightHud extends ConsumerWidget {
  const TopRightHud({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (ref.watch(topRightHudProvider) == false) return SizedBox.shrink();

    return FilledButton.tonal(
      onPressed: () {
        OverlayService.openAssessmentCreationOverlay(
          context,
          onCreate: (assessmentName) async {
            String assessmentId = await FirestoreService.createAssessment(ref.read(appStateProvider).orgId!, assessmentName);
            ref.read(appStateProvider.notifier).setAppView(AppView.assessmentCreate);

            //TODO: Return assesment ID and Assessment Name. 
            ref.read(appStateProvider.notifier).setAssessment(assessmentId, "assessment.assessmentName");

            print('Creating assessment: $assessmentName');
          },
          onClose: () {
            // Handle close if needed
          },
        );
      },
      child: Text("Create Assessment"),
    );
  }
}
