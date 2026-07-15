import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../nike_colors.dart';
import '../theme_notifier.dart';
import '../font_scale_notifier.dart';
import '../services/chatbot_service.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Shared header controls — circular icon button (back / menu) + slide-in
// nav drawer. Used across every screen so navigation stays consistent now
// that the floating pill nav bar is gone.
// ─────────────────────────────────────────────────────────────────────────────

/// 40x40 circular icon button matching the app's established back-button
/// style (dark translucent bg, bordered). Used for both back arrows and
/// the hamburger menu trigger.
class CircleIconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onTap;
  final NikeColors c;

  const CircleIconButton({
    super.key,
    required this.icon,
    required this.onTap,
    required this.c,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: c.card2,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: c.border),
        ),
        child: Icon(icon, color: c.text, size: 20),
      ),
    );
  }
}

class NavDrawerItem {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool selected;

  const NavDrawerItem({
    required this.icon,
    required this.label,
    required this.onTap,
    this.selected = false,
  });
}

/// Slide-in drawer listing navigation destinations (+ optional Sign Out).
/// Pass items in display order; the last item is visually separated if
/// [signOut] is provided.
class NavDrawer extends StatelessWidget {
  final NikeColors c;
  final List<NavDrawerItem> items;
  final ChatPersona? chatPersona;
  final VoidCallback? onSignOut;
  /// Extra widget inserted after nav items/chat, before the theme toggle.
  /// Used by the Inspector drawer to show the productivity stats row.
  final Widget? extra;
  final bool showThemeToggle;
  /// Which dark/light switch this drawer's toggle controls. Defaults to the
  /// app-wide [isDarkMode]; Inspector passes its own [inspectorDarkMode] so
  /// its toggle never affects Customer or Admin.
  final ValueNotifier<bool>? themeNotifier;
  /// Text for the sign-out row — Inspector uses "Punch Out" to match its
  /// Employee ID + PIN entry flow; other personas keep the default.
  final String signOutLabel;

  const NavDrawer({
    super.key,
    required this.c,
    this.signOutLabel = 'Sign Out',
    required this.items,
    this.chatPersona,
    this.onSignOut,
    this.extra,
    this.showThemeToggle = true,
    this.themeNotifier,
  });

  @override
  Widget build(BuildContext context) {
    // The drawer itself stays at a fixed text scale regardless of the app's
    // font-size setting below — a 260px-wide menu can't safely grow to 160%.
    return MediaQuery(
      data: MediaQuery.of(context).copyWith(textScaler: TextScaler.noScaling),
      child: Drawer(
      backgroundColor: c.card,
      width: 260,
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 20),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Text(
                'MENU',
                style: GoogleFonts.bebasNeue(
                  fontSize: 22,
                  color: c.text,
                  letterSpacing: 2,
                ),
              ),
            ),
            const SizedBox(height: 24),
            for (final item in items) _tile(item),
            if (chatPersona != null)
              ListTile(
                leading: Icon(Icons.chat_bubble_outline, color: c.sub),
                title: Text(
                  'Nike Bot',
                  style: GoogleFonts.nunito(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: c.text,
                  ),
                ),
                onTap: () {
                  Navigator.of(context).pop();
                  requestOpenChat.value = chatPersona;
                },
              ),
            if (extra != null) ...[
              Divider(color: c.border, height: 32, indent: 20, endIndent: 20),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: extra!,
              ),
            ],
            Divider(color: c.border, height: 32, indent: 20, endIndent: 20),
            if (showThemeToggle) ...[
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: _ThemeToggle(c: c, notifier: themeNotifier ?? isDarkMode),
              ),
              const SizedBox(height: 20),
            ],
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: _FontSizeControl(c: c),
            ),
            if (onSignOut != null) ...[
              Divider(color: c.border, height: 32, indent: 20, endIndent: 20),
              ListTile(
                leading: Icon(Icons.logout, color: c.sub),
                title: Text(
                  signOutLabel,
                  style: GoogleFonts.nunito(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: c.sub,
                  ),
                ),
                onTap: onSignOut,
              ),
            ],
          ],
        ),
      ),
      ),
    );
  }

  Widget _tile(NavDrawerItem item) {
    return ListTile(
      leading: Icon(item.icon, color: c.sub),
      title: Text(
        item.label,
        style: GoogleFonts.nunito(
          fontSize: 15,
          fontWeight: FontWeight.w700,
          color: item.selected ? c.accent : c.text,
        ),
      ),
      onTap: item.onTap,
    );
  }
}

/// Dark/light mode switch, embedded in [NavDrawer] so it's reachable from
/// the hamburger menu on every screen instead of only the Profile tab.
class _ThemeToggle extends StatelessWidget {
  final NikeColors c;
  final ValueNotifier<bool> notifier;
  const _ThemeToggle({required this.c, required this.notifier});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<bool>(
      valueListenable: notifier,
      builder: (_, dark, __) => GestureDetector(
        onTap: () => notifier.value = !notifier.value,
        child: Row(
          children: [
            Icon(
              dark ? Icons.light_mode_outlined : Icons.dark_mode_outlined,
              color: c.sub, size: 20,
            ),
            const SizedBox(width: 12),
            Text(
              dark ? 'Dark Mode' : 'Light Mode',
              style: GoogleFonts.nunito(
                fontSize: 14,
                color: c.text,
                fontWeight: FontWeight.w700,
              ),
            ),
            const Spacer(),
            Container(
              width: 44, height: 24,
              decoration: BoxDecoration(
                color: dark ? c.accent.withOpacity(0.2) : c.accent,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: c.accent.withOpacity(0.6)),
              ),
              child: AnimatedAlign(
                duration: const Duration(milliseconds: 200),
                curve: Curves.easeOutCubic,
                alignment: dark ? Alignment.centerLeft : Alignment.centerRight,
                child: Container(
                  width: 18, height: 18,
                  margin: const EdgeInsets.symmetric(horizontal: 3),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: dark ? c.sub : NikeColors.black,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Text-size stepper (5 steps, 100%–160%), embedded in [NavDrawer] so it's
/// reachable from every screen — the fix for "too small to read on the
/// projector" complaints during presentations.
class _FontSizeControl extends StatelessWidget {
  final NikeColors c;
  const _FontSizeControl({required this.c});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<double>(
      valueListenable: fontScale,
      builder: (_, scale, __) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.text_fields_rounded, color: c.sub, size: 20),
                const SizedBox(width: 12),
                Text(
                  'Text Size',
                  style: GoogleFonts.nunito(
                    fontSize: 14,
                    color: c.text,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const Spacer(),
                Text(
                  '${(scale * 100).round()}%',
                  style: GoogleFonts.nunito(fontSize: 12, color: c.sub),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                for (var i = 0; i < fontScaleSteps.length; i++) ...[
                  if (i > 0) const SizedBox(width: 6),
                  Expanded(child: _step(i, scale)),
                ],
              ],
            ),
          ],
        );
      },
    );
  }

  Widget _step(int i, double scale) {
    final active = fontScaleSteps[i] == scale;
    return GestureDetector(
      onTap: () => fontScale.value = fontScaleSteps[i],
      child: Container(
        height: 30,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: active ? c.accent : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: active ? c.accent : c.border),
        ),
        child: Text(
          'A',
          style: GoogleFonts.nunito(
            fontSize: 12 + i * 2.0,
            fontWeight: FontWeight.w800,
            color: active ? c.bg : c.sub,
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Inspector productivity stats — collapsed behind a "Your Stats" row so the
// drawer stays uncluttered. These are THIS SHIFT'S numbers only (INS-SHF-*),
// reset to zero on sign out via resetInspectorShiftStats() — the permanent,
// never-reset lifetime totals (INS-SCN/INS-TTM) live on the Profile screen
// instead, not here.
// ─────────────────────────────────────────────────────────────────────────────

/// Resets this inspector's current-shift counters (not the lifetime ones on
/// Profile) — call right before signing out so the next shift starts at
/// zero.
Future<void> resetInspectorShiftStats() async {
  final uid = FirebaseAuth.instance.currentUser?.uid;
  if (uid == null) return;
  await FirebaseFirestore.instance.collection('users').doc(uid).update({
    'INS-SHF-SCN': 0,
    'INS-SHF-TTM': 0,
  });
}

class InspectorStatsRow extends StatefulWidget {
  final NikeColors c;
  const InspectorStatsRow({super.key, required this.c});

  @override
  State<InspectorStatsRow> createState() => _InspectorStatsRowState();
}

class _InspectorStatsRowState extends State<InspectorStatsRow> {
  bool _expanded = false;
  int? _scanned;
  double? _totalSeconds;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;
    final doc = await FirebaseFirestore.instance.collection('users').doc(uid).get();
    if (!mounted) return;
    final data = doc.data();
    setState(() {
      _scanned      = (data?['INS-SHF-SCN'] as num?)?.toInt() ?? 0;
      _totalSeconds = (data?['INS-SHF-TTM'] as num?)?.toDouble() ?? 0;
    });
  }

  @override
  Widget build(BuildContext context) {
    final c = widget.c;
    final scanned = _scanned ?? 0;
    final avg = (_scanned != null && _scanned! > 0)
        ? _totalSeconds! / _scanned!
        : 0.0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        GestureDetector(
          onTap: () => setState(() => _expanded = !_expanded),
          child: Row(
            children: [
              Icon(Icons.bar_chart_rounded, color: c.sub, size: 20),
              const SizedBox(width: 12),
              Text(
                'This Shift',
                style: GoogleFonts.nunito(
                  fontSize: 14,
                  color: c.text,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const Spacer(),
              Icon(
                _expanded ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
                color: c.sub,
                size: 20,
              ),
            ],
          ),
        ),
        AnimatedCrossFade(
          duration: const Duration(milliseconds: 200),
          crossFadeState:
              _expanded ? CrossFadeState.showFirst : CrossFadeState.showSecond,
          firstChild: Padding(
            padding: const EdgeInsets.only(top: 12),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: c.card2,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: c.border),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _statLine('Shoes scanned', '$scanned', c),
                  const SizedBox(height: 6),
                  _statLine(
                    'Avg time/shoe',
                    scanned > 0 ? '${avg.toStringAsFixed(1)}s' : '—',
                    c,
                  ),
                ],
              ),
            ),
          ),
          secondChild: const SizedBox(width: double.infinity),
        ),
      ],
    );
  }

  Widget _statLine(String label, String value, NikeColors c) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: GoogleFonts.nunito(fontSize: 13, color: c.sub)),
        Text(value,
            style: GoogleFonts.nunito(
                fontSize: 13, color: c.accent, fontWeight: FontWeight.w700)),
      ],
    );
  }
}
