// ignore_for_file: deprecated_member_use

import 'package:bill_split/core/utils/showcase_keys.dart';
import 'package:flutter/material.dart';
import 'package:showcaseview/showcaseview.dart';

// ─── Shared design tokens ─────────────────────────────────────────────────────
const _kBg = Color(0xFF12121E);
const _kBorder = Color(0xFF252540);
const _kAccent = Color(0xFF7C6EF8); // soft indigo matching AI/showcase identity
const _kAccentEnd = Color(0xFF38BDF8); // cyan gradient end
const _kTextPrimary = Color(0xFFF0F0FF);
const _kTextSecondary = Color(0xFF9494B8);
const _kHint = Color(0xFF5C5C7A);
const _kTooltipWidth = 272.0;

/// A branded, reusable showcase wrapper using [Showcase.withWidget].
///
/// Drop-in replacement for raw [Showcase] calls. Renders a consistent
/// dark tooltip card with a gradient accent bar, step counter, and
/// animated progress dots.
///
/// Usage:
/// ```dart
/// AppShowcase(
///   showcaseKey: ShowcaseKeys.profileAvatar,
///   title: 'Profile',
///   description: 'Tap to view your account details.',
///   icon: Icons.person_rounded,
///   child: YourWidget(),
/// )
/// ```
class AppShowcase extends StatelessWidget {
  final GlobalKey showcaseKey;
  final String title;
  final String description;
  final Widget child;

  /// The ordered set of keys this showcase belongs to (e.g.
  /// [ShowcaseKeys.homeGroup]), used to derive the step counter.
  final List<GlobalKey> group;

  /// Optional icon displayed inside the title row.
  final IconData? icon;

  const AppShowcase({
    super.key,
    required this.showcaseKey,
    required this.title,
    required this.description,
    required this.child,
    required this.group,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final step = ShowcaseKeys.stepIndexOf(showcaseKey, group);
    final total = group.length;

    return Showcase.withWidget(
      key: showcaseKey,
      overlayColor: Colors.black,
      overlayOpacity: 0.70,
      targetBorderRadius: BorderRadius.circular(14),
      targetPadding: const EdgeInsets.all(4),
      container: _TooltipCard(
        title: title,
        description: description,
        icon: icon,
        step: step,
        total: total,
      ),
      child: child,
    );
  }
}

// ─── Custom tooltip card ──────────────────────────────────────────────────────

class _TooltipCard extends StatelessWidget {
  final String title;
  final String description;
  final IconData? icon;
  final int step;
  final int total;

  const _TooltipCard({
    required this.title,
    required this.description,
    required this.step,
    required this.total,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: _kTooltipWidth,
      decoration: BoxDecoration(
        color: _kBg,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: _kBorder),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.45),
            blurRadius: 32,
            offset: const Offset(0, 10),
          ),
          BoxShadow(
            color: _kAccent.withOpacity(0.08),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(18),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Gradient accent bar ───────────────────────────────────
            Container(
              height: 3,
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [_kAccent, _kAccentEnd],
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                ),
              ),
            ),

            Padding(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  // ── Title row ─────────────────────────────────────
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      if (icon != null) ...[
                        Container(
                          padding: const EdgeInsets.all(7),
                          decoration: BoxDecoration(
                            color: _kAccent.withOpacity(0.12),
                            borderRadius: BorderRadius.circular(9),
                            border: Border.all(
                              color: _kAccent.withOpacity(0.28),
                            ),
                          ),
                          child: Icon(icon, size: 13, color: _kAccent),
                        ),
                        const SizedBox(width: 10),
                      ],
                      Expanded(
                        child: Text(
                          title,
                          style: const TextStyle(
                            color: _kTextPrimary,
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            fontFamily: 'Lato',
                            letterSpacing: -0.1,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      // Step badge
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color: _kAccent.withOpacity(0.10),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: _kAccent.withOpacity(0.30)),
                        ),
                        child: Text(
                          '$step / $total',
                          style: const TextStyle(
                            color: _kAccent,
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            fontFamily: 'Lato',
                            letterSpacing: 0.2,
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 10),

                  // ── Description ───────────────────────────────────
                  Text(
                    description,
                    style: const TextStyle(
                      color: _kTextSecondary,
                      fontSize: 12.5,
                      fontFamily: 'Lato',
                      fontWeight: FontWeight.w400,
                      height: 1.55,
                    ),
                  ),

                  const SizedBox(height: 14),

                  // ── Footer: hint + progress dots ──────────────────
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      const Icon(
                        Icons.touch_app_rounded,
                        size: 11,
                        color: _kHint,
                      ),
                      const SizedBox(width: 5),
                      const Text(
                        'Tap anywhere to continue',
                        style: TextStyle(
                          color: _kHint,
                          fontSize: 10,
                          fontFamily: 'Lato',
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const Spacer(),
                      _ProgressDots(current: step, total: total),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Progress dots ─────────────────────────────────────────────────────────────

class _ProgressDots extends StatelessWidget {
  final int current; // 1-based
  final int total;

  const _ProgressDots({required this.current, required this.total});

  @override
  Widget build(BuildContext context) {
    // Show at most 5 dots; slide window to keep current visible
    const maxDots = 5;
    final visibleCount = total.clamp(1, maxDots);
    final windowStart = ((current - 1) - (maxDots ~/ 2)).clamp(
      0,
      (total - maxDots).clamp(0, total),
    );
    final activeDotIndex = (current - 1 - windowStart).clamp(
      0,
      visibleCount - 1,
    );

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(visibleCount, (i) {
        final isActive = i == activeDotIndex;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          margin: const EdgeInsets.only(left: 4),
          width: isActive ? 14 : 5,
          height: 5,
          decoration: BoxDecoration(
            color: isActive ? _kAccent : _kBorder,
            borderRadius: BorderRadius.circular(3),
          ),
        );
      }),
    );
  }
}
