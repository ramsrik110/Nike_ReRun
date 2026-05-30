import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
// ─────────────────────────────────────────────────────────────────────────────
// Colours
// ─────────────────────────────────────────────────────────────────────────────
const _black  = Color(0xFF111111);
const _lime   = Color(0xFFCDFC49);
const _white  = Color(0xFFFFFFFF);
const _grey   = Color(0xFF888888);
const _border = Color(0xFF2A2A2A);

// ─────────────────────────────────────────────────────────────────────────────
// Font helpers
// ─────────────────────────────────────────────────────────────────────────────
TextStyle _heading(double size, {Color color = _white}) =>
    GoogleFonts.bebasNeue(fontSize: size, color: color, letterSpacing: 1.5);
TextStyle _body(double size, {Color color = _white}) =>
    GoogleFonts.nunito(fontSize: size, color: color);

// ─────────────────────────────────────────────────────────────────────────────
// Screen
// ─────────────────────────────────────────────────────────────────────────────

class CustomerReturnSuccessScreen extends StatefulWidget {
  final int rwdAmt;

  const CustomerReturnSuccessScreen({super.key, required this.rwdAmt});

  @override
  State<CustomerReturnSuccessScreen> createState() =>
      _CustomerReturnSuccessScreenState();
}

class _CustomerReturnSuccessScreenState
    extends State<CustomerReturnSuccessScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _checkCtrl;
  late final Animation<double>   _checkProgress;

  @override
  void initState() {
    super.initState();
    _checkCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );
    _checkProgress = CurvedAnimation(
      parent: _checkCtrl,
      curve: Curves.easeOutCubic,
    );
    // Small delay so the screen settles before the stroke draws
    Future.delayed(const Duration(milliseconds: 200), () {
      if (mounted) _checkCtrl.forward();
    });
  }

  @override
  void dispose() {
    _checkCtrl.dispose();
    super.dispose();
  }

  void _goHome(BuildContext context) {
    Navigator.of(context).popUntil((route) => route.isFirst);
  }

  // ── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _black,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Spacer(),
              _buildCheckmark(),
              const SizedBox(height: 40),
              _buildHeading(),
              const SizedBox(height: 12),
              _buildCoinRow(),
              const SizedBox(height: 10),
              _buildSubtext(),
              const Spacer(),
              _buildDivider(),
              const SizedBox(height: 24),
              _buildBackHomeButton(context),
              const SizedBox(height: 36),
            ],
          ),
        ),
      ),
    );
  }

  // ── Nike swoosh — filled shape revealed left→right ───────────────────────

  Widget _buildCheckmark() {
    return SizedBox(
      width: 220,
      height: 120,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Diffuse lime glow that blooms in once the swoosh is fully revealed
          AnimatedBuilder(
            animation: _checkProgress,
            builder: (_, __) {
              final bloom =
                  ((_checkProgress.value - 0.75) / 0.25).clamp(0.0, 1.0);
              return Opacity(
                opacity: bloom * 0.55,
                child: Container(
                  width:  220 * bloom,
                  height: 120 * bloom,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(90),
                    boxShadow: [
                      BoxShadow(
                        color: _lime.withValues(alpha: 0.45),
                        blurRadius: 60,
                        spreadRadius: 20,
                      ),
                    ],
                  ),
                ),
              );
            },
          ),

          // The Nike swoosh — filled, revealed left→right via clipRect
          AnimatedBuilder(
            animation: _checkProgress,
            builder: (_, __) => CustomPaint(
              size: const Size(220, 120),
              painter: _SwooshPainter(
                progress: _checkProgress.value,
                color: _lime,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Content ───────────────────────────────────────────────────────────────

  Widget _buildHeading() {
    return Column(
      children: [
        Text('LOOP CLOSED.',
            style: _heading(42),
            textAlign: TextAlign.center)
            .animate()
            .fadeIn(delay: 750.ms, duration: 450.ms)
            .slideY(
              begin: 0.18,
              end: 0,
              delay: 750.ms,
              duration: 450.ms,
              curve: Curves.easeOutCubic,
            ),
        const SizedBox(height: 6),
        Container(
          width: 40,
          height: 2,
          color: _lime,
        )
            .animate()
            .scaleX(
              begin: 0,
              end: 1,
              delay: 1000.ms,
              duration: 300.ms,
              curve: Curves.easeOutCubic,
            ),
      ],
    );
  }

  Widget _buildCoinRow() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Icon(Icons.toll_outlined, color: _lime, size: 20),
        const SizedBox(width: 8),
        Text(
          '+${widget.rwdAmt} NikeCoins',
          style: _body(18, color: _lime).copyWith(fontWeight: FontWeight.w800),
        ),
      ],
    )
        .animate()
        .fadeIn(delay: 1100.ms, duration: 400.ms)
        .slideY(
          begin: 0.15,
          end: 0,
          delay: 1100.ms,
          duration: 400.ms,
          curve: Curves.easeOutCubic,
        );
  }

  Widget _buildSubtext() {
    return Text(
      'Your shoe is officially back in the game.',
      style: _body(14, color: _grey),
      textAlign: TextAlign.center,
    )
        .animate()
        .fadeIn(delay: 1250.ms, duration: 400.ms)
        .slideY(
          begin: 0.15,
          end: 0,
          delay: 1250.ms,
          duration: 400.ms,
          curve: Curves.easeOutCubic,
        );
  }

  Widget _buildDivider() {
    return Container(height: 1, color: _border)
        .animate()
        .scaleX(
          begin: 0,
          end: 1,
          delay: 1350.ms,
          duration: 400.ms,
          curve: Curves.easeOutCubic,
        );
  }

  Widget _buildBackHomeButton(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: () => _goHome(context),
        style: ElevatedButton.styleFrom(
          backgroundColor: _lime,
          foregroundColor: _black,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12)),
          elevation: 0,
        ),
        child: Text('Back Home.',
            style: _body(16, color: _black)
                .copyWith(fontWeight: FontWeight.w900)),
      ),
    )
        .animate()
        .fadeIn(delay: 1450.ms, duration: 400.ms)
        .slideY(
          begin: 0.15,
          end: 0,
          delay: 1450.ms,
          duration: 400.ms,
          curve: Curves.easeOutCubic,
        );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Nike swoosh painter — filled Bézier shape revealed left→right (0.0 → 1.0)
//
// Shape anatomy (in normalised 0–1 space, canvas is 220×120):
//   • Top edge  : concave cubic — starts thick at the left curl, sweeps up
//                 to a sharp vanishing tip at the far right
//   • Bottom edge: convex cubic — the wide belly of the swoosh
//   • The left end closes with a tight rounded curl (the "hook")
//
// Animation: a clipRect sweeps from x=0 to x=full_width so the swoosh
// appears to fly in from the left, matching the swoosh's own direction.
// ─────────────────────────────────────────────────────────────────────────────

class _SwooshPainter extends CustomPainter {
  final double progress;
  final Color  color;

  const _SwooshPainter({required this.progress, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    if (progress <= 0) return;

    final w = size.width;
    final h = size.height;

    // ── Clip left→right reveal ──────────────────────────────────────────────
    canvas.save();
    canvas.clipRect(Rect.fromLTWH(0, 0, w * progress, h));

    // ── Build the swoosh path ───────────────────────────────────────────────
    //
    // Key points (all relative to canvas size):
    //   hookTip   — the very top of the left curl (pointy top-left)
    //   hookBase  — where the curl rejoins the body on the inner-top edge
    //   tipTop    — the sharp right tip (top side)
    //   tipBot    — the sharp right tip (bottom side, ~same x, slightly lower)
    //   bellyBot  — the lowest point of the swoosh belly
    //   curlBase  — bottom of the left curl where it meets the belly

    final hookTip  = Offset(w * 0.08, h * 0.22);   // top-left pointy curl tip
    final tipTop   = Offset(w * 0.995, h * 0.30);  // sharp right tip (top)
    final tipBot   = Offset(w * 0.985, h * 0.34);  // sharp right tip (bottom)
    final bellyBot = Offset(w * 0.38, h * 0.92);   // lowest belly point
    final curlBase = Offset(w * 0.03, h * 0.74);   // bottom of the left curl

    final path = Path();

    // Start at the top of the left curl
    path.moveTo(hookTip.dx, hookTip.dy);

    // ── Top (concave) edge: left curl tip → right sharp tip ────────────────
    // Control points pull the line inward (upward concave dip then rise)
    path.cubicTo(
      w * 0.22, h * 0.08,   // cp1 — pull up and right early
      w * 0.70, h * 0.12,   // cp2 — keep it high as we approach the tip
      tipTop.dx, tipTop.dy, // end at the sharp right tip
    );

    // ── Close the tip (tiny step down) ─────────────────────────────────────
    path.lineTo(tipBot.dx, tipBot.dy);

    // ── Bottom (convex) edge: right tip → belly → left curl base ───────────
    path.cubicTo(
      w * 0.68, h * 0.72,    // cp1 — drop into the belly
      w * 0.20, h * 1.00,    // cp2 — push the belly down and left
      bellyBot.dx, bellyBot.dy,
    );

    // ── Belly continues to the left curl base ──────────────────────────────
    path.cubicTo(
      w * 0.18, h * 0.95,   // cp1
      w * 0.04, h * 0.88,   // cp2 — tight left curve
      curlBase.dx, curlBase.dy,
    );

    // ── Left curl: bottom of curl back up to the hook tip ──────────────────
    // This is the characteristic Nike concave inner-curl
    path.cubicTo(
      w * 0.00, h * 0.58,   // cp1 — swing left and up
      w * 0.01, h * 0.34,   // cp2 — continue the tight curl
      hookTip.dx, hookTip.dy,
    );

    path.close();

    // ── Draw filled swoosh ──────────────────────────────────────────────────
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    canvas.drawPath(path, paint);
    canvas.restore();
  }

  @override
  bool shouldRepaint(_SwooshPainter old) => old.progress != progress;
}
