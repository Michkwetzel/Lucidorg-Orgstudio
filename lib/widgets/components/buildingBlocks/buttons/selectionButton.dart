import 'package:flutter/material.dart';
import 'package:logging/logging.dart';
import 'package:platform_v2/config/constants.dart';

final Logger logger = Logger('selectionButton.dart');

class SelectionButton extends StatelessWidget {
  final String? heading;
  final String? data;
  final VoidCallback? onPressed;
  const SelectionButton({super.key, required this.heading, this.data, this.onPressed});

  @override
  Widget build(BuildContext context) {
    return Ink(
      decoration: kboxShadowNormal,
      width: 250,
      height: 150,
      child: InkWell(
        onTap: onPressed,
        child: FittedBox(
          fit: BoxFit.scaleDown,
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: Text(
              heading ?? "",
              style: kTextHeading3R,
            ),
          ),
        ),
      ),
    );
  }
}
