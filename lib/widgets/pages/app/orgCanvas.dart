import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:platform_v2/config/provider.dart';
import 'package:platform_v2/services/customPainters/connectionPainter.dart';
import 'package:platform_v2/services/firestoreIdGenerator.dart';
import 'package:platform_v2/widgets/components/general/block.dart';

class OrgCanvas extends ConsumerStatefulWidget {
  const OrgCanvas({super.key});

  @override
  ConsumerState<OrgCanvas> createState() => _OrgCanvasState();
}

class _OrgCanvasState extends ConsumerState<OrgCanvas> {
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

    if (canvasNotifier.isInitialLoadComplete == false) {
      print("Busy Loading Initial Canvas");
      return const Center(child: CircularProgressIndicator());
    }

    print("Build orgCanvas");
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
                final blockID = FirestoreIdGenerator.generate();
                ref.read(canvasProvider.notifier).addBlock(blockID, _lastTapPosition);
              },
              child: Container(
                width: 7000,
                height: 7000,
                color: Colors.transparent,
                child: Stack(
                  children: [
                    // Connections layer with tap detection (isolated consumer)
                    // Connections layer (isolated consumer - doesn't affect blocks)
                    Consumer(
                      builder: (context, ref, child) {
                        final connectionState = ref.watch(connectionManagerProvider);

                        return RepaintBoundary(
                          child: CustomPaint(
                            painter: ConnectionsPainter(
                              connections: connectionState.connections,
                              blockPositions: connectionState.blockPositions,
                            ),
                            size: const Size(3000, 3000),
                          ),
                        );
                      },
                    ),

                    ...canvasState.map(
                      (blockID) => Block(
                        key: ValueKey(blockID),
                        blockID: blockID,
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
