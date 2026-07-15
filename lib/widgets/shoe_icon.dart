import 'package:flutter/material.dart';

// ─────────────────────────────────────────────────────────────────────────────
// A real sneaker side-profile, hand-drawn — neither Flutter's Material Icons
// nor Font Awesome's free set actually ships a shoe glyph (verified against
// both source files: Material only has "snowshoeing", Font Awesome only has
// "shoe-prints" and a "shoelace" brand logo). Drop-in replacement for
// Icon(...) wherever a literal shoe is meant, not a running figure.
// ─────────────────────────────────────────────────────────────────────────────

class ShoeIcon extends StatelessWidget {
  final Color color;
  final double size;

  const ShoeIcon({super.key, required this.color, this.size = 16});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(painter: _ShoePainter(color: color)),
    );
  }
}

class _ShoePainter extends CustomPainter {
  final Color color;
  const _ShoePainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final scaleX = size.width / 24;
    final scaleY = size.height / 24;

    final path = Path()
      ..moveTo(3 * scaleX, 17 * scaleY)
      ..lineTo(3 * scaleX, 12 * scaleY)
      ..cubicTo(3 * scaleX, 9 * scaleY, 6 * scaleX, 7 * scaleY, 9 * scaleX, 7 * scaleY)
      ..cubicTo(11 * scaleX, 7 * scaleY, 12 * scaleX, 5 * scaleY, 14 * scaleX, 5.5 * scaleY)
      ..cubicTo(16 * scaleX, 6 * scaleY, 17 * scaleX, 8 * scaleY, 19 * scaleX, 9 * scaleY)
      ..cubicTo(20 * scaleX, 9.5 * scaleY, 21 * scaleX, 10.5 * scaleY, 21 * scaleX, 12 * scaleY)
      ..lineTo(21 * scaleX, 15 * scaleY)
      ..cubicTo(21 * scaleX, 16.5 * scaleY, 20 * scaleX, 17 * scaleY, 18 * scaleX, 17 * scaleY)
      ..lineTo(3 * scaleX, 17 * scaleY)
      ..close();

    canvas.drawPath(
      path,
      Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.6
        ..strokeJoin = StrokeJoin.round
        ..strokeCap = StrokeCap.round,
    );

    // Laces — two short marks over the tongue.
    final lacePaint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(Offset(10.5 * scaleX, 8 * scaleY), Offset(12.5 * scaleX, 9.5 * scaleY), lacePaint);
    canvas.drawLine(Offset(12.5 * scaleX, 7.2 * scaleY), Offset(14.5 * scaleX, 8.8 * scaleY), lacePaint);

    // Sole line — a slightly thicker underline to read as the sole tread.
    canvas.drawLine(
      Offset(3 * scaleX, 17 * scaleY),
      Offset(18.5 * scaleX, 17 * scaleY),
      Paint()
        ..color = color
        ..strokeWidth = 2.2
        ..strokeCap = StrokeCap.round,
    );
  }

  @override
  bool shouldRepaint(_ShoePainter old) => old.color != color;
}
