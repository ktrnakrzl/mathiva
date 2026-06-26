import 'package:flutter/material.dart';
import '../presentation/widgets/atmosphere_background.dart';
import '../presentation/widgets/tap_scale.dart';
import '../services/app_preferences.dart';
import 'package:go_router/go_router.dart';

import '../services/local_content_service.dart';
import '../utils/route_names.dart';
import '../widgets/mathiva_app_bar.dart';

// Shared tokens — identical values to HomeScreen's palette, so this screen
// reads as the same surface system rather than its own design.
const _ink = Color(0xFF111827);
const _muted = Color(0xFF6B7280);
const _border = Color(0xFFE5E7EB);
const _surface = Color(0xFFFFFFFF);
const _pageBg = Color(0xFFF8F9FB);

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  String _query = '';

  @override
  Widget build(BuildContext context) {
    final primary = AppPreferences.palette.value.primary;

    final subjects = LocalContentService().getSubjects();
    final filtered = subjects
        .where((subject) => subject.title.toLowerCase().contains(_query.toLowerCase()))
        .toList();

    return Scaffold(
      appBar: MathivaAppBar(
        title: 'Search',
        subtitle: 'Find topics and lessons',
        icon: Icons.search_rounded,
        showBack: true,
        onBack: () => context.canPop() ? context.pop() : context.go('/home'),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 18),
            child: TapScale(
              onTap: () => context.push(RouteNames.chat),
              child: Tooltip(
                message: 'Ask Math Tutor',
                child: Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: primary.withOpacity(0.09),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    Icons.chat_bubble_outline_rounded,
                    color: primary,
                    size: 19,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
      body: AtmosphereBackground(
        child: SafeArea(
          top: false,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
            physics: const BouncingScrollPhysics(),
            children: [
              TextField(
                onChanged: (value) => setState(() => _query = value),
                decoration: InputDecoration(
                  hintText: 'Search subjects or topics',
                  prefixIcon: Icon(Icons.search_rounded, color: _muted),
                  filled: true,
                  fillColor: _pageBg,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: const BorderSide(color: _border, width: 1),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: const BorderSide(color: _border, width: 1),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide(color: primary, width: 1.6),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              ...filtered.map(
                (subject) => Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: _SoftCard(
                    onTap: () => context.push(RouteNames.lessons, extra: {'subjectId': subject.id}),
                    child: Row(
                      children: [
                        Container(
                          width: 46,
                          height: 46,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: primary.withOpacity(0.08),
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: Icon(Icons.menu_book_rounded, color: primary, size: 22),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                subject.title,
                                style: const TextStyle(
                                  color: _ink,
                                  fontSize: 13.5,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                subject.gradeLevel,
                                style: const TextStyle(color: _muted, fontSize: 12),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        const Icon(Icons.chevron_right_rounded, color: _muted, size: 17),
                      ],
                    ),
                  ),
                ),
              ),
            ],
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
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _border, width: 1),
        boxShadow: const [
          BoxShadow(
            color: Color(0x08000000),
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: child,
    );

    if (onTap == null) return card;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: card,
      ),
    );
  }
}