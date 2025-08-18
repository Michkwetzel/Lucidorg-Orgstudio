import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:platform_v2/config/provider.dart';
import 'package:platform_v2/notifiers/general/analysisBlockNotifer.dart';

class AnalysisBlockContext {
  final WidgetRef ref;
  final String blockId;
  final BuildContext buildContext;
  final double hitboxOffset;

  AnalysisBlockContext({
    required this.ref,
    required this.blockId,
    required this.buildContext,
    required this.hitboxOffset,
  });

  // Convenience getter for the analysis block notifier
  AnalysisBlockNotifer get analysisBlockNotifier => ref.read(analysisBlockNotifierProvider(blockId));
  
  // Convenience getters for common properties
  double get hitboxWidth => 150 + (hitboxOffset * 2);
  double get hitboxHeight => 150 + (hitboxOffset * 2);
}