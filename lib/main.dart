import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:platform_v2/config/setup_logging.dart';
import 'package:platform_v2/firebase_options.dart';
import 'package:platform_v2/services/firestoreService.dart';
import 'package:platform_v2/services/uiServices/navigationService.dart';
import 'package:platform_v2/services/uiServices/snackBarService.dart';
import 'package:platform_v2/config/setup_router.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  FirestoreService.initialize(); //Initialize service class.

  setupLogging();

  final router = setupRouter();
  NavigationService.initialize(router);

  runApp(const ProviderScope(child: App()));
  
  // Shows FPS overlay in debug mode
  if (kDebugMode) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // This enables the performance overlay
      debugProfileBuildsEnabled = true;
    });
  }
}

class App extends StatelessWidget {
  const App({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      theme: ThemeData(),
      title: "LucidORG",
      scaffoldMessengerKey: SnackBarService.scaffoldKey,
      routerConfig: NavigationService.router,
    );
  }
}
