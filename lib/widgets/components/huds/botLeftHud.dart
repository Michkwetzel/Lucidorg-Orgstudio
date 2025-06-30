import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:platform_v2/config/provider.dart';
import 'package:platform_v2/services/firestoreService.dart';
import 'package:platform_v2/services/uiServices/navigationService.dart';

class BotLeftHud extends ConsumerWidget {
  const BotLeftHud({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      spacing: 4,
      children: [
        if (ref.watch(botLeftHudProvider.select((state) => state.showOrgsButton)))
          FilledButton.tonal(
            onPressed: () {
              ref.read(topleftHudProvider.notifier).setTitle('Orgs');
              ref.read(botLeftHudProvider.notifier).toggleOrgsButton(false);
              NavigationService.navigateTo('/app/orgs');
            },
            child: Text("Back"),
          ),
        FilledButton.tonal(
          onPressed: () async {
            await FirestoreService.dispose();
            ref.read(authProvider.notifier).signOutUser();
            NavigationService.navigateTo('/auth/landingPage');
          },
          child: Text("Exit"),
        ),
      ],
    );
  }
}
