import 'dart:math' as math;

import 'package:flutter/material.dart';

/// 홈 화면 배경: 높은 봉우리 앞에서 산악회 회원들이 다같이 만세 포즈로 사진
/// 찍는 장면을 코드로 직접 그린 벡터 일러스트. 외부 이미지 없이
/// CustomPainter로 그리고, 구름 흐름 / 햇살 맥동 / 카메라 플래시 / 인물들의
/// 살짝 튀는 동작을 하나의 반복 애니메이션으로 묶어 정지된 그림 느낌을 지운다.
class MountainHeroIllustration extends StatefulWidget {
  const MountainHeroIllustration({super.key});

  @override
  State<MountainHeroIllustration> createState() => _MountainHeroIllustrationState();
}

class _MountainHeroIllustrationState extends State<MountainHeroIllustration>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: const Duration(seconds: 8))
      ..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        return CustomPaint(
          painter: _MountainScenePainter(t: _controller.value),
          size: Size.infinite,
        );
      },
    );
  }
}

class _MountainScenePainter extends CustomPainter {
  final double t; // 0..1, 반복되는 애니메이션 진행도

  _MountainScenePainter({required this.t});

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    _paintSky(canvas, w, h);
    _paintSun(canvas, w, h);
    _paintClouds(canvas, w, h);
    _paintMountains(canvas, w, h);
    _paintGroupPhotoPose(canvas, w, h);
  }

  void _paintSky(Canvas canvas, double w, double h) {
    final rect = Rect.fromLTWH(0, 0, w, h);
    final paint = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [Color(0xFF0B3D5C), Color(0xFF3E7CA6), Color(0xFFF2B675)],
        stops: [0.0, 0.55, 1.0],
      ).createShader(rect);
    canvas.drawRect(rect, paint);
  }

  void _paintSun(Canvas canvas, double w, double h) {
    final pulse = 0.5 + 0.5 * math.sin(t * 2 * math.pi);
    final center = Offset(w * 0.72, h * 0.26);
    final glowPaint = Paint()
      ..shader = RadialGradient(
        colors: [
          Colors.amberAccent.withValues(alpha: 0.35 + 0.15 * pulse),
          Colors.amberAccent.withValues(alpha: 0.0),
        ],
      ).createShader(Rect.fromCircle(center: center, radius: w * 0.22));
    canvas.drawCircle(center, w * 0.22, glowPaint);
    canvas.drawCircle(center, w * 0.05, Paint()..color = const Color(0xFFFFE8B0));
  }

  void _paintClouds(Canvas canvas, double w, double h) {
    final paint = Paint()..color = Colors.white.withValues(alpha: 0.55);
    _drawCloud(canvas, paint, w, h, baseX: 0.1, y: 0.2, scale: 1.0, speed: 0.18);
    _drawCloud(canvas, paint, w, h, baseX: 0.5, y: 0.13, scale: 0.7, speed: 0.12);
    _drawCloud(canvas, paint, w, h, baseX: 0.82, y: 0.3, scale: 0.85, speed: 0.22);
  }

  void _drawCloud(
    Canvas canvas,
    Paint paint,
    double w,
    double h, {
    required double baseX,
    required double y,
    required double scale,
    required double speed,
  }) {
    final travel = ((baseX + t * speed) % 1.3) - 0.15;
    final cx = travel * w;
    final cy = y * h;
    final r = 26.0 * scale;
    for (final dx in [-r, -r * 0.3, r * 0.3, r * 0.9]) {
      canvas.drawCircle(Offset(cx + dx, cy - (dx.abs() * 0.15)), r * 0.7, paint);
    }
  }

  void _paintMountains(Canvas canvas, double w, double h) {
    _mountainLayer(canvas, w, h,
        baseline: 0.7, peakY: 0.36, color: const Color(0xFF2E4A63), jitter: 0.02, seed: 1);
    _mountainLayer(canvas, w, h,
        baseline: 0.76, peakY: 0.46, color: const Color(0xFF3C6180), jitter: 0.03, seed: 2);
    _tallPeak(canvas, w, h);
    // 맨 앞 능선은 인물 그룹이 서는 자리(약 0.84h) 아래로만 낮게 깔아서, 봉우리 삼각형
    // 위에 서는 인물 실루엣이 이 짙은 능선 색과 겹쳐 묻히지 않게 한다.
    _mountainLayer(canvas, w, h,
        baseline: 0.97, peakY: 0.91, color: const Color(0xFF16232E), jitter: 0.01, seed: 3);
  }

  void _mountainLayer(
    Canvas canvas,
    double w,
    double h, {
    required double baseline,
    required double peakY,
    required Color color,
    required double jitter,
    required int seed,
  }) {
    final path = Path()..moveTo(0, h * baseline);
    final rnd = math.Random(seed);
    const steps = 6;
    for (int i = 0; i <= steps; i++) {
      final x = w * i / steps;
      final wobble = (rnd.nextDouble() - 0.5) * jitter * h;
      final y = h * (i.isOdd ? peakY : (peakY + baseline) / 2) + wobble;
      path.lineTo(x, y);
    }
    path
      ..lineTo(w, h * baseline)
      ..lineTo(w, h)
      ..lineTo(0, h)
      ..close();
    canvas.drawPath(path, Paint()..color = color);
  }

  void _tallPeak(Canvas canvas, double w, double h) {
    final path = Path()
      ..moveTo(w * 0.32, h * 0.84)
      ..lineTo(w * 0.5, h * 0.2)
      ..lineTo(w * 0.68, h * 0.84)
      ..close();
    canvas.drawPath(path, Paint()..color = const Color(0xFF4A7290));

    final snow = Path()
      ..moveTo(w * 0.5, h * 0.2)
      ..lineTo(w * 0.44, h * 0.31)
      ..lineTo(w * 0.47, h * 0.3)
      ..lineTo(w * 0.5, h * 0.36)
      ..lineTo(w * 0.53, h * 0.3)
      ..lineTo(w * 0.56, h * 0.31)
      ..close();
    canvas.drawPath(snow, Paint()..color = Colors.white.withValues(alpha: 0.92));
  }

  // 인물 그룹은 봉우리 삼각형의 밑변(약 0.84h) 위에 세워서, 짙은 몸통 실루엣이
  // 봉우리의 밝은 파란색을 배경으로 뚜렷하게 도드라지게 한다. 맨 앞 능선(위
  // _paintMountains의 마지막 레이어)은 이보다 훨씬 아래에 낮게 깔아서 겹치지 않는다.
  void _paintGroupPhotoPose(Canvas canvas, double w, double h) {
    final groundY = h * 0.84;
    const positions = [-0.09, -0.03, 0.03, 0.09];
    final flashPulse = math.sin(t * 2 * math.pi * 2) > 0.85;

    for (int i = 0; i < positions.length; i++) {
      final bounce = math.sin(t * 2 * math.pi + i * 1.3) * 4;
      final cx = w * 0.5 + positions[i] * w;
      final baseY = groundY - bounce;
      _drawHiker(canvas, cx, baseY, h * 0.024);
    }

    if (flashPulse) {
      canvas.drawCircle(
          Offset(w * 0.5, groundY - h * 0.16), h * 0.03, Paint()..color = Colors.white.withValues(alpha: 0.5));
    }
  }

  void _drawHiker(Canvas canvas, double cx, double groundY, double unit) {
    final bodyPaint = Paint()..color = const Color(0xFF16232E);
    // 배경이 밝은 봉우리든 어두운 능선이든 항상 도드라지도록, 실루엣 가장자리에
    // 옅은 흰색 테두리를 한 겹 더 그린다.
    final rimPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.55)
      ..style = PaintingStyle.stroke
      ..strokeWidth = unit * 0.22;

    final head = Rect.fromCircle(center: Offset(cx, groundY - unit * 3.6), radius: unit * 0.9);
    canvas.drawOval(head, bodyPaint);
    canvas.drawOval(head, rimPaint);

    final body = Path()
      ..moveTo(cx - unit * 0.9, groundY - unit * 0.4)
      ..lineTo(cx - unit * 0.6, groundY - unit * 2.7)
      ..lineTo(cx + unit * 0.6, groundY - unit * 2.7)
      ..lineTo(cx + unit * 0.9, groundY - unit * 0.4)
      ..close();
    canvas.drawPath(body, bodyPaint);
    canvas.drawPath(body, rimPaint);

    final armPaint = Paint()
      ..color = bodyPaint.color
      ..strokeWidth = unit * 0.45
      ..strokeCap = StrokeCap.round;
    final leftArm = [
      Offset(cx - unit * 0.55, groundY - unit * 2.4),
      Offset(cx - unit * 1.5, groundY - unit * 4.0),
    ];
    final rightArm = [
      Offset(cx + unit * 0.55, groundY - unit * 2.4),
      Offset(cx + unit * 1.5, groundY - unit * 4.0),
    ];
    final armRim = Paint()
      ..color = rimPaint.color
      ..strokeWidth = unit * 0.55
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(leftArm[0], leftArm[1], armRim);
    canvas.drawLine(rightArm[0], rightArm[1], armRim);
    canvas.drawLine(leftArm[0], leftArm[1], armPaint);
    canvas.drawLine(rightArm[0], rightArm[1], armPaint);
  }

  @override
  bool shouldRepaint(covariant _MountainScenePainter oldDelegate) => oldDelegate.t != t;
}
