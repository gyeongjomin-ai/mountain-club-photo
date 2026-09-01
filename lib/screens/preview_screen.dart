import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:gal/gal.dart';

import '../models/frame_style.dart';
import '../widgets/frame_painter.dart';

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
    if (!mounted) return;
    setState(() => _composed = byteData!.buffer.asUint8List());
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
