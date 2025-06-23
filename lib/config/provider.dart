import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:platform_v2/notifiers/general/appStateNotifier.dart';
import 'package:platform_v2/notifiers/general/authNotifier.dart';
import 'package:platform_v2/notifiers/general/canvasNotifier.dart';
import 'package:platform_v2/notifiers/general/companiesScreenNotifier.dart';
import 'package:platform_v2/notifiers/huds/botLeftHudNotifier.dart';
import 'package:platform_v2/notifiers/huds/toolBarHudNotifier.dart';
import 'package:platform_v2/notifiers/huds/topLeftHudNotifier.dart';
import 'package:platform_v2/widgets/components/general/orgBlock.dart';

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

final canvasProvider = StateNotifierProvider<CanvasNotifier, List<OrgBlock>>((ref) {
  return CanvasNotifier();
});
