import 'package:flutter/material.dart';
import 'package:platform_v2/config/enums.dart';
import 'package:platform_v2/dataClasses/blockData.dart';
import 'package:platform_v2/widgets/overlays/createAssessment.dart';
import 'package:platform_v2/widgets/overlays/sendAssessmentOverlay.dart';
import 'package:platform_v2/widgets/overlays/blockInputOverlay.dart';
import 'package:platform_v2/widgets/overlays/sendAssConfirmOverlay.dart';

class OverlayService {
  static OverlayEntry? _activeBlockInputOverlay;
  static OverlayEntry? _activeSendAssessmentOverlay;
  static OverlayEntry? _activeAssessmentCreationOverlay;

  static void showBlockInput(BuildContext context, {required Function(BlockData) onSave, VoidCallback? onCancel, BlockData? initialData, required String blockId}) {
    // Close existing block input overlay if one exists
    _activeBlockInputOverlay?.remove();
    _activeBlockInputOverlay = null;
    final overlay = Overlay.of(context);
    late OverlayEntry overlayEntry;

    overlayEntry = OverlayEntry(
      builder: (context) => BlockInputOverlay(
        initialData: initialData,
        blockId: blockId,
        onSave: (data) {
          overlayEntry.remove();
          _activeBlockInputOverlay = null;
          onSave(data);
        },
        onClose: () {
          overlayEntry.remove();
          _activeBlockInputOverlay = null;
          onCancel?.call();
        },
      ),
    );

    _activeBlockInputOverlay = overlayEntry;
    overlay.insert(overlayEntry);
  }

  static void showAssessmentCreation(BuildContext context, {required Future<void> Function(String) onCreate, VoidCallback? onCancel}) {
    // Close existing assessment creation overlay if one exists
    _activeAssessmentCreationOverlay?.remove();
    _activeAssessmentCreationOverlay = null;
    
    final overlay = Overlay.of(context);
    late OverlayEntry overlayEntry;

    overlayEntry = OverlayEntry(
      builder: (context) => AssessmentCreationOverlay(
        onCreate: (assessmentName) async {
          await onCreate(assessmentName);
          overlayEntry.remove();
          _activeAssessmentCreationOverlay = null;
        },
        onClose: () {
          overlayEntry.remove();
          _activeAssessmentCreationOverlay = null;
          onCancel?.call();
        },
      ),
    );

    _activeAssessmentCreationOverlay = overlayEntry;
    overlay.insert(overlayEntry);
  }

  static void showSendAssessment(BuildContext context, {required Function(Options, String) onSend, VoidCallback? onCancel}) {
    // Close existing send assessment overlay if one exists
    _activeSendAssessmentOverlay?.remove();
    _activeSendAssessmentOverlay = null;
    
    final overlay = Overlay.of(context);
    late OverlayEntry overlayEntry;

    overlayEntry = OverlayEntry(
      builder: (context) => SendAssessmentOverlay(
        onSend: (selectionType, textData) {
          overlayEntry.remove();
          _activeSendAssessmentOverlay = null;
          onSend(selectionType, textData);
        },
        onClose: () {
          overlayEntry.remove();
          _activeSendAssessmentOverlay = null;
          onCancel?.call();
        },
      ),
    );

    _activeSendAssessmentOverlay = overlayEntry;
    overlay.insert(overlayEntry);
  }

  static void showAssessmentSendConfirmation(BuildContext context, {required VoidCallback onSend, VoidCallback? onCancel}) {
    // Note: Confirmation overlay can stack over send assessment overlay
    final overlay = Overlay.of(context);
    late OverlayEntry overlayEntry;

    overlayEntry = OverlayEntry(
      builder: (context) => AssessmentSendConfirmationOverlay(
        onSend: () {
          overlayEntry.remove();
          onSend();
        },
        onCancel: () {
          overlayEntry.remove();
          onCancel?.call();
        },
      ),
    );

    overlay.insert(overlayEntry);
  }
}
