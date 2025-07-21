import 'package:flutter/material.dart';
import 'package:platform_v2/dataClasses/blockData.dart';
import 'package:platform_v2/widgets/overlays/createAssessment.dart';
import 'package:platform_v2/widgets/overlays/sendAssessmentOverlay.dart';
import 'package:platform_v2/widgets/overlays/blockInputOverlay.dart';
import 'package:platform_v2/widgets/overlays/sendAssConfirmOverlay.dart';

class OverlayService {
  static OverlayEntry? _currentOverlay;

  // When double taping a block
  static void openBlockInputBox(
    BuildContext context, {
    Function(BlockData)? onSave,
    VoidCallback? onClose,
    BlockData? initialData,
  }) {
    final overlay = Overlay.of(context);

    // Remove any existing overlay
    _currentOverlay?.remove();

    late OverlayEntry overlayEntry;

    overlayEntry = OverlayEntry(
      builder: (context) => BlockInputOverlay(
        initialData: initialData,
        onSave: (data) {
          overlayEntry.remove();
          _currentOverlay = null;
          onSave?.call(data);
        },
        onClose: () {
          overlayEntry.remove();
          _currentOverlay = null;
          onClose?.call();
        },
      ),
    );

    _currentOverlay = overlayEntry;
    overlay.insert(overlayEntry);
  }

  // Dialogie that opens when you want to create a new Assessment
  static void openAssessmentCreationOverlay(
    BuildContext context, {
    Future<void> Function(String)? onCreate,
    VoidCallback? onClose,
  }) {
    final overlay = Overlay.of(context);

    // Remove any existing overlay
    _currentOverlay?.remove();

    late OverlayEntry overlayEntry;

    overlayEntry = OverlayEntry(
      builder: (context) => AssessmentCreationOverlay(
        onCreate: (assessmentName) async {
          await onCreate?.call(assessmentName);
          overlayEntry.remove();
          _currentOverlay = null;
        },
        onClose: () {
          overlayEntry.remove();
          _currentOverlay = null;
          onClose?.call();
        },
      ),
    );

    _currentOverlay = overlayEntry;
    overlay.insert(overlayEntry);
  }

  // Selecting which emails to send Assessment to
  static void openSendAssessmentOverlay(
    BuildContext context, {
    Function(String, String)? onSend,
    VoidCallback? onClose,
  }) {
    final overlay = Overlay.of(context);

    late OverlayEntry overlayEntry;

    overlayEntry = OverlayEntry(
      builder: (context) => SendAssessmentOverlay(
        onSend: (selectionType, textData) {
          overlayEntry.remove();
          _currentOverlay = null;
          onSend?.call(selectionType, textData);
        },
        onClose: () {
          overlayEntry.remove();
          _currentOverlay = null;
          onClose?.call();
        },
      ),
    );

    _currentOverlay = overlayEntry;
    overlay.insert(overlayEntry);
  }

  // Opens to confirm what you assessments you are about to send
  static void openAssessmentSendConfirmationOverlay(
    BuildContext context, {
    VoidCallback? onSend,
    VoidCallback? onCancel,
  }) {
    final overlay = Overlay.of(context);

    late OverlayEntry overlayEntry;

    overlayEntry = OverlayEntry(
      builder: (context) => AssessmentSendConfirmationOverlay(
        onSend: () {
          overlayEntry.remove();
          _currentOverlay = null;
          onSend?.call();
        },
        onCancel: () {
          overlayEntry.remove();
          _currentOverlay = null;
          onCancel?.call();
        },
      ),
    );

    _currentOverlay = overlayEntry;
    overlay.insert(overlayEntry);
  }
}
