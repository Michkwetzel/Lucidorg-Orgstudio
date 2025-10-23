import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:platform_v2/config/setupLogging.dart';
import 'package:platform_v2/firebase_options.dart';
import 'package:platform_v2/services/firestoreService.dart';
import 'package:platform_v2/services/uiServices/navigationService.dart';
import 'package:platform_v2/services/uiServices/snackBarService.dart';
import 'package:platform_v2/config/setupRouter.dart';
import 'package:platform_v2/config/provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  FirestoreService.initialize(); //Initialize service class.

  setupLogging();

  final router = setupRouter();
  NavigationService.initialize(router);

  print("platform v2.3.0");

  runApp(const ProviderScope(child: App()));

}

class App extends ConsumerWidget {
  const App({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isInitialized = ref.watch(appStateProvider.select((state) => state.isInitialized));
    
    // Show loading screen until initialization completes
    if (!isInitialized) {
      return MaterialApp(
        title: "LucidORG",
        home: Scaffold(
          backgroundColor: Colors.grey.shade100,
          body: const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                CircularProgressIndicator(),
                SizedBox(height: 16),
                Text(
                  'Initializing...',
                  style: TextStyle(fontSize: 16, color: Colors.grey),
                ),
              ],
            ),
          ),
        ),
      );
    }

    // Show main app once initialized (router will handle orgId logic)
    return MaterialApp.router(
      theme: ThemeData(),
      title: "LucidORG",
      scaffoldMessengerKey: SnackBarService.scaffoldKey,
      routerConfig: NavigationService.router,
    );
  }
}
