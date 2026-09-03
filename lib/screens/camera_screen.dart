import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../models/frame_style.dart';
import '../services/settings_service.dart';
import '../widgets/frame_painter.dart';
import '../widgets/illustrated_caption_painter.dart';
import 'preview_screen.dart';

class CameraScreen extends StatefulWidget {
  const CameraScreen({super.key});

  @override
  State<CameraScreen> createState() => _CameraScreenState();
}

class _CameraScreenState extends State<CameraScreen> with WidgetsBindingObserver {
  CameraController? _controller;
  Future<void>? _initFuture;
  List<CameraDescription> _cameras = [];
  bool _loadingCameras = true;
  FrameStyle _selectedFrame = FrameStyle.classic;
  String _clubName = '';
  String _comment = '';
  List<String> _clubNameHistory = [];
  List<String> _commentHistory = [];
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    // availableCameras()가 웹에서는 카메라 권한 팝업 응답을 기다리므로, main()에서
    // 미리 기다리지 않고 여기서 첫 프레임이 그려진 뒤에 비동기로 가져온다 -
    // 그래야 권한 응답 전에도 화면(로딩 UI)이 바로 보인다.
    _loadCameras();
    _loadSettings();
  }

  Future<void> _loadCameras() async {
    try {
      _cameras = await availableCameras();
    } catch (_) {
      _cameras = [];
    }
    if (!mounted) return;
    setState(() => _loadingCameras = false);
    _initCamera();
  }

  Future<void> _loadSettings() async {
    final clubName = await SettingsService.loadClubName();
    final comment = await SettingsService.loadComment();
    final frameIndex = await SettingsService.loadFrameIndex();
    final clubNameHistory = await SettingsService.loadClubNameHistory();
    final commentHistory = await SettingsService.loadCommentHistory();
    if (!mounted) return;
    setState(() {
      _clubName = clubName;
      _comment = comment;
      _selectedFrame =
          FrameStyle.values[frameIndex.clamp(0, FrameStyle.values.length - 1)];
      _clubNameHistory = clubNameHistory;
      _commentHistory = commentHistory;
    });
  }

  void _initCamera() {
    if (_cameras.isEmpty) return;
    final camera = _cameras.firstWhere(
      (c) => c.lensDirection == CameraLensDirection.back,
      orElse: () => _cameras.first,
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
      // 컨트롤러를 null로 비워둬야 다음 build()가 "카메라를 찾을 수 없습니다" 상태로
      // 안전하게 떨어진다 - 그대로 두면 resumed로 돌아오기 전 프레임에서 이미
      // dispose된 컨트롤러를 CameraPreview/AspectRatio가 계속 참조하게 된다.
      setState(() {
        _controller = null;
        _initFuture = null;
      });
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

  // 나의 산악회 / 나의 멘트: 저장된 목록에서 고르거나(항목 탭), 오른쪽 X로 지운다.
  Future<void> _pickFromHistory({
    required String title,
    required List<String> history,
    required Future<void> Function(String value) removeItem,
    required ValueChanged<String> onSelect,
  }) async {
    final items = List<String>.from(history);
    final result = await showDialog<String>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: Text(title),
          content: SizedBox(
            width: 320,
            child: items.isEmpty
                ? const Padding(
                    padding: EdgeInsets.symmetric(vertical: 8),
                    child: Text('저장된 항목이 없습니다', style: TextStyle(color: Colors.grey)),
                  )
                : ConstrainedBox(
                    constraints: const BoxConstraints(maxHeight: 320),
                    child: ListView.builder(
                      shrinkWrap: true,
                      itemCount: items.length,
                      itemBuilder: (context, index) {
                        final item = items[index];
                        return ListTile(
                          dense: true,
                          title: Text(item),
                          onTap: () => Navigator.pop(ctx, item),
                          trailing: IconButton(
                            icon: const Icon(Icons.close, size: 18),
                            onPressed: () async {
                              await removeItem(item);
                              setDialogState(() => items.removeAt(index));
                            },
                          ),
                        );
                      },
                    ),
                  ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('닫기')),
          ],
        ),
      ),
    );
    if (result != null) onSelect(result);
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
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('촬영 실패: $e')));
      }
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
              child: _loadingCameras
                  ? const Center(
                      child: CircularProgressIndicator(color: Colors.white))
                  : _controller == null
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
                          child: _selectedFrame.isIllustrated
                              ? _buildIllustratedPreview(dateText)
                              // CameraPreview 위젯 자체가 현재 기기 방향(portrait/landscape)에
                              // 맞는 가로세로 비율을 이미 계산해준다 - 그 바깥에 다시
                              // 1/aspectRatio로 세로를 강제하는 AspectRatio를 씌우면, 웹처럼
                              // aspectRatio 값이 플랫폼마다 다르게 보고되는 환경에서 두 비율
                              // 계산이 충돌해 미리보기가 화면 가운데에 작은 가로 박스로
                              // 찌그러져 보이는 문제가 생긴다. child로 프레임을 얹어서
                              // CameraPreview가 직접 크기를 정하게 둔다.
                              : CameraPreview(
                                  _controller!,
                                  child: CustomPaint(
                                    painter: PhotoFramePainter(
                                      style: _selectedFrame,
                                      clubName:
                                          _clubName.isEmpty ? '산악회 이름' : _clubName,
                                      dateText: dateText,
                                      comment: _comment,
                                    ),
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

  // 일러스트 프레임(사찰/계곡)은 사진이 들어갈 창이 가로로 넓게 뚫려 있다.
  // 폰을 돌리라고 요구하지 않고, 세로로 찍히는 카메라 화면을 자르지 않은 채
  // 그 창 안에 contain으로 통째로 넣는다(창보다 남는 자리는 배경 톤으로 채움) -
  // 그래서 사진이 배경(삽화) 앞에 있는 그대로, 과하게 확대되지도 않고 항상
  // 라이브 카메라가 바로 보인다.
  Widget _buildIllustratedPreview(String dateText) {
    final camAspect = 1 / _controller!.value.aspectRatio;
    final hole = _selectedFrame.holeFraction!;
    return AspectRatio(
      aspectRatio: _selectedFrame.frameAspectRatio,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final w = constraints.maxWidth;
          final h = constraints.maxHeight;
          final holeRect =
              Rect.fromLTRB(hole[0] * w, hole[1] * h, hole[2] * w, hole[3] * h);
          return Stack(
            fit: StackFit.expand,
            children: [
              Positioned.fromRect(
                rect: holeRect,
                child: Container(
                  color: const Color(0xFFF0E6D2),
                  child: ClipRect(
                    child: FittedBox(
                      fit: BoxFit.contain,
                      child: SizedBox(
                        width: 1000 * camAspect,
                        height: 1000,
                        child: CameraPreview(_controller!),
                      ),
                    ),
                  ),
                ),
              ),
              Image.asset(_selectedFrame.assetPath!, fit: BoxFit.fill),
              CustomPaint(
                painter: IllustratedCaptionPainter(
                  style: _selectedFrame,
                  clubName: _clubName.isEmpty ? '산악회 이름' : _clubName,
                  dateText: dateText,
                  comment: _comment,
                ),
              ),
            ],
          );
        },
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
                        child: style.isIllustrated
                            ? Stack(
                                fit: StackFit.expand,
                                children: [
                                  Container(color: const Color(0xFF3A506B)),
                                  Image.asset(style.assetPath!, fit: BoxFit.cover),
                                ],
                              )
                            : Stack(
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
              _miniButton(
                icon: Icons.group_add,
                label: '산악회 추가',
                onTap: () => _editText(
                  title: '산악회 추가',
                  initial: _clubName,
                  onSave: (value) async {
                    setState(() => _clubName = value);
                    await SettingsService.saveClubName(value);
                    final history = await SettingsService.loadClubNameHistory();
                    if (mounted) setState(() => _clubNameHistory = history);
                  },
                ),
              ),
              _miniButton(
                icon: Icons.groups,
                label: '나의 산악회',
                onTap: () => _pickFromHistory(
                  title: '나의 산악회',
                  history: _clubNameHistory,
                  removeItem: SettingsService.removeClubNameFromHistory,
                  onSelect: (value) async {
                    setState(() => _clubName = value);
                    await SettingsService.saveClubName(value);
                  },
                ).then((_) async {
                  final history = await SettingsService.loadClubNameHistory();
                  if (mounted) setState(() => _clubNameHistory = history);
                }),
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
              _miniButton(
                icon: Icons.edit_note,
                label: '멘트 추가',
                onTap: () => _editText(
                  title: '멘트 추가',
                  initial: _comment,
                  onSave: (value) async {
                    setState(() => _comment = value);
                    await SettingsService.saveComment(value);
                    final history = await SettingsService.loadCommentHistory();
                    if (mounted) setState(() => _commentHistory = history);
                  },
                ),
              ),
              _miniButton(
                icon: Icons.bookmark,
                label: '나의 멘트',
                onTap: () => _pickFromHistory(
                  title: '나의 멘트',
                  history: _commentHistory,
                  removeItem: SettingsService.removeCommentFromHistory,
                  onSelect: (value) async {
                    setState(() => _comment = value);
                    await SettingsService.saveComment(value);
                  },
                ).then((_) async {
                  final history = await SettingsService.loadCommentHistory();
                  if (mounted) setState(() => _commentHistory = history);
                }),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _miniButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: SizedBox(
        width: 72,
        child: Column(
          children: [
            Icon(icon, color: Colors.white70, size: 20),
            const SizedBox(height: 2),
            Text(
              label,
              style: const TextStyle(color: Colors.white70, fontSize: 9.5),
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
