import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../models/frame_style.dart';
import '../services/settings_service.dart';
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

      // 카메라 화면에서 골랐던 프레임/산악회 이름/한마디를 그대로 이어받아,
      // 불러온 사진에도 같은 설정으로 바로 합성 미리보기를 보여준다.
      final frameIndex = await SettingsService.loadFrameIndex();
      final clubName = await SettingsService.loadClubName();
      final comment = await SettingsService.loadComment();
      final frameStyle = FrameStyle.values[frameIndex.clamp(0, FrameStyle.values.length - 1)];

      if (!mounted) return;
      await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => PreviewScreen(
            imageBytes: bytes,
            frameStyle: frameStyle,
            clubName: clubName,
            comment: comment,
          ),
        ),
      );
    } finally {
      if (mounted) setState(() => _loadingPhoto = false);
    }
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
