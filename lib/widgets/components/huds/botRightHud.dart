import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:platform_v2/config/enums.dart';
import 'package:platform_v2/config/provider.dart';
import 'package:platform_v2/services/httpService.dart';
import 'package:platform_v2/services/firestoreService.dart';
import 'package:platform_v2/services/uiServices/overLayService.dart';

class BotRightHud extends ConsumerWidget {
  const BotRightHud({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final appView = ref.watch(appStateProvider).appView;
    final assessmentMode = ref.watch(appStateProvider).assessmentMode;

    // Show in assessmentBuild, assessmentDataView, and assessmentAnalyze modes
    if (appView != AppView.assessmentBuild || (assessmentMode != AssessmentMode.assessmentBuild && assessmentMode != AssessmentMode.assessmentDataView && assessmentMode != AssessmentMode.assessmentAnalyze)) {
      return SizedBox.shrink();
    }

    // Different functionality based on mode
    if (assessmentMode == AssessmentMode.assessmentDataView) {
      return Tooltip(
        message: 'Create Group',
        child: FilledButton.tonal(
          onPressed: () {
            // unselect a block if it was selected.
            ref.read(selectedBlockProvider.notifier).state = null;
            ref.read(appStateProvider.notifier).setAssessmentMode(AssessmentMode.assessmentGroupCreate);
            _openCreateGroupOverlay(context, ref);
          },
          child: Icon(Icons.add),
        ),
      );
    } else if (assessmentMode == AssessmentMode.assessmentAnalyze) {
      return Tooltip(
        message: 'Reload Groups',
        child: FilledButton.tonal(
          onPressed: () async {
            await ref.read(groupsProvider).loadGroups();
          },
          child: Icon(Icons.refresh),
        ),
      );
    } else {
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

            HttpService.postRequest(path: 'https://us-central1-efficiency-1st.cloudfunctions.net/sendAssessmentToBlockIdsV2', request: request);
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

  void _openCreateGroupOverlay(BuildContext context, WidgetRef ref) {
    OverlayService.showCreateGroup(
      context,
      onCreate: (selectionType, groupName) {
        _handleGroupCreation(context, ref, groupName);
      },
      onCancel: () {
        // Clear selected blocks and reset mode
        ref.read(selectedBlocksProvider.notifier).state = {};
        ref.read(selectedDepartmentsProvider.notifier).state = {};
        ref.read(appStateProvider.notifier).setAssessmentMode(AssessmentMode.assessmentDataView);
      },
    );
  }

  Future<void> _handleGroupCreation(BuildContext context, WidgetRef ref, String groupName) async {
    final blockIds = ref.read(selectedBlocksProvider);
    final assessmentId = ref.read(appStateProvider).assessmentId;
    final orgId = ref.read(appStateProvider).orgId;

    // Collect dataDoc IDs and rawResults for selected blocks from blockNotifiers
    final dataDocIds = <String>[];
    final allRawResults = <List<int>>[];

    for (final blockId in blockIds) {
      final blockNotifier = ref.read(blockNotifierProvider(blockId));
      final blockData = blockNotifier.blockData;
      
      // Check data availability instead of email count - more reliable
      final allDataDocs = blockNotifier.allDataDocs;
      if (allDataDocs.isNotEmpty) {
        // Multi-email data available: collect all doc IDs
        for (final docData in allDataDocs) {
          final docId = docData['id'] as String?;
          if (docId != null && docId.isNotEmpty) {
            dataDocIds.add(docId);
          }
        }
      } else if (blockNotifier.blockResultDocId.isNotEmpty) {
        // Single-email data available: use blockResultDocId
        dataDocIds.add(blockNotifier.blockResultDocId);
      }
      
      // Collect rawResults for averaging (this works for both single and multi-email)
      if (blockData != null && blockData.rawResults.isNotEmpty) {
        // Only include blocks with complete rawResults (37 questions)
        if (blockData.rawResults.length == 37) {
          allRawResults.add(blockData.rawResults);
        }
      }
    }

    // Calculate averaged raw results across all selected blocks
    final averagedRawResults = _calculateAveragedRawResults(allRawResults);

    final groupData = {
      'groupName': groupName,
      'dataDocIds': dataDocIds,
      'blockIds': blockIds.toList(),
      'averagedRawResults': averagedRawResults,
      'createdAt': DateTime.now().toIso8601String(),
    };

    try {
      // Create the group using existing FirestoreService method
      await FirestoreService.createGroup(
        orgId: orgId,
        assessmentId: assessmentId,
        groupData: groupData,
      );

      // Show success message
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Group "$groupName" created successfully!')),
        );
      }
    } catch (e) {
      // Show error message
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error creating group: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }

    // Clear selections after creation attempt and reset mode
    ref.read(selectedBlocksProvider.notifier).state = {};
    ref.read(selectedDepartmentsProvider.notifier).state = {};
    ref.read(appStateProvider.notifier).setAssessmentMode(AssessmentMode.assessmentDataView);
  }

  /// Calculate averaged raw results across multiple blocks
  /// Returns a List<double> with 37 averaged values (one for each question)
  List<double> _calculateAveragedRawResults(List<List<int>> allRawResults) {
    if (allRawResults.isEmpty) {
      // Return empty list if no valid raw results
      return [];
    }

    const int expectedQuestions = 37;
    final sums = List<double>.filled(expectedQuestions, 0.0);
    final blockCount = allRawResults.length;

    // Sum up all the raw results for each question
    for (final rawResults in allRawResults) {
      for (int i = 0; i < expectedQuestions && i < rawResults.length; i++) {
        sums[i] += rawResults[i].toDouble();
      }
    }

    // Calculate averages
    final averages = <double>[];
    for (int i = 0; i < expectedQuestions; i++) {
      averages.add(sums[i] / blockCount);
    }

    return averages;
  }
}
