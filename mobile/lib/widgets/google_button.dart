import 'package:flutter/material.dart';

class GoogleSignInButton extends StatelessWidget {
  final VoidCallback onPressed;
  final bool isLoading;

  const GoogleSignInButton({
    super.key,
    required this.onPressed,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 48,
      child: TextButton(
        onPressed: isLoading ? null : onPressed,
        style: TextButton.styleFrom(
          backgroundColor: const Color(0xFFF3F4F6),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 16),
        ),
        child: isLoading
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.black54,
                ),
              )
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CustomPaint(
                    size: const Size(18, 18),
                    painter: GoogleLogoPainter(),
                  ),
                  const SizedBox(width: 12),
                  const Text(
                    'Continue with Google',
                    style: TextStyle(
                      color: Color(0xFF1F2937),
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      letterSpacing: -0.2,
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}

/// Razor-sharp 4-color Google "G" icon vector painter
class GoogleLogoPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final double w = size.width;
    final double h = size.height;

    final paint = Paint()..style = PaintingStyle.fill;

    // Blue section
    paint.color = const Color(0xFF4285F4);
    final bluePath = Path()
      ..moveTo(w * 0.95, h * 0.51)
      ..cubicTo(w * 0.95, h * 0.47, w * 0.94, h * 0.44, w * 0.93, h * 0.41)
      ..lineTo(w * 0.5, h * 0.41)
      ..lineTo(w * 0.5, h * 0.6)
      ..lineTo(w * 0.75, h * 0.6)
      ..cubicTo(w * 0.74, h * 0.67, w * 0.69, h * 0.73, w * 0.63, h * 0.77)
      ..lineTo(w * 0.79, h * 0.89)
      ..cubicTo(w * 0.88, h * 0.81, w * 0.95, h * 0.67, w * 0.95, h * 0.51)
      ..close();
    canvas.drawPath(bluePath, paint);

    // Green section
    paint.color = const Color(0xFF34A853);
    final greenPath = Path()
      ..moveTo(w * 0.5, h * 0.96)
      ..cubicTo(w * 0.64, h * 0.96, w * 0.76, h * 0.91, w * 0.85, h * 0.83)
      ..lineTo(w * 0.69, h * 0.71)
      ..cubicTo(w * 0.64, h * 0.74, w * 0.58, h * 0.76, w * 0.5, h * 0.76)
      ..cubicTo(w * 0.38, h * 0.76, w * 0.28, h * 0.68, w * 0.24, h * 0.57)
      ..lineTo(w * 0.08, h * 0.69)
      ..cubicTo(w * 0.16, h * 0.85, w * 0.32, h * 0.96, w * 0.5, h * 0.96)
      ..close();
    canvas.drawPath(greenPath, paint);

    // Yellow section
    paint.color = const Color(0xFFFBBC05);
    final yellowPath = Path()
      ..moveTo(w * 0.24, h * 0.57)
      ..cubicTo(w * 0.23, h * 0.53, w * 0.22, h * 0.49, w * 0.22, h * 0.45)
      ..cubicTo(w * 0.22, h * 0.41, w * 0.23, h * 0.37, w * 0.24, h * 0.33)
      ..lineTo(w * 0.08, h * 0.21)
      ..cubicTo(w * 0.05, h * 0.28, w * 0.03, h * 0.36, w * 0.03, h * 0.45)
      ..cubicTo(w * 0.03, h * 0.54, w * 0.05, h * 0.62, w * 0.08, h * 0.69)
      ..lineTo(w * 0.24, h * 0.57)
      ..close();
    canvas.drawPath(yellowPath, paint);

    // Red section
    paint.color = const Color(0xFFEA4335);
    final redPath = Path()
      ..moveTo(w * 0.5, h * 0.14)
      ..cubicTo(w * 0.58, h * 0.14, w * 0.65, h * 0.17, w * 0.7, h * 0.22)
      ..lineTo(w * 0.85, h * 0.07)
      ..cubicTo(w * 0.76, h * -0.01, w * 0.64, -0.05, w * 0.5, -0.05)
      ..cubicTo(w * 0.32, -0.05, w * 0.16, 0.05, 0.08, 0.21)
      ..lineTo(w * 0.24, h * 0.33)
      ..cubicTo(w * 0.28, h * 0.22, w * 0.38, h * 0.14, w * 0.5, h * 0.14)
      ..close();
    canvas.drawPath(redPath, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
