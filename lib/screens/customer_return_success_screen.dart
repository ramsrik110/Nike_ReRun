import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:confetti/confetti.dart';
import 'dart:math' as math;

// ─────────────────────────────────────────────────────────────────────────────
// Colours
// ─────────────────────────────────────────────────────────────────────────────
const _black  = Color(0xFF111111);
const _card   = Color(0xFF1A1A1A);
const _lime   = Color(0xFFCDFC49);
const _white  = Color(0xFFFFFFFF);
const _grey   = Color(0xFF888888);

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
    extends State<CustomerReturnSuccessScreen> {
  late ConfettiController _confettiCtrl;

  @override
  void initState() {
    super.initState();
    // FIX 7: confetti fires immediately on screen load
    _confettiCtrl = ConfettiController(
      duration: const Duration(seconds: 5),
    );
    _confettiCtrl.play();
  }

  @override
  void dispose() {
    _confettiCtrl.dispose();
    super.dispose();
  }

  void _goHome(BuildContext context) {
    // Pop all routes back to the root (CustomerShell)
    Navigator.of(context).popUntil((route) => route.isFirst);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _black,
      body: Stack(
        children: [
          // ── Main content ────────────────────────────────────────────────
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Spacer(),
                  _buildLoopIcon(),
                  const SizedBox(height: 32),
                  _buildHeading(),
                  const SizedBox(height: 16),
                  _buildCoinText(),
                  const SizedBox(height: 12),
                  _buildSubtext(),
                  const Spacer(),
                  _buildBackHomeButton(context),
                  const SizedBox(height: 36),
                ],
              ),
            ),
          ),

          // ── Confetti — top centre ────────────────────────────────────────
          Align(
            alignment: Alignment.topCenter,
            child: ConfettiWidget(
              confettiController: _confettiCtrl,
              blastDirectionality: BlastDirectionality.explosive,
              particleDrag: 0.05,
              emissionFrequency: 0.06,
              numberOfParticles: 30,
              gravity: 0.08,
              shouldLoop: false,
              colors: const [
                _lime,
                Colors.white,
                Color(0xFFFFE066),
                Color(0xFF80FF80),
              ],
              createParticlePath: (size) {
                // Star-shaped confetti
                final path = Path();
                final double w = size.width;
                final double h = size.height;
                path
                  ..moveTo(w * 0.5, 0)
                  ..lineTo(w * 0.6, h * 0.35)
                  ..lineTo(w, h * 0.35)
                  ..lineTo(w * 0.68, h * 0.57)
                  ..lineTo(w * 0.79, h)
                  ..lineTo(w * 0.5, h * 0.75)
                  ..lineTo(w * 0.21, h)
                  ..lineTo(w * 0.32, h * 0.57)
                  ..lineTo(0, h * 0.35)
                  ..lineTo(w * 0.4, h * 0.35)
                  ..close();
                return path;
              },
            ),
          ),

          // ── Second confetti burst — left side ────────────────────────────
          Align(
            alignment: Alignment.topLeft,
            child: ConfettiWidget(
              confettiController: _confettiCtrl,
              blastDirection: math.pi / 6, // slight downward right
              particleDrag: 0.05,
              emissionFrequency: 0.04,
              numberOfParticles: 15,
              gravity: 0.1,
              shouldLoop: false,
              colors: const [_lime, Colors.white, Color(0xFFFFE066)],
            ),
          ),

          // ── Third confetti burst — right side ────────────────────────────
          Align(
            alignment: Alignment.topRight,
            child: ConfettiWidget(
              confettiController: _confettiCtrl,
              blastDirection: math.pi * 5 / 6, // slight downward left
              particleDrag: 0.05,
              emissionFrequency: 0.04,
              numberOfParticles: 15,
              gravity: 0.1,
              shouldLoop: false,
              colors: const [_lime, Colors.white, Color(0xFFFFE066)],
            ),
          ),
        ],
      ),
    );
  }

  // FIX 7: loop icon scales in with bounce elastic over 800ms
  Widget _buildLoopIcon() {
    return Container(
      width: 120,
      height: 120,
      decoration: BoxDecoration(
        color: _lime.withOpacity(0.15),
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: _lime.withOpacity(0.3),
            blurRadius: 40,
            spreadRadius: 10,
          ),
        ],
      ),
      child: const Icon(Icons.recycling, color: _lime, size: 64),
    )
        .animate()
        .scale(
          begin: const Offset(0.1, 0.1),
          end: const Offset(1.0, 1.0),
          duration: 800.ms,
          curve: Curves.elasticOut,
        );
  }

  Widget _buildHeading() {
    return Text('LOOP CLOSED.',
            style: _heading(40),
            textAlign: TextAlign.center)
        .animate()
        .fadeIn(delay: 200.ms, duration: 500.ms)
        .slideY(begin: 0.2, end: 0, duration: 500.ms);
  }

  // FIX 7: NikeCoin text fades in with 400ms delay
  Widget _buildCoinText() {
    return Text(
      'You earned ${widget.rwdAmt} NikeCoins.',
      style: _body(20, color: _lime).copyWith(fontWeight: FontWeight.w700),
      textAlign: TextAlign.center,
    ).animate().fadeIn(delay: 400.ms, duration: 500.ms);
  }

  Widget _buildSubtext() {
    return Text(
      'Your shoe is officially back in the game.',
      style: _body(14, color: _grey),
      textAlign: TextAlign.center,
    ).animate().fadeIn(delay: 550.ms, duration: 500.ms);
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
        .fadeIn(delay: 700.ms, duration: 400.ms)
        .slideY(begin: 0.2, end: 0, duration: 400.ms);
  }
}
