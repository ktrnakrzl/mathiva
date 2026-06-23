import 'dart:io';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';

import '../presentation/widgets/animated_background.dart';
import '../presentation/widgets/fade_slide_in.dart';
import '../presentation/widgets/tap_scale.dart';
import '../services/app_preferences.dart';
import '../utils/route_names.dart';
import '../widgets/mathiva_bottom_nav.dart';

// ── Design tokens (mirrors HomeScreen exactly) ────────────────────────────────
const _ink = Color(0xFF111827);
const _muted = Color(0xFF6B7280);
const _border = Color(0xFFE5E7EB);
const _surface = Color(0xFFFFFFFF);
const _pageBg = Color(0xFFF8F9FB);

// Shared app-chrome surface — matches the HomeScreen header tint so this
// screen's AppBar reads as the same chrome layer, not a separate white bar.
const _chromeSurface = Color(0xFFF6F5FB);
const _chromeBorder = Color(0xFFEAE8F5);

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

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);
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
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        behavior: SnackBarBehavior.floating,
        backgroundColor: _ink,
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

  void _onContinueToSolve() {
    context.push(RouteNames.solution);
  }

  @override
  Widget build(BuildContext context) {
    final primary = AppPreferences.palette.value.primary;

    return Scaffold(
      extendBody: _step == _SolverStep.scan,
      backgroundColor: _step == _SolverStep.crop ? Colors.black : _pageBg,
      appBar: AppBar(
        backgroundColor:
            _step == _SolverStep.crop ? Colors.black : _chromeSurface,
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
            color: _step == _SolverStep.crop ? Colors.white : _ink,
            size: 22,
          ),
          onPressed: () => _onBack(),
        ),
        title: Text(
          _titleFor(_step),
          style: TextStyle(
            color: _step == _SolverStep.crop
                ? Colors.white
                : const Color(0xFF312E81),
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
        bottom: _step == _SolverStep.crop
            ? null
            : PreferredSize(
                preferredSize: const Size.fromHeight(1),
                child: Container(height: 1, color: _chromeBorder),
              ),
      ),
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
    return AnimatedBackground(
      child: SafeArea(
        top: false,
        child: LayoutBuilder(
          builder: (context, constraints) {
            return Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
              child: Column(
                children: [
                  // ── Scanner viewport (hero) ─────────────────────────────
                  Expanded(
                    child: FadeSlideIn(
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(20),
                        child: Container(
                          width: double.infinity,
                          decoration: BoxDecoration(
                            color: primary.withOpacity(0.05),
                            border: Border.all(
                              color: primary.withOpacity(0.14),
                              width: 1,
                            ),
                          ),
                          child: Stack(
                            alignment: Alignment.center,
                            children: [
                              Icon(
                                Icons.document_scanner_rounded,
                                color: primary.withOpacity(0.16),
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
                                        color: primary.withOpacity(0.6),
                                        borderRadius: BorderRadius.circular(99),
                                      ),
                                    ),
                                  );
                                },
                              ),
                              ..._cornerGuides(primary),
                              Positioned(
                                bottom: 18,
                                child: Text(
                                  'Align the problem within the frame',
                                  style: TextStyle(
                                    color: primary.withOpacity(0.55),
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
                  const SizedBox(height: 16),

                  // ── Actions ──────────────────────────────────────────────
                  FadeSlideIn(
                    delay: const Duration(milliseconds: 100),
                    child: Row(
                      children: [
                        Expanded(
                          child: _ScanActionButton(
                            label: 'Open Camera',
                            icon: Icons.camera_alt_rounded,
                            primary: primary,
                            filled: true,
                            onPressed: onOpenCamera,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: _ScanActionButton(
                            label: 'Gallery',
                            icon: Icons.image_outlined,
                            primary: primary,
                            filled: false,
                            onPressed: onOpenGallery,
                          ),
                        ),
                      ],
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
    final color = primary.withOpacity(0.5);
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
  final VoidCallback onRetake;
  final VoidCallback onEditCrop;
  final VoidCallback onContinue;

  const _PreviewStage({
    super.key,
    required this.primary,
    required this.image,
    required this.onRetake,
    required this.onEditCrop,
    required this.onContinue,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: _pageBg,
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
          child: Column(
            children: [
              Expanded(
                child: FadeSlideIn(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(20),
                    child: Container(
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: _surface,
                        border: Border.all(color: _border, width: 1),
                        boxShadow: const [
                          BoxShadow(
                            color: Color(0x08000000),
                            blurRadius: 10,
                            offset: Offset(0, 3),
                          ),
                        ],
                      ),
                      child: _PickedImageView(image: image),
                    ),
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
                        onPressed: onRetake,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _ScanActionButton(
                        label: 'Continue',
                        icon: Icons.arrow_forward_rounded,
                        primary: primary,
                        filled: true,
                        onPressed: onContinue,
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
    if (image == null) {
      return Container(
        color: const Color(0xFFFDFDFD),
        child: const Center(
          child: Text(
            'No image yet',
            style: TextStyle(color: _muted, fontSize: 14),
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
          color: const Color(0xFFFDFDFD),
          child: const Center(
            child: Padding(
              padding: EdgeInsets.all(24),
              child: Text(
                'Could not load this image.',
                textAlign: TextAlign.center,
                style: TextStyle(color: _muted, fontSize: 14),
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
  final VoidCallback onPressed;

  const _ScanActionButton({
    required this.label,
    required this.icon,
    required this.primary,
    required this.filled,
    required this.onPressed,
    this.dark = false,
  });

  @override
  Widget build(BuildContext context) {
    // Primary actions get the accent color outline/text; secondary actions
    // get a neutral outline/text. `dark` (used on the black crop screen)
    // swaps the neutral tone for a white-on-black equivalent.
    final accentColor = filled ? primary : (dark ? Colors.white : _ink);
    final outlineColor = filled ? primary : (dark ? Colors.white24 : _border);

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
