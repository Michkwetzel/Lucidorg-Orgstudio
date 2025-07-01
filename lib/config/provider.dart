import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:platform_v2/dataClasses/blockId.dart';
import 'package:platform_v2/notifiers/general/appStateNotifier.dart';
import 'package:platform_v2/notifiers/general/authNotifier.dart';
import 'package:platform_v2/notifiers/general/blockNotifier.dart';
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
  return CanvasNotifier(orgId: orgId);
});

final blockNotifierProvider = ChangeNotifierProvider.family.autoDispose<BlockNotifier, BlockID>((ref, params) {
  final String? orgId = ref.read(appStateProvider).orgId;

  return BlockNotifier(
    blockId: params.blockId,
    orgId: orgId ?? 'null',
    position: params.initialPosition ?? Offset.zero,
    onPositionChanged: (blockId, position) {
      ref.read(connectionManagerProvider.notifier).updateBlockPosition(blockId, position);
    },
  );
});

final connectionManagerProvider = StateNotifierProvider<ConnectionManager, ConnectionsState>((ref) {
  return ConnectionManager();
});

final canvasScaleProvider = StateProvider<double>((ref) => 1.0);
