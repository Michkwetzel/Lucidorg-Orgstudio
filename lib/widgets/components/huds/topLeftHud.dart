import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:platform_v2/config/constants.dart';
import 'package:platform_v2/config/enums.dart';
import 'package:platform_v2/config/provider.dart';
import 'package:platform_v2/services/firestoreService.dart';
import 'package:platform_v2/services/uiServices/navigationService.dart';

class TopLeftHud extends ConsumerWidget {
  const TopLeftHud({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final appstate = ref.watch(appStateProvider);

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          width: 35,
          height: 35,
          child: Image.asset('assets/logo/logoIcon.png'),
        ),
        SizedBox(width: 12),
        Text(appstate.orgName ?? "", style: kTextHeading2R),
        if (appstate.orgId != null && 
            (appstate.appView == AppView.orgBuild || 
             appstate.appView == AppView.selectAssessment || 
             appstate.appView == AppView.assessment)) 
          _buildDropdown(context, ref),
        if (appstate.assessmentName != null) Text(" - ${appstate.assessmentName}"),
      ],
    );
  }

  Widget _buildDropdown(BuildContext context, WidgetRef ref) {
    return PopupMenuButton<AppView>(
      icon: Icon(Icons.arrow_drop_down, size: 16),
      padding: EdgeInsets.zero,
      onSelected: (value) {
        final orgId = ref.read(appStateProvider).orgId;
        if (orgId == null) {
          print("Error: orgId is null when switching to org builder");
          return;
        }
        
        switch (value) {
          case AppView.orgBuild:
            // Set Firestore path for org builder
            FirestoreService.setFirestorePathOrgBuilder(orgId);
            ref.read(appStateProvider.notifier).setAppView(AppView.orgBuild);
            NavigationService.navigateTo("/app/orgStructure");
            break;
          case AppView.selectAssessment:
            ref.read(appStateProvider.notifier).setAppView(AppView.selectAssessment);
            NavigationService.navigateTo("/app/assessmentSelect");
            break;
          default:
            break;
        }
      },
      itemBuilder: (context) => [
        PopupMenuItem(value: AppView.orgBuild, child: Text('Org Builder')),
        PopupMenuItem(value: AppView.selectAssessment, child: Text('Assessments')),
      ],
    );
  }
}
