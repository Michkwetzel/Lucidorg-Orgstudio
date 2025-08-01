import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:logging/logging.dart';
import 'package:platform_v2/config/enums.dart';
import 'package:platform_v2/config/provider.dart';

final Logger logger = Logger('navigationService.dart');

class NavigationService {
  // This static variable will hold our router instance
  static late GoRouter router;

  // This method is called once at app startup to set up the router
  static void initialize(GoRouter goRouter) {
    router = goRouter;
  }

  // This method can be called from anywhere to trigger navigation
  static void navigateTo(String route) {
    router.go(route, extra: {'internal': true});
  }

  // Add these to your NavigationService class

  // Login navigation - clear everything
  static void navigateToLogin(WidgetRef ref) {
    final appStateNotifier = ref.read(appStateProvider.notifier);

    // Clear org and assessment data
    appStateNotifier.clearOrg();
    appStateNotifier.clearAssessment();
    appStateNotifier.setAssessmentMode(AssessmentMode.none);
    appStateNotifier.setAppView(AppView.logIn);

    router.go('/login', extra: {'internal': true});
  }

  // Org selection - clear org data, set to org select view
  static void navigateToOrgSelect(WidgetRef ref) {
    final appStateNotifier = ref.read(appStateProvider.notifier);
    appStateNotifier.clearOrg();
    appStateNotifier.setAssessmentMode(null);
    appStateNotifier.setAppView(AppView.orgSelect);

    router.go('/app/orgSelect', extra: {'internal': true});
  }

  // Org build - set org context
  static void navigateToOrgBuild(WidgetRef ref, String? orgId, String? orgName) {
    final appStateNotifier = ref.read(appStateProvider.notifier);

    // Set org data and clear assessment mode
    appStateNotifier.setAssessmentMode(null);
    if (orgId == null || orgName == null) {
      appStateNotifier.setAppView(AppView.orgBuild);
    } else {
      appStateNotifier.setOrgAndNavigate(orgId, orgName, AppView.orgBuild);
    }

    router.go('/app/canvas', extra: {'internal': true});
  }

  // Assessment selection
  static void navigateToAssessmentSelect(WidgetRef ref) {
    final appStateNotifier = ref.read(appStateProvider.notifier);

    // Clear assessment mode and set view
    appStateNotifier.setAssessmentMode(null);
    appStateNotifier.setAppView(AppView.assessmentSelect);

    router.go('/app/assessmentSelect', extra: {'internal': true});
  }

  // Assessment build - set assessment context and build mode
  static void navigateToAssessmentBuild(WidgetRef ref, String assessmentId, String assessmentName) {
    final appStateNotifier = ref.read(appStateProvider.notifier);

    // Set assessment mode to build and update assessment data
    appStateNotifier.setAssessmentMode(AssessmentMode.assessmentBuild);
    appStateNotifier.setAssessmentAndNavigate(assessmentId, assessmentName, AppView.assessmentBuild);

    router.go('/app/canvas', extra: {'internal': true});
  }
}
