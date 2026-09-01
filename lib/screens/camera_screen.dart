import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../models/frame_style.dart';
import '../services/settings_service.dart';
import '../widgets/frame_painter.dart';
import 'preview_screen.dart';

class CameraScreen extends StatefulWidget {
  final List<CameraDescription> cameras;
  const CameraScreen({super.key, required this.cameras});

  @override
  State<CameraScreen> createState() => _CameraScreenState();
}

class _CameraScreenState extends State<CameraScreen> with WidgetsBindingObserver {
  CameraController? _controller;
  Future<void>? _initFuture;
  FrameStyle _selectedFrame = FrameStyle.classic;
  String _clubName = '';
  String _comment = '';
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _initCamera();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final clubName = await SettingsService.loadClubName();
    final comment = await SettingsService.loadComment();
    final frameIndex = await SettingsService.loadFrameIndex();
    if (!mounted) return;
    setState(() {
      _clubName = clubName;
      _comment = comment;
      _selectedFrame =
          FrameStyle.values[frameIndex.clamp(0, FrameStyle.values.length - 1)];
    });
  }

  void _initCamera() {
    if (widget.cameras.isEmpty) return;
    final camera = widget.cameras.firstWhere(
      (c) => c.lensDirection == CameraLensDirection.back,
      orElse: () => widget.cameras.first,
    );
    _controller = CameraController(camera, ResolutionPreset.max, enableAudio: false);
    _initFuture = _controller!.initialize();
    setState(() {});
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _controller?.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    final controller = _controller;
    if (controller == null || !controller.value.isInitialized) return;
    if (state == AppLifecycleState.inactive) {
      controller.dispose();
    } else if (state == AppLifecycleState.resumed) {
      _initCamera();
    }
  }

  Future<void> _editText({
    required String title,
    required String initial,
    required ValueChanged<String> onSave,
  }) async {
    final controller = TextEditingController(text: initial);
    final result = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(title),
        content: TextField(controller: controller, autofocus: true, maxLength: 30),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('취소')),
          TextButton(
              onPressed: () => Navigator.pop(ctx, controller.text),
              child: const Text('저장')),
        ],
      ),
    );
    if (result != null) onSave(result);
  }

  Future<void> _capture() async {
    final controller = _controller;
    if (controller == null || !controller.value.isInitialized || _busy) return;
    setState(() => _busy = true);
    try {
      final file = await controller.takePicture();
      // XFile.readAsBytes()로 바로 읽는다 - dart:io의 File(path)는 웹에서 아예 지원되지
      // 않고(카메라 캡처 결과가 blob: URL이라 File로 열 수도 없음), XFile은 모바일/웹 양쪽에서
      // 똑같이 동작해서 플랫폼 분기 없이 PreviewScreen까지 바이트로만 넘기면 된다.
      final bytes = await file.readAsBytes();
      if (!mounted) return;
      await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => PreviewScreen(
            imageBytes: bytes,
            frameStyle: _selectedFrame,
            clubName: _clubName,
            comment: _comment,
          ),
        ),
      );
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final dateText = DateFormat('yyyy.MM.dd').format(DateTime.now());
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: _controller == null
                  ? const Center(
                      child: Text('카메라를 찾을 수 없습니다',
                          style: TextStyle(color: Colors.white)))
                  : FutureBuilder<void>(
                      future: _initFuture,
                      builder: (context, snapshot) {
                        if (snapshot.connectionState != ConnectionState.done) {
                          return const Center(child: CircularProgressIndicator());
                        }
                        return Center(
                          child: AspectRatio(
                            aspectRatio: 1 / _controller!.value.aspectRatio,
                            child: Stack(
                              fit: StackFit.expand,
                              children: [
                                CameraPreview(_controller!),
                                CustomPaint(
                                  painter: PhotoFramePainter(
                                    style: _selectedFrame,
                                    clubName: _clubName.isEmpty ? '산악회 이름' : _clubName,
                                    dateText: dateText,
                                    comment: _comment,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
            ),
            _buildControls(),
          ],
        ),
      ),
    );
  }

  Widget _buildControls() {
    return Container(
      color: Colors.black,
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            height: 74,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              itemCount: FrameStyle.values.length,
              separatorBuilder: (_, __) => const SizedBox(width: 10),
              itemBuilder: (context, index) {
                final style = FrameStyle.values[index];
                final selected = style == _selectedFrame;
                return GestureDetector(
                  onTap: () {
                    setState(() => _selectedFrame = style);
                    SettingsService.saveFrameIndex(index);
                  },
                  child: Column(
                    children: [
                      Container(
                        width: 52,
                        height: 52,
                        decoration: BoxDecoration(
                          border: Border.all(
                              color: selected ? Colors.amber : Colors.white24,
                              width: selected ? 2.5 : 1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        clipBehavior: Clip.hardEdge,
                        child: Stack(
                          fit: StackFit.expand,
                          children: [
                            Container(color: const Color(0xFF3A506B)),
                            CustomPaint(
                              painter: PhotoFramePainter(
                                style: style,
                                clubName: '산악회',
                                dateText: '01.01',
                                comment: '산행',
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(style.label,
                          style: const TextStyle(color: Colors.white70, fontSize: 10)),
                    ],
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 6),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _editButton(
                icon: Icons.groups,
                label: _clubName.isEmpty ? '산악회 이름' : _clubName,
                onTap: () => _editText(
                  title: '산악회 이름',
                  initial: _clubName,
                  onSave: (value) {
                    setState(() => _clubName = value);
                    SettingsService.saveClubName(value);
                  },
                ),
              ),
              GestureDetector(
                onTap: _capture,
                child: Container(
                  width: 70,
                  height: 70,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: _busy ? Colors.grey : Colors.white,
                    border: Border.all(color: Colors.white54, width: 3),
                  ),
                  child: _busy
                      ? const Padding(
                          padding: EdgeInsets.all(20), child: CircularProgressIndicator())
                      : null,
                ),
              ),
              _editButton(
                icon: Icons.edit_note,
                label: _comment.isEmpty ? '한마디' : _comment,
                onTap: () => _editText(
                  title: '한마디 (멘트)',
                  initial: _comment,
                  onSave: (value) {
                    setState(() => _comment = value);
                    SettingsService.saveComment(value);
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _editButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: SizedBox(
        width: 100,
        child: Column(
          children: [
            Icon(icon, color: Colors.white70),
            Text(
              label,
              style: const TextStyle(color: Colors.white70, fontSize: 11),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
