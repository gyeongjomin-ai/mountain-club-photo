import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'screens/camera_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // 폰을 어느 방향으로 들고 있다가 앱을 열든 첫 화면은 항상 세로로 시작하게 강제한다.
  // 화면을 처음 그린 직후 바로 잠금을 풀어서, 실행 중 폰을 가로로 눕히면 정상적으로
  // 회전되도록 한다(계속 세로로 고정해두지 않음).
  await SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
  SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
  runApp(const MountainClubPhotoApp());
  WidgetsBinding.instance.addPostFrameCallback((_) {
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);
  });
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
