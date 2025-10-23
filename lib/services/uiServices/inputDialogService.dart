import 'package:flutter/material.dart';
import 'package:platform_v2/config/constants.dart';
import 'package:platform_v2/services/uiServices/navigationService.dart';


class InputDialogService {
  // Generic form dialog - handles any field configuration
  static Future<Map<String, String>?> showFormDialog({
    required String title,
    required List<FormField> fields,
    String confirmText = 'Create',
    String cancelText = 'Cancel',
    bool enableConfirm = true,
    String? demoMessage,
  }) async {
    final BuildContext? context = NavigationService.router.routerDelegate.navigatorKey.currentContext;
    if (context == null) return null;

    return await showDialog<Map<String, String>>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext dialogContext) {
        return _FormDialog(
          title: title,
          fields: fields,
          confirmText: confirmText,
          cancelText: cancelText,
          enableConfirm: enableConfirm,
          demoMessage: demoMessage,
        );
      },
    );
  }

  static Future<Map<String, String>?> showorgForm() async {
    return showFormDialog(
      title: 'Add org',
      fields: [
        FormField(
          key: 'orgName',
          label: 'org Name',
          hint: 'Enter org name',
          required: true,
        ),
      ],
      enableConfirm: false,
      demoMessage: "This is a demo, can't create org",
    );
  }
}

// Field Data class
class FormField {
  final String key;
  final String label;
  final String? hint;
  final bool required;
  final int maxLines;
  final TextInputType inputType;

  FormField({
    required this.key,
    required this.label,
    this.hint,
    this.required = false,
    this.maxLines = 1,
    this.inputType = TextInputType.text,
  });
}

// Internal dialog widget
class _FormDialog extends StatefulWidget {
  final String title;
  final List<FormField> fields;
  final String confirmText;
  final String cancelText;
  final bool enableConfirm;
  final String? demoMessage;

  const _FormDialog({
    required this.title,
    required this.fields,
    required this.confirmText,
    required this.cancelText,
    this.enableConfirm = true,
    this.demoMessage,
  });

  @override
  State<_FormDialog> createState() => _FormDialogState();
}

class _FormDialogState extends State<_FormDialog> {
  final _formKey = GlobalKey<FormState>();
  late final Map<String, TextEditingController> _controllers;

  @override
  void initState() {
    super.initState();
    _controllers = {
      for (final field in widget.fields) field.key: TextEditingController(),
    };
  }

  @override
  void dispose() {
    for (var controller in _controllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      title: Text(widget.title, style: kTextHeading3R),
      content: SizedBox(
        width: 300,
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Show demo message if provided
              if (widget.demoMessage != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: Text(
                    widget.demoMessage!,
                    style: const TextStyle(
                      color: Colors.orange,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              // Show form fields
              ...widget.fields.map((field) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: TextFormField(
                    controller: _controllers[field.key],
                    decoration: InputDecoration(
                      labelText: field.label,
                      hintText: field.hint,
                    ),
                    keyboardType: field.inputType,
                    maxLines: field.maxLines,
                    validator: field.required ? (value) => value?.trim().isEmpty == true ? 'This field is required' : null : null,
                  ),
                );
              }),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(widget.cancelText),
        ),
        ElevatedButton(
          onPressed: widget.enableConfirm ? () {
            if (_formKey.currentState!.validate()) {
              final result = {
                for (final field in widget.fields) field.key: _controllers[field.key]!.text.trim(),
              };
              Navigator.of(context).pop(result);
            }
          } : null,
          child: Text(widget.confirmText),
        ),
      ],
    );
  }
}
