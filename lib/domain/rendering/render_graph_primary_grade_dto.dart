import 'package:nle_editor/domain/color_grade/primary_grade_models.dart';

class RenderGraphPrimaryGradeDto {
  final NlePrimaryGrade grade;

  const RenderGraphPrimaryGradeDto({
    required this.grade,
  });

  Map<String, dynamic> toJson() {
    return {
      'enabled': grade.enabled,
      'mode': grade.mode.name,
      'intensity': grade.intensity,
      'lift': grade.lift.toJson(),
      'gamma': grade.gamma.toJson(),
      'gain': grade.gain.toJson(),
      'offset': grade.offset.toJson(),
      'contrast': grade.contrast,
      'pivot': grade.pivot,
      'saturation': grade.saturation,
    };
  }
}
