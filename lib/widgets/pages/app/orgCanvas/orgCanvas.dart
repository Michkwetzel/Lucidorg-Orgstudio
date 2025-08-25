import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:logging/logging.dart';
import 'package:platform_v2/config/enums.dart';
import 'package:platform_v2/config/provider.dart';
import 'package:platform_v2/services/customPainters/connectionPainter.dart';
import 'package:platform_v2/services/firestoreIdGenerator.dart';
import 'package:platform_v2/widgets/components/general/block.dart';
import 'package:platform_v2/widgets/components/general/analysisBlock.dart';
import 'package:platform_v2/widgets/pages/app/orgCanvas/connectionsLayer.dart';

class OrgCanvas extends ConsumerStatefulWidget {
  const OrgCanvas({super.key});

  @override
  ConsumerState<OrgCanvas> createState() => _OrgCanvasState();
}

class _OrgCanvasState extends ConsumerState<OrgCanvas> {
  Logger logger = Logger('Canvas');

  final TransformationController _transformationController = TransformationController();
  late Offset _lastTapPosition;

  @override
  void initState() {
    super.initState();
    // Listen to transformation changes and update the scale provider
    _transformationController.addListener(() {
      final scale = _transformationController.value.getMaxScaleOnAxis();
      ref.read(canvasScaleProvider.notifier).state = scale;
    });
  }

  @override
  void dispose() {
    _transformationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final canvasState = ref.watch(canvasProvider);
    final canvasNotifier = ref.read(canvasProvider.notifier);
    final assessmentMode = ref.watch(appStateProvider).assessmentMode;

    if (canvasNotifier.isInitialLoadComplete == false) {
      return const Center(child: CircularProgressIndicator());
    }

    // logger.info("Building Canvas");
    return SizedBox.expand(
      child: InteractiveViewer(
        transformationController: _transformationController,
        constrained: false,
        minScale: 0.1,
        maxScale: 10,
        boundaryMargin: EdgeInsets.all(20),
        child: Builder(
          builder: (context) {
            // Note Gesture system is a little weird. Flutter gestures compete in Arena with child winning a tap.
            // However, onTapDown or onDoubleTapDown is registered by all Gesture Detectors no matter widget tree.
            // Thus. onDoubleTapDown save pointer position. Then if this doulbe tap is on canvas, Canvas DoubleTap() will win.
            //If it is on Block then Block DoubleTap() will win
            return GestureDetector(
              onDoubleTapDown: (details) {
                // Save pointer position
                final RenderBox renderBox = context.findRenderObject() as RenderBox;
                _lastTapPosition = renderBox.globalToLocal(details.globalPosition);
              },
              onDoubleTap: () {
                // Create new block at tap position
                if (ref.read(appStateProvider.notifier).assessmentMode != AssessmentMode.assessmentSend) {
                  // But only if not select blocks for assessment mode.
                  final blockID = FirestoreIdGenerator.generate();
                  ref.read(canvasProvider.notifier).addBlock(blockID, _lastTapPosition);
                }
              },
              child: Container(
                width: 30000,
                height: 7000,
                color: Colors.grey,
                child: Stack(
                  children: [
                    // Only show connections layer for non-analysis modes
                    if (assessmentMode != AssessmentMode.assessmentAnalyze)
                      ConnectionLayer(),

                    // Conditionally render analysis blocks or regular blocks
                    if (assessmentMode == AssessmentMode.assessmentAnalyze)
                      ...canvasState.map(
                        (blockID) => AnalysisBlock(
                          key: ValueKey('analysis_$blockID'), // Unique key for analysis blocks
                          blockId: blockID,
                        ),
                      )
                    else
                      ...canvasState.map(
                        (blockID) => Block(
                          key: ValueKey('block_$blockID'), // Unique key for regular blocks
                          blockId: blockID,
                        ),
                      ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
