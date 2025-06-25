import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:platform_v2/dataClasses/blockParam.dart';
import 'package:platform_v2/notifiers/general/appStateNotifier.dart';
import 'package:platform_v2/notifiers/general/authNotifier.dart';
import 'package:platform_v2/notifiers/general/blockNotifier.dart';
import 'package:platform_v2/notifiers/general/canvasNotifier.dart';
import 'package:platform_v2/notifiers/general/orgsScreenNotifier.dart';
import 'package:platform_v2/notifiers/huds/botLeftHudNotifier.dart';
import 'package:platform_v2/notifiers/huds/toolBarHudNotifier.dart';
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

final toolBarHudProvider = StateNotifierProvider<ToolBarHudNotifier, ToolbarHudState>((ref) {
  return ToolBarHudNotifier();
});

final orgsScreenProvider = StateNotifierProvider.autoDispose<OrgsScreenNotifier, OrgsScreenState>((ref) {
  return OrgsScreenNotifier();
});

final appStateProvider = StateNotifierProvider<AppStateNotifier, AppState>((ref) {
  return AppStateNotifier();
});

final canvasProvider = StateNotifierProvider.autoDispose<CanvasNotifier, Map<String, BlockParams>>((ref) {
  ref.keepAlive();
  final AppStateNotifier appStateNotifier = ref.read(appStateProvider.notifier);

  return CanvasNotifier(appStateNotifier: appStateNotifier);
});

final blockListProvider = StateProvider<Map<String, BlockParams>>((ref) {
  return ref.watch(canvasProvider);
});

final blockNotifierProvider = ChangeNotifierProvider.family.autoDispose<BlockNotifier, String>((ref, blockId) {
  return BlockNotifier(
    id: blockId,
    position: Offset.zero,
  );
});

final canvasScaleProvider = StateProvider<double>((ref) => 1.0);
