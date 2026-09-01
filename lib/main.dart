import 'package:camera/camera.dart';
import 'package:flutter/material.dart';

import 'screens/camera_screen.dart';

List<CameraDescription> _cameras = [];

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    _cameras = await availableCameras();
  } catch (_) {
    _cameras = [];
  }
  runApp(const MountainClubPhotoApp());
}

class MountainClubPhotoApp extends StatelessWidget {
  const MountainClubPhotoApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '산악회 사진',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF1B4332),
          brightness: Brightness.dark,
        ),
        useMaterial3: true,
      ),
      home: CameraScreen(cameras: _cameras),
    );
  }
}
