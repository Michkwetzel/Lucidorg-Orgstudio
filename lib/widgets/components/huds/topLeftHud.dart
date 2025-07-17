import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:platform_v2/config/constants.dart';
import 'package:platform_v2/config/enums.dart';
import 'package:platform_v2/config/provider.dart';
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
        if (appstate.orgId != null && (appstate.appView == AppView.orgBuild || appstate.appView == AppView.assessmentCreate || appstate.appView == AppView.assessmentView)) _buildDropdown(context, ref),
        if (appstate.assessmentName != null) Text(" - ${appstate.assessmentName}"),
      ],
    );
  }

  Widget _buildDropdown(BuildContext context, WidgetRef ref) {
    return PopupMenuButton<AppView>(
      icon: Icon(Icons.arrow_drop_down, size: 16),
      padding: EdgeInsets.zero,
      onSelected: (value) {
        switch (value) {
          case AppView.orgBuild:
            // Set Firestore path for org builder
            ref.read(appStateProvider.notifier).setAppView(AppView.orgBuild);
            NavigationService.navigateTo("/app/orgStructure");
            break;
          case AppView.assessmentCreate:
            ref.read(appStateProvider.notifier).setAppView(AppView.assessmentCreate);
            NavigationService.navigateTo("/app/assessmentSelect");
            break;
          default:
            break;
        }
      },
      itemBuilder: (context) => [
        PopupMenuItem(value: AppView.orgBuild, child: Text('Org Builder')),
        PopupMenuItem(value: AppView.assessmentCreate, child: Text('Assessments')),
      ],
    );
  }
}
