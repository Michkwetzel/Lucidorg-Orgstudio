import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:platform_v2/config/provider.dart';
import 'package:platform_v2/config/enums.dart';
import 'package:platform_v2/services/uiServices/navigationService.dart';
import 'package:platform_v2/services/uiServices/overLayService.dart';
import 'package:platform_v2/services/firestoreService.dart';

class BotLeftHud extends ConsumerWidget {
  const BotLeftHud({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final appView = ref.watch(appStateProvider).appView;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      spacing: 4,
      children: [
        if (appView == AppView.orgBuild || appView == AppView.assessmentBuild)
          FilledButton.tonal(
            onPressed: () async {
              NavigationService.navigateToOrgSelect(ref);
            },
            child: Text("Orgs"),
          ),
      ],
    );
  }

  void _openSelectOrgForAssessmentOverlay(BuildContext context, WidgetRef ref) {
    OverlayService.showSelectOrgForAssessment(
      context,
      onSelect: (orgId, orgName) {
        // Navigate to assessment select with org context
        NavigationService.navigateToAssessmentSelect(ref, orgId: orgId, orgName: orgName);
      },
      onCancel: () {},
    );
  }

  void _openGenerateMockDataOverlay(BuildContext context, WidgetRef ref) {
    OverlayService.showGenerateMockData(
      context,
      onGenerate: (region, variationLevel) async {
        final orgId = ref.read(appStateProvider).orgId;
        final assessmentId = ref.read(appStateProvider).assessmentId;

        try {
          // Show loading indicator
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Row(
                  children: [
                    SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                    SizedBox(width: 12),
                    Text('Generating mock data for region $region...'),
                  ],
                ),
                duration: Duration(hours: 1), // Keep visible until complete
              ),
            );
          }

          final result = await FirestoreService.generateMockAssessmentData(
            orgId: orgId!,
            assessmentId: assessmentId!,
            region: region,
            department: 'Office',
            variationLevel: variationLevel,
          );

          // Close loading indicator
          if (context.mounted) {
            ScaffoldMessenger.of(context).clearSnackBars();

            // Show success message
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  'Successfully generated ${result['dataDocsCreated']} data docs for ${result['blocksProcessed']} blocks in region $region!',
                ),
                backgroundColor: Colors.green,
                duration: Duration(seconds: 5),
              ),
            );
          }
        } catch (e) {
          // Close loading indicator
          if (context.mounted) {
            ScaffoldMessenger.of(context).clearSnackBars();

            // Show error message
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Error generating mock data: $e'),
                backgroundColor: Colors.red,
                duration: Duration(seconds: 5),
              ),
            );
          }
        }
      },
      onCancel: () {},
    );
  }

  void _openCopyRegionOverlay(BuildContext context, WidgetRef ref) {
    OverlayService.showCopyRegion(
      context,
      onCopy: (sourceRegion, targetRegion) async {
        final orgId = ref.read(appStateProvider).orgId;

        try {
          // Show loading indicator
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Row(
                  children: [
                    SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                    SizedBox(width: 12),
                    Text('Copying blocks from region $sourceRegion to region $targetRegion...'),
                  ],
                ),
                duration: Duration(hours: 1), // Keep it visible until operation completes
              ),
            );
          }

          final result = await FirestoreService.copyRegionBlocksAndConnections(
            orgId: orgId!,
            sourceRegion: sourceRegion,
            targetRegion: targetRegion,
          );

          // Close loading indicator
          if (context.mounted) {
            ScaffoldMessenger.of(context).clearSnackBars();

            // Show success message
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  'Successfully copied ${result['blocksCreated']} blocks and ${result['connectionsCreated']} connections to region $targetRegion!',
                ),
                backgroundColor: Colors.green,
              ),
            );
          }
        } catch (e) {
          // Close loading indicator
          if (context.mounted) {
            ScaffoldMessenger.of(context).clearSnackBars();

            // Show error message
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Error copying region: $e'),
                backgroundColor: Colors.red,
              ),
            );
          }
        }
      },
      onCancel: () {},
    );
  }

  void _fixBlockIds(BuildContext context, WidgetRef ref) async {
    final orgId = ref.read(appStateProvider).orgId;
    final assessmentId = ref.read(appStateProvider).assessmentId;

    try {
      // Show loading indicator
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
                SizedBox(width: 12),
                Text('Fixing block IDs...'),
              ],
            ),
            duration: Duration(hours: 1),
          ),
        );
      }

      final result = await FirestoreService.fixBlockIds(
        orgId: orgId!,
        assessmentId: assessmentId,
      );

      // Close loading indicator
      if (context.mounted) {
        ScaffoldMessenger.of(context).clearSnackBars();

        // Show success message
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Successfully fixed ${result['blocksFixed']} block IDs!',
            ),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 5),
          ),
        );
      }
    } catch (e) {
      // Close loading indicator
      if (context.mounted) {
        ScaffoldMessenger.of(context).clearSnackBars();

        // Show error message
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error fixing block IDs: $e'),
            backgroundColor: Colors.red,
            duration: Duration(seconds: 5),
          ),
        );
      }
    }
  }
}
