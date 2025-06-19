import 'package:flutter/material.dart';
import 'package:platform_v2/widgets/components/general/loadingAnimation.dart';

class LoadingService {
  static OverlayEntry? _overlayEntry;

  // Cover whole screen and absorb pointers
  static void show(BuildContext context, String? loadingText) {
    if (_overlayEntry != null) return;

    _overlayEntry = OverlayEntry(
      builder: (context) => AbsorbPointer(
        absorbing: true,
        child: Container(
          width: double.infinity,
          height: double.infinity,
          color: Colors.transparent,
          child: Center(
            child: LoadingAnimation(
              loadingText,
            ),
          ),
        ),
      ),
    );

    Overlay.of(context).insert(_overlayEntry!);
  }

  static void hide() {
    _overlayEntry?.remove();
    _overlayEntry = null;
  }
}
