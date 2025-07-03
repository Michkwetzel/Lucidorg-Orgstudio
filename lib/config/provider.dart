import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:platform_v2/notifiers/general/appStateNotifier.dart';
import 'package:platform_v2/notifiers/general/authNotifier.dart';
import 'package:platform_v2/notifiers/general/blockNotifier.dart';
import 'package:platform_v2/notifiers/general/blockRegistry.dart';
import 'package:platform_v2/notifiers/general/canvasNotifier.dart';
import 'package:platform_v2/notifiers/general/connectionsManager.dart';
import 'package:platform_v2/notifiers/general/orgsScreenNotifier.dart';
import 'package:platform_v2/notifiers/huds/botLeftHudNotifier.dart';
import 'package:platform_v2/notifiers/huds/topLeftHudNotifier.dart';

final authProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  return AuthNotifier()..initState();
});

final topleftHudProvider = StateNotifierProvider<TopleftHudNotifier, TopleftHudState>((ref) {
  return TopleftHudNotifier();
});

final botLeftHudProvider = StateNotifierProvider<BotLeftHudNotifier, BotleftHudState>((ref) {
  return BotLeftHudNotifier();
});

// final toolBarHudProvider = StateNotifierProvider<ToolBarHudNotifier, ToolbarHudState>((ref) {
//   return ToolBarHudNotifier();
// });

final orgsScreenProvider = StateNotifierProvider.autoDispose<OrgsScreenNotifier, OrgsScreenState>((ref) {
  return OrgsScreenNotifier();
});

final appStateProvider = StateNotifierProvider<AppStateNotifier, AppState>((ref) {
  return AppStateNotifier();
});

final canvasProvider = StateNotifierProvider.autoDispose<CanvasNotifier, Set<String>>((ref) {
  final String? orgId = ref.watch(appStateProvider).orgId;
  final ConnectionManager connectionManager = ref.read(connectionManagerProvider.notifier);

  return CanvasNotifier(orgId: orgId, connectionManager: connectionManager);
});

final blockNotifierProvider = ChangeNotifierProvider.family.autoDispose<BlockNotifier, String>((ref, blockID) {
  final String? orgId = ref.read(appStateProvider).orgId;

  final notifier = BlockNotifier(
    blockID: blockID,
    orgId: orgId ?? 'null',
  );

  return notifier;
});

//Get block Ids from canvas. Canvas is source of truth for blockIds
final blockPositionsProvider = Provider<Map<String, Offset>>((ref) {
  final activeBlocks = ref.watch(canvasProvider);
  final canvasNotifier = ref.read(canvasProvider.notifier);
  
  if (!canvasNotifier.isInitialLoadComplete) {
    return {};
  }
  
  // Get live positions from individual block notifiers, with fallback to initial positions
  return Map.fromEntries(
    activeBlocks.map((blockID) {
      final blockNotifier = ref.watch(blockNotifierProvider(blockID));
      if (blockNotifier.positionLoaded) {
        // Use live position from block notifier
        return MapEntry(blockID, blockNotifier.position);
      } else {
        // Fallback to initial position until block notifier loads
        return MapEntry(blockID, canvasNotifier.initialPositions[blockID] ?? Offset.zero);
      }
    }),
  );
});

final connectionManagerProvider = StateNotifierProvider<ConnectionManager, ConnectionsState>((ref) {
  final String? orgId = ref.watch(appStateProvider).orgId;

  return ConnectionManager(orgId: orgId);
});

final canvasScaleProvider = StateProvider<double>((ref) => 1.0);
