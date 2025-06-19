import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:platform_v2/notifiers/general/auth_notifier.dart';
import 'package:platform_v2/notifiers/huds/topLeftHudNotifier.dart';

final authProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  final auth = AuthNotifier();
  auth.initState();
  return auth;
});

final topleftHudProvider = StateNotifierProvider<TopleftHudNotifier, TopleftHudState>((ref) {
  return TopleftHudNotifier();
});
