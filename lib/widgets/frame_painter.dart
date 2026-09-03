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
    _paintClassic(canvas, size);
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
    double maxWidth = double.infinity,
  }) {
    if (text.isEmpty) return;
    final tp = TextPainter(
      text: TextSpan(
        text: text,
        style: TextStyle(color: color, fontSize: fontSize, fontWeight: weight),
      ),
      textAlign: TextAlign.center,
      textDirection: TextDirection.ltr,
      maxLines: 1,
      ellipsis: '…',
    )..layout(maxWidth: maxWidth);
    tp.paint(canvas, center - Offset(tp.width / 2, tp.height / 2));
  }

  // museum-style border with bottom banner - 사진 위에 얇은 테두리만 그리는
  // 방식이라 세로/가로 어떤 비율의 사진이든 잘리거나 찌그러지지 않는다.
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
}
