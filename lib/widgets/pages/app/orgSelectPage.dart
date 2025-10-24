import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:logging/logging.dart';
import 'package:platform_v2/config/enums.dart';
import 'package:platform_v2/config/provider.dart';
import 'package:platform_v2/dataClasses/org.dart';
import 'package:platform_v2/services/uiServices/inputDialogService.dart';
import 'package:platform_v2/services/uiServices/navigationService.dart';
import 'package:platform_v2/widgets/components/buildingBlocks/buttons/addButton.dart';
import 'package:platform_v2/widgets/components/buildingBlocks/buttons/selectionButton.dart';
import 'package:platform_v2/widgets/components/general/loadingAnimation.dart';

class OrgSelectPage extends ConsumerWidget {
  const OrgSelectPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final Logger logger = Logger('orgSelectPage.dart');

    final List<Org> orgs = ref.watch(orgsSelectProvider.select((state) => state.orgs));
    final bool isLoading = ref.watch(orgsSelectProvider.select((state) => state.isLoading));
    final String loadingMessage = ref.watch(orgsSelectProvider.select((state) => state.loadingMessage));

    //logger.info("org Screen, Build run");

    return Padding(
      padding: const EdgeInsets.only(left: 32, right: 32, top: 105, bottom: 32),
      child: isLoading
          ? LoadingAnimation(loadingMessage)
          : SingleChildScrollView(
              child: Wrap(
                spacing: 24,
                crossAxisAlignment: WrapCrossAlignment.center,
                runSpacing: 24,
                children: [
                  ...orgs.map(
                    (org) => SelectionButton(
                      heading: org.orgName,
                      data: org.id,
                      onPressed: () {
                        // Automatically select the specific assessment and go to canvas
                        const assessmentId = 't4vXyZAB6bzYbbriJg7n';
                        const assessmentName = 'Demo Assessment'; // You can change this name

                        // Set org context first
                        ref.read(appStateProvider.notifier).batchUpdate(
                          (state) => state.copyWith(
                            orgId: org.id,
                            orgName: org.orgName,
                          ),
                        );

                        // Navigate directly to assessment build (canvas)
                        NavigationService.navigateToAssessmentBuild(ref, assessmentId, assessmentName);
                      },
                    ),
                  ),
                  AddButton(
                    onPressed: () async {
                      // FirestoreService.addQuestiontoDB();
                      Map<String, String>? neworgInfo = await InputDialogService.showorgForm();
                      if (neworgInfo != null) {
                        ref.read(orgsSelectProvider.notifier).createorg(neworgInfo['orgName']!);
                      }
                    },
                  ),
                ],
              ),
            ),
    );
  }
}
