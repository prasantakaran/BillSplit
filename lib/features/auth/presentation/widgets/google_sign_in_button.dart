import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';

class GoogleSignInButton extends StatelessWidget {
  const GoogleSignInButton({
    super.key,
    required this.isSubmitting,
    required this.onPressed,
  });

  final ValueListenable<bool> isSubmitting;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<bool>(
      valueListenable: isSubmitting,
      builder: (context, submitting, _) => SizedBox(
        width: double.infinity,
        height: 56,
        child: OutlinedButton(
          onPressed: submitting ? null : onPressed,
          style: OutlinedButton.styleFrom(
            backgroundColor: AppColors.lightSurface,
            side: BorderSide(
              color: AppColors.brandBlue.withValues(alpha: 0.55),
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const CustomPaint(size: Size(22, 22), painter: _GoogleGPainter()),
              const SizedBox(width: 12),
              Text(
                'Continue with Google',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: AppColors.brandNavy.withValues(alpha: 0.9),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Paints the multicolour Google "G" mark using canvas arcs, so no image
/// asset is needed.
class _GoogleGPainter extends CustomPainter {
  const _GoogleGPainter();

  static const Color _blue = Color(0xFF4285F4);
  static const Color _green = Color(0xFF34A853);
  static const Color _yellow = Color(0xFFFBBC05);
  static const Color _red = Color(0xFFEA4335);

  @override
  void paint(Canvas canvas, Size size) {
    final double stroke = size.width * 0.22;
    final Rect rect = Rect.fromLTWH(
      stroke / 2,
      stroke / 2,
      size.width - stroke,
      size.height - stroke,
    );
    final Paint paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke;

    double rad(double degrees) => degrees * math.pi / 180;

    // Angles: 0° = right, positive sweep = clockwise. The gap between the
    // red arc's end (-45°) and the blue arc's start (0°) forms the G opening.
    canvas.drawArc(rect, rad(180), rad(135), false, paint..color = _red);
    canvas.drawArc(rect, rad(135), rad(45), false, paint..color = _yellow);
    canvas.drawArc(rect, rad(45), rad(90), false, paint..color = _green);
    canvas.drawArc(rect, rad(0), rad(45), false, paint..color = _blue);

    // Horizontal bar of the G.
    canvas.drawRect(
      Rect.fromLTWH(
        size.width / 2,
        (size.height - stroke) / 2,
        size.width / 2 - stroke / 4,
        stroke,
      ),
      paint
        ..style = PaintingStyle.fill
        ..color = _blue,
    );
  }

  @override
  bool shouldRepaint(_GoogleGPainter oldDelegate) => false;
}
