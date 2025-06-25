import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:platform_v2/notifiers/general/appStateNotifier.dart';
import 'package:platform_v2/notifiers/general/authNotifier.dart';
import 'package:platform_v2/notifiers/general/blockNotifier.dart';
import 'package:platform_v2/notifiers/general/canvasNotifier.dart';
import 'package:platform_v2/notifiers/general/companiesScreenNotifier.dart';
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

final companiesScreenProvider = StateNotifierProvider.autoDispose<CompaniesScreenNotifier, CompaniesScreenState>((ref) {
  return CompaniesScreenNotifier();
});

final appStateProvider = StateNotifierProvider<AppStateNotifier, AppState>((ref) {
  return AppStateNotifier();
});

final canvasProvider = StateNotifierProvider<CanvasNotifier, CanvasState>((ref) {
  return CanvasNotifier();
});

// Separate providers for better performance
final blockListProvider = StateProvider<Set<String>>((ref) {
  return ref.watch(canvasProvider).blockIds;
});

final connectionListProvider = StateProvider<List<Connection>>((ref) {
  return ref.watch(canvasProvider).connections;
});

final blockNotifierProvider = ChangeNotifierProvider.family.autoDispose<BlockNotifier, String>((ref, blockId) {
  return BlockNotifier(
    id: blockId,
    position: Offset.zero,
  );
});
