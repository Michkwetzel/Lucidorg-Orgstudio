import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:logging/logging.dart';
import 'package:platform_v2/config/enums.dart';
import 'package:platform_v2/config/provider.dart';
import 'package:platform_v2/dataClasses/assessment.dart';
import 'package:platform_v2/services/uiServices/inputDialogService.dart';
import 'package:platform_v2/services/uiServices/navigationService.dart';
import 'package:platform_v2/widgets/components/buildingBlocks/buttons/addButton.dart';
import 'package:platform_v2/widgets/components/buildingBlocks/buttons/selectionButton.dart';
import 'package:platform_v2/widgets/components/general/loadingAnimation.dart';

class AssessmentSelectPage extends ConsumerWidget {
  const AssessmentSelectPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final Logger logger = Logger('assessmentSelectPage.dart');

    final List<Assessment> assessments = ref.watch(assessmentsSelectProvider.select((state) => state.assessments));
    final bool isLoading = ref.watch(assessmentsSelectProvider.select((state) => state.isLoading));
    final String loadingMessage = ref.watch(assessmentsSelectProvider.select((state) => state.loadingMessage));

    // //logger.info("Assessment Screen, Build run");

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
                  ...assessments.map(
                    (assessment) => SelectionButton(
                      heading: assessment.assessmentName,
                      data: assessment.id,
                      onPressed: () {
                        NavigationService.navigateToAssessmentBuild(ref, assessment.id, assessment.assessmentName);
                      },
                    ),
                  ),
                  // AddButton(
                  //   onPressed: () async {
                  //     Map<String, String>? newAssessmentInfo = await InputDialogService.showorgForm();
                  //     if (newAssessmentInfo != null) {
                  //       ref.read(assessmentScreenProvider.notifier).createAssessment(newAssessmentInfo['orgName']!);
                  //     }
                  //   },
                  // ),
                ],
              ),
            ),
    );
  }
}
