import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:platform_v2/notifiers/general/appStateNotifier.dart';
import 'package:platform_v2/notifiers/general/authNotifier.dart';
import 'package:platform_v2/notifiers/general/blockNotifier.dart';
import 'package:platform_v2/notifiers/general/orgCanvasNotifier.dart';
import 'package:platform_v2/notifiers/general/connectionsManager.dart';
import 'package:platform_v2/notifiers/general/orgsScreenNotifier.dart';
import 'package:platform_v2/notifiers/general/assessmentScreenNotifier.dart';
import 'package:platform_v2/config/enums.dart';

final authProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  return AuthNotifier()..initState();
});

// For Org select State
final orgsSelectProvider = StateNotifierProvider.autoDispose<OrgsScreenNotifier, OrgsScreenState>((ref) {
  return OrgsScreenNotifier();
});

// For Assessment select State
final assessmentsSelectProvider = StateNotifierProvider.autoDispose<AssessmentScreenNotifier, AssessmentScreenState>((ref) {
  final String orgId = ref.read(appStateProvider.select((state) => state.firestoreContext.orgId!));
  return AssessmentScreenNotifier(orgId: orgId);
});

final appStateProvider = StateNotifierProvider<AppStateNotifier, AppState>((ref) {
  return AppStateNotifier();
});

final canvasProvider = StateNotifierProvider.autoDispose<OrgCanvasNotifier, Set<String>>((ref) {
  final context = ref.watch(appStateProvider.select((state) => state.firestoreContext));

  final ConnectionManager connectionManager = ref.read(connectionManagerProvider.notifier);

  return OrgCanvasNotifier(context: context, connectionManager: connectionManager);
});

final blockNotifierProvider = ChangeNotifierProvider.family.autoDispose<BlockNotifier, String>((ref, blockID) {
  final context = ref.read(appStateProvider.select((state) => state.firestoreContext));

  final notifier = BlockNotifier(
    blockID: blockID,
    context: context,
  );

  return notifier;
});

final connectionManagerProvider = StateNotifierProvider.autoDispose<ConnectionManager, ConnectionsState>((ref) {
  final context = ref.watch(appStateProvider.select((state) => state.firestoreContext));

  return ConnectionManager(context: context);
});

// For assessment Send Mode - Tracks which blocks are selected to send assessments too
final selectedBlocksProvider = StateProvider<Set<String>>((ref) => {});
final selectedDepartmentsProvider = StateProvider<Set<String>>((ref) => {});

// For Assessment/Org Builder. Tracks which block is selected
final selectedBlockProvider = StateProvider<String?>((ref) => null);

// For Assessment Data View - tracks which blocks show detailed view
final detailedViewBlocksProvider = StateProvider<Set<String>>((ref) => {});

// For Assessment Data View - tracks selected benchmark for display
final selectedBenchmarkProvider = StateProvider<Benchmark>((ref) => Benchmark.orgIndex);

// For orgCanvas scale.
final canvasScaleProvider = StateProvider<double>((ref) => 1.0);
