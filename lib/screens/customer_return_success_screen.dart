import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:lottie/lottie.dart';
import '../nike_colors.dart';

const _lime  = Color(0xFFCDFC49);
const _black = Color(0xFF111111);

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

  NikeColors get _c => context.nc;

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
    final c = _c;
    return Scaffold(
      backgroundColor: c.bg,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Spacer(),
              _buildCheckmark(),
              const SizedBox(height: 40),
              _buildHeading(c),
              const SizedBox(height: 12),
              _buildCoinRow(),
              const SizedBox(height: 10),
              _buildSubtext(c),
              const Spacer(),
              _buildDivider(c),
              const SizedBox(height: 24),
              _buildBackHomeButton(context),
              const SizedBox(height: 36),
            ],
          ),
        ),
      ),
    );
  }

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

  Widget _buildHeading(NikeColors c) {
    return Column(
      children: [
        Text('LOOP CLOSED.',
            style: GoogleFonts.bebasNeue(
                fontSize: 42, color: c.text, letterSpacing: 1.5),
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
        Container(width: 40, height: 2, color: _lime)
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
          style: GoogleFonts.nunito(
              fontSize: 18, color: _lime,
              fontWeight: FontWeight.w800),
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

  Widget _buildSubtext(NikeColors c) {
    return Text(
      'Your shoe is officially back in the game.',
      style: GoogleFonts.nunito(fontSize: 15, color: c.sub),
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

  Widget _buildDivider(NikeColors c) {
    return Container(height: 1, color: c.border)
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
            style: GoogleFonts.nunito(
                fontSize: 17, color: _black,
                fontWeight: FontWeight.w900)),
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
