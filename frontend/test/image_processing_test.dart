import 'dart:ui';
import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;
import 'package:mathiva/services/image_processing.dart';

void main() {
  test('preview worker preserves original dimensions and bounds upload size',
      () async {
    final bytes =
        Uint8List.fromList(img.encodePng(img.Image(width: 1600, height: 800)));
    final (preview, size) = await compute(preparePhotoPreview, bytes);
    expect(size, const Size(1600, 800));
    final decoded = img.decodeJpg(preview)!;
    expect(decoded.width, 1280);
    expect(decoded.height, 640);
  });

  test('crop worker selects the requested region', () async {
    final source = img.Image(width: 100, height: 100);
    img.fillRect(source,
        x1: 50, y1: 0, x2: 99, y2: 99, color: img.ColorRgb8(255, 0, 0));
    final bytes = Uint8List.fromList(img.encodePng(source));
    final result = await compute(cropPhoto,
        (bytes, const Size(100, 100), const Rect.fromLTWH(.5, 0, .5, 1)));
    final decoded = img.decodeJpg(result)!;
    expect(decoded.width, 50);
    expect(decoded.height, 100);
    expect(decoded.getPixel(25, 50).r, greaterThan(240));
  });

  test('invalid photo fails clearly', () {
    expect(() => preparePhotoPreview(Uint8List(0)), throwsFormatException);
  });
}
