import 'package:flutter/material.dart';
import 'package:platform_v2/config/constants.dart';
import 'package:platform_v2/services/uiServices/navigationService.dart'; // Assuming you're using go_router based on the NavigationService.router

class AlertService {
  static Future<void> showAlert({
    required String title,
    required String message,
    String confirmText = 'OK',
    String? cancelText,
    Function()? onConfirm,
    Function()? onCancel,
  }) async {
    // Get the current context from the router
    final BuildContext? context = NavigationService.router.routerDelegate.navigatorKey.currentContext;

    if (context == null) return;

    return await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          title: Text(
            title,
            style: kTextHeading3R,
          ),
          content: Text(
            message,
            style: kTextBodyR,
          ),
          actions: <Widget>[
            if (cancelText != null)
              TextButton(
                onPressed: () {
                  Navigator.of(dialogContext).pop();
                  if (onCancel != null) onCancel();
                },
                child: Text(cancelText),
              ),
            TextButton(
              onPressed: () {
                Navigator.of(dialogContext).pop();
                if (onConfirm != null) onConfirm();
              },
              child: Text(confirmText),
            ),
          ],
        );
      },
    );
  }

  static Future<void> showConfirmation({
    required String title,
    required String message,
    String confirmText = 'Yes',
    String cancelText = 'No',
    required Function() onConfirm,
    Function()? onCancel,
  }) async {
    return showAlert(
      title: title,
      message: message,
      confirmText: confirmText,
      cancelText: cancelText,
      onConfirm: onConfirm,
      onCancel: onCancel,
    );
  }
}
