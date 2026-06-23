import 'package:uuid/uuid.dart';

import 'package:nle_editor/domain/overlays/overlay_clip_models.dart';
import 'package:nle_editor/domain/overlays/overlay_value_models.dart';

enum NleOverlayTemplateId {
  rectangle,
  circle,
  line,
  arrow,
  calloutBox,
  sticker,
}

class OverlayTemplateFactory {
  static const _uuid = Uuid();

  const OverlayTemplateFactory();

  NleOverlayClipData create(NleOverlayTemplateId template) {
    final id = _uuid.v4();

    switch (template) {
      case NleOverlayTemplateId.rectangle:
        return NleOverlayClipData.rectangle(id: id);

      case NleOverlayTemplateId.circle:
        return NleOverlayClipData.circle(id: id);

      case NleOverlayTemplateId.line:
        return NleOverlayClipData.line(id: id);

      case NleOverlayTemplateId.arrow:
        return NleOverlayClipData.arrow(id: id);

      case NleOverlayTemplateId.calloutBox:
        return NleOverlayClipData.callout(id: id);

      case NleOverlayTemplateId.sticker:
        return NleOverlayClipData.sticker(id: id);
    }
  }

  String label(NleOverlayTemplateId template) {
    switch (template) {
      case NleOverlayTemplateId.rectangle:
        return 'Rectangle';
      case NleOverlayTemplateId.circle:
        return 'Circle';
      case NleOverlayTemplateId.line:
        return 'Line';
      case NleOverlayTemplateId.arrow:
        return 'Arrow';
      case NleOverlayTemplateId.calloutBox:
        return 'Callout';
      case NleOverlayTemplateId.sticker:
        return 'Sticker';
    }
  }

  NleOverlayClipKind kind(NleOverlayTemplateId template) {
    switch (template) {
      case NleOverlayTemplateId.rectangle:
      case NleOverlayTemplateId.circle:
        return NleOverlayClipKind.shape;
      case NleOverlayTemplateId.line:
        return NleOverlayClipKind.line;
      case NleOverlayTemplateId.arrow:
        return NleOverlayClipKind.arrow;
      case NleOverlayTemplateId.calloutBox:
        return NleOverlayClipKind.callout;
      case NleOverlayTemplateId.sticker:
        return NleOverlayClipKind.sticker;
    }
  }
}
