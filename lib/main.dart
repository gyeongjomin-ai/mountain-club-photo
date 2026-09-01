import 'package:flutter/material.dart';

import 'screens/camera_screen.dart';

void main() {
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
      home: const CameraScreen(),
    );
  }
}
