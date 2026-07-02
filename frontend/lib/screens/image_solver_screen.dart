import 'dart:io';
import 'dart:math' as math;
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';

import '../presentation/widgets/animated_background.dart';
import '../presentation/widgets/fade_slide_in.dart';
import '../presentation/widgets/glass_card.dart';
import '../presentation/widgets/tap_scale.dart';
import '../services/app_preferences.dart';
import '../services/solver_service.dart';
import '../theme/app_theme.dart';
import '../utils/route_names.dart';
import '../widgets/mathiva_bottom_nav.dart';
import '../widgets/mathiva_top_bar.dart';

/// The three steps of the scan → solve workflow. Kept private to this file
/// since navigation/routing elsewhere is untouched — only what happens
/// *within* the Image Solver screen is affected.
enum _SolverStep { scan, preview, crop }

class ImageSolverScreen extends StatefulWidget {
  const ImageSolverScreen({super.key});

  @override
  State<ImageSolverScreen> createState() => _ImageSolverScreenState();
}

class _ImageSolverScreenState extends State<ImageSolverScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  final ImagePicker _picker = ImagePicker();

  _SolverStep _step = _SolverStep.scan;

  // The actual picked image (camera or gallery). Null until the user
  // successfully picks one — the scan stage is shown until then.
  File? _pickedImage;

  // True while the picked image is being uploaded and solved.
  bool _isSolving = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);

    // Open the camera immediately on entering this screen, rather than
    // waiting for the user to tap "Open Camera" — per manual test feedback,
    // the scan-first flow should put the camera up front. Scheduled for
    // after the first frame so `context`/`mounted` are safe to use inside
    // `_pickImage`.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _onOpenCamera();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _onOpenCamera() => _pickImage(ImageSource.camera);

  Future<void> _onOpenGallery() => _pickImage(ImageSource.gallery);

  Future<void> _pickImage(ImageSource source) async {
    try {
      final XFile? file = await _picker.pickImage(
        source: source,
        imageQuality: 90,
      );

      if (!mounted) return;

      if (file == null) {
        // User backed out of the camera/gallery without picking anything.
        _showPickError(
          source == ImageSource.camera
              ? 'No photo was taken. Please try again.'
              : 'No image was selected. Please try again.',
        );
        return;
      }

      setState(() {
        _pickedImage = File(file.path);
        _step = _SolverStep.preview;
      });
    } catch (e) {
      if (!mounted) return;
      _showPickError(
        source == ImageSource.camera
            ? 'Could not open the camera. Please check camera permissions and try again.'
            : 'Could not open the gallery. Please try again.',
      );
    }
  }

  void _showPickError(String message) {
    final colors = AppTheme.colorsOf(context);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message, style: TextStyle(color: colors.pageBg)),
        behavior: SnackBarBehavior.floating,
        backgroundColor: colors.ink,
      ),
    );
  }

  void _onRetake() {
    setState(() {
      _step = _SolverStep.scan;
      _pickedImage = null;
    });
  }

  void _onEditCrop() {
    setState(() => _step = _SolverStep.crop);
  }

  void _onCropDone() {
    setState(() => _step = _SolverStep.preview);
  }

  Future<void> _onContinueToSolve() async {
    final image = _pickedImage;
    if (image == null || _isSolving) return;

    setState(() => _isSolving = true);
    try {
      final problem = await SolverService.solveImage(image);
      if (!mounted) return;
      context.push(RouteNames.solution, extra: problem);
    } catch (e) {
      if (!mounted) return;
      _showPickError('Could not solve this problem. Please try again.');
    } finally {
      if (mounted) setState(() => _isSolving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final primary = AppPreferences.palette.value.primary;
    final colors = AppTheme.colorsOf(context);

    // Scan is a main tab → the shared brand top bar. Preview/crop are in-flow
    // detail steps that need a back affordance, so they keep the dedicated bar
    // (crop stays solid black; preview matches app chrome).
    final PreferredSizeWidget appBar = _step == _SolverStep.scan
        ? const MathivaTopBar() as PreferredSizeWidget
        : PreferredSize(
            preferredSize: const Size.fromHeight(58),
            child: _step == _SolverStep.crop
                ? _buildAppBar(primary, glass: false)
                : ClipRect(
                    child: BackdropFilter(
                      filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
                      child: _buildAppBar(primary, glass: true),
                    ),
                  ),
          );

    return Scaffold(
      extendBody: _step == _SolverStep.scan,
      backgroundColor:
          _step == _SolverStep.crop ? Colors.black : colors.pageBg,
      appBar: appBar,
      body: AnimatedSwitcher(
        duration: const Duration(milliseconds: 220),
        switchInCurve: Curves.easeOut,
        switchOutCurve: Curves.easeIn,
        child: _buildStep(primary),
      ),
      bottomNavigationBar: _step == _SolverStep.scan
          ? const MathivaBottomNav(selected: MathivaTab.scan)
          : null,
    );
  }

  AppBar _buildAppBar(Color primary, {required bool glass}) {
    final colors = AppTheme.colorsOf(context);

    return AppBar(
      backgroundColor: glass ? colors.glassFillStart : Colors.black,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      scrolledUnderElevation: 0,
      shadowColor: Colors.transparent,
      centerTitle: false,
      toolbarHeight: 58,
      titleSpacing: 4,
      leading: IconButton(
        icon: Icon(
          Icons.arrow_back_rounded,
          color: glass ? colors.ink : Colors.white,
          size: 22,
        ),
        onPressed: () => _onBack(),
      ),
      title: Text(
        _titleFor(_step),
        style: TextStyle(
          color: glass ? colors.titleColor : Colors.white,
          fontSize: 19,
          fontWeight: FontWeight.w600,
          letterSpacing: -0.2,
          height: 1,
        ),
      ),
      actions: _step == _SolverStep.scan
          ? [
              IconButton(
                tooltip: 'Ask Math Tutor',
                onPressed: () => context.push(RouteNames.chat),
                icon: Icon(
                  Icons.chat_bubble_outline_rounded,
                  color: primary,
                  size: 22,
                ),
              ),
              const SizedBox(width: 8),
            ]
          : null,
      bottom: glass
          ? PreferredSize(
              preferredSize: const Size.fromHeight(1),
              child: Container(height: 1, color: colors.glassBorder),
            )
          : null,
    );
  }

  void _onBack() {
    switch (_step) {
      case _SolverStep.scan:
        context.canPop() ? context.pop() : context.go('/home');
        break;
      case _SolverStep.preview:
        _onRetake();
        break;
      case _SolverStep.crop:
        // Discard crop adjustments and return to the preview.
        setState(() => _step = _SolverStep.preview);
        break;
    }
  }

  String _titleFor(_SolverStep step) {
    switch (step) {
      case _SolverStep.scan:
        return 'Scan';
      case _SolverStep.preview:
        return 'Preview';
      case _SolverStep.crop:
        return 'Crop';
    }
  }

  Widget _buildStep(Color primary) {
    switch (_step) {
      case _SolverStep.scan:
        return _ScanStage(
          key: const ValueKey('scan'),
          controller: _controller,
          primary: primary,
          onOpenCamera: _onOpenCamera,
          onOpenGallery: _onOpenGallery,
        );
      case _SolverStep.preview:
        return _PreviewStage(
          key: const ValueKey('preview'),
          primary: primary,
          image: _pickedImage,
          isSolving: _isSolving,
          onRetake: _onRetake,
          onEditCrop: _onEditCrop,
          onContinue: _onContinueToSolve,
        );
      case _SolverStep.crop:
        return _CropStage(
          key: const ValueKey('crop'),
          primary: primary,
          image: _pickedImage,
          onCancel: () => setState(() => _step = _SolverStep.preview),
          onDone: _onCropDone,
        );
    }
  }
}

// ── Scan stage (camera-first entry point) ─────────────────────────────────────

class _ScanStage extends StatelessWidget {
  final AnimationController controller;
  final Color primary;
  final VoidCallback onOpenCamera;
  final VoidCallback onOpenGallery;

  const _ScanStage({
    super.key,
    required this.controller,
    required this.primary,
    required this.onOpenCamera,
    required this.onOpenGallery,
  });

  @override
  Widget build(BuildContext context) {
    final colors = AppTheme.colorsOf(context);
    return AnimatedBackground(
      child: SafeArea(
        top: false,
        child: LayoutBuilder(
          builder: (context, constraints) {
            return Padding(
              padding: const EdgeInsets.fromLTRB(18, 22, 18, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Page title + subtitle (in-body, per the shell pattern).
                  Text(
                    'Scan a Problem',
                    style: AppTheme.serif(
                      fontSize: 26,
                      fontWeight: FontWeight.w600,
                      color: colors.ink,
                      height: 1.1,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Point your camera at a math problem to solve it',
                    style: TextStyle(
                      color: colors.muted,
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 18),

                  // ── Scanner viewport (solid dark camera frame) ──────────
                  // A solid near-black viewport (like a live camera feed
                  // placeholder) with accent corner brackets and a sweeping
                  // scan line. Tapping it (re-)opens the camera.
                  Expanded(
                    child: FadeSlideIn(
                      child: GestureDetector(
                        behavior: HitTestBehavior.opaque,
                        onTap: onOpenCamera,
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(20),
                          child: Container(
                            width: double.infinity,
                            decoration: const BoxDecoration(
                              color: Color(0xFF0B0B0F),
                            ),
                            child: Stack(
                              alignment: Alignment.center,
                              children: [
                                Icon(
                                  Icons.document_scanner_rounded,
                                  color: Colors.white.withOpacity(0.10),
                                  size: 72,
                                ),
                                AnimatedBuilder(
                                  animation: controller,
                                  builder: (context, child) {
                                    final h = constraints.maxHeight - 232;
                                    final travel = h > 60 ? h - 48 : 60.0;
                                    return Positioned(
                                      top: 24 + controller.value * travel,
                                      left: 24,
                                      right: 24,
                                      child: Container(
                                        height: 2,
                                        decoration: BoxDecoration(
                                          color: primary.withOpacity(0.85),
                                          borderRadius:
                                              BorderRadius.circular(99),
                                          boxShadow: [
                                            BoxShadow(
                                              color: primary.withOpacity(0.5),
                                              blurRadius: 8,
                                            ),
                                          ],
                                        ),
                                      ),
                                    );
                                  },
                                ),
                                ..._cornerGuides(primary),
                                Positioned(
                                  bottom: 18,
                                  child: Text(
                                    'Tap to open the camera',
                                    style: TextStyle(
                                      color: Colors.white.withOpacity(0.7),
                                      fontSize: 12.5,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // ── Actions ──────────────────────────────────────────────
                  // No "Open Camera" button -- the camera opens automatically
                  // on entry and the viewport above re-opens it on tap. Gallery
                  // is the only explicit action: pick an existing photo instead
                  // of taking one.
                  FadeSlideIn(
                    delay: const Duration(milliseconds: 100),
                    child: _ScanActionButton(
                      label: 'Choose from Gallery',
                      icon: Icons.image_outlined,
                      primary: primary,
                      filled: false,
                      onPressed: onOpenGallery,
                    ),
                  ),
                  const SizedBox(height: 16),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  /// Four corner L-shaped bracket guides for the scan viewport.
  List<Widget> _cornerGuides(Color primary) {
    const size = 22.0;
    const thickness = 2.5;
    final color = primary.withOpacity(0.9);
    final paint = BoxDecoration(color: color);

    Widget corner({required bool top, required bool left}) {
      return Positioned(
        top: top ? 16 : null,
        bottom: top ? null : 16,
        left: left ? 16 : null,
        right: left ? null : 16,
        child: SizedBox(
          width: size,
          height: size,
          child: Stack(
            children: [
              Positioned(
                top: top ? 0 : null,
                bottom: top ? null : 0,
                left: left ? 0 : null,
                right: left ? null : 0,
                child: Container(
                  width: size,
                  height: thickness,
                  decoration: paint,
                ),
              ),
              Positioned(
                top: top ? 0 : null,
                bottom: top ? null : 0,
                left: left ? 0 : null,
                right: left ? null : 0,
                child: Container(
                  width: thickness,
                  height: size,
                  decoration: paint,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return [
      corner(top: true, left: true),
      corner(top: true, left: false),
      corner(top: false, left: true),
      corner(top: false, left: false),
    ];
  }
}

// ── Preview stage ──────────────────────────────────────────────────────────────

class _PreviewStage extends StatelessWidget {
  final Color primary;
  final File? image;
  final bool isSolving;
  final VoidCallback onRetake;
  final VoidCallback onEditCrop;
  final VoidCallback onContinue;

  const _PreviewStage({
    super.key,
    required this.primary,
    required this.image,
    required this.isSolving,
    required this.onRetake,
    required this.onEditCrop,
    required this.onContinue,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedBackground(
      vivid: true,
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
          child: Column(
            children: [
              // GlassCard rather than a flat white frame — the photo itself
              // (BoxFit.contain) renders crisp on top since it's opaque, but
              // any letterboxed space around it shows the blurred vivid
              // background through, instead of dead white space.
              Expanded(
                child: FadeSlideIn(
                  child: GlassCard(
                    padding: EdgeInsets.zero,
                    child: _PickedImageView(image: image),
                  ),
                ),
              ),
              const SizedBox(height: 14),

              // Edit crop — secondary, text-style action just above the CTAs.
              FadeSlideIn(
                delay: const Duration(milliseconds: 60),
                child: TapScale(
                  onTap: onEditCrop,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.crop_rounded, size: 16, color: primary),
                        const SizedBox(width: 6),
                        Text(
                          'Crop to math problem',
                          style: TextStyle(
                            color: primary,
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 14),

              FadeSlideIn(
                delay: const Duration(milliseconds: 100),
                child: Row(
                  children: [
                    Expanded(
                      child: _ScanActionButton(
                        label: 'Retake',
                        icon: Icons.refresh_rounded,
                        primary: primary,
                        filled: false,
                        onPressed: isSolving ? null : onRetake,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _ScanActionButton(
                        label: isSolving ? 'Solving…' : 'Continue',
                        icon: Icons.arrow_forward_rounded,
                        primary: primary,
                        filled: true,
                        isLoading: isSolving,
                        onPressed: isSolving ? null : onContinue,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Crop stage ──────────────────────────────────────────────────────────────────

/// A minimal, from-scratch crop tool: a single draggable-corner rectangle
/// over the image. No rotation, no filters, no aspect presets — just enough
/// to isolate the relevant problem area, per the "avoid complex editing
/// tools" requirement.
class _CropStage extends StatefulWidget {
  final Color primary;
  final File? image;
  final VoidCallback onCancel;
  final VoidCallback onDone;

  const _CropStage({
    super.key,
    required this.primary,
    required this.image,
    required this.onCancel,
    required this.onDone,
  });

  @override
  State<_CropStage> createState() => _CropStageState();
}

class _CropStageState extends State<_CropStage> {
  // Crop rect expressed as fractions (0..1) of the image area, so it is
  // resolution-independent.
  Rect _crop = const Rect.fromLTRB(0.08, 0.22, 0.92, 0.62);

  static const double _handleTouchSize = 36;
  static const double _minSize = 0.12;

  int? _activeHandle; // 0=TL,1=TR,2=BL,3=BR, 4=move, null = none

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.black,
      child: SafeArea(
        top: false,
        child: Column(
          children: [
            Expanded(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final size =
                      Size(constraints.maxWidth, constraints.maxHeight);
                  return GestureDetector(
                    onPanStart: (details) =>
                        _onPanStart(details.localPosition, size),
                    onPanUpdate: (details) => _onPanUpdate(details.delta, size),
                    onPanEnd: (_) => setState(() => _activeHandle = null),
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        // Full image, shown at normal brightness.
                        Positioned.fill(
                          child: _PickedImageView(image: widget.image),
                        ),
                        // Dimming mask outside the crop rect, via four
                        // simple bars — straightforward and robust, no
                        // alignment math required.
                        ..._buildDimMask(size),
                        // Crop frame border + corner handles.
                        Positioned(
                          left: _crop.left * size.width,
                          top: _crop.top * size.height,
                          width: _crop.width * size.width,
                          height: _crop.height * size.height,
                          child: IgnorePointer(
                            child: Container(
                              decoration: BoxDecoration(
                                border: Border.all(
                                  color: widget.primary,
                                  width: 2,
                                ),
                              ),
                            ),
                          ),
                        ),
                        ..._buildHandles(size),
                      ],
                    ),
                  );
                },
              ),
            ),

            // ── Bottom action bar ─────────────────────────────────────────
            Container(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
              decoration: const BoxDecoration(color: Colors.black),
              child: Row(
                children: [
                  Expanded(
                    child: _ScanActionButton(
                      label: 'Cancel',
                      icon: Icons.close_rounded,
                      primary: widget.primary,
                      filled: false,
                      dark: true,
                      onPressed: widget.onCancel,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _ScanActionButton(
                      label: 'Done',
                      icon: Icons.check_rounded,
                      primary: widget.primary,
                      filled: true,
                      onPressed: widget.onDone,
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

  List<Widget> _buildHandles(Size size) {
    final points = <int, Offset>{
      0: Offset(_crop.left * size.width, _crop.top * size.height),
      1: Offset(_crop.right * size.width, _crop.top * size.height),
      2: Offset(_crop.left * size.width, _crop.bottom * size.height),
      3: Offset(_crop.right * size.width, _crop.bottom * size.height),
    };

    return points.entries.map((entry) {
      final p = entry.value;
      return Positioned(
        left: p.dx - _handleTouchSize / 2,
        top: p.dy - _handleTouchSize / 2,
        width: _handleTouchSize,
        height: _handleTouchSize,
        child: IgnorePointer(
          child: Center(
            child: Container(
              width: 18,
              height: 18,
              decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                border: Border.all(color: widget.primary, width: 2.5),
                boxShadow: const [
                  BoxShadow(
                    color: Color(0x33000000),
                    blurRadius: 4,
                    offset: Offset(0, 1),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }).toList();
  }

  /// Dims everything outside the crop rect using four simple bars (top,
  /// bottom, left, right) instead of any clipping/alignment trick — easy to
  /// reason about and resilient to edge cases (e.g. crop near the edges).
  List<Widget> _buildDimMask(Size size) {
    const dim = Color(0xB3000000); // ~70% black
    final left = _crop.left * size.width;
    final top = _crop.top * size.height;
    final right = _crop.right * size.width;
    final bottom = _crop.bottom * size.height;

    return [
      // Top bar: full width, above the crop.
      Positioned(
        left: 0,
        top: 0,
        right: 0,
        height: top,
        child: const IgnorePointer(child: ColoredBox(color: dim)),
      ),
      // Bottom bar: full width, below the crop.
      Positioned(
        left: 0,
        top: bottom,
        right: 0,
        bottom: 0,
        child: const IgnorePointer(child: ColoredBox(color: dim)),
      ),
      // Left bar: between top and bottom, left of the crop.
      Positioned(
        left: 0,
        top: top,
        width: left,
        height: bottom - top,
        child: const IgnorePointer(child: ColoredBox(color: dim)),
      ),
      // Right bar: between top and bottom, right of the crop.
      Positioned(
        left: right,
        top: top,
        right: 0,
        height: bottom - top,
        child: const IgnorePointer(child: ColoredBox(color: dim)),
      ),
    ];
  }

  void _onPanStart(Offset localPos, Size size) {
    final handlePositions = <int, Offset>{
      0: Offset(_crop.left * size.width, _crop.top * size.height),
      1: Offset(_crop.right * size.width, _crop.top * size.height),
      2: Offset(_crop.left * size.width, _crop.bottom * size.height),
      3: Offset(_crop.right * size.width, _crop.bottom * size.height),
    };

    for (final entry in handlePositions.entries) {
      if ((entry.value - localPos).distance <= _handleTouchSize) {
        setState(() => _activeHandle = entry.key);
        return;
      }
    }

    final cropPxRect = Rect.fromLTRB(
      _crop.left * size.width,
      _crop.top * size.height,
      _crop.right * size.width,
      _crop.bottom * size.height,
    );
    if (cropPxRect.contains(localPos)) {
      setState(() => _activeHandle = 4); // move whole rect
    } else {
      setState(() => _activeHandle = null);
    }
  }

  void _onPanUpdate(Offset delta, Size size) {
    if (_activeHandle == null) return;

    final dxF = delta.dx / size.width;
    final dyF = delta.dy / size.height;

    setState(() {
      switch (_activeHandle) {
        case 0: // top-left
          _crop = Rect.fromLTRB(
            math.min(_crop.left + dxF, _crop.right - _minSize).clamp(0.0, 1.0),
            math.min(_crop.top + dyF, _crop.bottom - _minSize).clamp(0.0, 1.0),
            _crop.right,
            _crop.bottom,
          );
          break;
        case 1: // top-right
          _crop = Rect.fromLTRB(
            _crop.left,
            math.min(_crop.top + dyF, _crop.bottom - _minSize).clamp(0.0, 1.0),
            math.max(_crop.right + dxF, _crop.left + _minSize).clamp(0.0, 1.0),
            _crop.bottom,
          );
          break;
        case 2: // bottom-left
          _crop = Rect.fromLTRB(
            math.min(_crop.left + dxF, _crop.right - _minSize).clamp(0.0, 1.0),
            _crop.top,
            _crop.right,
            math.max(_crop.bottom + dyF, _crop.top + _minSize).clamp(0.0, 1.0),
          );
          break;
        case 3: // bottom-right
          _crop = Rect.fromLTRB(
            _crop.left,
            _crop.top,
            math.max(_crop.right + dxF, _crop.left + _minSize).clamp(0.0, 1.0),
            math.max(_crop.bottom + dyF, _crop.top + _minSize).clamp(0.0, 1.0),
          );
          break;
        case 4: // move
          final w = _crop.width;
          final h = _crop.height;
          var newLeft = (_crop.left + dxF).clamp(0.0, 1.0 - w);
          var newTop = (_crop.top + dyF).clamp(0.0, 1.0 - h);
          _crop = Rect.fromLTWH(newLeft, newTop, w, h);
          break;
      }
    });
  }
}

// ── Picked image renderer ──────────────────────────────────────────────────────

/// Renders the actual picked photo via `Image.file`. Falls back to a plain
/// placeholder if, for whatever reason, no image is available yet (e.g. the
/// screen is rebuilt before a pick completes) — this should be rare since
/// the scan stage is shown until a pick succeeds, but keeps the UI from
/// breaking instead of crashing on a null file.
class _PickedImageView extends StatelessWidget {
  final File? image;

  const _PickedImageView({required this.image});

  @override
  Widget build(BuildContext context) {
    final colors = AppTheme.colorsOf(context);

    if (image == null) {
      return Container(
        color: colors.surface,
        child: Center(
          child: Text(
            'No image yet',
            style: TextStyle(color: colors.muted, fontSize: 14),
          ),
        ),
      );
    }

    return Image.file(
      image!,
      fit: BoxFit.contain,
      width: double.infinity,
      height: double.infinity,
      errorBuilder: (context, error, stackTrace) {
        return Container(
          color: colors.surface,
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Text(
                'Could not load this image.',
                textAlign: TextAlign.center,
                style: TextStyle(color: colors.muted, fontSize: 14),
              ),
            ),
          ),
        );
      },
    );
  }
}

// ── Scan Action Button ────────────────────────────────────────────────────────

// Minimal outline button. No fill, no shadow — every action (primary or
// secondary) reads the same way: a thin border with matching text/icon
// color. `filled` is kept as a parameter (rather than removed) so call
// sites don't need to change, but it now only controls *which color* the
// outline uses, not whether there's a fill — `filled: true` means "this is
// the primary action on this row", rendered with the accent color instead
// of neutral gray.
class _ScanActionButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color primary;
  final bool filled;
  final bool dark;
  final bool isLoading;
  final VoidCallback? onPressed;

  const _ScanActionButton({
    required this.label,
    required this.icon,
    required this.primary,
    required this.filled,
    required this.onPressed,
    this.dark = false,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    final colors = AppTheme.colorsOf(context);

    // Primary actions get the accent color outline/text; secondary actions
    // get a neutral outline/text. `dark` (used on the black crop screen)
    // swaps the neutral tone for a white-on-black equivalent.
    final accentColor = filled ? primary : (dark ? Colors.white : colors.ink);
    final outlineColor =
        filled ? primary : (dark ? Colors.white24 : colors.border);

    return TapScale(
      onTap: onPressed,
      child: Container(
        height: 52,
        decoration: BoxDecoration(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: outlineColor, width: 1),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (isLoading)
              SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: accentColor,
                ),
              )
            else
              Icon(icon, size: 18, color: accentColor),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 14.5,
                color: accentColor,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
