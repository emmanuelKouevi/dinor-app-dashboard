/**
 * GOOGLE_LOGO.DART - Logo Google officiel en SVG
 * 
 * Logo Google intégré directement dans le code
 * Pas besoin de fichier asset externe
 */

import 'package:flutter/material.dart';

class GoogleLogo extends StatelessWidget {
  final double size;

  const GoogleLogo({
    Key? key,
    this.size = 20,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(
        painter: _GoogleLogoPainter(),
      ),
    );
  }
}

class _GoogleLogoPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..style = PaintingStyle.fill
      ..isAntiAlias = true;

    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;

    // Bleu (partie droite)
    paint.color = const Color(0xFF4285F4);
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -0.52, // -30 degrés
      2.09, // 120 degrés
      true,
      paint,
    );

    // Rouge (partie haute)
    paint.color = const Color(0xFFEA4335);
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      1.57, // 90 degrés
      1.05, // 60 degrés
      true,
      paint,
    );

    // Jaune (partie gauche)
    paint.color = const Color(0xFFFBBC05);
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      2.62, // 150 degrés
      1.05, // 60 degrés
      true,
      paint,
    );

    // Vert (partie basse)
    paint.color = const Color(0xFF34A853);
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      3.67, // 210 degrés
      1.05, // 60 degrés
      true,
      paint,
    );

    // Centre blanc (pour créer l'effet "G")
    paint.color = Colors.white;
    canvas.drawCircle(center, radius * 0.45, paint);

    // Partie bleue centrale (complète le "G")
    paint.color = const Color(0xFF4285F4);
    final path = Path();
    path.moveTo(center.dx, center.dy - radius * 0.45);
    path.lineTo(center.dx + radius, center.dy - radius * 0.45);
    path.lineTo(center.dx + radius, center.dy + radius * 0.15);
    path.lineTo(center.dx + radius * 0.45, center.dy + radius * 0.15);
    path.lineTo(center.dx + radius * 0.45, center.dy - radius * 0.15);
    path.lineTo(center.dx + radius * 0.7, center.dy - radius * 0.15);
    path.lineTo(center.dx + radius * 0.7, center.dy);
    path.lineTo(center.dx, center.dy);
    path.close();
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
