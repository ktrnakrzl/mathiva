import 'dart:async';
import 'dart:math' as math;

import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:image/image.dart' as img;
import 'package:image_picker/image_picker.dart';

import '../presentation/widgets/animated_background.dart';
import '../presentation/widgets/fade_slide_in.dart';
import '../presentation/widgets/tap_scale.dart';
import '../services/app_preferences.dart';
import '../services/scan_history_service.dart';
import '../services/solver_service.dart';
import '../theme/app_theme.dart';
import '../utils/route_names.dart';
import '../widgets/mathiva_bottom_nav.dart';
import '../widgets/mathiva_top_bar.dart';

enum _SolverStep { scan, preview }

class ImageSolverScreen extends StatefulWidget {
  const ImageSolverScreen({super.key});

  @override
  State<ImageSolverScreen> createState() => _ImageSolverScreenState();
}

class _ImageSolverScreenState extends State<ImageSolverScreen>
    with WidgetsBindingObserver {
  final ImagePicker _picker = ImagePicker();

  CameraController? _camera;
  Future<void>? _cameraInit;
  List<CameraDescription> _cameras = const [];

  _SolverStep _step = _SolverStep.scan;
  Rect _crop = const Rect.fromLTWH(0.08, 0.34, 0.84, 0.24);
  Uint8List? _previewBytes;
  XFile? _imageToSolve;

  bool _isCapturing = false;
  bool _isSolving = false;
  bool _isPicking = false;
  bool _isInitializingCamera = false;
  bool _flashOn = false;
  String? _cameraError;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    unawaited(_initializeCamera());
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    unawaited(_camera?.dispose());
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // On web, opening the browser permission prompt can trigger inactive/resumed
    // lifecycle events. Reinitializing there makes Chrome/Edge appear to ask
    // for camera access repeatedly even after the user approved it.
    if (kIsWeb) return;

    final camera = _camera;
    if (camera == null || !camera.value.isInitialized) return;

    if (state == AppLifecycleState.inactive ||
        state == AppLifecycleState.paused) {
      unawaited(camera.dispose());
      _camera = null;
    } else if (state == AppLifecycleState.resumed &&
        _step == _SolverStep.scan) {
      unawaited(_initializeCamera());
    }
  }

  Future<void> _initializeCamera() async {
    final current = _camera;
    if (_isSolving ||
        _isInitializingCamera ||
        (current != null && current.value.isInitialized)) {
      return;
    }

    _isInitializingCamera = true;
    setState(() => _cameraError = null);
    try {
      _cameras = await availableCameras();
      if (_cameras.isEmpty) {
        throw CameraException('no_camera', 'No camera found on this device.');
      }

      final camera = _cameras.firstWhere(
        (c) => c.lensDirection == CameraLensDirection.back,
        orElse: () => _cameras.first,
      );

      final controller = CameraController(
        camera,
        ResolutionPreset.high,
        enableAudio: false,
        imageFormatGroup: ImageFormatGroup.jpeg,
      );
      _camera = controller;
      _cameraInit = controller.initialize().then((_) async {
        await controller.setFlashMode(FlashMode.off);
        await controller.setFocusMode(FocusMode.auto);
      });
      await _cameraInit;
      if (!mounted) return;
      setState(() {});
    } catch (e) {
      if (!mounted) return;
      _camera = null;
      _cameraInit = null;
      debugPrint('Camera initialization failed: $e');
      setState(() {
        _cameraError =
            'Could not open the live camera. Check camera permission and try again.';
      });
    } finally {
      _isInitializingCamera = false;
    }
  }

  Future<void> _toggleFlash() async {
    final camera = _camera;
    if (camera == null || !camera.value.isInitialized) return;
    try {
      final next = !_flashOn;
      await camera.setFlashMode(next ? FlashMode.torch : FlashMode.off);
      if (!mounted) return;
      setState(() => _flashOn = next);
    } catch (_) {
      _showMessage('Flash is not available on this device.');
    }
  }

  Future<void> _capture() async {
    final camera = _camera;
    if (camera == null || _isCapturing || _isSolving) return;
    setState(() => _isCapturing = true);
    try {
      await _cameraInit;
      final photo = await camera.takePicture();
      final bytes = await photo.readAsBytes();
      final cropped = _cropBytes(bytes, _lastViewportSize, _crop);
      if (!mounted) return;
      setState(() {
        _previewBytes = cropped;
        _imageToSolve = XFile.fromData(
          cropped,
          name: 'mathiva-crop.jpg',
          mimeType: 'image/jpeg',
        );
        _step = _SolverStep.preview;
      });
    } catch (_) {
      if (!mounted) return;
      _showMessage('Could not capture the problem. Please try again.');
    } finally {
      if (mounted) setState(() => _isCapturing = false);
    }
  }

  Future<void> _pickFromGallery() async {
    await _pickImage(ImageSource.gallery);
  }

  Future<void> _pickImage(ImageSource source) async {
    if (_isPicking || _isSolving) return;
    setState(() => _isPicking = true);
    try {
      final file = await _picker.pickImage(
        source: source,
        imageQuality: 92,
      );
      if (!mounted || file == null) return;
      final bytes = await file.readAsBytes();
      final normalized = _normalizeImageBytes(bytes);
      setState(() {
        _previewBytes = normalized;
        _imageToSolve = XFile.fromData(
          normalized,
          name: source == ImageSource.camera
              ? 'mathiva-camera.jpg'
              : 'mathiva-gallery.jpg',
          mimeType: 'image/jpeg',
        );
        _step = _SolverStep.preview;
      });
    } catch (_) {
      if (!mounted) return;
      _showMessage(
        source == ImageSource.camera
            ? 'Could not open the camera. Please try again.'
            : 'Could not open the gallery. Please try again.',
      );
    } finally {
      if (mounted) setState(() => _isPicking = false);
    }
  }

  Uint8List _normalizeImageBytes(Uint8List bytes) {
    final decoded = img.decodeImage(bytes);
    if (decoded == null) return bytes;
    return Uint8List.fromList(
        img.encodeJpg(img.bakeOrientation(decoded), quality: 92));
  }

  Size _lastViewportSize = Size.zero;

  Uint8List _cropBytes(
      Uint8List bytes, Size viewportSize, Rect normalizedCrop) {
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
    return Uint8List.fromList(img.encodeJpg(cropped, quality: 94));
  }

  void _retake() {
    setState(() {
      _step = _SolverStep.scan;
      _previewBytes = null;
      _imageToSolve = null;
    });
    if (_camera == null) unawaited(_initializeCamera());
  }

  Future<void> _solve() async {
    final image = _imageToSolve;
    if (image == null || _isSolving) return;

    setState(() => _isSolving = true);
    try {
      final problem = await SolverService.solveImage(image);
      await ScanHistoryService.record(problem);
      if (!mounted) return;
      context.push(RouteNames.solution, extra: problem);
    } catch (e) {
      if (!mounted) return;
      _showMessage(
        e is SolverServiceException
            ? e.message
            : 'Could not solve this problem. Please try again.',
      );
    } finally {
      if (mounted) setState(() => _isSolving = false);
    }
  }

  void _showMessage(String message) {
    final colors = AppTheme.colorsOf(context);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message, style: TextStyle(color: colors.pageBg)),
        behavior: SnackBarBehavior.floating,
        backgroundColor: colors.ink,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = AppTheme.colorsOf(context);

    return Scaffold(
      extendBody: _step == _SolverStep.scan,
      backgroundColor: colors.pageBg,
      appBar: _step == _SolverStep.scan
          ? const MathivaTopBar()
          : AppBar(
              backgroundColor: colors.pageBg,
              elevation: 0,
              scrolledUnderElevation: 0,
              foregroundColor: colors.ink,
              title: const Text('Preview'),
              leading: IconButton(
                icon: const Icon(Icons.arrow_back_rounded),
                onPressed: _retake,
              ),
            ),
      body: AnimatedSwitcher(
        duration: const Duration(milliseconds: 220),
        child:
            _step == _SolverStep.scan ? _buildLiveScanner() : _buildPreview(),
      ),
      bottomNavigationBar: _step == _SolverStep.scan
          ? const MathivaBottomNav(selected: MathivaTab.scan)
          : null,
    );
  }

  Widget _buildLiveScanner() {
    final primary = AppPreferences.palette.value.primary;
    final colors = AppTheme.colorsOf(context);

    return Container(
      key: const ValueKey('live-scanner'),
      color: Colors.black,
      child: SafeArea(
        top: false,
        child: Column(
          children: [
            Expanded(
              child: FutureBuilder<void>(
                future: _cameraInit,
                builder: (context, snapshot) {
                  final camera = _camera;
                  if (_cameraError != null) {
                    return _CameraFallback(
                      message: _cameraError!,
                      onRetry: _initializeCamera,
                      onGallery: _pickFromGallery,
                    );
                  }
                  if (camera == null ||
                      snapshot.connectionState != ConnectionState.done ||
                      !camera.value.isInitialized) {
                    return Center(
                      child: CircularProgressIndicator(color: primary),
                    );
                  }

                  return LayoutBuilder(
                    builder: (context, constraints) {
                      _lastViewportSize = Size(
                        constraints.maxWidth,
                        constraints.maxHeight,
                      );
                      return Stack(
                        fit: StackFit.expand,
                        children: [
                          _CoverCameraPreview(controller: camera),
                          _CropShade(crop: _crop),
                          _InteractiveCropBox(
                            crop: _crop,
                            color: primary,
                            onChanged: (next) => setState(() => _crop = next),
                          ),
                          Positioned(
                            left: 18,
                            right: 18,
                            top: MediaQuery.of(context).padding.top + 18,
                            child: Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    'Adjust the box around the math problem',
                                    style: TextStyle(
                                      color:
                                          Colors.white.withValues(alpha: 0.88),
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                                _CircleIconButton(
                                  icon: _flashOn
                                      ? Icons.flash_on_rounded
                                      : Icons.flash_off_rounded,
                                  onPressed: _toggleFlash,
                                ),
                              ],
                            ),
                          ),
                        ],
                      );
                    },
                  );
                },
              ),
            ),
            Container(
              color: colors.pageBg,
              padding: const EdgeInsets.fromLTRB(18, 14, 18, 18),
              child: Row(
                children: [
                  _BottomToolButton(
                    icon: Icons.photo_library_outlined,
                    label: 'Gallery',
                    onTap: _isPicking ? null : _pickFromGallery,
                  ),
                  const Spacer(),
                  TapScale(
                    onTap: _isCapturing ? null : _capture,
                    child: Container(
                      width: 74,
                      height: 74,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: primary, width: 4),
                      ),
                      padding: const EdgeInsets.all(7),
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: _isCapturing ? colors.muted : Colors.white,
                        ),
                        child: _isCapturing
                            ? const Padding(
                                padding: EdgeInsets.all(16),
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : null,
                      ),
                    ),
                  ),
                  const Spacer(),
                  _BottomToolButton(
                    icon: Icons.center_focus_strong_rounded,
                    label: 'Reset',
                    onTap: () => setState(
                      () => _crop = const Rect.fromLTWH(0.08, 0.34, 0.84, 0.24),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPreview() {
    final primary = AppPreferences.palette.value.primary;
    final colors = AppTheme.colorsOf(context);
    final bytes = _previewBytes;

    return AnimatedBackground(
      key: const ValueKey('preview'),
      vivid: true,
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
          child: Column(
            children: [
              Expanded(
                child: FadeSlideIn(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: Container(
                      width: double.infinity,
                      color: Colors.black,
                      child: bytes == null
                          ? Center(
                              child: CircularProgressIndicator(color: primary),
                            )
                          : Image.memory(bytes, fit: BoxFit.contain),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'Cropped problem preview',
                style: TextStyle(
                  color: colors.muted,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 18),
              Row(
                children: [
                  Expanded(
                    child: _ActionButton(
                      label: 'Retake',
                      icon: Icons.refresh_rounded,
                      onPressed: _isSolving ? null : _retake,
                      filled: false,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _ActionButton(
                      label: _isSolving ? 'Solving...' : 'Solve',
                      icon: Icons.arrow_forward_rounded,
                      onPressed: _isSolving ? null : _solve,
                      filled: true,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CoverCameraPreview extends StatelessWidget {
  final CameraController controller;

  const _CoverCameraPreview({required this.controller});

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    final previewSize = controller.value.previewSize;
    final previewAspect = previewSize == null
        ? controller.value.aspectRatio
        : previewSize.height / previewSize.width;

    return ClipRect(
      child: OverflowBox(
        alignment: Alignment.center,
        child: FittedBox(
          fit: BoxFit.cover,
          child: SizedBox(
            width: size.width,
            height: size.width / previewAspect,
            child: CameraPreview(controller),
          ),
        ),
      ),
    );
  }
}

class _CropShade extends StatelessWidget {
  final Rect crop;

  const _CropShade({required this.crop});

  @override
  Widget build(BuildContext context) {
    return CustomPaint(painter: _CropShadePainter(crop));
  }
}

class _CropShadePainter extends CustomPainter {
  final Rect crop;

  _CropShadePainter(this.crop);

  @override
  void paint(Canvas canvas, Size size) {
    final cropRect = Rect.fromLTWH(
      crop.left * size.width,
      crop.top * size.height,
      crop.width * size.width,
      crop.height * size.height,
    );
    final path = Path()..addRect(Offset.zero & size);
    final hole = Path()
      ..addRRect(RRect.fromRectAndRadius(cropRect, const Radius.circular(12)));
    canvas.drawPath(
      Path.combine(PathOperation.difference, path, hole),
      Paint()..color = Colors.black.withValues(alpha: 0.48),
    );
  }

  @override
  bool shouldRepaint(covariant _CropShadePainter oldDelegate) =>
      oldDelegate.crop != crop;
}

class _InteractiveCropBox extends StatelessWidget {
  final Rect crop;
  final Color color;
  final ValueChanged<Rect> onChanged;

  const _InteractiveCropBox({
    required this.crop,
    required this.color,
    required this.onChanged,
  });

  static const _minW = 0.28;
  static const _minH = 0.12;

  Rect _clamp(Rect rect) {
    final width = rect.width.clamp(_minW, 0.96);
    final height = rect.height.clamp(_minH, 0.86);
    final left = rect.left.clamp(0.02, 0.98 - width);
    final top = rect.top.clamp(0.04, 0.96 - height);
    return Rect.fromLTWH(left, top, width, height);
  }

  void _move(DragUpdateDetails details, Size size) {
    onChanged(_clamp(crop.translate(
      details.delta.dx / size.width,
      details.delta.dy / size.height,
    )));
  }

  void _resize(DragUpdateDetails details, Size size, Alignment corner) {
    final dx = details.delta.dx / size.width;
    final dy = details.delta.dy / size.height;
    var left = crop.left;
    var top = crop.top;
    var right = crop.right;
    var bottom = crop.bottom;

    if (corner.x < 0) left += dx;
    if (corner.x > 0) right += dx;
    if (corner.y < 0) top += dy;
    if (corner.y > 0) bottom += dy;

    onChanged(_clamp(Rect.fromLTRB(left, top, right, bottom)));
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final size = Size(constraints.maxWidth, constraints.maxHeight);
        final rect = Rect.fromLTWH(
          crop.left * size.width,
          crop.top * size.height,
          crop.width * size.width,
          crop.height * size.height,
        );
        return Stack(
          children: [
            Positioned.fromRect(
              rect: rect,
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onPanUpdate: (details) => _move(details, size),
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: color, width: 2),
                  ),
                  child: CustomPaint(painter: _GridPainter(color)),
                ),
              ),
            ),
            for (final corner in const [
              Alignment.topLeft,
              Alignment.topRight,
              Alignment.bottomLeft,
              Alignment.bottomRight,
            ])
              _Handle(
                rect: rect,
                corner: corner,
                color: color,
                onDrag: (details) => _resize(details, size, corner),
              ),
          ],
        );
      },
    );
  }
}

class _Handle extends StatelessWidget {
  final Rect rect;
  final Alignment corner;
  final Color color;
  final ValueChanged<DragUpdateDetails> onDrag;

  const _Handle({
    required this.rect,
    required this.corner,
    required this.color,
    required this.onDrag,
  });

  @override
  Widget build(BuildContext context) {
    final left = corner.x < 0 ? rect.left - 15 : rect.right - 15;
    final top = corner.y < 0 ? rect.top - 15 : rect.bottom - 15;
    return Positioned(
      left: left,
      top: top,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onPanUpdate: onDrag,
        child: Container(
          width: 30,
          height: 30,
          alignment: Alignment.center,
          child: Container(
            width: 18,
            height: 18,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white, width: 2),
            ),
          ),
        ),
      ),
    );
  }
}

class _GridPainter extends CustomPainter {
  final Color color;

  _GridPainter(this.color);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withValues(alpha: 0.38)
      ..strokeWidth = 1;
    for (final x in [size.width / 3, size.width * 2 / 3]) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }
    for (final y in [size.height / 3, size.height * 2 / 3]) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  @override
  bool shouldRepaint(covariant _GridPainter oldDelegate) =>
      oldDelegate.color != color;
}

class _CircleIconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onPressed;

  const _CircleIconButton({required this.icon, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.black.withValues(alpha: 0.45),
      shape: const CircleBorder(),
      child: IconButton(
        icon: Icon(icon, color: Colors.white),
        onPressed: onPressed,
      ),
    );
  }
}

class _BottomToolButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback? onTap;

  const _BottomToolButton({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colors = AppTheme.colorsOf(context);
    return TapScale(
      onTap: onTap,
      child: SizedBox(
        width: 78,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: colors.ink, size: 22),
            const SizedBox(height: 5),
            Text(
              label,
              style: TextStyle(
                color: colors.muted,
                fontSize: 11.5,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final VoidCallback? onPressed;
  final bool filled;

  const _ActionButton({
    required this.label,
    required this.icon,
    required this.onPressed,
    required this.filled,
  });

  @override
  Widget build(BuildContext context) {
    final colors = AppTheme.colorsOf(context);
    final primary = AppPreferences.palette.value.primary;
    final color = filled ? primary : colors.ink;
    return TapScale(
      onTap: onPressed,
      child: Container(
        height: 52,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: filled ? primary : colors.border),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: color, size: 18),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                color: color,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CameraFallback extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;
  final VoidCallback onGallery;

  const _CameraFallback({
    required this.message,
    required this.onRetry,
    required this.onGallery,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.camera_alt_outlined,
                color: Colors.white70, size: 48),
            const SizedBox(height: 16),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.white, height: 1.4),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: onRetry,
                    child: const Text('Try Again'),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: OutlinedButton(
                    onPressed: onGallery,
                    child: const Text('Gallery'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
