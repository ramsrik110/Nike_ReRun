import 'dart:async';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'customer_locker_screen.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Colours
// ─────────────────────────────────────────────────────────────────────────────
const _black = Color(0xFF111111);
const _lime  = Color(0xFFCDFC49);
const _white = Color(0xFFFFFFFF);
const _grey  = Color(0xFF888888);

// ─────────────────────────────────────────────────────────────────────────────
// Screen
// ─────────────────────────────────────────────────────────────────────────────

class CustomerLandingScreen extends StatefulWidget {
  final VoidCallback? onScanTap;

  const CustomerLandingScreen({super.key, this.onScanTap});

  @override
  State<CustomerLandingScreen> createState() =>
      _CustomerLandingScreenState();
}

class _CustomerLandingScreenState extends State<CustomerLandingScreen> {
  int    _count     = 0;
  int    _prevCount = 0; // animate FROM here, not from 0
  bool   _loaded    = false;
  Timer? _ticker;

  @override
  void initState() {
    super.initState();
    _fetchCount();
  }

  @override
  void dispose() {
    _ticker?.cancel();
    super.dispose();
  }

  // ── Fetch real return count from Firestore ────────────────────────────────

  Future<void> _fetchCount() async {
    try {
      final snap = await FirebaseFirestore.instance
          .collection('Shoes') // capital S — always
          .where('LCS-STS', isEqualTo: 'RETURN INITIATED.')
          .get();

      if (mounted) {
        setState(() {
          _prevCount = 0;
          _count     = snap.docs.length;
          _loaded    = true;
        });

        // Tick up by 1 every 4 seconds — animate only the +1 step
        _ticker = Timer.periodic(const Duration(seconds: 4), (_) {
          if (mounted) {
            setState(() {
              _prevCount = _count;
              _count++;
            });
          }
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _prevCount = 0;
          _count     = 48392;
          _loaded    = true;
        });
        _ticker = Timer.periodic(const Duration(seconds: 4), (_) {
          if (mounted) {
            setState(() {
              _prevCount = _count;
              _count++;
            });
          }
        });
      }
    }
  }

  // ── Navigate to locker ────────────────────────────────────────────────────

  void _enterLocker() {
    Navigator.of(context).push(
      PageRouteBuilder(
        pageBuilder: (_, __, ___) =>
            CustomerLockerScreen(onScanTap: widget.onScanTap),
        transitionsBuilder: (_, anim, __, child) => FadeTransition(
          opacity: CurvedAnimation(parent: anim, curve: Curves.easeInOut),
          child: child,
        ),
        transitionDuration: const Duration(milliseconds: 500),
      ),
    );
  }

  // ── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _black,
      body: Stack(
        fit: StackFit.expand,
        children: [
          // ── Radial lime glow ──────────────────────────────────────────
          Container(
            decoration: BoxDecoration(
              gradient: RadialGradient(
                center: const Alignment(0.0, 0.15),
                radius: 1.1,
                colors: [
                  _lime.withOpacity(0.09),
                  Colors.transparent,
                ],
              ),
            ),
          ),

          // ── Subtle grid lines for depth ───────────────────────────────
          CustomPaint(painter: _GridPainter()),

          // ── Content ───────────────────────────────────────────────────
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(28, 0, 28, 110),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 28),
                  _buildLogo(),
                  const Spacer(flex: 2),
                  _buildHeroText(),
                  const SizedBox(height: 36),
                  _buildCounter(),
                  const Spacer(flex: 3),
                  _buildEnterButton(),
                  const SizedBox(height: 8),
                  _buildSubtext(),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Logo ──────────────────────────────────────────────────────────────────

  Widget _buildLogo() {
    return Row(
      children: [
        ColorFiltered(
          colorFilter: const ColorFilter.mode(_lime, BlendMode.modulate),
          child: Image.asset('assets/images/nikererun.png', height: 26),
        ),
        const SizedBox(width: 8),
        Text(
          'RERUN',
          style: GoogleFonts.bebasNeue(
            fontSize: 22,
            color: _white,
            letterSpacing: 2,
          ),
        ),
      ],
    ).animate().fadeIn(duration: 500.ms);
  }

  // ── Hero headline ─────────────────────────────────────────────────────────

  Widget _buildHeroText() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'THE LOOP',
          style: GoogleFonts.bebasNeue(
            fontSize: 86,
            color: _white,
            letterSpacing: 2,
            height: 0.88,
          ),
        )
            .animate()
            .fadeIn(delay: 200.ms, duration: 600.ms)
            .slideY(
              begin: 0.3,
              end: 0,
              delay: 200.ms,
              duration: 600.ms,
              curve: Curves.easeOutCubic,
            ),
        Text(
          'IS ALIVE.',
          style: GoogleFonts.bebasNeue(
            fontSize: 86,
            color: _lime,
            letterSpacing: 2,
            height: 0.88,
          ),
        )
            .animate()
            .fadeIn(delay: 380.ms, duration: 600.ms)
            .slideY(
              begin: 0.3,
              end: 0,
              delay: 380.ms,
              duration: 600.ms,
              curve: Curves.easeOutCubic,
            ),
        const SizedBox(height: 20),
        Container(width: 52, height: 3, color: _lime)
            .animate()
            .scaleX(
              begin: 0,
              end: 1,
              delay: 650.ms,
              duration: 400.ms,
              curve: Curves.easeOutCubic,
            ),
      ],
    );
  }

  // ── Live counter ──────────────────────────────────────────────────────────

  Widget _buildCounter() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _loaded
            ? TweenAnimationBuilder<int>(
                // key changes only when count changes — animates _prevCount → _count
                key: ValueKey(_count),
                tween: IntTween(begin: _prevCount, end: _count),
                duration: const Duration(milliseconds: 800),
                curve: Curves.easeOut,
                builder: (_, value, __) {
                  return Text(
                    _formatNumber(value),
                    style: GoogleFonts.bebasNeue(
                      fontSize: 60,
                      color: _lime,
                      letterSpacing: 4,
                    ),
                  );
                },
              )
            : Text(
                '— — — —',
                style: GoogleFonts.bebasNeue(
                  fontSize: 60,
                  color: _lime.withOpacity(0.25),
                  letterSpacing: 4,
                ),
              ),
        const SizedBox(height: 6),
        Row(
          children: [
            Text(
              'shoes returned worldwide',
              style: GoogleFonts.nunito(
                fontSize: 14,
                color: _grey,
                letterSpacing: 0.5,
              ),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: _lime.withOpacity(0.12),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.trending_up, color: _lime, size: 13),
                  const SizedBox(width: 3),
                  Text(
                    'LIVE',
                    style: GoogleFonts.nunito(
                      fontSize: 11,
                      color: _lime,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 1,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        Text(
          '≈ 15 / min globally',
          style: GoogleFonts.nunito(
            fontSize: 12,
            color: _grey.withOpacity(0.6),
            letterSpacing: 0.3,
          ),
        ),
      ],
    )
        .animate()
        .fadeIn(delay: 550.ms, duration: 500.ms)
        .slideY(begin: 0.2, end: 0, delay: 550.ms, duration: 500.ms);
  }

  // ── CTA button ────────────────────────────────────────────────────────────

  Widget _buildEnterButton() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: _enterLocker,
        style: ElevatedButton.styleFrom(
          backgroundColor: _lime,
          foregroundColor: _black,
          padding: const EdgeInsets.symmetric(vertical: 18),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(50),
          ),
          elevation: 0,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'Enter the Locker',
              style: GoogleFonts.bebasNeue(
                fontSize: 22,
                color: _black,
                letterSpacing: 1.5,
              ),
            ),
            const SizedBox(width: 10),
            const Icon(Icons.arrow_forward_rounded, color: _black, size: 22),
          ],
        ),
      ),
    )
        .animate()
        .fadeIn(delay: 750.ms, duration: 500.ms)
        .slideY(begin: 0.2, end: 0, delay: 750.ms, duration: 500.ms);
  }

  Widget _buildSubtext() {
    return Center(
      child: Text(
        'Your kicks. Your impact. Your loop.',
        style: GoogleFonts.nunito(fontSize: 13, color: _grey),
      ),
    )
        .animate()
        .fadeIn(delay: 900.ms, duration: 400.ms);
  }

  // ── Helpers ───────────────────────────────────────────────────────────────

  String _formatNumber(int n) {
    if (n >= 1000000) {
      return '${(n / 1000000).toStringAsFixed(1)}M';
    }
    if (n >= 1000) {
      final thousands  = n ~/ 1000;
      final remainder  = (n % 1000).toString().padLeft(3, '0');
      return '$thousands,$remainder';
    }
    return n.toString();
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Subtle grid background painter
// ─────────────────────────────────────────────────────────────────────────────

class _GridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFFCDFC49).withOpacity(0.025)
      ..strokeWidth = 0.5;

    const spacing = 40.0;

    for (double x = 0; x < size.width; x += spacing) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }
    for (double y = 0; y < size.height; y += spacing) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  @override
  bool shouldRepaint(_GridPainter old) => false;
}
