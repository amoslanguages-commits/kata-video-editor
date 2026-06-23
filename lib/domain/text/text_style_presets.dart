import 'package:nle_editor/domain/text/text_style_model.dart';

class BuiltInTextStylePresets {
  BuiltInTextStylePresets._();

  static final List<TextStylePreset> all = [
    TextStylePreset(
      id: 'bold_social_caption',
      name: 'Bold Caption',
      category: 'Social',
      isPremium: false,
      isBuiltIn: true,
      style: NleTextStyle.defaults().copyWith(
        fontSize: 38,
        fontWeight: 900,
        color: '#FFFFFF',
        strokeColor: '#000000',
        strokeWidth: 3,
        shadowEnabled: true,
        shadowBlur: 4,
        backgroundEnabled: false,
      ),
    ),
    TextStylePreset(
      id: 'cinematic_title',
      name: 'Cinematic',
      category: 'Cinematic',
      isPremium: false,
      isBuiltIn: true,
      style: NleTextStyle.defaults().copyWith(
        fontSize: 34,
        fontWeight: 600,
        color: '#F6E7C1',
        strokeWidth: 0,
        shadowEnabled: true,
        shadowBlur: 14,
        letterSpacing: 1.5,
      ),
    ),
    TextStylePreset(
      id: 'meme_caption',
      name: 'Meme',
      category: 'Social',
      isPremium: false,
      isBuiltIn: true,
      style: NleTextStyle.defaults().copyWith(
        fontSize: 40,
        fontWeight: 900,
        color: '#FFFFFF',
        strokeColor: '#000000',
        strokeWidth: 4,
        shadowEnabled: false,
      ),
    ),
    TextStylePreset(
      id: 'luxury_product',
      name: 'Luxury',
      category: 'Business',
      isPremium: true,
      isBuiltIn: true,
      style: NleTextStyle.defaults().copyWith(
        fontSize: 32,
        fontWeight: 700,
        color: '#F7D36B',
        strokeWidth: 0,
        shadowEnabled: true,
        shadowBlur: 18,
        letterSpacing: 2.0,
      ),
    ),
    TextStylePreset(
      id: 'minimal_lower_third',
      name: 'Lower Third',
      category: 'Clean',
      isPremium: false,
      isBuiltIn: true,
      style: NleTextStyle.defaults().copyWith(
        fontSize: 26,
        fontWeight: 700,
        color: '#FFFFFF',
        backgroundEnabled: true,
        backgroundColor: '#000000',
        backgroundOpacity: 0.65,
        backgroundRadius: 10,
        backgroundPadding: 10,
        shadowEnabled: false,
      ),
    ),
    TextStylePreset(
      id: 'viral_yellow',
      name: 'Viral Yellow',
      category: 'Social',
      isPremium: false,
      isBuiltIn: true,
      style: NleTextStyle.defaults().copyWith(
        fontSize: 38,
        fontWeight: 900,
        color: '#FFE600',
        strokeColor: '#000000',
        strokeWidth: 3,
        shadowEnabled: true,
        shadowBlur: 5,
      ),
    ),
    TextStylePreset(
      id: 'glow_caption',
      name: 'Glow',
      category: 'Premium',
      isPremium: true,
      isBuiltIn: true,
      style: NleTextStyle.defaults().copyWith(
        fontSize: 36,
        fontWeight: 800,
        color: '#B7F7FF',
        strokeColor: '#003C4A',
        strokeWidth: 1.5,
        shadowEnabled: true,
        shadowColor: '#00E5FF',
        shadowBlur: 22,
      ),
    ),
    TextStylePreset(
      id: 'karaoke',
      name: 'Karaoke',
      category: 'Captions',
      isPremium: true,
      isBuiltIn: true,
      style: NleTextStyle.defaults().copyWith(
        fontSize: 36,
        fontWeight: 900,
        color: '#FFFFFF',
        strokeColor: '#000000',
        strokeWidth: 3,
        shadowEnabled: true,
        animation: TextAnimationType.karaoke,
      ),
    ),
  ];

  static TextStylePreset byId(String id) {
    return all.firstWhere(
      (preset) => preset.id == id,
      orElse: () => all.first,
    );
  }

  static List<String> categories() {
    return all.map((preset) => preset.category).toSet().toList();
  }
}
