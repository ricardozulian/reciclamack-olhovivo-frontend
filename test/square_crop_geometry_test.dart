import 'package:flutter_test/flutter_test.dart';
import 'package:reciclamack_web/src/square_crop_geometry.dart';

void main() {
  test('centers a square crop in a 1280 by 720 camera frame', () {
    final crop = SquareCropRect.centered(1280, 720);

    expect(crop.x, 280);
    expect(crop.y, 0);
    expect(crop.side, 720);
  });

  test('centers a square crop in a portrait frame', () {
    final crop = SquareCropRect.centered(720, 1280);

    expect(crop.x, 0);
    expect(crop.y, 280);
    expect(crop.side, 720);
  });

  test('rejects invalid image dimensions', () {
    expect(() => SquareCropRect.centered(0, 720), throwsArgumentError);
  });
}
