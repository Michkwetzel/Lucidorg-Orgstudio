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
    for (final connection in connections) {
      final parentPos = blockPositions[connection.parentId];
      final childPos = blockPositions[connection.childId];

      // print("Connection ${connection.id}: parent=${connection.parentId} at $parentPos, child=${connection.childId} at $childPos");

      // Skip if either block position is unknown
      if (parentPos == null || childPos == null) {
        print("Skipping connection - missing positions");
        continue;
      }

      _drawConnection(canvas, connection, parentPos, childPos);
      // print("Drew connection from $parentPos to $childPos");
    }
  }

  void _drawConnection(Canvas canvas, Connection connection, Offset parentPos, Offset childPos) {
    // Calculate connection points (assuming 200x100 block size - adjust as needed)
    const blockWidth = 120.0;
    const blockHeight = 100.0;

    final startPoint = _getConnectionPoint(parentPos, childPos, blockWidth, blockHeight, isParent: true);
    final endPoint = _getConnectionPoint(childPos, parentPos, blockWidth, blockHeight, isParent: false);

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

  Offset _getConnectionPoint(Offset blockPos, Offset otherBlockPos, double blockWidth, double blockHeight, {required bool isParent}) {
    final blockCenter = blockPos + Offset(blockWidth / 2, blockHeight / 2);
    final otherCenter = otherBlockPos + Offset(blockWidth / 2, blockHeight / 2);

    // Calculate which edge to connect to based on relative position
    final dx = otherCenter.dx - blockCenter.dx;
    final dy = otherCenter.dy - blockCenter.dy;

    if (dx.abs() > dy.abs()) {
      // Connect to left or right edge
      if (dx > 0) {
        // Connect to right edge
        return Offset(blockPos.dx + blockWidth, blockPos.dy + blockHeight / 2);
      } else {
        // Connect to left edge
        return Offset(blockPos.dx, blockPos.dy + blockHeight / 2);
      }
    } else {
      // Connect to top or bottom edge
      if (dy > 0) {
        // Connect to bottom edge
        return Offset(blockPos.dx + blockWidth / 2, blockPos.dy + blockHeight);
      } else {
        // Connect to top edge
        return Offset(blockPos.dx + blockWidth / 2, blockPos.dy);
      }
    }
  }

  void _drawCurvedLine(Canvas canvas, Offset start, Offset end, Paint paint) {
    final path = Path();
    path.moveTo(start.dx, start.dy);

    // Create a smooth horizontal curve
    final distance = (end.dx - start.dx).abs();
    final curveOffset = distance * 0.4; // Adjust curve intensity

    final controlPoint1 = Offset(start.dx + curveOffset, start.dy);
    final controlPoint2 = Offset(end.dx - curveOffset, end.dy);

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

    // Calculate arrow direction
    final direction = atan2(end.dy - start.dy, end.dx - start.dx);

    // Calculate arrowhead points
    final arrowPoint1 = Offset(
      end.dx - arrowLength * cos(direction - arrowAngle),
      end.dy - arrowLength * sin(direction - arrowAngle),
    );
    final arrowPoint2 = Offset(
      end.dx - arrowLength * cos(direction + arrowAngle),
      end.dy - arrowLength * sin(direction + arrowAngle),
    );

    // Draw arrowhead lines
    canvas.drawLine(end, arrowPoint1, paint);
    canvas.drawLine(end, arrowPoint2, paint);
  }

  @override
  bool shouldRepaint(ConnectionsPainter oldDelegate) {
    return connections != oldDelegate.connections || blockPositions != oldDelegate.blockPositions;
  }
}
