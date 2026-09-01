enum FrameStyle {
  classic,
  forest,
  filmStrip,
  polaroid,
  ribbon,
  templeValley,
  lanternGorge,
  ganggu,
}

extension FrameStyleLabel on FrameStyle {
  String get label => switch (this) {
        FrameStyle.classic => '클래식',
        FrameStyle.forest => '숲',
        FrameStyle.filmStrip => '필름',
        FrameStyle.polaroid => '폴라로이드',
        FrameStyle.ribbon => '리본',
        FrameStyle.templeValley => '사찰',
        FrameStyle.lanternGorge => '계곡',
        FrameStyle.ganggu => '강구항',
      };

  bool get isIllustrated =>
      this == FrameStyle.templeValley ||
      this == FrameStyle.lanternGorge ||
      this == FrameStyle.ganggu;

  String? get assetPath => switch (this) {
        FrameStyle.templeValley => 'assets/frames/temple_valley.png',
        FrameStyle.lanternGorge => 'assets/frames/lantern_gorge.png',
        FrameStyle.ganggu => 'assets/frames/ganggu_harbor.png',
        _ => null,
      };

  /// 일러스트 프레임(사진 전체가 캔버스를 채우는 삽화 + 투명 창)의 가로세로 비율.
  /// 사찰/계곡은 가로로 넓은 삽화, 강구항은 실사 사진이라 세로로 긴 삽화다.
  double get frameAspectRatio => switch (this) {
        FrameStyle.templeValley || FrameStyle.lanternGorge => 1200 / 655,
        FrameStyle.ganggu => 900 / 1200,
        _ => 1,
      };

  /// 사진 박스 아래쪽과 삽화 하단 사이 여백의 세로 중심 위치(0~1, 캔버스 높이 기준).
  /// 산악회 이름/날짜/한마디를 한 배너에 모아 이 지점에 겹쳐 그린다 (사찰/계곡 전용).
  double? get captionCenterYFraction => switch (this) {
        FrameStyle.templeValley => 0.87,
        FrameStyle.lanternGorge => 0.845,
        _ => null,
      };

  /// 강구항처럼 원본 삽화에 박혀 있던 제목 자리를 지우고 그 위치에 산악회 이름 +
  /// 날짜를 그릴 때 쓰는 세로 중심 위치. captionCenterYFraction과 별개로, 한마디는
  /// 사진 아래쪽 commentBandCenterYFraction 위치에 따로 그린다.
  double? get titleBandCenterYFraction => switch (this) {
        FrameStyle.ganggu => 0.228,
        _ => null,
      };

  double? get commentBandCenterYFraction => switch (this) {
        FrameStyle.ganggu => 0.944,
        _ => null,
      };

  /// 사진이 들어갈 투명 창의 위치(캔버스 크기 대비 0~1 비율, left/top/right/bottom).
  /// 세로로 긴 카메라 사진을 이 창 안에 꽉 채우려고 cover로 자르면 창 자체가
  /// 가로로 넓어서 지나치게 확대돼 보이므로, contain으로 맞출 때 기준 크기로 쓴다.
  List<double>? get holeFraction => switch (this) {
        FrameStyle.templeValley => const [0.2674, 0.2474, 0.7298, 0.7546],
        FrameStyle.lanternGorge => const [0.3224, 0.2188, 0.6772, 0.6992],
        FrameStyle.ganggu => const [0.0865, 0.3900, 0.9136, 0.8875],
        _ => null,
      };
}
