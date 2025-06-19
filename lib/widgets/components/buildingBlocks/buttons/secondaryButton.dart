import 'package:flutter/material.dart';
import 'package:platform_v2/config/constants.dart';

class Secondarybutton extends StatelessWidget {
  final VoidCallback onPressed;
  final String buttonText;

  const Secondarybutton({super.key, required this.onPressed, required this.buttonText});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: kButtonHeight,
      child: MaterialButton(
        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
        onPressed: onPressed,
        color: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
          side: const BorderSide(color: Color(0xFFBBBBBB), width: 1),
        ),
        elevation: 1,
        child: Text(
          buttonText,
          style: kSecondaryButtonTextStyle,
        ),
      ),
    );
  }
}
