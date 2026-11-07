import 'dart:math' as math;

import 'package:flutter/material.dart';

/// The isometric cube tessellation from ALU's own brand material, drawn at
/// low contrast as a header texture.
class AluPattern extends StatelessWidget {
  const AluPattern({
    super.key,
    this.cubeRadius = 26,
    this.opacity = 0.07,
    this.color = Colors.white,
  });

  final double cubeRadius;
  final double opacity;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: CustomPaint(
        painter: _CubePainter(
          radius: cubeRadius,
          color: color,
          opacity: opacity,
        ),
        size: Size.infinite,
      ),
    );
  }
}

class _CubePainter extends CustomPainter {
  _CubePainter({
    required this.radius,
    required this.color,
    required this.opacity,
  });

  final double radius;
  final Color color;
  final double opacity;

  @override
  void paint(Canvas canvas, Size size) {
    final horizontal = math.sqrt(3) * radius;
    final vertical = 1.5 * radius;

    for (var row = -1; row * vertical < size.height + radius; row++) {
      final offsetX = row.isOdd ? horizontal / 2 : 0.0;
      for (var col = -1; col * horizontal + offsetX < size.width + radius; col++) {
        _paintCube(
          canvas,
          Offset(col * horizontal + offsetX, row * vertical),
        );
      }
    }
  }

  /// A hexagon split from its centre into three rhombi reads as a cube.
  void _paintCube(Canvas canvas, Offset centre) {
    final vertices = List.generate(6, (i) {
      final angle = math.pi / 180 * (60 * i - 90);
      return Offset(
        centre.dx + radius * math.cos(angle),
        centre.dy + radius * math.sin(angle),
      );
    });

    const faceOpacity = [1.0, 0.55, 0.25];
    for (var face = 0; face < 3; face++) {
      final path = Path()
        ..moveTo(centre.dx, centre.dy)
        ..lineTo(vertices[face * 2].dx, vertices[face * 2].dy)
        ..lineTo(vertices[face * 2 + 1].dx, vertices[face * 2 + 1].dy)
        ..lineTo(vertices[(face * 2 + 2) % 6].dx, vertices[(face * 2 + 2) % 6].dy)
        ..close();

      canvas.drawPath(
        path,
        Paint()..color = color.withValues(alpha: opacity * faceOpacity[face]),
      );
    }
  }

  @override
  bool shouldRepaint(_CubePainter oldDelegate) =>
      oldDelegate.radius != radius ||
      oldDelegate.color != color ||
      oldDelegate.opacity != opacity;
}
