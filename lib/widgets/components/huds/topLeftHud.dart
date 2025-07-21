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
    final appDisplayState = ref.watch(appStateProvider).displayContext;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Logo and org info section
        Row(
          children: [
            SizedBox(
              width: 35,
              height: 35,
              child: Image.asset('assets/logo/logoIcon.png'),
            ),
            SizedBox(width: 12),
            Text(
              appDisplayState.orgName ?? "",
              style: kTextHeading2R,
            ),
            SizedBox(width: 12),
            // Mode and assessment info
            _buildModeText(appDisplayState),
            if (appDisplayState.appView == AppView.assessmentView || appDisplayState.appView == AppView.assessmentCreate && appDisplayState.assessmentName != null) ...[
              Text(" • ", style: kTextHeading3L.copyWith(color: Colors.grey[600])),
              Text(
                appDisplayState.assessmentName!,
                style: kTextHeading3L.copyWith(
                  color: Colors.blue[700],
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ],
        ),

        // Dropdown section
        if (_shouldShowDropdown(appDisplayState)) ...[
          SizedBox(width: 16),
          _buildDropdown(context, ref),
        ],
      ],
    );
  }

  Widget _buildModeText(appstate) {
    String modeText = "";
    Color? modeColor;

    switch (appstate.appView) {
      case AppView.orgSelect:
        modeText = "Select Org";
        modeColor = Colors.green[700];
        break;
      case AppView.orgBuild:
        modeText = "Org Builder";
        modeColor = Colors.green[700];
        break;
      case AppView.assessmentSelect:
        modeText = "Select Assessment";
        modeColor = Colors.blue[700];
        break;
      case AppView.assessmentView:
        modeText = "Assessment Builder";
        modeColor = Colors.blue[700];
        break;
      default:
        return SizedBox.shrink();
    }

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: modeColor?.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: modeColor?.withValues(alpha: 0.3) ?? Colors.transparent),
      ),
      child: Text(
        modeText,
        style: kTextHeading3L.copyWith(
          color: modeColor,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  bool _shouldShowDropdown(appstate) {
    return appstate.appView == AppView.orgBuild || appstate.appView == AppView.assessmentCreate || appstate.appView == AppView.assessmentView || appstate.appView == AppView.assessmentSelect;
  }

  // Updated TopLeftHud dropdown styling
  Widget _buildDropdown(BuildContext context, WidgetRef ref) {
    return Container(
      decoration: BoxDecoration(
        // Dark theme for HUD distinction
        borderRadius: BorderRadius.circular(6),
      ),
      child: PopupMenuButton<AppView>(
        icon: Icon(
          Icons.keyboard_arrow_down,
          size: 18,
          color: Colors.black,
        ),
        padding: EdgeInsets.zero,
        tooltip: 'Switch mode',
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        onSelected: (value) {
          switch (value) {
            case AppView.orgBuild:
              ref.read(appStateProvider.notifier).toOrgBuilder();
              NavigationService.navigateTo("/app/canvas");
              break;
            case AppView.assessmentSelect:
              ref.read(appStateProvider.notifier).toAssessmentSelect();
              NavigationService.navigateTo("/app/assessmentSelect");
              break;
            default:
              break;
          }
        },
        itemBuilder: (context) => [
          PopupMenuItem(
            value: AppView.orgBuild,
            child: Row(
              children: [
                Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: const Color.fromRGBO(56, 142, 60, 1),
                    shape: BoxShape.circle,
                  ),
                ),
                SizedBox(width: 8),
                Text('Org Builder'),
              ],
            ),
          ),
          PopupMenuItem(
            value: AppView.assessmentSelect,
            child: Row(
              children: [
                Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: Colors.blue[700],
                    shape: BoxShape.circle,
                  ),
                ),
                SizedBox(width: 8),
                Text('Assessment'),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
