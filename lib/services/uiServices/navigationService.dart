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

  // Login navigation - clear everything
  static void navigateToLogin(WidgetRef ref) {
    final appStateNotifier = ref.read(appStateProvider.notifier);

    appStateNotifier.batchUpdate(
      (state) => state.copyWith(
        clearOrgId: true,
        clearOrgName: true,
        clearAssessmentId: true,
        clearAssessmentName: true,
        clearAssessmentMode: true,
        appView: AppView.logIn,
      ),
    );

    router.go('/login', extra: {'internal': true});
  }

  // Org selection - clear org data, set to org select appView
  static void navigateToOrgSelect(WidgetRef ref) {
    final appStateNotifier = ref.read(appStateProvider.notifier);

    appStateNotifier.batchUpdate(
      (state) => state.copyWith(
        clearOrgId: true,
        clearOrgName: true,
        clearAssessmentId: true,
        clearAssessmentName: true,
        clearAssessmentMode: true,
        appView: AppView.orgSelect,
      ),
    );

    router.go('/app/orgSelect', extra: {'internal': true});
  }

  // Org build - set org context
  static void navigateToOrgBuild(WidgetRef ref, String? orgId, String? orgName) {
    final appStateNotifier = ref.read(appStateProvider.notifier);

    if (orgId == null || orgName == null) {
      appStateNotifier.batchUpdate(
        (state) => state.copyWith(
          clearAssessmentId: true,
          clearAssessmentName: true,
          clearAssessmentMode: true,
          appView: AppView.orgBuild,
        ),
      );
    } else {
      appStateNotifier.batchUpdate(
        (state) => state.copyWith(
          orgId: orgId,
          orgName: orgName,
          clearAssessmentMode: true,
          appView: AppView.orgBuild,
        ),
      );
    }

    router.go('/app/canvas', extra: {'internal': true});
  }

  // Assessment selection
  static void navigateToAssessmentSelect(WidgetRef ref, {String? orgId, String? orgName}) {
    final appStateNotifier = ref.read(appStateProvider.notifier);

    appStateNotifier.batchUpdate(
      (state) => state.copyWith(
        orgId: orgId,
        clearOrgId: orgId == null,
        orgName: orgName,
        clearOrgName: orgName == null,
        clearAssessmentMode: true,
        appView: AppView.assessmentSelect,
      ),
    );

    router.go('/app/assessmentSelect', extra: {'internal': true});
  }

  // Assessment build - set assessment context and build mode
  static void navigateToAssessmentBuild(WidgetRef ref, String assessmentId, String assessmentName) {
    final appStateNotifier = ref.read(appStateProvider.notifier);

    appStateNotifier.batchUpdate(
      (state) => state.copyWith(
        assessmentId: assessmentId,
        assessmentName: assessmentName,
        assessmentMode: AssessmentMode.assessmentBuild,
        appView: AppView.assessmentBuild,
      ),
    );

    router.go('/app/canvas', extra: {'internal': true});
  }
}
