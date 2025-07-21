import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:platform_v2/widgets/pages/app/appScaffold.dart';
import 'package:platform_v2/widgets/pages/app/orgSelectPage.dart';
import 'package:platform_v2/widgets/pages/app/orgCanvas.dart';
import 'package:platform_v2/widgets/pages/app/assessmentSelectPage.dart';
import 'package:platform_v2/widgets/pages/auth/appEntryLayout.dart';
import 'package:platform_v2/widgets/pages/auth/logInScreen.dart';

GoRouter setupRouter() {
  return GoRouter(
    initialLocation: '/auth/landingPage',
    routerNeglect: true,
    errorBuilder: (context, state) => const Scaffold(
      body: Center(child: Text('Route not found')),
    ),
    routes: [
      ShellRoute(
        builder: (context, state, child) => Scaffold(
          backgroundColor: Colors.grey,
          body: Center(child: child),
        ),
        routes: [
          GoRoute(
            path: '/auth/landingPage',
            pageBuilder: (context, state) => NoTransitionPage(child: Center(child: const AppEntryLayout())),
          ),
          GoRoute(
            path: '/auth/logIn',
            pageBuilder: (context, state) => NoTransitionPage(child: Center(child: const LogInScreen())),
          ),
        ],
      ),
      ShellRoute(
        builder: (context, state, child) => AppScaffold(child: child),
        routes: [
          GoRoute(
            path: '/app/orgSelect',
            pageBuilder: (context, state) => NoTransitionPage(child: OrgSelectPage()),
          ),
          GoRoute(
            // path: '/app/orgStructure',
            path: '/app/canvas',
            pageBuilder: (context, state) => NoTransitionPage(child: OrgCanvas()),
          ),
          GoRoute(
            path: '/app/assessmentSelect',
            pageBuilder: (context, state) => NoTransitionPage(child: AssessmentSelectPage()),
          ),
        ],
      ),
    ],
  );
}
