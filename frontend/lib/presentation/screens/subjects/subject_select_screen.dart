import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:mathiva/data/models/subject_models.dart';
import 'package:mathiva/data/providers/repository_providers.dart';
import 'package:mathiva/presentation/widgets/loading_overlay.dart';
import 'package:mathiva/presentation/widgets/animated_background.dart';
import 'package:mathiva/presentation/widgets/fade_slide_in.dart';
import 'package:mathiva/presentation/widgets/section_header.dart';
import 'package:mathiva/presentation/widgets/tap_scale.dart';
import 'package:mathiva/services/app_preferences.dart';
import '../../../widgets/mathiva_app_bar.dart';

const _ink = Color(0xFF242033);
const _muted = Color(0xFF8C879A);

final subjectsProvider = FutureProvider<List<Subject>>((ref) {
  return ref.read(subjectRepositoryProvider).getSubjects();
});

class SubjectSelectScreen extends ConsumerWidget {
  const SubjectSelectScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final subjects = ref.watch(subjectsProvider);
    final palette = AppPreferences.palette.value;
    return Scaffold(
      backgroundColor: Colors.transparent,
      extendBodyBehindAppBar: true,
      appBar: MathivaAppBar(
        title: 'Select Subject',
        subtitle: 'Choose what to study',
        icon: Icons.school_rounded,
        showBack: true,
      ),
      body: AnimatedBackground(
        child: SafeArea(
          top: false,
          child: subjects.when(
            data: (items) => ListView.separated(
              padding: const EdgeInsets.fromLTRB(16, 70, 16, 28),
              physics: const BouncingScrollPhysics(),
              itemCount: items.length + 1,
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                if (index == 0) {
                  return const SectionHeader(
                    title: 'Select Subject',
                    subtitle: 'Choose what to study today',
                  );
                }
                final subject = items[index - 1];
                return FadeSlideIn(
                  delay: Duration(milliseconds: 60 * index),
                  child: _SoftCard(
                    onTap: () => context.go('/subjects/${subject.subject_id}/topics'),
                    child: Row(children: [
                      Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [palette.primary.withOpacity(.16), palette.secondary.withOpacity(.16)],
                          ),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Icon(Icons.menu_book_rounded, color: palette.primary),
                      ),
                      const SizedBox(width: 12),
                      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Text(subject.name, style: const TextStyle(color: _ink, fontWeight: FontWeight.w900, fontSize: 16)),
                        Text(subject.grade_level, style: const TextStyle(color: _muted)),
                      ])),
                      Icon(Icons.chevron_right_rounded, color: palette.primary),
                    ]),
                  ),
                );
              },
            ),
            loading: () => const LoadingOverlay(),
            error: (error, _) => Center(child: Text('Error: $error')),
          ),
        ),
      ),
    );
  }
}

class _SoftCard extends StatelessWidget {
  final Widget child;
  final VoidCallback? onTap;
  const _SoftCard({required this.child, this.onTap});

  @override
  Widget build(BuildContext context) {
    final card = Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFFF7F9FC).withOpacity(.92),
        borderRadius: BorderRadius.circular(20),
        boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 16, offset: Offset(0, 8))],
      ),
      child: child,
    );
    if (onTap == null) return card;
    return TapScale(onTap: onTap, child: card);
  }
}
