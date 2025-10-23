import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:platform_v2/config/constants.dart';
import 'package:platform_v2/services/firestoreService.dart';
import 'package:platform_v2/services/uiServices/navigationService.dart';
import 'package:platform_v2/widgets/components/buildingBlocks/buttons/callToActionButton.dart';

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
          CallToActionButton(
            onPressed: () async {
              // Log the access to Firestore (best effort, don't block on failure)
              try {
                FirestoreService.logGuestAccess();
              } catch (e) {
                // Silently fail - don't block demo access
              }

              // Navigate directly to org select screen
              NavigationService.navigateToOrgSelect(ref);
            },
            buttonText: "Demo Sign in",
          ),
        ],
      ),
    );
  }
}
