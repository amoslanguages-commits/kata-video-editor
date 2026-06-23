class RenderGraphContract {
  static const String schema = 'nle.render_graph';
  static const int version = 2;

  static const String source = 'flutter_multitrack_timeline';

  const RenderGraphContract._();
}

class RenderGraphTrackTypes {
  static const String video = 'video';
  static const String overlay = 'overlay';
  static const String text = 'text';
  static const String adjustment = 'adjustment';
  static const String audio = 'audio';

  const RenderGraphTrackTypes._();
}

class RenderGraphClipTypes {
  static const String video = 'video';
  static const String image = 'image';
  static const String audio = 'audio';
  static const String text = 'text';
  static const String adjustment = 'adjustment';
  static const String unknown = 'unknown';

  const RenderGraphClipTypes._();
}

class RenderGraphFitModes {
  static const String fit = 'fit';
  static const String fill = 'fill';
  static const String stretch = 'stretch';

  const RenderGraphFitModes._();
}
