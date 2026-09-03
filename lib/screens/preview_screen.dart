import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:gal/gal.dart';

import '../models/frame_style.dart';
import '../widgets/frame_painter.dart';
import '../widgets/illustrated_caption_painter.dart';

class PreviewScreen extends StatefulWidget {
  final Uint8List imageBytes;
  final FrameStyle frameStyle;
  final String clubName;
  final String comment;

  const PreviewScreen({
    super.key,
    required this.imageBytes,
    required this.frameStyle,
    required this.clubName,
    required this.comment,
  });

  @override
  State<PreviewScreen> createState() => _PreviewScreenState();
}

class _PreviewScreenState extends State<PreviewScreen> {
  bool _saving = false;
  Uint8List? _composed;

  @override
  void initState() {
    super.initState();
    _compose();
  }

  String get _dateText {
    final now = DateTime.now();
    return '${now.year}.${now.month.toString().padLeft(2, '0')}.${now.day.toString().padLeft(2, '0')}';
  }

  Future<void> _compose() async {
    final codec = await ui.instantiateImageCodec(widget.imageBytes);
    final frame = await codec.getNextFrame();
    final image = frame.image;
    final width = image.width.toDouble();
    final height = image.height.toDouble();

    final Uint8List bytes;
    if (widget.frameStyle.isIllustrated) {
      bytes = await _composeIllustrated(image, width, height);
    } else {
      bytes = await _composePainted(image, width, height);
    }
    if (!mounted) return;
    setState(() => _composed = bytes);
  }

  Future<Uint8List> _composePainted(ui.Image image, double width, double height) async {
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder, Rect.fromLTWH(0, 0, width, height));
    canvas.drawImage(image, Offset.zero, Paint());

    PhotoFramePainter(
      style: widget.frameStyle,
      clubName: widget.clubName.isEmpty ? '산악회' : widget.clubName,
      dateText: _dateText,
      comment: widget.comment,
    ).paint(canvas, Size(width, height));

    final picture = recorder.endRecording();
    final outputImage = await picture.toImage(width.toInt(), height.toInt());
    final byteData = await outputImage.toByteData(format: ui.ImageByteFormat.png);
    return byteData!.buffer.asUint8List();
  }

  // 사찰/계곡/강구항 프레임은 사진 위에 얇은 테두리를 그리는 방식이 아니라, 가운데가
  // 뚫린 삽화 전체가 캔버스를 채우는 방식이다. 라이브 카메라 화면(CameraScreen)에서
  // 항상 사진 전체를 창 안에 contain으로 보여주므로, 여기서도 동일하게 창 안에
  // contain으로만 넣어야 촬영 화면과 저장된 사진의 구도가 일치한다. 예전에는 사진
  // 비율이 창 비율과 비슷하면 카드 전체를 cover로 꽉 채우는 경로가 따로 있었지만,
  // 그러면 화면에서 본 것보다 사진이 크게 잘려 보여서(특히 세로 카드인 강구항에서
  // 세로 사진을 찍을 때 자주 발생) 제거했다.
  Future<Uint8List> _composeIllustrated(ui.Image image, double width, double height) async {
    final assetData = await rootBundle.load(widget.frameStyle.assetPath!);
    final frameCodec = await ui.instantiateImageCodec(assetData.buffer.asUint8List());
    final frameImage = (await frameCodec.getNextFrame()).image;
    final outW = frameImage.width.toDouble();
    final outH = frameImage.height.toDouble();

    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder, Rect.fromLTWH(0, 0, outW, outH));
    canvas.drawRect(
        Rect.fromLTWH(0, 0, outW, outH), Paint()..color = const Color(0xFFF0E6D2));

    final hole = widget.frameStyle.holeFraction!;
    final holeRect = Rect.fromLTRB(
        hole[0] * outW, hole[1] * outH, hole[2] * outW, hole[3] * outH);
    final scale = (holeRect.width / width < holeRect.height / height)
        ? holeRect.width / width
        : holeRect.height / height;
    final destW = width * scale;
    final destH = height * scale;
    final destRect = Rect.fromLTWH(
      holeRect.left + (holeRect.width - destW) / 2,
      holeRect.top + (holeRect.height - destH) / 2,
      destW,
      destH,
    );
    canvas.drawImageRect(
        image, Rect.fromLTWH(0, 0, width, height), destRect, Paint());
    canvas.drawImage(frameImage, Offset.zero, Paint());

    IllustratedCaptionPainter(
      style: widget.frameStyle,
      clubName: widget.clubName.isEmpty ? '산악회' : widget.clubName,
      dateText: _dateText,
      comment: widget.comment,
    ).paint(canvas, Size(outW, outH));

    final picture = recorder.endRecording();
    final outputImage = await picture.toImage(outW.toInt(), outH.toInt());
    final byteData = await outputImage.toByteData(format: ui.ImageByteFormat.png);
    return byteData!.buffer.asUint8List();
  }

  Future<void> _save() async {
    final composed = _composed;
    if (composed == null || _saving) return;
    // gal 패키지는 안드로이드/iOS/macOS만 지원하고 웹은 지원하지 않는다 - 웹에서 그대로
    // 호출하면 예외가 나므로, 미리보기 확인용 웹 빌드에서는 안내만 보여준다.
    if (kIsWeb) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('웹 미리보기에서는 갤러리 저장을 지원하지 않습니다. 앱(APK/iOS)에서 저장해주세요.')));
      return;
    }
    setState(() => _saving = true);
    try {
      final hasAccess = await Gal.hasAccess() || await Gal.requestAccess();
      if (!hasAccess) {
        if (mounted) {
          ScaffoldMessenger.of(context)
              .showSnackBar(const SnackBar(content: Text('사진 저장 권한이 필요합니다')));
        }
        return;
      }
      await Gal.putImageBytes(
        composed,
        album: '산악회사진',
        name: 'mountain_${DateTime.now().millisecondsSinceEpoch}',
      );
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text('갤러리에 저장되었습니다')));
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('저장 실패: $e')));
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: Center(
                child: _composed == null
                    ? const CircularProgressIndicator()
                    : Image.memory(_composed!),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  OutlinedButton.icon(
                    onPressed: _saving ? null : () => Navigator.pop(context),
                    icon: const Icon(Icons.refresh),
                    label: const Text('다시 찍기'),
                    style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.white,
                        side: const BorderSide(color: Colors.white54)),
                  ),
                  ElevatedButton.icon(
                    onPressed: _composed == null || _saving ? null : _save,
                    icon: _saving
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2))
                        : const Icon(Icons.download),
                    label: const Text('저장'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
