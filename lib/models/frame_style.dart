enum FrameStyle { classic, forest, filmStrip, polaroid, ribbon, templeValley, lanternGorge }

/// Illustrated frames (templeValley, lanternGorge) are a full-canvas artwork
/// with a transparent window cut out for the photo, unlike the other styles
/// which paint a border on top of a full-bleed photo - so they carry their
/// own (landscape) aspect ratio instead of following the camera's.
const illustratedFrameAspectRatio = 1200 / 655;

extension FrameStyleLabel on FrameStyle {
  String get label => switch (this) {
        FrameStyle.classic => '클래식',
        FrameStyle.forest => '숲',
        FrameStyle.filmStrip => '필름',
        FrameStyle.polaroid => '폴라로이드',
        FrameStyle.ribbon => '리본',
        FrameStyle.templeValley => '사찰',
        FrameStyle.lanternGorge => '계곡',
      };

  bool get isIllustrated =>
      this == FrameStyle.templeValley || this == FrameStyle.lanternGorge;

  String? get assetPath => switch (this) {
        FrameStyle.templeValley => 'assets/frames/temple_valley.png',
        FrameStyle.lanternGorge => 'assets/frames/lantern_gorge.png',
        _ => null,
      };

  /// 사진 박스 아래쪽과 삽화 하단 사이 여백의 세로 중심 위치(0~1, 캔버스 높이 기준).
  /// 산악회 이름/한마디 캡션을 이 지점에 겹쳐 그린다.
  double? get captionCenterYFraction => switch (this) {
        FrameStyle.templeValley => 0.87,
        FrameStyle.lanternGorge => 0.845,
        _ => null,
      };

  /// 사진이 들어갈 투명 창의 위치(캔버스 크기 대비 0~1 비율, left/top/right/bottom).
  /// 세로로 긴 카메라 사진을 이 창 안에 꽉 채우려고 cover로 자르면 창 자체가
  /// 가로로 넓어서 지나치게 확대돼 보이므로, contain으로 맞출 때 기준 크기로 쓴다.
  List<double>? get holeFraction => switch (this) {
        FrameStyle.templeValley => const [0.2674, 0.2474, 0.7298, 0.7546],
        FrameStyle.lanternGorge => const [0.3224, 0.2188, 0.6772, 0.6992],
        _ => null,
      };
}
