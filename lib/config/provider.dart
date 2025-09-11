import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:platform_v2/notifiers/general/appStateNotifier.dart';
import 'package:platform_v2/notifiers/general/authNotifier.dart';
import 'package:platform_v2/notifiers/general/blockNotifier.dart';
import 'package:platform_v2/notifiers/general/orgCanvasNotifier.dart';
import 'package:platform_v2/notifiers/general/connectionsManager.dart';
import 'package:platform_v2/notifiers/general/orgsScreenNotifier.dart';
import 'package:platform_v2/notifiers/general/assessmentScreenNotifier.dart';
import 'package:platform_v2/notifiers/general/analysisBlockNotifer.dart';
import 'package:platform_v2/notifiers/general/groupsNotifier.dart';
import 'package:platform_v2/config/enums.dart';
import 'package:platform_v2/dataClasses/displayOption.dart';

final authProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  return AuthNotifier()..initState();
});

// For Org select State
final orgsSelectProvider = StateNotifierProvider.autoDispose<OrgsScreenNotifier, OrgsScreenState>((ref) {
  return OrgsScreenNotifier();
});

// For Assessment select State
final assessmentsSelectProvider = StateNotifierProvider.autoDispose<AssessmentScreenNotifier, AssessmentScreenState>((ref) {
  final orgId = ref.read(appStateProvider.notifier).orgId;
  return AssessmentScreenNotifier(orgId: orgId!);
});

final appStateProvider = StateNotifierProvider<AppStateNotifier, AppState>((ref) {
  return AppStateNotifier();
});

final canvasProvider = StateNotifierProvider<OrgCanvasNotifier, Set<String>>((ref) {
  final appStateNotifier = ref.read(appStateProvider.notifier);
  final connectionManager = ref.read(connectionManagerProvider.notifier);

  // Rebuild when below changes
  ref.watch(appStateProvider.select((state) => state.orgId));
  ref.watch(appStateProvider.select((state) => state.assessmentId));

  final notifier = OrgCanvasNotifier(appState: appStateNotifier, connectionManager: connectionManager);

  // Watch for appView changes
  ref.listen(appStateProvider.select((state) => state.assessmentMode), (previous, next) {
    if (next == AssessmentMode.assessmentAnalyze) {
      notifier.subscribeToAnalysisBlocks(); // Call method on the notifier instance
    } else if (previous == AssessmentMode.assessmentAnalyze) {
      notifier.subscribeToBlocks(); // Call method on the notifier instance
    }
  });

  return notifier;
});

final blockNotifierProvider = ChangeNotifierProvider.family<BlockNotifier, String>((ref, blockID) {
  final appStateNotifier = ref.read(appStateProvider.notifier);
  ref.watch(appStateProvider.select((state) => state.appView));

  final notifier = BlockNotifier(
    blockID: blockID,
    appState: appStateNotifier,
  );

  return notifier;
});

// Analysis Block Notifier Provider - no autoDispose for caching
final analysisBlockNotifierProvider = ChangeNotifierProvider.family<AnalysisBlockNotifer, String>((ref, blockID) {
  final appStateNotifier = ref.read(appStateProvider.notifier);
  final groupsNotifier = ref.read(groupsProvider);
  return AnalysisBlockNotifer(blockID: blockID, appState: appStateNotifier, groupsNotifier: groupsNotifier);
});

// Groups Provider - no autoDispose for caching
final groupsProvider = ChangeNotifierProvider<GroupsNotifier>((ref) {
  final appStateNotifier = ref.read(appStateProvider.notifier);

  // Rebuild when orgId or assessmentId changes
  ref.watch(appStateProvider.select((state) => state.orgId));
  ref.watch(appStateProvider.select((state) => state.assessmentId));

  return GroupsNotifier(appState: appStateNotifier);
});

final connectionManagerProvider = StateNotifierProvider<ConnectionManager, ConnectionsState>((ref) {
  final appStateNotifier = ref.read(appStateProvider.notifier);

  final notifier = ConnectionManager(appState: appStateNotifier);
  ref.listen(appStateProvider, (previous, next) {
    if (next.assessmentId != previous?.assessmentId || next.orgId != previous?.orgId) {
      notifier.subscribeToConnections();
    }
  });
  return notifier;
});

// For assessment Send Mode - Tracks which blocks are selected to send assessments too
final selectedBlocksProvider = StateProvider<Set<String>>((ref) => {});
final selectedDepartmentsProvider = StateProvider<Set<String>>((ref) => {});
final selectedHierarchiesProvider = StateProvider<Set<Hierarchy>>((ref) => {});

// For Assessment/Org Builder. Tracks which block is selected
final selectedBlockProvider = StateProvider<String?>((ref) => null);

// For Assessment Data View - tracks which blocks show detailed view
final detailedViewBlocksProvider = StateProvider<Set<String>>((ref) => {});

// For Assessment Data View - tracks selected display option (benchmark or question)
final selectedDisplayOptionProvider = StateProvider<DisplayOption>((ref) => DisplayOption.benchmark(Benchmark.orgIndex));

// For orgCanvas scale.
final canvasScaleProvider = StateProvider<double>((ref) => 1.0);
