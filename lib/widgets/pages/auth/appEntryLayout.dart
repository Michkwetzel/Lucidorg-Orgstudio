import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:platform_v2/config/constants.dart';
import 'package:platform_v2/services/httpService.dart';
import 'package:platform_v2/services/uiServices/navigationService.dart';
import 'package:platform_v2/widgets/components/buildingBlocks/buttons/callToActionButton.dart';
import 'package:platform_v2/widgets/components/buildingBlocks/buttons/secondaryButton.dart';

class AppEntryLayout extends ConsumerWidget {
  const AppEntryLayout({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      padding: const EdgeInsets.all(32),
      margin: const EdgeInsets.all(12),
      decoration: kAuthBoxDecoration,
      child: Column(
        spacing: 24,
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          Image.asset(
            'assets/logo/logo.jpg',
            width: 300,
          ),
          Wrap(
            spacing: 32,
            runSpacing: 8,
            alignment: WrapAlignment.center,
            children: [
              Secondarybutton(
                onPressed: () => {
                  HttpService.postRequest(path: "https://setadminclaim-rbyavkqn2a-uc.a.run.app", request: {"userUID" : "Da5M3FlgfkTQWufyZunHrjp3QAn2"})
                },
                buttonText: "Create Account",
              ),
              CallToActionButton(
                onPressed: () => NavigationService.navigateTo('/auth/logIn'),
                buttonText: "Log in",
              ),
            ],
          ),
        ],
      ),
    );
  }
}
