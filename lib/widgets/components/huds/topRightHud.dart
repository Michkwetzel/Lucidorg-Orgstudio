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
    final appView = ref.watch(appStateProvider).appView;

    if (appView == AppView.orgBuild) {
      return _buildPopupMenu(context, ref);
    } else if (appView == AppView.assessmentBuild) {
      return _buildSegmentedButton(context, ref);
    } else {
      return SizedBox.shrink();
    }
  }

  Widget _buildPopupMenu(BuildContext context, WidgetRef ref) {
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

  Widget _buildSegmentedButton(BuildContext context, WidgetRef ref) {
    final currentAssessmentMode = ref.watch(appStateProvider).assessmentMode;
    final groupsNotifier = ref.watch(groupsProvider);
    final isAnalyzeLoading = groupsNotifier.isAnalysisModeActive && groupsNotifier.emailDataLoading;

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade300),
        color: Colors.white,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildSegmentButton(
            context: context,
            ref: ref,
            text: 'Builder',
            isActive: currentAssessmentMode == AssessmentMode.assessmentBuild,
            onTap: () {
              // Clear analysis cache when leaving analysis mode
              ref.read(groupsProvider).exitAnalysisMode();
              ref.read(appStateProvider.notifier).setAssessmentMode(AssessmentMode.assessmentBuild);
            },
            isFirst: true,
          ),
          _buildSegmentButton(
            context: context,
            ref: ref,
            text: 'Data View',
            isActive: currentAssessmentMode == AssessmentMode.assessmentDataView,
            onTap: () {
              // Clear analysis cache when leaving analysis mode
              ref.read(groupsProvider).exitAnalysisMode();
              ref.read(appStateProvider.notifier).setAssessmentMode(AssessmentMode.assessmentDataView);
            },
            isFirst: false,
          ),
          _buildSegmentButton(
            context: context,
            ref: ref,
            text: 'Analyze',
            isActive: currentAssessmentMode == AssessmentMode.assessmentAnalyze,
            isLoading: isAnalyzeLoading,
            onTap: () async {
              // Initialize analysis mode cache before switching
              final groupsNotifier = ref.read(groupsProvider);
              
              // Only switch mode after cache initialization completes
              await groupsNotifier.initializeAnalysisMode();
              ref.read(appStateProvider.notifier).setAssessmentMode(AssessmentMode.assessmentAnalyze);
            },
            isFirst: false,
            isLast: true,
          ),
        ],
      ),
    );
  }

  Widget _buildSegmentButton({
    required BuildContext context,
    required WidgetRef ref,
    required String text,
    required bool isActive,
    required VoidCallback onTap,
    required bool isFirst,
    bool isLast = false,
    bool isLoading = false,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isActive ? Colors.blue.shade100 : Colors.transparent,
          borderRadius: BorderRadius.horizontal(
            left: isFirst ? Radius.circular(7) : Radius.zero,
            right: isLast ? Radius.circular(7) : Radius.zero,
          ),
        ),
        child: isLoading 
            ? Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SizedBox(
                    width: 12,
                    height: 12,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.blue.shade700,
                    ),
                  ),
                  SizedBox(width: 6),
                  Text(
                    text,
                    style: TextStyle(
                      color: Colors.blue.shade700,
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                    ),
                  ),
                ],
              )
            : Text(
                text,
                style: TextStyle(
                  color: isActive ? Colors.blue.shade700 : Colors.grey.shade600,
                  fontWeight: isActive ? FontWeight.w600 : FontWeight.normal,
                  fontSize: 14,
                ),
              ),
      ),
    );
  }

  void _createAssessment(BuildContext context, WidgetRef ref) {
    OverlayService.showAssessmentCreation(
      context,
      onCreate: (assessmentName) async {
        await FirestoreService.createAssessment(orgId: ref.read(appStateProvider).orgId!, assessmentName: assessmentName);
        // ref.read(appStateProvider.notifier).toAssessmentView(assessmentId, assessmentName);
        print('Creating assessment: $assessmentName');
      },
      onCancel: () {
        // Handle close if needed
      },
    );
  }
}
