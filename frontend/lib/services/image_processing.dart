import 'dart:math' as math;
import 'dart:typed_data';
import 'dart:ui';

import 'package:image/image.dart' as img;

const int _maxUploadDimension = 1280;
const int _uploadJpegQuality = 82;

/// Decode once for dimensions and preview. Used with compute off the native UI isolate.
(Uint8List, Size) preparePhotoPreview(Uint8List bytes) {
  if (bytes.isEmpty) throw const FormatException('Unsupported photo');
  final decoded = img.decodeImage(bytes);
  if (decoded == null) throw const FormatException('Unsupported photo');
  final oriented = img.bakeOrientation(decoded);
  final size = Size(oriented.width.toDouble(), oriented.height.toDouble());
  final preview = Uint8List.fromList(img.encodeJpg(
    _fitForUpload(oriented),
    quality: _uploadJpegQuality,
  ));
  return (preview, size);
}

img.Image _fitForUpload(img.Image source) {
  final longest = math.max(source.width, source.height);
  if (longest <= _maxUploadDimension) return source;
  if (source.width >= source.height) {
    return img.copyResize(source, width: _maxUploadDimension);
  }
  return img.copyResize(source, height: _maxUploadDimension);
}

Uint8List cropPhoto((Uint8List, Size, Rect) input) {
  final (bytes, viewportSize, normalizedCrop) = input;
  if (bytes.isEmpty) throw const FormatException('Unsupported photo');
  final decoded = img.decodeImage(bytes);
  if (decoded == null || viewportSize == Size.zero) return bytes;

  final oriented = img.bakeOrientation(decoded);
  final imageW = oriented.width.toDouble();
  final imageH = oriented.height.toDouble();
  final scale = math.max(
    viewportSize.width / imageW,
    viewportSize.height / imageH,
  );
  final drawnW = imageW * scale;
  final drawnH = imageH * scale;
  final offsetX = (viewportSize.width - drawnW) / 2;
  final offsetY = (viewportSize.height - drawnH) / 2;

  final cropPx = Rect.fromLTWH(
    ((normalizedCrop.left * viewportSize.width) - offsetX) / scale,
    ((normalizedCrop.top * viewportSize.height) - offsetY) / scale,
    (normalizedCrop.width * viewportSize.width) / scale,
    (normalizedCrop.height * viewportSize.height) / scale,
  );

  final x = cropPx.left.floor().clamp(0, oriented.width - 1);
  final y = cropPx.top.floor().clamp(0, oriented.height - 1);
  final right = cropPx.right.ceil().clamp(x + 1, oriented.width);
  final bottom = cropPx.bottom.ceil().clamp(y + 1, oriented.height);

  final cropped = img.copyCrop(
    oriented,
    x: x,
    y: y,
    width: right - x,
    height: bottom - y,
  );
  return Uint8List.fromList(
    img.encodeJpg(
      _fitForUpload(cropped),
      quality: _uploadJpegQuality,
    ),
  );
}
