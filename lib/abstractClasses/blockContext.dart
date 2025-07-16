import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:platform_v2/config/provider.dart';
import 'package:platform_v2/notifiers/general/blockNotifier.dart';
import 'package:platform_v2/notifiers/general/connectionsManager.dart';
import 'package:platform_v2/notifiers/general/orgCanvasNotifier.dart';

//The context that my BlockStrategy classess need.
class BlockContext {
  final WidgetRef ref;
  final String blockId;
  final BuildContext buildContext;
  final double dotOverhang;

  BlockContext({
    required this.ref,
    required this.blockId,
    required this.buildContext,
    required this.dotOverhang,
  });

  // Access notifiers via getters - much cleaner!
  BlockNotifier get blockNotifier => ref.read(blockNotifierProvider(blockId).notifier);
  OrgCanvasNotifier get orgCanvasNotifier => ref.read(canvasProvider.notifier);
  ConnectionManager get connectionManager => ref.read(connectionManagerProvider.notifier);
}
