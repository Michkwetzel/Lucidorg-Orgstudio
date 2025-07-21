import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:platform_v2/config/enums.dart';
import 'package:platform_v2/config/provider.dart';
import 'package:platform_v2/services/uiServices/overLayService.dart';

class TopRightHud extends ConsumerWidget {
  const TopRightHud({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (ref.watch(appStateProvider).displayContext.appView != AppView.orgBuild) return SizedBox.shrink();

    return PopupMenuButton<String>(
      icon: Container(
        padding: EdgeInsets.all(8),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(
          Icons.more_vert,
          size: 20,
          color: Colors.black,
        ),
      ),
      tooltip: 'More options',
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
      ),
      onSelected: (value) {
        switch (value) {
          case 'create_assessment':
            _createAssessment(context, ref);
            break;
        }
      },
      itemBuilder: (context) => [
        PopupMenuItem(
          value: 'create_assessment',
          child: Row(
            children: [
              Icon(Icons.add_circle_outline, size: 18, color: Colors.blue[700]),
              SizedBox(width: 8),
              Text('Create Assessment'),
            ],
          ),
        ),
      ],
    );
  }

  void _createAssessment(BuildContext context, WidgetRef ref) {
    OverlayService.openAssessmentCreationOverlay(
      context,
      onCreate: (assessmentName) async {
        // String assessmentId = await FirestoreService.createAssessment(ref.read(appStateProvider).orgId!, assessmentName);

        // ref.read(appStateProvider.notifier).toAssessmentView(assessmentId, assessmentName);
        print('Creating assessment: $assessmentName');
      },
      onClose: () {
        // Handle close if needed
      },
    );
  }
}
