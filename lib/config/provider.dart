import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:platform_v2/notifiers/general/appStateNotifier.dart';
import 'package:platform_v2/notifiers/general/authNotifier.dart';
import 'package:platform_v2/notifiers/general/blockNotifier.dart';
import 'package:platform_v2/notifiers/general/orgCanvasNotifier.dart';
import 'package:platform_v2/notifiers/general/connectionsManager.dart';
import 'package:platform_v2/notifiers/general/orgsScreenNotifier.dart';
import 'package:platform_v2/notifiers/general/assessmentScreenNotifier.dart';
import 'package:platform_v2/notifiers/huds/botLeftHudNotifier.dart';
import 'package:platform_v2/notifiers/huds/topLeftHudNotifier.dart';
import 'package:platform_v2/notifiers/huds/topRightHudNotifier.dart';

final authProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  return AuthNotifier()..initState();
});

final topleftHudProvider = StateNotifierProvider<TopleftHudNotifier, TopleftHudState>((ref) {
  return TopleftHudNotifier();
});

final botLeftHudProvider = StateNotifierProvider<BotLeftHudNotifier, BotleftHudState>((ref) {
  return BotLeftHudNotifier();
});

final topRightHudProvider = StateNotifierProvider<TopRightHudNotifier, bool>((ref) {
  return TopRightHudNotifier();
});

// final toolBarHudProvider = StateNotifierProvider<ToolBarHudNotifier, ToolbarHudState>((ref) {
//   return ToolBarHudNotifier();
// });

final orgsScreenProvider = StateNotifierProvider.autoDispose<OrgsScreenNotifier, OrgsScreenState>((ref) {
  return OrgsScreenNotifier();
});

final assessmentScreenProvider = StateNotifierProvider.autoDispose<AssessmentScreenNotifier, AssessmentScreenState>((ref) {
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
  final context = ref.watch(appStateProvider.select((state) => state.firestoreContext));

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

// For assessment Send Mode
final selectedBlocksProvider = StateProvider<Set<String>>((ref) => {});
final selectedDepartmentsProvider = StateProvider<Set<String>>((ref) => {});

// For Builder
final selectedBlockProvider = StateProvider<String?>((ref) => null);

// For Assessment Data View - tracks which blocks show detailed view
final detailedViewBlocksProvider = StateProvider<Set<String>>((ref) => {});

final canvasScaleProvider = StateProvider<double>((ref) => 1.0);
