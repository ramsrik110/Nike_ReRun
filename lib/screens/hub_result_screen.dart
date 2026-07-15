import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../nike_colors.dart';
import '../theme_notifier.dart';
import '../utils/routing_algorithm.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Routing decision reveal. Purely monochrome, same flat theme as the rest of
// the Inspector persona — no color-coding between outcomes, since lime (and
// color generally) was dropped for this persona. Resellable vs recycle reads
// through the icon shape and the routing instruction text, not hue.
//
// Stays up until the inspector taps "Scan Next Shoe." — they need time to
// physically place the shoe in its tub before moving on, so this must not
// auto-dismiss.
// ─────────────────────────────────────────────────────────────────────────────

class HubResultScreen extends StatefulWidget {
  final RoutingResult result;

  const HubResultScreen({super.key, required this.result});

  @override
  State<HubResultScreen> createState() => _HubResultScreenState();
}

class _HubResultScreenState extends State<HubResultScreen> {
  bool get _isDark => inspectorDarkMode.value;
  NikeColors get _c => _isDark ? NikeColors.inspectorDark : NikeColors.inspectorLight;

  @override
  void initState() {
    super.initState();
    inspectorDarkMode.addListener(_onThemeChanged);
  }

  void _onThemeChanged() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    inspectorDarkMode.removeListener(_onThemeChanged);
    super.dispose();
  }

  void _scanNext() {
    if (Navigator.of(context).canPop()) Navigator.of(context).pop();
  }

  // One distinct icon per specific outcome. "To cleaning." never appears
  // as a headline (see routing_algorithm.dart) — cleaning shows only as
  // the small footnote below, using this same droplet icon.
  static IconData _iconFor(String routingInstruction) {
    switch (routingInstruction) {
      case 'To resale.':          return Icons.verified_outlined;
      case 'To fabric rework.':   return Icons.style_outlined;
      case 'To sole rework.':     return Icons.blur_circular_outlined;
      case 'To full recycle.':    return Icons.recycling_outlined;
      default:                    return Icons.recycling_outlined;
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = _c;
    final result = widget.result;

    return Scaffold(
      backgroundColor: c.bg,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 28),
          child: Column(
            children: [
              const Spacer(),
              Icon(
                _iconFor(result.routingInstruction),
                color: c.text,
                size: 44,
              ).animate().fadeIn(duration: 250.ms).scale(
                  begin: const Offset(0.7, 0.7), duration: 300.ms),
              const SizedBox(height: 20),
              Text(
                result.routingInstruction,
                textAlign: TextAlign.center,
                style: GoogleFonts.bebasNeue(
                    fontSize: 42, color: c.text, letterSpacing: 1, height: 1.05),
              ).animate().fadeIn(delay: 100.ms, duration: 300.ms),
              const SizedBox(height: 14),
              Text(
                result.subLabel,
                style: GoogleFonts.nunito(fontSize: 14, color: c.sub),
              ).animate().fadeIn(delay: 200.ms, duration: 300.ms),
              if (result.cleaningRequired) ...[
                const SizedBox(height: 8),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.water_drop_outlined, color: c.sub, size: 13),
                    const SizedBox(width: 4),
                    Text(
                      '"Cleaning required"',
                      style: GoogleFonts.nunito(
                          fontSize: 11, color: c.sub, fontStyle: FontStyle.italic),
                    ),
                  ],
                ).animate().fadeIn(delay: 250.ms, duration: 300.ms),
              ],
              const Spacer(),
              SizedBox(
                width: double.infinity,
                child: GestureDetector(
                  onTap: _scanNext,
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: _isDark ? Colors.transparent : c.text,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: c.text, width: 1.5),
                    ),
                    child: Text(
                      'Scan Next Shoe.',
                      style: GoogleFonts.nunito(
                        fontSize: 16,
                        color: _isDark ? c.text : c.bg,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                ),
              ).animate().fadeIn(delay: 300.ms, duration: 300.ms),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}
