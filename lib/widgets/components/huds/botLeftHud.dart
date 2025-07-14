import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:platform_v2/config/provider.dart';
import 'package:platform_v2/config/enums.dart';
import 'package:platform_v2/services/uiServices/navigationService.dart';

class BotLeftHud extends ConsumerWidget {
  const BotLeftHud({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final appView = ref.watch(appStateProvider.select((state) => state.appView));
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      spacing: 4,
      children: [
        if (appView == AppView.orgBuild || appView == AppView.assessment)
          FilledButton.tonal(
            onPressed: () {
              final currentAppView = ref.read(appStateProvider).appView;
              
              if (currentAppView == AppView.orgBuild) {
                // From org builder, go back to org select
                ref.read(appStateProvider.notifier).setAppView(AppView.selectOrg);
                NavigationService.navigateTo('/app/orgs');
              } else if (currentAppView == AppView.assessment) {
                // From assessment, go back to assessment select
                ref.read(appStateProvider.notifier).setAppView(AppView.selectAssessment);
                NavigationService.navigateTo('/app/assessmentSelect');
              }
            },
            child: Text("Back"),
          ),
        FilledButton.tonal(
          onPressed: () async {
            ref.read(authProvider.notifier).signOutUser();
            NavigationService.navigateTo('/auth/landingPage');
          },
          child: Text("Exit"),
        ),
      ],
    );
  }
}
