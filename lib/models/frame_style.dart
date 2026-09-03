enum FrameStyle {
  classic,
}

extension FrameStyleLabel on FrameStyle {
  String get label => switch (this) {
        FrameStyle.classic => '클래식',
      };
}
