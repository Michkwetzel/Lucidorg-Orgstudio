import 'package:go_router/go_router.dart';

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
}
