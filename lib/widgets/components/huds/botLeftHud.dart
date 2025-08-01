import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:platform_v2/config/provider.dart';
import 'package:platform_v2/config/enums.dart';
import 'package:platform_v2/services/uiServices/navigationService.dart';

class BotLeftHud extends ConsumerWidget {
  const BotLeftHud({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final appView = ref.watch(appStateProvider).displayContext.appView;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      spacing: 4,
      children: [
        if (appView == AppView.assessmentBuild)
          FilledButton.tonal(
            onPressed: () {
              NavigationService.navigateToAssessmentSelect(ref);
            },
            child: Text("Assessments"),
          ),
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
}
