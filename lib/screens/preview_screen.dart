import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:gal/gal.dart';

import '../models/frame_style.dart';
import '../widgets/frame_painter.dart';

class PreviewScreen extends StatefulWidget {
  final String imagePath;
  final FrameStyle frameStyle;
  final String clubName;
  final String comment;

  const PreviewScreen({
    super.key,
    required this.imagePath,
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
    final bytes = await File(widget.imagePath).readAsBytes();
    final codec = await ui.instantiateImageCodec(bytes);
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
