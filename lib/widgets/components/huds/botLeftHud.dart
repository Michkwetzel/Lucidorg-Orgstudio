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
        if (appView == AppScreen.assessmentBuild)
          FilledButton.tonal(
            onPressed: () {
              ref.read(appStateProvider.notifier).setAppView(AppScreen.assessmentSelect);
              NavigationService.navigateTo('/app/assessmentSelect');
            },
            child: Text("Assessments"),
          ),
        if (appView == AppScreen.orgBuild || appView == AppScreen.assessmentBuild || appView == AppScreen.assessmentSelect)
          FilledButton.tonal(
            onPressed: () async {
              ref.read(appStateProvider.notifier).setAppView(AppScreen.orgSelect);
              NavigationService.navigateTo('/app/orgSelect');
            },
            child: Text("Orgs"),
          ),
      ],
    );
  }
}
