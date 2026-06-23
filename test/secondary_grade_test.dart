import 'package:flutter_test/flutter_test.dart';
import 'package:nle_editor/domain/color_qualifier/hsl_qualifier_models.dart';
import 'package:nle_editor/domain/rendering/render_graph_secondary_grade_dto.dart';

void main() {
  group('Secondary Color Grading Domain Models', () {
    test('Identity stack initialization', () {
      const stack = NleSecondaryGradeStack.empty();
      expect(stack.enabled, isTrue);
      expect(stack.layers.isEmpty, isTrue);
      expect(stack.isIdentity, isTrue);
    });

    test('isIdentity checks custom settings', () {
      const layer = NleSecondaryGradeLayer(
        id: '123',
        name: 'Skin Tone',
        enabled: true,
        qualifier: NleHslQualifier.identity(),
        correction: NleSecondaryCorrection.identity(),
      );
      expect(layer.isIdentity, isTrue);

      final modifiedQualifier = layer.copyWith(
        qualifier: const NleHslQualifier.identity().copyWith(enabled: true),
      );
      expect(modifiedQualifier.isIdentity, isFalse);

      final modifiedCorrection = layer.copyWith(
        correction: const NleSecondaryCorrection.identity().copyWith(exposure: 1.0),
      );
      expect(modifiedCorrection.isIdentity, isFalse);
    });

    test('updateLayer and removeLayer helper functions', () {
      var stack = const NleSecondaryGradeStack.empty();
      const layer = NleSecondaryGradeLayer(
        id: 'layer_1',
        name: 'Layer 1',
        enabled: true,
        qualifier: NleHslQualifier.identity(),
        correction: NleSecondaryCorrection.identity(),
      );

      stack = stack.updateLayer(layer);
      expect(stack.layers.length, equals(1));
      expect(stack.layers.first.id, equals('layer_1'));

      final updatedLayer = layer.copyWith(name: 'Updated Layer 1');
      stack = stack.updateLayer(updatedLayer);
      expect(stack.layers.length, equals(1));
      expect(stack.layers.first.name, equals('Updated Layer 1'));

      stack = stack.removeLayer('layer_1');
      expect(stack.layers.isEmpty, isTrue);
    });
  });

  group('Secondary Grade Serialization', () {
    test('JSON serialization roundtrip', () {
      final stack = NleSecondaryGradeStack(
        enabled: true,
        layers: [
          NleSecondaryGradeLayer(
            id: 'layer_skin',
            name: 'Skin tone',
            enabled: true,
            qualifier: const NleHslQualifier.identity().copyWith(
              enabled: true,
              invert: true,
              cleanBlack: 0.15,
              viewMode: NleQualifierViewMode.matte,
            ),
            correction: const NleSecondaryCorrection.identity().copyWith(
              exposure: -0.5,
              saturation: 1.25,
            ),
          )
        ],
      );

      final json = stack.toJson();
      final decoded = NleSecondaryGradeStack.fromJson(json);

      expect(decoded.enabled, isTrue);
      expect(decoded.layers.length, equals(1));

      final firstLayer = decoded.layers.first;
      expect(firstLayer.id, equals('layer_skin'));
      expect(firstLayer.name, equals('Skin tone'));
      expect(firstLayer.qualifier.enabled, isTrue);
      expect(firstLayer.qualifier.invert, isTrue);
      expect(firstLayer.qualifier.cleanBlack, equals(0.15));
      expect(firstLayer.qualifier.viewMode, equals(NleQualifierViewMode.matte));
      expect(firstLayer.correction.exposure, equals(-0.5));
      expect(firstLayer.correction.saturation, equals(1.25));
    });

    test('RenderGraph DTO serialization', () {
      final stack = NleSecondaryGradeStack(
        enabled: true,
        layers: [
          NleSecondaryGradeLayer(
            id: 'layer_1',
            name: 'Layer 1',
            enabled: true,
            qualifier: const NleHslQualifier.identity().copyWith(enabled: true),
            correction: const NleSecondaryCorrection.identity().copyWith(exposure: 1.0),
          )
        ],
      );

      final dto = RenderGraphSecondaryGradeStackDto(stack: stack);
      final json = dto.toJson();

      expect(json['enabled'], isTrue);
      expect(json['layers'], isA<List>());
      expect(json['layers'].length, equals(1));
      expect(json['layers'][0]['id'], equals('layer_1'));
    });
  });
}
