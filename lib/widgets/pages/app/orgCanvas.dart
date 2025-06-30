import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:platform_v2/config/provider.dart';
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
              onTap: () => print("object"),
              onDoubleTapDown: (details) {
                // Save pointer position
                final RenderBox renderBox = context.findRenderObject() as RenderBox;
                _lastTapPosition = renderBox.globalToLocal(details.globalPosition);
              },
              onDoubleTap: () {
                // Create new block at tap position
                final blockId = FirestoreIdGenerator.generate();
                ref.read(canvasProvider.notifier).addBlock(blockId, _lastTapPosition);
              },
              child: Container(
                width: 3000,
                height: 3000,
                color: Colors.transparent,
                child: Stack(
                  children: ref
                      .watch(canvasProvider)
                      .map(
                        (entry) => Block(
                          key: ValueKey(entry),
                          blockId: entry,
                          initialPosition: ref.read(canvasProvider.notifier).initialPositions[entry]!,
                        ),
                      )
                      .toList(),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
