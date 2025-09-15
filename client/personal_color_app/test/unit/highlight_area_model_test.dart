import 'package:flutter_test/flutter_test.dart';
import 'package:personal_color_app/features/makeup/domain/entities/highlight_area.dart';

void main() {
  test('RelativeCoordinates toAbsolute converts correctly', () {
    const rel = RelativeCoordinates(x: 0.1, y: 0.2, width: 0.3, height: 0.4);
    final abs = rel.toAbsolute(1000, 2000);
    expect(abs.x, 100);
    expect(abs.y, 400);
    expect(abs.width, 300);
    expect(abs.height, 800);
  });

  test('RelativeCoordinates validation works', () {
    const valid = RelativeCoordinates(x: 0.1, y: 0.1, width: 0.5, height: 0.5);
    expect(valid.isValid, true);

    const invalid = RelativeCoordinates(x: 0.8, y: 0.8, width: 0.5, height: 0.5);
    expect(invalid.isValid, false);
  });

  test('HighlightArea JSON roundtrip with shape and animation', () {
    final json = {
      'type': 'eye',
      'coordinates': {'x': 0.1, 'y': 0.2, 'width': 0.3, 'height': 0.4},
      'description': 'test',
      'shape': 'circle',
      'animation_type': 'pulse',
      'animationDuration': 1500,
      'isVisible': true,
    };
    final area = HighlightArea.fromJson(json);
    expect(area.type, HighlightType.eye);
    expect(area.shape, HighlightShape.circle);
    expect(area.animationType, HighlightAnimationType.pulse);
    expect(area.animationDuration.inMilliseconds, 1500);

    final out = area.toJson();
    expect(out['shape'], 'circle');
    expect(out['animation_type'], 'pulse');
  });
}

