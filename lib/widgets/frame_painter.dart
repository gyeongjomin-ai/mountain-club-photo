import 'dart:math' as math;
import 'package:flutter/material.dart';

import '../models/frame_style.dart';

class PhotoFramePainter extends CustomPainter {
  final FrameStyle style;
  final String clubName;
  final String dateText;
  final String comment;

  PhotoFramePainter({
    required this.style,
    required this.clubName,
    required this.dateText,
    required this.comment,
  });

  @override
  void paint(Canvas canvas, Size size) {
    switch (style) {
      case FrameStyle.classic:
        _paintClassic(canvas, size);
        break;
      case FrameStyle.forest:
        _paintForest(canvas, size);
        break;
      case FrameStyle.filmStrip:
        _paintFilmStrip(canvas, size);
        break;
      case FrameStyle.polaroid:
        _paintPolaroid(canvas, size);
        break;
      case FrameStyle.ribbon:
        _paintRibbon(canvas, size);
        break;
      case FrameStyle.templeValley:
      case FrameStyle.lanternGorge:
      case FrameStyle.ganggu:
        // 일러스트 프레임은 이 페인터가 아니라 CameraScreen/PreviewScreen에서
        // 직접 asset 이미지를 합성하는 별도 경로로 그려진다.
        break;
    }
  }

  @override
  bool shouldRepaint(covariant PhotoFramePainter oldDelegate) {
    return oldDelegate.style != style ||
        oldDelegate.clubName != clubName ||
        oldDelegate.dateText != dateText ||
        oldDelegate.comment != comment;
  }

  void _text(
    Canvas canvas, {
    required String text,
    required Offset center,
    required double fontSize,
    required Color color,
    FontWeight weight = FontWeight.w600,
    FontStyle style = FontStyle.normal,
    double letterSpacing = 0,
    double maxWidth = double.infinity,
  }) {
    if (text.isEmpty) return;
    final tp = TextPainter(
      text: TextSpan(
        text: text,
        style: TextStyle(
          color: color,
          fontSize: fontSize,
          fontWeight: weight,
          fontStyle: style,
          letterSpacing: letterSpacing,
        ),
      ),
      textAlign: TextAlign.center,
      textDirection: TextDirection.ltr,
      maxLines: 1,
      ellipsis: '…',
    )..layout(maxWidth: maxWidth);
    tp.paint(canvas, center - Offset(tp.width / 2, tp.height / 2));
  }

  // ---------------- 1. classic: museum-style border with bottom banner ----------------
  void _paintClassic(Canvas canvas, Size size) {
    final short = math.min(size.width, size.height);
    final border = short * 0.045;
    const navy = Color(0xFF17233F);
    const gold = Color(0xFFC9A24B);

    final outer = Paint()..color = navy;
    final path = Path()
      ..addRect(Rect.fromLTWH(0, 0, size.width, size.height))
      ..addRect(Rect.fromLTWH(
          border, border, size.width - border * 2, size.height - border * 2))
      ..fillType = PathFillType.evenOdd;
    canvas.drawPath(path, outer);

    final innerLine = Paint()
      ..color = gold
      ..style = PaintingStyle.stroke
      ..strokeWidth = short * 0.006;
    canvas.drawRect(
      Rect.fromLTWH(border * 0.6, border * 0.6, size.width - border * 1.2,
          size.height - border * 1.2),
      innerLine,
    );

    final bannerHeight = size.height * 0.16;
    final bannerRect = Rect.fromLTWH(border, size.height - border - bannerHeight,
        size.width - border * 2, bannerHeight);
    canvas.drawRect(bannerRect, Paint()..color = navy.withValues(alpha: 0.85));
    canvas.drawLine(
      Offset(bannerRect.left + short * 0.05, bannerRect.top),
      Offset(bannerRect.right - short * 0.05, bannerRect.top),
      Paint()
        ..color = gold
        ..strokeWidth = short * 0.004,
    );

    _text(canvas,
        text: clubName,
        center: Offset(size.width / 2, bannerRect.top + bannerRect.height * 0.36),
        fontSize: short * 0.058,
        color: Colors.white,
        weight: FontWeight.bold,
        maxWidth: bannerRect.width * 0.92);
    _text(canvas,
        text: [dateText, comment].where((s) => s.isNotEmpty).join('   ·   '),
        center: Offset(size.width / 2, bannerRect.top + bannerRect.height * 0.74),
        fontSize: short * 0.032,
        color: gold,
        weight: FontWeight.w500,
        maxWidth: bannerRect.width * 0.92);
  }

  // ---------------- 2. forest: green gradient border with badge ----------------
  void _paintForest(Canvas canvas, Size size) {
    final short = math.min(size.width, size.height);
    final border = short * 0.035;
    const darkGreen = Color(0xFF1B4332);
    const lightGreen = Color(0xFF74C69D);

    final borderPaint = Paint()
      ..shader = const LinearGradient(
        colors: [darkGreen, lightGreen],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));

    final path = Path()
      ..addRect(Rect.fromLTWH(0, 0, size.width, size.height))
      ..addRect(Rect.fromLTWH(
          border, border, size.width - border * 2, size.height - border * 2))
      ..fillType = PathFillType.evenOdd;
    canvas.drawPath(path, borderPaint);

    final flagPaint = Paint()..color = lightGreen;
    final flagSize = short * 0.09;
    canvas.drawPath(
      Path()
        ..moveTo(0, 0)
        ..lineTo(flagSize, 0)
        ..lineTo(0, flagSize)
        ..close(),
      flagPaint,
    );
    canvas.drawPath(
      Path()
        ..moveTo(size.width, 0)
        ..lineTo(size.width - flagSize, 0)
        ..lineTo(size.width, flagSize)
        ..close(),
      flagPaint,
    );

    final badgeWidth = size.width * 0.62;
    final badgeRect = RRect.fromRectAndRadius(
      Rect.fromCenter(
          center: Offset(size.width / 2, border + short * 0.06),
          width: badgeWidth,
          height: short * 0.09),
      Radius.circular(short * 0.045),
    );
    canvas.drawRRect(badgeRect, Paint()..color = darkGreen.withValues(alpha: 0.88));
    _text(canvas,
        text: clubName,
        center: badgeRect.center,
        fontSize: short * 0.042,
        color: Colors.white,
        weight: FontWeight.bold,
        maxWidth: badgeWidth * 0.9);

    final stripHeight = size.height * 0.14;
    final stripRect = Rect.fromLTWH(border, size.height - border - stripHeight,
        size.width - border * 2, stripHeight);
    canvas.drawRect(
      stripRect,
      Paint()
        ..shader = LinearGradient(
          colors: [Colors.black.withValues(alpha: 0.0), Colors.black.withValues(alpha: 0.65)],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ).createShader(stripRect),
    );

    _text(canvas,
        text: dateText,
        center: Offset(stripRect.left + stripRect.width * 0.27,
            stripRect.bottom - stripRect.height * 0.3),
        fontSize: short * 0.034,
        color: Colors.white,
        weight: FontWeight.w600,
        maxWidth: stripRect.width * 0.45);
    _text(canvas,
        text: comment,
        center: Offset(stripRect.left + stripRect.width * 0.73,
            stripRect.bottom - stripRect.height * 0.3),
        fontSize: short * 0.034,
        color: Colors.white,
        weight: FontWeight.w500,
        maxWidth: stripRect.width * 0.48);
  }

  // ---------------- 3. filmStrip: black bars with sprocket holes ----------------
  void _paintFilmStrip(Canvas canvas, Size size) {
    final short = math.min(size.width, size.height);
    final barHeight = size.height * 0.11;
    final barPaint = Paint()..color = Colors.black;

    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, barHeight), barPaint);
    canvas.drawRect(
        Rect.fromLTWH(0, size.height - barHeight, size.width, barHeight), barPaint);

    final holeRadius = barHeight * 0.16;
    final holePaint = Paint()..color = Colors.white.withValues(alpha: 0.85);
    final holeSpacing = holeRadius * 4.2;
    final holeCount = math.max(2, (size.width / holeSpacing).floor());
    final startX = (size.width - (holeCount - 1) * holeSpacing) / 2;
    for (var i = 0; i < holeCount; i++) {
      final cx = startX + i * holeSpacing;
      canvas.drawCircle(Offset(cx, barHeight * 0.5), holeRadius, holePaint);
      canvas.drawCircle(Offset(cx, size.height - barHeight * 0.5), holeRadius, holePaint);
    }

    _text(canvas,
        text: clubName.toUpperCase(),
        center: Offset(size.width / 2, barHeight * 0.5),
        fontSize: short * 0.042,
        color: Colors.white,
        weight: FontWeight.bold,
        letterSpacing: short * 0.003,
        maxWidth: size.width * 0.58);

    _text(canvas,
        text: [dateText, comment].where((s) => s.isNotEmpty).join('   ·   '),
        center: Offset(size.width / 2, size.height - barHeight * 0.5),
        fontSize: short * 0.03,
        color: Colors.white,
        weight: FontWeight.w500,
        maxWidth: size.width * 0.7);
  }

  // ---------------- 4. polaroid: thick bottom border, mountain icon ----------------
  void _paintPolaroid(Canvas canvas, Size size) {
    final short = math.min(size.width, size.height);
    final thin = short * 0.035;
    final thickBottom = size.height * 0.22;
    final white = Paint()..color = Colors.white;

    final path = Path()
      ..addRect(Rect.fromLTWH(0, 0, size.width, size.height))
      ..addRect(Rect.fromLTWH(thin, thin, size.width - thin * 2,
          size.height - thin - thickBottom))
      ..fillType = PathFillType.evenOdd;
    canvas.drawPath(path, white);

    final iconPaint = Paint()..color = const Color(0xFF3A5A40);
    final baseY = size.height - thickBottom * 0.42;
    final iconX = size.width * 0.14;
    final iconSize = thickBottom * 0.42;
    canvas.drawPath(
      Path()
        ..moveTo(iconX - iconSize, baseY + iconSize * 0.5)
        ..lineTo(iconX - iconSize * 0.15, baseY - iconSize * 0.6)
        ..lineTo(iconX + iconSize * 0.35, baseY + iconSize * 0.1)
        ..lineTo(iconX + iconSize * 0.75, baseY - iconSize * 0.35)
        ..lineTo(iconX + iconSize * 1.3, baseY + iconSize * 0.5)
        ..close(),
      iconPaint,
    );

    _text(canvas,
        text: clubName,
        center: Offset(size.width * 0.6, size.height - thickBottom * 0.62),
        fontSize: short * 0.052,
        color: const Color(0xFF2B2B2B),
        weight: FontWeight.w700,
        style: FontStyle.italic,
        maxWidth: size.width * 0.6);

    _text(canvas,
        text: [dateText, comment].where((s) => s.isNotEmpty).join('   '),
        center: Offset(size.width * 0.6, size.height - thickBottom * 0.25),
        fontSize: short * 0.028,
        color: const Color(0xFF6B6B6B),
        maxWidth: size.width * 0.6);
  }

  // ---------------- 5. ribbon: diagonal corner banner + bottom strip ----------------
  void _paintRibbon(Canvas canvas, Size size) {
    final short = math.min(size.width, size.height);
    const accent = Color(0xFFD62828);

    canvas.save();
    final ribbonLength = short * 0.6;
    final ribbonWidth = short * 0.11;
    canvas.translate(0, ribbonWidth * 0.3);
    canvas.rotate(-math.pi / 4);
    canvas.drawRect(
      Rect.fromLTWH(-ribbonLength * 0.2, 0, ribbonLength, ribbonWidth),
      Paint()..color = accent,
    );
    _text(canvas,
        text: clubName,
        center: Offset(ribbonLength * 0.3, ribbonWidth * 0.5),
        fontSize: short * 0.038,
        color: Colors.white,
        weight: FontWeight.bold,
        maxWidth: ribbonLength * 0.75);
    canvas.restore();

    final stripHeight = size.height * 0.1;
    final stripRect = Rect.fromLTWH(0, size.height - stripHeight, size.width, stripHeight);
    canvas.drawRect(
      stripRect,
      Paint()
        ..shader = LinearGradient(
          colors: [Colors.black.withValues(alpha: 0.0), Colors.black.withValues(alpha: 0.7)],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ).createShader(stripRect),
    );
    _text(canvas,
        text: [dateText, comment].where((s) => s.isNotEmpty).join('   ·   '),
        center: Offset(size.width / 2, size.height - stripHeight * 0.4),
        fontSize: short * 0.032,
        color: Colors.white,
        weight: FontWeight.w500,
        maxWidth: size.width * 0.85);
  }
}
