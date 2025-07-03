import 'dart:math';
import 'package:flutter/material.dart';
import 'package:platform_v2/dataClasses/connection.dart';

// Simple ConnectionsPainter
class ConnectionsPainter extends CustomPainter {
  final List<Connection> connections;
  final Map<String, Offset> blockPositions;

  ConnectionsPainter({
    required this.connections,
    required this.blockPositions,
  });

  @override
  void paint(Canvas canvas, Size size) {
    print("!!!Paint Connections");
    for (final connection in connections) {
      final parentPos = blockPositions[connection.parentId];
      final childPos = blockPositions[connection.childId];

      // Skip if either block position is unknown
      if (parentPos == null || childPos == null) {
        continue;
      }

      _drawConnection(canvas, connection, parentPos, childPos);
      // print("Drew connection from $parentPos to $childPos");
    }
  }

  void _drawConnection(Canvas canvas, Connection connection, Offset parentPos, Offset childPos) {
    // Calculate connection points (assuming 120x100 block size)
    const blockWidth = 120.0;
    const blockHeight = 100.0;

    final startPoint = _getConnectionPoint(parentPos, blockWidth, blockHeight, isParent: true);
    final endPoint = _getConnectionPoint(childPos, blockWidth, blockHeight, isParent: false);

    // Create paint style
    final paint = Paint()
      ..color = Colors.grey.shade400
      ..strokeWidth = 2.0
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    // Draw curved line
    _drawCurvedLine(canvas, startPoint, endPoint, paint);

    // Draw arrowhead
    _drawArrowhead(canvas, startPoint, endPoint, paint);
  }

  Offset _getConnectionPoint(Offset blockPos, double blockWidth, double blockHeight, {required bool isParent}) {
    if (isParent) {
      // Parent: always connect from bottom center
      return Offset(blockPos.dx + blockWidth / 2, blockPos.dy + blockHeight);
    } else {
      // Child: always connect to top center
      return Offset(blockPos.dx + blockWidth / 2, blockPos.dy);
    }
  }

  void _drawCurvedLine(Canvas canvas, Offset start, Offset end, Paint paint) {
    final path = Path();
    path.moveTo(start.dx, start.dy);

    // Create a smooth vertical curve since we're connecting bottom to top
    final distance = (end.dy - start.dy).abs();
    final curveOffset = distance * 0.4; // Adjust curve intensity

    // Use vertical control points for better parent-child connections
    final controlPoint1 = Offset(start.dx, start.dy + curveOffset);
    final controlPoint2 = Offset(end.dx, end.dy - curveOffset);

    path.cubicTo(
      controlPoint1.dx,
      controlPoint1.dy,
      controlPoint2.dx,
      controlPoint2.dy,
      end.dx,
      end.dy,
    );

    canvas.drawPath(path, paint);
  }

  void _drawArrowhead(Canvas canvas, Offset start, Offset end, Paint paint) {
    const arrowLength = 12.0;
    const arrowAngle = 0.5; // radians (~30 degrees)

    // Always face down (π/2 radians = 90 degrees)
    final direction = pi / 2;

    // Calculate arrowhead points
    final arrowPoint1 = Offset(
      end.dx - arrowLength * cos(direction - arrowAngle),
      end.dy - arrowLength * sin(direction - arrowAngle),
    );
    final arrowPoint2 = Offset(
      end.dx - arrowLength * cos(direction + arrowAngle),
      end.dy - arrowLength * sin(direction + arrowAngle),
    );

    // Create filled arrowhead triangle
    final arrowPath = Path();
    arrowPath.moveTo(end.dx, end.dy);
    arrowPath.lineTo(arrowPoint1.dx, arrowPoint1.dy);
    arrowPath.lineTo(arrowPoint2.dx, arrowPoint2.dy);
    arrowPath.close();

    // Create fill paint for arrowhead
    final arrowPaint = Paint()
      ..color = Colors.grey.shade400
      ..style = PaintingStyle.fill;

    canvas.drawPath(arrowPath, arrowPaint);
  }

  @override
  bool shouldRepaint(ConnectionsPainter oldDelegate) {
    return connections != oldDelegate.connections || blockPositions != oldDelegate.blockPositions;
  }
}
