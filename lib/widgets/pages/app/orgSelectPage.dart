import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
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
    final List<Org> orgs = ref.watch(orgsScreenProvider.select((state) => state.orgs));
    final bool isLoading = ref.watch(orgsScreenProvider.select((state) => state.isLoading));
    final String loadingMessage = ref.watch(orgsScreenProvider.select((state) => state.loadingMessage));

    print("org Screen, Build run");

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
                        ref.read(appStateProvider.notifier).setOrg(org.id, org.orgName);
                        ref.read(appStateProvider.notifier).setScreen(Screen.orgStructure);
                        ref.read(topleftHudProvider.notifier).setTitle(org.orgName);
                        ref.read(botLeftHudProvider.notifier).toggleOrgsButton(true);
                        NavigationService.navigateTo("/app/orgStructure");
                      },
                    ),
                  ),
                  AddButton(
                    onPressed: () async {
                      Map<String, String>? neworgInfo = await InputDialogService.showorgForm();
                      if (neworgInfo != null) {
                        ref.read(orgsScreenProvider.notifier).createorg(neworgInfo['orgName']!);
                      }
                    },
                  ),
                ],
              ),
            ),
    );
  }
}
