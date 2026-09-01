import 'package:flutter/material.dart';

import '../models/frame_style.dart';

/// 사찰/계곡 같은 일러스트 프레임은 사진 박스 아래쪽에 별도 텍스트 배너가 없어서,
/// 박스 하단과 삽화 하단 사이 여백에 산악회 이름/한마디를 겹쳐 그린다.
/// 라이브 프리뷰와 최종 합성 이미지 양쪽에서 동일한 상대 위치/크기로 그리기 위해
/// CustomPainter로 공유한다.
class IllustratedCaptionPainter extends CustomPainter {
  final FrameStyle style;
  final String clubName;
  final String dateText;
  final String comment;

  IllustratedCaptionPainter({
    required this.style,
    required this.clubName,
    required this.dateText,
    required this.comment,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final centerYFraction = style.captionCenterYFraction;
    if (centerYFraction == null) return;
    final centerY = size.height * centerYFraction;

    final bandRect = Rect.fromCenter(
      center: Offset(size.width / 2, centerY),
      width: size.width * 0.56,
      height: size.height * 0.12,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(bandRect, Radius.circular(size.height * 0.02)),
      Paint()..color = Colors.white.withValues(alpha: 0.6),
    );

    _text(
      canvas,
      text: clubName,
      center: Offset(size.width / 2, centerY - size.height * 0.028),
      fontSize: size.width * 0.028,
      color: const Color(0xFF3A2A1A),
      weight: FontWeight.bold,
      maxWidth: bandRect.width * 0.92,
    );
    final sub = [dateText, comment].where((s) => s.isNotEmpty).join('   ·   ');
    _text(
      canvas,
      text: sub,
      center: Offset(size.width / 2, centerY + size.height * 0.026),
      fontSize: size.width * 0.018,
      color: const Color(0xFF6B5A45),
      maxWidth: bandRect.width * 0.92,
    );
  }

  void _text(
    Canvas canvas, {
    required String text,
    required Offset center,
    required double fontSize,
    required Color color,
    FontWeight weight = FontWeight.w500,
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

  @override
  bool shouldRepaint(covariant IllustratedCaptionPainter oldDelegate) {
    return oldDelegate.style != style ||
        oldDelegate.clubName != clubName ||
        oldDelegate.dateText != dateText ||
        oldDelegate.comment != comment;
  }
}
