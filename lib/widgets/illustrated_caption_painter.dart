import 'package:flutter/material.dart';

import '../models/frame_style.dart';

/// 일러스트 프레임(사찰/계곡/강구항)은 사진 자체에는 텍스트를 넣을 자리가 없어서,
/// 삽화의 빈 여백에 산악회 이름/날짜/한마디를 겹쳐 그린다. 라이브 프리뷰와 최종
/// 합성 이미지 양쪽에서 동일한 상대 위치/크기로 그리기 위해 CustomPainter로 공유한다.
///
/// 사찰/계곡은 사진 박스 바로 아래 여백 한 곳에 이름+날짜+한마디를 한 배너로 모아
/// 그리고(captionCenterYFraction), 강구항은 원본 삽화의 제목 자리(사진 위쪽)에
/// 이름+날짜를, 사진 아래 여백에 한마디를 따로 그린다(titleBandCenterYFraction /
/// commentBandCenterYFraction).
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
    final combinedY = style.captionCenterYFraction;
    if (combinedY != null) {
      _paintCombinedBand(canvas, size, combinedY);
      return;
    }
    final titleY = style.titleBandCenterYFraction;
    if (titleY != null) {
      _paintTitle(canvas, size, titleY);
    }
    final commentY = style.commentBandCenterYFraction;
    if (commentY != null && comment.isNotEmpty) {
      _paintCommentBand(canvas, size, commentY);
    }
  }

  void _paintCombinedBand(Canvas canvas, Size size, double centerYFraction) {
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

  // 강구항: 원본 삽화의 텍스트 자리를 지우고 단색 패널로 남겨둔 곳이라 별도
  // 반투명 배경 없이 바로 이름(크게)+날짜(작게) 두 줄을 그린다.
  void _paintTitle(Canvas canvas, Size size, double centerYFraction) {
    final centerY = size.height * centerYFraction;
    _text(
      canvas,
      text: clubName,
      center: Offset(size.width / 2, centerY - size.height * 0.03),
      fontSize: size.width * 0.075,
      color: const Color(0xFF2A1A0E),
      weight: FontWeight.w900,
      maxWidth: size.width * 0.82,
    );
    if (dateText.isNotEmpty) {
      _text(
        canvas,
        text: dateText,
        center: Offset(size.width / 2, centerY + size.height * 0.045),
        fontSize: size.width * 0.032,
        color: const Color(0xFF5A4A38),
        weight: FontWeight.w600,
        maxWidth: size.width * 0.82,
      );
    }
  }

  void _paintCommentBand(Canvas canvas, Size size, double centerYFraction) {
    final centerY = size.height * centerYFraction;
    final bandRect = Rect.fromCenter(
      center: Offset(size.width / 2, centerY),
      width: size.width * 0.7,
      height: size.height * 0.05,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(bandRect, Radius.circular(size.height * 0.012)),
      Paint()..color = Colors.white.withValues(alpha: 0.65),
    );
    _text(
      canvas,
      text: comment,
      center: bandRect.center,
      fontSize: size.width * 0.024,
      color: const Color(0xFF3A2A1A),
      weight: FontWeight.w600,
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
