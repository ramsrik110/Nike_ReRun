import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:lottie/lottie.dart';
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
  late final AnimationController _lottieCtrl;

  @override
  void initState() {
    super.initState();
    _lottieCtrl = AnimationController(vsync: this);
  }

  @override
  void dispose() {
    _lottieCtrl.dispose();
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

  // ── Lottie Nike swoosh animation ─────────────────────────────────────────

  Widget _buildCheckmark() {
    return Lottie.asset(
      'assets/lottie/swoosh_success.json',
      controller: _lottieCtrl,
      width: 280,
      height: 280,
      fit: BoxFit.contain,
      backgroundLoading: true,
      onLoaded: (composition) {
        _lottieCtrl
          ..duration = composition.duration
          ..forward();
      },
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

