import 'dart:async';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:video_player/video_player.dart';
import '../nike_colors.dart';
import '../services/chatbot_service.dart';
import '../widgets/nav_controls.dart';
import 'customer_locker_screen.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Static consts (never themed — always lime or text-on-lime)
// ─────────────────────────────────────────────────────────────────────────────
const _lime  = Color(0xFFCDFC49);
const _black = Color(0xFF111111);

// ─────────────────────────────────────────────────────────────────────────────
// Screen
// ─────────────────────────────────────────────────────────────────────────────

class CustomerLandingScreen extends StatefulWidget {
  final VoidCallback? onScanTap;
  final ValueChanged<int>? onNavSelect;

  const CustomerLandingScreen({super.key, this.onScanTap, this.onNavSelect});

  @override
  State<CustomerLandingScreen> createState() =>
      _CustomerLandingScreenState();
}

class _CustomerLandingScreenState extends State<CustomerLandingScreen> {
  final _scaffoldKey = GlobalKey<ScaffoldState>();

  int    _count     = 0;
  int    _prevCount = 0;
  bool   _loaded    = false;
  Timer? _ticker;

  late final VideoPlayerController _videoController;
  bool _videoReady = false;

  NikeColors get _c => context.nc;

  @override
  void initState() {
    super.initState();
    _fetchCount();

    _videoController = VideoPlayerController.asset('assets/videos/AD.mp4')
      ..setLooping(true)
      ..setVolume(0);
    _videoController.initialize().then((_) {
      if (mounted) {
        setState(() => _videoReady = true);
        _videoController.play();
      }
    });
  }

  @override
  void dispose() {
    _ticker?.cancel();
    _videoController.dispose();
    super.dispose();
  }

  // ── Fetch real return count from Firestore ────────────────────────────────

  Future<void> _fetchCount() async {
    try {
      final results = await Future.wait([
        FirebaseFirestore.instance
            .collection('dashboard')
            .doc('DASHBOARD-GLOBAL')
            .get(),
        FirebaseFirestore.instance
            .collection('Shoes')
            .where('LCS-STS', isEqualTo: 'RETURN INITIATED.')
            .get(),
      ]);

      final dashDoc   = results[0] as DocumentSnapshot;
      final shoesSnap = results[1] as QuerySnapshot;

      final base = (dashDoc.data() as Map<String, dynamic>?)?['OPS-TSP'] as int? ?? 48392;
      final live = shoesSnap.docs.length;

      if (mounted) {
        setState(() {
          _prevCount = base;
          _count     = base + live;
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
    } catch (_) {
      const fallbackBase = 48392;
      if (mounted) {
        setState(() {
          _prevCount = fallbackBase;
          _count     = fallbackBase;
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
        pageBuilder: (_, __, ___) => CustomerLockerScreen(
          onScanTap: widget.onScanTap,
          onNavSelect: widget.onNavSelect,
        ),
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
    final c = _c;
    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: c.bg,
      endDrawer: _buildNavDrawer(c),
      body: Stack(
        fit: StackFit.expand,
        children: [
          // ── Ad video background (surprise reveal) ─────────────────────
          if (_videoReady)
            FittedBox(
              fit: BoxFit.cover,
              child: SizedBox(
                width: _videoController.value.size.width,
                height: _videoController.value.size.height,
                child: VideoPlayer(_videoController),
              ),
            ),

          // ── Scrim for text readability over the video ─────────────────
          Container(color: Colors.black.withOpacity(0.55)),

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
              padding: const EdgeInsets.fromLTRB(28, 0, 28, 28),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 28),
                  _buildLogo(c),
                  const Spacer(flex: 2),
                  _buildHeroText(c),
                  const SizedBox(height: 36),
                  _buildCounter(c),
                  const Spacer(flex: 3),
                  _buildEnterButton(),
                  const SizedBox(height: 8),
                  _buildSubtext(c),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Logo ──────────────────────────────────────────────────────────────────

  Widget _buildLogo(NikeColors c) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
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
                color: c.text,
                letterSpacing: 2,
              ),
            ),
          ],
        ),
        CircleIconButton(
          icon: Icons.menu_rounded,
          c: c,
          onTap: () => _scaffoldKey.currentState?.openEndDrawer(),
        ),
      ],
    ).animate().fadeIn(duration: 500.ms);
  }

  // ── Nav drawer (replaces bottom nav bar on this screen) ────────────────────

  Widget _buildNavDrawer(NikeColors c) {
    return NavDrawer(
      c: c,
      chatPersona: ChatPersona.customer,
      onSignOut: () => FirebaseAuth.instance.signOut(),
      items: [
        NavDrawerItem(icon: Icons.home, label: 'Home', selected: true,
            onTap: () => Navigator.of(context).pop()),
        NavDrawerItem(icon: Icons.qr_code, label: 'Scan',
            onTap: () {
              Navigator.of(context).pop();
              widget.onNavSelect?.call(1);
            }),
        NavDrawerItem(icon: Icons.person, label: 'Profile',
            onTap: () {
              Navigator.of(context).pop();
              widget.onNavSelect?.call(2);
            }),
      ],
    );
  }

  // ── Hero headline ─────────────────────────────────────────────────────────

  Widget _buildHeroText(NikeColors c) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'THE LOOP',
          style: GoogleFonts.bebasNeue(
            fontSize: 86,
            color: c.text,
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

  Widget _buildCounter(NikeColors c) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _loaded
            ? TweenAnimationBuilder<int>(
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
                color: c.sub,
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
            color: c.sub.withOpacity(0.6),
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

  Widget _buildSubtext(NikeColors c) {
    return Center(
      child: Text(
        'Your kicks. Your impact. Your loop.',
        style: GoogleFonts.nunito(fontSize: 13, color: c.sub),
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
