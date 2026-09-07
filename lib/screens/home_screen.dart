import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../models/frame_style.dart';
import '../services/settings_service.dart';
import '../widgets/frame_painter.dart';
import '../widgets/mountain_hero_illustration.dart';
import 'camera_screen.dart';
import 'preview_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  bool _loadingPhoto = false;
  FrameStyle _selectedFrame = FrameStyle.classic;

  @override
  void initState() {
    super.initState();
    _loadFrame();
  }

  Future<void> _loadFrame() async {
    final index = await SettingsService.loadFrameIndex();
    if (!mounted) return;
    setState(() {
      _selectedFrame = FrameStyle.values[index.clamp(0, FrameStyle.values.length - 1)];
    });
  }

  void _openCamera() {
    Navigator.push(context, MaterialPageRoute(builder: (_) => const CameraScreen()));
  }

  Future<void> _pickFromGallery() async {
    if (_loadingPhoto) return;
    setState(() => _loadingPhoto = true);
    try {
      final picked = await ImagePicker().pickImage(source: ImageSource.gallery);
      if (picked == null) return;
      final bytes = await picked.readAsBytes();

      // 카메라 화면에서 저장했던 산악회 이름/한마디를 그대로 이어받아,
      // 불러온 사진에도 같은 설정(프레임 포함)으로 바로 합성 미리보기를 보여준다.
      final clubName = await SettingsService.loadClubName();
      final comment = await SettingsService.loadComment();

      if (!mounted) return;
      await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => PreviewScreen(
            imageBytes: bytes,
            frameStyle: _selectedFrame,
            clubName: clubName,
            comment: comment,
          ),
        ),
      );
    } finally {
      if (mounted) setState(() => _loadingPhoto = false);
    }
  }

  Future<void> _pickFrame() async {
    final index = await showModalBottomSheet<int>(
      context: context,
      backgroundColor: const Color(0xFF14181D),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Padding(
                padding: EdgeInsets.only(bottom: 16),
                child: Text('프레임 선택',
                    style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w600)),
              ),
              SizedBox(
                height: 96,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: FrameStyle.values.length,
                  separatorBuilder: (_, _) => const SizedBox(width: 14),
                  itemBuilder: (context, i) {
                    final style = FrameStyle.values[i];
                    final selected = style == _selectedFrame;
                    return GestureDetector(
                      onTap: () => Navigator.pop(ctx, i),
                      child: Column(
                        children: [
                          _FrameSwatch(style: style, size: 60, selected: selected),
                          const SizedBox(height: 4),
                          Text(style.label,
                              style: const TextStyle(color: Colors.white70, fontSize: 11)),
                        ],
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
    if (index == null) return;
    setState(() => _selectedFrame = FrameStyle.values[index]);
    await SettingsService.saveFrameIndex(index);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Column(
          children: [
            // 일러스트는 버튼 바를 뺀 나머지 영역에만 그려지므로, 화면 비율이
            // 바뀌어도 등산객 그림이 아래쪽 버튼 바에 가려지지 않는다.
            Expanded(
              child: Stack(
                fit: StackFit.expand,
                children: [
                  const MountainHeroIllustration(),
                  Padding(
                    padding: const EdgeInsets.only(top: 24),
                    child: Text(
                      '산악회 사진',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 26,
                        fontWeight: FontWeight.bold,
                        shadows: [
                          Shadow(
                              color: Colors.black.withValues(alpha: 0.5),
                              blurRadius: 8,
                              offset: const Offset(0, 2)),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Container(
              width: double.infinity,
              color: Colors.black,
              padding: const EdgeInsets.fromLTRB(24, 20, 24, 20),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _HomeButton(icon: Icons.photo_camera, label: '사진 찍기', onTap: _openCamera),
                  _FrameHomeButton(style: _selectedFrame, onTap: _pickFrame),
                  _HomeButton(
                    icon: Icons.photo_library,
                    label: '사진 불러오기',
                    onTap: _pickFromGallery,
                    busy: _loadingPhoto,
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

class _HomeButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool busy;

  const _HomeButton({
    required this.icon,
    required this.label,
    required this.onTap,
    this.busy = false,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: busy ? null : onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 76,
            height: 76,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white.withValues(alpha: 0.14),
              border: Border.all(color: Colors.white70, width: 2),
            ),
            child: busy
                ? const Padding(
                    padding: EdgeInsets.all(24),
                    child: CircularProgressIndicator(color: Colors.white))
                : Icon(icon, color: Colors.white, size: 32),
          ),
          const SizedBox(height: 8),
          Text(label,
              style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}

// 두 버튼 사이에 놓인 프레임 선택 버튼. 현재 선택된 프레임의 미리보기를
// 원형 배지 안에 보여주고, 탭하면 프레임 목록 바텀시트가 뜬다.
class _FrameHomeButton extends StatelessWidget {
  final FrameStyle style;
  final VoidCallback onTap;

  const _FrameHomeButton({required this.style, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white70, width: 2),
            ),
            clipBehavior: Clip.hardEdge,
            child: _FrameSwatch(style: style, size: 56, selected: false),
          ),
          const SizedBox(height: 8),
          const Text('프레임', style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}

class _FrameSwatch extends StatelessWidget {
  final FrameStyle style;
  final double size;
  final bool selected;

  const _FrameSwatch({required this.style, required this.size, required this.selected});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        border: Border.all(color: selected ? Colors.amber : Colors.white24, width: selected ? 2.5 : 1),
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
    );
  }
}
