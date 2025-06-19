import 'package:flutter/material.dart';
import 'package:platform_v2/config/constants.dart';

class Primarybutton extends StatelessWidget {
  final VoidCallback onPressed;
  final String buttonText;

  const Primarybutton({super.key, required this.onPressed, required this.buttonText});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: kButtonHeight,
      child: MaterialButton(
        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
        onPressed: onPressed,
        color: const Color(0xFF838282),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
        elevation: 1,
        child: Text(
          buttonText,
          style: kPrimaryButtonTextStyle,
        ),
      ),
    );
  }
}
