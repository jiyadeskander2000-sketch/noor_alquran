import 'dart:math' as math;
import 'package:flutter/material.dart';

class NoorLogo extends StatelessWidget {
  const NoorLogo({super.key, this.size = 40, this.elevation = 4.0});

  final double size;
  final double elevation;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        boxShadow: elevation > 0
            ? [
                BoxShadow(
                  color: const Color(0xFFD4AF37).withValues(alpha: 0.35),
                  blurRadius: size * 0.22,
                  spreadRadius: 1,
                  offset: Offset(0, size * 0.05),
                ),
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.3),
                  blurRadius: size * 0.15,
                  offset: Offset(0, size * 0.08),
                ),
              ]
            : null,
      ),
      child: ClipOval(
        child: CustomPaint(
          size: Size(size, size),
          painter: NoorMajesticLogoPainter(),
        ),
      ),
    );
  }
}

class NoorMajesticLogoPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final scale = size.width / 128.0;
    canvas.save();
    canvas.scale(scale);

    const center = Offset(64, 64);
    const radius = 63.0;

    // 1. Deep Islamic Emerald Radial Gradient Background
    final bgPaint = Paint()
      ..shader = const RadialGradient(
        colors: [
          Color(0xFF0F4F3B), // Vibrant emerald heart
          Color(0xFF0B382A), // Rich forest emerald
          Color(0xFF051B13), // Deep royal midnight green
        ],
        stops: [0.0, 0.65, 1.0],
      ).createShader(Rect.fromCircle(center: center, radius: radius));
    canvas.drawCircle(center, radius, bgPaint);

    // 2. Divine Noor Rays (Beaming upwards from the Quran)
    final rayPaint = Paint()
      ..style = PaintingStyle.fill
      ..shader = RadialGradient(
        center: const Alignment(0, 0.2),
        colors: [
          const Color(0xFFFDE68A).withValues(alpha: 0.35),
          const Color(0xFFEAB308).withValues(alpha: 0.15),
          Colors.transparent,
        ],
        stops: const [0.0, 0.5, 1.0],
      ).createShader(const Rect.fromLTWH(0, 0, 128, 128));

    for (int i = -3; i <= 3; i++) {
      final rayAngle = -math.pi / 2 + (i * 0.18);
      final rayPath = Path()
        ..moveTo(64, 76)
        ..lineTo(64 + math.cos(rayAngle - 0.06) * 58, 76 + math.sin(rayAngle - 0.06) * 58)
        ..lineTo(64 + math.cos(rayAngle + 0.06) * 58, 76 + math.sin(rayAngle + 0.06) * 58)
        ..close();
      canvas.drawPath(rayPath, rayPaint);
    }

    // 3. Islamic Octagram Star Border (ثماني إسلامي هندسي ملكي)
    final goldShader = const LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [
        Color(0xFFFFF3C4), // Bright golden light
        Color(0xFFF5D061), // Rich warm gold
        Color(0xFFD4AF37), // Classic metallic gold
        Color(0xFFA67C1E), // Deep antique bronze gold
        Color(0xFFFEE685), // Highlight
      ],
      stops: [0.0, 0.25, 0.55, 0.85, 1.0],
    ).createShader(const Rect.fromLTWH(0, 0, 128, 128));

    final starPaint = Paint()
      ..shader = goldShader
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;

    // Draw two interlocking 45-degree rounded squares for the Islamic 8-pointed star
    for (int pass = 0; pass < 2; pass++) {
      canvas.save();
      canvas.translate(64, 64);
      canvas.rotate(pass * math.pi / 4);
      final rrect = RRect.fromRectAndRadius(
        Rect.fromCenter(center: Offset.zero, width: 104, height: 104),
        const Radius.circular(10),
      );
      canvas.drawRRect(rrect, starPaint);
      canvas.restore();
    }

    // Inner Delicate Golden Circle Ring
    final innerRingPaint = Paint()
      ..shader = goldShader
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2;
    canvas.drawCircle(center, 54, innerRingPaint);

    // Decorative Golden Dots at 8 Cardinal Nodes
    final dotPaint = Paint()..shader = goldShader;
    for (int i = 0; i < 8; i++) {
      final angle = i * math.pi / 4;
      final dotPos = Offset(64 + math.cos(angle) * 54, 64 + math.sin(angle) * 54);
      canvas.drawCircle(dotPos, 2.0, dotPaint);
    }

    // 4. Wooden Carved Rehal / Book Stand (حامل المصحف الخشبي المذهب)
    final rehalPaint = Paint()
      ..color = const Color(0xFF6B4423)
      ..style = PaintingStyle.fill;
    final rehalBorder = Paint()
      ..shader = goldShader
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.4;

    final rehalPath = Path()
      ..moveTo(42, 94)
      ..lineTo(64, 84)
      ..lineTo(86, 94)
      ..lineTo(80, 102)
      ..lineTo(64, 91)
      ..lineTo(48, 102)
      ..close();
    canvas.drawPath(rehalPath, rehalPaint);
    canvas.drawPath(rehalPath, rehalBorder);

    // 5. Open Holy Quran Pages (المصحف الشريف المفتوح بنعومة وتذهيب)
    final pageBgShader = const LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [Color(0xFFFFFDF5), Color(0xFFF4EDE0)],
    ).createShader(const Rect.fromLTWH(26, 60, 76, 32));

    final pageFill = Paint()
      ..shader = pageBgShader
      ..style = PaintingStyle.fill;

    final pageBorder = Paint()
      ..shader = goldShader
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.8
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    // Left Page with natural curvature
    final leftPage = Path()
      ..moveTo(64, 82)
      ..quadraticBezierTo(46, 73, 27, 74)
      ..quadraticBezierTo(25, 87, 29, 93)
      ..quadraticBezierTo(47, 91, 64, 96)
      ..close();

    // Right Page with natural curvature
    final rightPage = Path()
      ..moveTo(64, 82)
      ..quadraticBezierTo(82, 73, 101, 74)
      ..quadraticBezierTo(103, 87, 99, 93)
      ..quadraticBezierTo(81, 91, 64, 96)
      ..close();

    // Draw Pages with Subtle Drop Shadows
    canvas.drawShadow(leftPage, Colors.black, 4, false);
    canvas.drawShadow(rightPage, Colors.black, 4, false);
    canvas.drawPath(leftPage, pageFill);
    canvas.drawPath(rightPage, pageFill);
    canvas.drawPath(leftPage, pageBorder);
    canvas.drawPath(rightPage, pageBorder);

    // Page Ruling / Gilded Script Lines (آيات وتذهيب متقن)
    final textLinePaint = Paint()
      ..color = const Color(0xFFD4AF37).withValues(alpha: 0.7)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.3
      ..strokeCap = StrokeCap.round;

    // Left Page Lines
    canvas.drawLine(const Offset(35, 78), const Offset(57, 77), textLinePaint);
    canvas.drawLine(const Offset(34, 83), const Offset(58, 82), textLinePaint);
    canvas.drawLine(const Offset(36, 88), const Offset(56, 87), textLinePaint);

    // Right Page Lines
    canvas.drawLine(const Offset(71, 77), const Offset(93, 78), textLinePaint);
    canvas.drawLine(const Offset(70, 82), const Offset(94, 83), textLinePaint);
    canvas.drawLine(const Offset(72, 87), const Offset(92, 88), textLinePaint);

    // Center Quran Spine & Bookmark Ribbon (الفاصل الشريطي المعلق)
    final spinePaint = Paint()
      ..shader = goldShader
      ..strokeWidth = 2.5
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(const Offset(64, 80), const Offset(64, 97), spinePaint);

    final ribbonPath = Path()
      ..moveTo(64, 95)
      ..quadraticBezierTo(61, 101, 65, 107)
      ..lineTo(63, 107)
      ..lineTo(64, 95);
    canvas.drawPath(ribbonPath, Paint()..shader = goldShader..style = PaintingStyle.stroke..strokeWidth = 2.0);

    // 6. Polished Majestic Golden Crescent Moon (الهلال الذهبي الملكي البراق)
    final crescentShader = const LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [
        Color(0xFFFFF9DB), // Shimmering light highlight
        Color(0xFFF7D154), // Royal gold
        Color(0xFFD4AF37), // Classic gold
        Color(0xFFA67C1E), // Deep shadow edge
      ],
      stops: [0.0, 0.35, 0.7, 1.0],
    ).createShader(const Rect.fromLTWH(42, 22, 44, 46));

    final crescentPaint = Paint()
      ..shader = crescentShader
      ..style = PaintingStyle.fill;

    // Outer & Inner arcs for a sleek, sharp royal crescent
    final crescentPath = Path()
      ..moveTo(64, 25)
      ..cubicTo(79, 25, 88, 36, 88, 50)
      ..cubicTo(88, 62, 77, 72, 63, 72)
      ..cubicTo(73, 67, 79, 58, 79, 49)
      ..cubicTo(79, 39, 72, 31, 64, 25)
      ..close();

    canvas.drawShadow(crescentPath, const Color(0xFFD4AF37).withValues(alpha: 0.6), 6, false);
    canvas.drawPath(crescentPath, crescentPaint);

    // 7. Sparkling 8-Pointed Star Inside Crescent (نجمة الهدى والنور)
    final starCenter = const Offset(61, 46);
    final starPath = Path();
    for (int i = 0; i < 16; i++) {
      final r = (i % 2 == 0) ? 9.0 : 3.8;
      final angle = i * math.pi / 8 - math.pi / 2;
      final x = starCenter.dx + math.cos(angle) * r;
      final y = starCenter.dy + math.sin(angle) * r;
      if (i == 0) {
        starPath.moveTo(x, y);
      } else {
        starPath.lineTo(x, y);
      }
    }
    starPath.close();

    canvas.drawShadow(starPath, const Color(0xFFFDE68A), 5, false);
    canvas.drawPath(starPath, Paint()..shader = crescentShader..style = PaintingStyle.fill);

    // Central Diamond Flare on the Star
    final flarePaint = Paint()..color = Colors.white;
    canvas.drawCircle(starCenter, 1.6, flarePaint);

    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
