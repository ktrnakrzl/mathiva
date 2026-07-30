import 'dart:typed_data';
import 'dart:ui';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:image_picker/image_picker.dart';

import '../presentation/widgets/animated_background.dart';
import '../presentation/widgets/fade_slide_in.dart';
import '../presentation/widgets/glass_card.dart';
import '../presentation/widgets/tap_scale.dart';
import '../services/app_preferences.dart';
import '../services/scan_history_service.dart';
import '../services/solver_service.dart';
import '../theme/app_theme.dart';
import '../utils/route_names.dart';
import '../widgets/mathiva_bottom_nav.dart';
import '../widgets/mathiva_top_bar.dart';

/// The two steps of the scan → solve workflow. Cropping is delegated to the
/// native image_cropper tool (launched from the preview), so it isn't a step
/// here. Navigation/routing elsewhere is untouched — only what happens *within*
/// the Image Solver screen is affected.
enum _SolverStep { scan, preview }

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
  XFile? _pickedImage;
  Uint8List? _pickedImageBytes;

  // True while the picked image is being uploaded and solved.
  bool _isSolving = false;
  bool _isPicking = false;

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
      if (mounted && !kIsWeb) _onOpenCamera();
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
    if (_isPicking) return;
    setState(() => _isPicking = true);
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
        _pickedImage = file;
        _pickedImageBytes = null;
        _step = _SolverStep.preview;
      });
      final bytes = await file.readAsBytes();
      if (!mounted || _pickedImage?.path != file.path) return;
      setState(() => _pickedImageBytes = bytes);
    } catch (e) {
      if (!mounted) return;
      _showPickError(
        source == ImageSource.camera
            ? 'Could not open the camera. Please check camera permissions and try again.'
            : 'Could not open the gallery. Please try again.',
      );
    } finally {
      if (mounted) setState(() => _isPicking = false);
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
      _pickedImageBytes = null;
    });
  }

  /// Launch the native crop tool on the picked photo and, if the user confirms,
  /// replace _pickedImage with the cropped file — so the *cropped* image is what
  /// gets uploaded to /api/solve-image. Cropping tightly around the equation is
  /// what actually lets pix2tex read it (a full photo with background rarely
  /// reads), which is why this replaced the old preview-only crop overlay.
  Future<void> _onCrop() async {
    final image = _pickedImage;
    if (image == null) return;
    try {
      final cropped = await ImageCropper().cropImage(
        sourcePath: image.path,
        uiSettings: [
          AndroidUiSettings(
            toolbarTitle: 'Crop to math problem',
            toolbarColor: Colors.black,
            toolbarWidgetColor: Colors.white,
            lockAspectRatio: false,
            aspectRatioPresets: [
              CropAspectRatioPreset.original,
              CropAspectRatioPreset.square,
              CropAspectRatioPreset.ratio3x2,
              CropAspectRatioPreset.ratio16x9,
            ],
          ),
          IOSUiSettings(
            title: 'Crop to math problem',
            aspectRatioPresets: [
              CropAspectRatioPreset.original,
              CropAspectRatioPreset.square,
              CropAspectRatioPreset.ratio3x2,
              CropAspectRatioPreset.ratio16x9,
            ],
          ),
          WebUiSettings(
            context: context,
            presentStyle: WebPresentStyle.dialog,
          ),
        ],
      );
      if (!mounted || cropped == null) return;
      final croppedFile =
          XFile(cropped.path, name: cropped.path.split('/').last);
      final bytes = await croppedFile.readAsBytes();
      if (!mounted) return;
      setState(() {
        _pickedImage = croppedFile;
        _pickedImageBytes = bytes;
      });
    } catch (e) {
      if (!mounted) return;
      _showPickError('Could not open the crop tool. Please try again.');
    }
  }

  Future<void> _onContinueToSolve() async {
    final image = _pickedImage;
    if (image == null || _isSolving) return;

    setState(() => _isSolving = true);
    try {
      final problem = await SolverService.solveImage(image);
      // Record the solved scan so the home screen's "Recent" list shows real
      // activity (persisted on-device -- see ScanHistoryService).
      await ScanHistoryService.record(problem);
      if (!mounted) return;
      context.push(RouteNames.solution, extra: problem);
    } catch (e) {
      if (!mounted) return;
      _showPickError(
        e is SolverServiceException
            ? e.message
            : 'Could not solve this problem. Please try again.',
      );
    } finally {
      if (mounted) setState(() => _isSolving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final primary = AppPreferences.palette.value.primary;
    final colors = AppTheme.colorsOf(context);

    // Scan is a main tab → the shared brand top bar. Preview is an in-flow
    // detail step that needs a back affordance, so it keeps the dedicated
    // glass bar matching the app chrome.
    final PreferredSizeWidget appBar = _step == _SolverStep.scan
        ? const MathivaTopBar() as PreferredSizeWidget
        : PreferredSize(
            preferredSize: const Size.fromHeight(58),
            child: ClipRect(
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
                child: _buildAppBar(primary, glass: true),
              ),
            ),
          );

    return Scaffold(
      extendBody: _step == _SolverStep.scan,
      backgroundColor: colors.pageBg,
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
    }
  }

  String _titleFor(_SolverStep step) {
    switch (step) {
      case _SolverStep.scan:
        return 'Scan';
      case _SolverStep.preview:
        return 'Preview';
    }
  }

  Widget _buildStep(Color primary) {
    switch (_step) {
      case _SolverStep.scan:
        return _ScanStage(
          key: const ValueKey('scan'),
          controller: _controller,
          primary: primary,
          isPicking: _isPicking,
          onOpenCamera: _onOpenCamera,
          onOpenGallery: _onOpenGallery,
        );
      case _SolverStep.preview:
        return _PreviewStage(
          key: const ValueKey('preview'),
          primary: primary,
          image: _pickedImage,
          imageBytes: _pickedImageBytes,
          isSolving: _isSolving,
          onRetake: _onRetake,
          onEditCrop: _onCrop,
          onContinue: _onContinueToSolve,
        );
    }
  }
}

// ── Scan stage (camera-first entry point) ─────────────────────────────────────

class _ScanStage extends StatelessWidget {
  final AnimationController controller;
  final Color primary;
  final bool isPicking;
  final VoidCallback onOpenCamera;
  final VoidCallback onOpenGallery;

  const _ScanStage({
    super.key,
    required this.controller,
    required this.primary,
    required this.isPicking,
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
                        onTap: isPicking ? null : onOpenCamera,
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
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      if (isPicking) ...[
                                        SizedBox(
                                          width: 14,
                                          height: 14,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2,
                                            color:
                                                Colors.white.withOpacity(0.75),
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                      ],
                                      Text(
                                        isPicking
                                            ? 'Opening camera...'
                                            : 'Tap to open the camera',
                                        style: TextStyle(
                                          color: Colors.white.withOpacity(0.7),
                                          fontSize: 12.5,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ],
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
                      isLoading: isPicking,
                      onPressed: isPicking ? null : onOpenGallery,
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
  final XFile? image;
  final Uint8List? imageBytes;
  final bool isSolving;
  final VoidCallback onRetake;
  final VoidCallback onEditCrop;
  final VoidCallback onContinue;

  const _PreviewStage({
    super.key,
    required this.primary,
    required this.image,
    required this.imageBytes,
    required this.isSolving,
    required this.onRetake,
    required this.onEditCrop,
    required this.onContinue,
  });

  @override
  Widget build(BuildContext context) {
    final imageReady = imageBytes != null;
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
                    child: _PickedImageView(
                      image: image,
                      imageBytes: imageBytes,
                      isSolving: isSolving,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 10),
              FadeSlideIn(
                delay: const Duration(milliseconds: 40),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      imageReady
                          ? Icons.check_circle_rounded
                          : Icons.hourglass_top_rounded,
                      color: primary,
                      size: 16,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      imageReady
                          ? 'Photo captured'
                          : 'Preparing image preview...',
                      style: TextStyle(
                        color: AppTheme.colorsOf(context).muted,
                        fontSize: 12.5,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 10),

              // Edit crop — secondary, text-style action just above the CTAs.
              FadeSlideIn(
                delay: const Duration(milliseconds: 60),
                child: TapScale(
                  onTap: isSolving || !imageReady ? null : onEditCrop,
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
                        onPressed: isSolving || !imageReady ? null : onContinue,
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

// ── Picked image renderer ──────────────────────────────────────────────────────

/// Renders the actual picked photo via `Image.file`. Falls back to a plain
/// placeholder if, for whatever reason, no image is available yet (e.g. the
/// screen is rebuilt before a pick completes) — this should be rare since
/// the scan stage is shown until a pick succeeds, but keeps the UI from
/// breaking instead of crashing on a null file.
class _PickedImageView extends StatelessWidget {
  final XFile? image;
  final Uint8List? imageBytes;
  final bool isSolving;

  const _PickedImageView({
    required this.image,
    required this.imageBytes,
    required this.isSolving,
  });

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

    final bytes = imageBytes;
    if (bytes == null) {
      return Center(
        child: CircularProgressIndicator(
          color: AppPreferences.palette.value.primary,
        ),
      );
    }

    return Stack(
      fit: StackFit.expand,
      children: [
        Image.memory(
          bytes,
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
        ),
        if (isSolving)
          Container(
            color: Colors.black.withOpacity(0.46),
            child: const Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircularProgressIndicator(color: Colors.white),
                  SizedBox(height: 14),
                  Text(
                    'Solving with Mathiva...',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    'This can take a few seconds.',
                    style: TextStyle(color: Colors.white70, fontSize: 12),
                  ),
                ],
              ),
            ),
          ),
      ],
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
  final bool isLoading;
  final VoidCallback? onPressed;

  const _ScanActionButton({
    required this.label,
    required this.icon,
    required this.primary,
    required this.filled,
    required this.onPressed,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    final colors = AppTheme.colorsOf(context);

    // Primary actions get the accent color outline/text; secondary actions
    // get a neutral outline/text.
    final accentColor = filled ? primary : colors.ink;
    final outlineColor = filled ? primary : colors.border;

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
