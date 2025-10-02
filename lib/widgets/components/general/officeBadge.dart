import 'package:flutter/material.dart';

/// Widget that displays a colored circular badge for region/subOffice indicators
class OfficeBadge extends StatelessWidget {
  final String value;
  final bool isTopLeft; // true for top-left, false for top-right

  const OfficeBadge({
    super.key,
    required this.value,
    this.isTopLeft = true,
  });

  @override
  Widget build(BuildContext context) {
    if (value.isEmpty) {
      return const SizedBox.shrink();
    }

    return Container(
      width: 22,
      height: 22,
      decoration: BoxDecoration(
        color: getColorForValue(value),
        shape: BoxShape.circle,
      ),
      child: Center(
        child: Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 9,
            fontWeight: FontWeight.bold,
          ),
          textAlign: TextAlign.center,
        ),
      ),
    );
  }

  /// Maps values to 7 distinct colors
  /// Extracts number from text (e.g., "1", "West 1", "Office 2")
  /// Returns color from predefined palette
  static Color getColorForValue(String value) {
    // Try to extract a number from the value
    final RegExp numberPattern = RegExp(r'\d+');
    final match = numberPattern.firstMatch(value);

    int number;
    if (match != null) {
      number = int.tryParse(match.group(0)!) ?? 0;
    } else {
      // If no number found, try to parse the whole string
      number = int.tryParse(value) ?? 0;
    }

    // Map number to color (1-7)
    switch (number % 8) { // Use modulo 8 to handle values > 7
      case 1:
        return const Color(0xFF2196F3); // Blue
      case 2:
        return const Color(0xFF4CAF50); // Green
      case 3:
        return const Color(0xFFFF9800); // Orange
      case 4:
        return const Color(0xFF9C27B0); // Purple
      case 5:
        return const Color(0xFFF44336); // Red
      case 6:
        return const Color(0xFF009688); // Teal
      case 7:
        return const Color(0xFFE91E63); // Pink
      default:
        return const Color(0xFF9E9E9E); // Grey for 0 or invalid
    }
  }
}
