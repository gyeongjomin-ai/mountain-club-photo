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
}
