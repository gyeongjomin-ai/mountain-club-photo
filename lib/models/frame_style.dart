enum FrameStyle { classic, forest, filmStrip, polaroid, ribbon }

extension FrameStyleLabel on FrameStyle {
  String get label => switch (this) {
        FrameStyle.classic => '클래식',
        FrameStyle.forest => '숲',
        FrameStyle.filmStrip => '필름',
        FrameStyle.polaroid => '폴라로이드',
        FrameStyle.ribbon => '리본',
      };
}
