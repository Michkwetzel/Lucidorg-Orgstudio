import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:platform_v2/config/constants.dart';

class CallToActionButton extends ConsumerWidget {
  final VoidCallback? onPressed;
  final String buttonText;
  final bool isSuccess;
  final bool disabled;

  const CallToActionButton({
    super.key,
    required this.onPressed,
    required this.buttonText,
    this.disabled = false,
    this.isSuccess = false,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return SizedBox(
      height: kButtonHeight,
      child: MaterialButton(
        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
        disabledColor: const Color(0x40A2B185),
        onPressed: disabled ? null : onPressed,
        color: const Color(0xFFA2B185),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
        elevation: 1,
        child: Text(
          buttonText,
          style: kCallToActionButtonTextStyle,
        ),
      ),
    );
  }
}
