import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../nike_colors.dart';
import '../models/shoe_model.dart';
import 'customer_return_success_screen.dart';

const _lime  = Color(0xFFCDFC49);
const _black = Color(0xFF111111);

// ─────────────────────────────────────────────────────────────────────────────
// Screen
// ─────────────────────────────────────────────────────────────────────────────

class CustomerReturnConfirmScreen extends StatefulWidget {
  final ShoeModel shoe;

  const CustomerReturnConfirmScreen({super.key, required this.shoe});

  @override
  State<CustomerReturnConfirmScreen> createState() =>
      _CustomerReturnConfirmScreenState();
}

class _CustomerReturnConfirmScreenState
    extends State<CustomerReturnConfirmScreen>
    with SingleTickerProviderStateMixin {
  bool _loading = false;

  late final AnimationController _rotateCtrl;

  NikeColors get _c => context.nc;

  @override
  void initState() {
    super.initState();
    _rotateCtrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    )..repeat();
  }

  @override
  void dispose() {
    _rotateCtrl.dispose();
    super.dispose();
  }

  // ── Firestore + email ────────────────────────────────────────────────────

  static const _webhookUrl =
      'https://hook.eu1.make.com/weifl2piodeq3xh37j3gbpj8ai6g1ep3';

  Future<void> _sendConfirmationEmail({
    required String email,
    required String shoeName,
    required int coinsEarned,
  }) async {
    try {
      await http.post(
        Uri.parse(_webhookUrl),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'email':       email,
          'shoeName':    shoeName,
          'coinsEarned': coinsEarned,
        }),
      );
    } catch (e) {
      debugPrint('[Email] Failed to send confirmation: $e');
    }
  }

  Future<void> _confirmReturn() async {
    HapticFeedback.mediumImpact();
    setState(() => _loading = true);
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    try {
      await FirebaseFirestore.instance
          .collection('Shoes')
          .doc(widget.shoe.suid)
          .update({
        'LCS-STS': 'LOOP CLOSED.',
        'RTE-DCN': 'RETURN INITIATED.',
      });

      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .update({
        'LCS-RTN': FieldValue.arrayUnion([widget.shoe.suid]),
        'RWD-NCB': FieldValue.increment(widget.shoe.rwdAmt),
      });

      final email = user.email ?? '';
      if (email.isNotEmpty) {
        await _sendConfirmationEmail(
          email:       email,
          shoeName:    widget.shoe.snm,
          coinsEarned: widget.shoe.rwdAmt,
        );
      }

      if (mounted) {
        Navigator.pushReplacement(
          context,
          PageRouteBuilder(
            pageBuilder: (_, __, ___) =>
                CustomerReturnSuccessScreen(rwdAmt: widget.shoe.rwdAmt),
            transitionsBuilder: (_, anim, __, child) => FadeTransition(
              opacity: anim,
              child: ScaleTransition(
                scale: Tween<double>(begin: 0.92, end: 1.0).animate(
                  CurvedAnimation(parent: anim, curve: Curves.easeOutCubic),
                ),
                child: child,
              ),
            ),
            transitionDuration: const Duration(milliseconds: 500),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _loading = false);
        final c = _c;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Something went wrong. Try again.',
                style: GoogleFonts.nunito(fontSize: 14, color: c.text)),
            backgroundColor: c.card,
          ),
        );
      }
    }
  }

  // ── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final c = _c;
    return Scaffold(
      backgroundColor: c.bg,
      body: SafeArea(
        child: Column(
          children: [
            _buildTopBar(c),
            Expanded(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(24, 0, 24, 32),
                child: Column(
                  children: [
                    const SizedBox(height: 32),
                    _buildRecycleAnimation(),
                    const SizedBox(height: 20),
                    _buildHeadline(c),
                    const SizedBox(height: 32),
                    _buildShoeCard(c),
                    const SizedBox(height: 20),
                    _buildCoinsCard(c),
                    const SizedBox(height: 36),
                    _buildButtons(c),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTopBar(NikeColors c) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
      child: Row(
        children: [
          GestureDetector(
            onTap: () {
              HapticFeedback.lightImpact();
              Navigator.of(context).pop();
            },
            child: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: c.card,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: c.border),
              ),
              child: Icon(Icons.arrow_back, color: c.text, size: 20),
            ),
          ),
          const Spacer(),
          Text('NIKE RERUN',
              style: GoogleFonts.bebasNeue(
                  fontSize: 18, color: _lime, letterSpacing: 1.5)),
          const Spacer(),
          const SizedBox(width: 40),
        ],
      ),
    );
  }

  Widget _buildRecycleAnimation() {
    return Stack(
      alignment: Alignment.center,
      children: [
        Container(
          width: 120,
          height: 120,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: _lime.withOpacity(0.06),
            border: Border.all(color: _lime.withOpacity(0.15), width: 1),
          ),
        ),
        RotationTransition(
          turns: _rotateCtrl,
          child: Container(
            width: 88,
            height: 88,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: _lime.withOpacity(0.12),
              border: Border.all(
                color: _lime.withOpacity(0.4),
                width: 1.5,
                strokeAlign: BorderSide.strokeAlignOutside,
              ),
            ),
          ),
        ),
        Container(
          width: 72,
          height: 72,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: _lime.withOpacity(0.18),
          ),
          child: const Icon(Icons.recycling, color: _lime, size: 38),
        ),
      ],
    )
        .animate()
        .scale(
          begin: const Offset(0.3, 0.3),
          end: const Offset(1.0, 1.0),
          duration: 600.ms,
          curve: Curves.elasticOut,
        )
        .fadeIn(duration: 400.ms);
  }

  Widget _buildHeadline(NikeColors c) {
    return Column(
      children: [
        Text(
          'CLOSING\nTHE LOOP.',
          style: GoogleFonts.bebasNeue(
              fontSize: 40, color: c.text, letterSpacing: 1.5),
          textAlign: TextAlign.center,
        )
            .animate()
            .fadeIn(delay: 200.ms, duration: 400.ms)
            .slideY(begin: 0.15, end: 0, delay: 200.ms, duration: 400.ms,
                curve: Curves.easeOutCubic),
        const SizedBox(height: 8),
        Text(
          'Review your return below.',
          style: GoogleFonts.nunito(fontSize: 14, color: c.sub),
          textAlign: TextAlign.center,
        )
            .animate()
            .fadeIn(delay: 320.ms, duration: 350.ms),
      ],
    );
  }

  Widget _buildShoeCard(NikeColors c) {
    return Container(
      decoration: BoxDecoration(
        color: c.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: c.border),
      ),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: const BorderRadius.horizontal(
                left: Radius.circular(16)),
            child: Container(
              width: 110,
              height: 110,
              color: c.bg,
              child: widget.shoe.snmImg.isNotEmpty
                  ? Image.network(
                      widget.shoe.snmImg,
                      fit: BoxFit.contain,
                      errorBuilder: (_, __, ___) => const Icon(
                          Icons.directions_run, color: _lime, size: 40),
                    )
                  : const Icon(Icons.directions_run, color: _lime, size: 40),
            ),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (widget.shoe.snmHdl.isNotEmpty)
                    Text(widget.shoe.snmHdl,
                        style: GoogleFonts.nunito(
                            fontSize: 10, color: c.sub,
                            letterSpacing: 0.4),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis),
                  const SizedBox(height: 2),
                  Text(widget.shoe.snm,
                      style: GoogleFonts.bebasNeue(
                          fontSize: 18, color: c.text, letterSpacing: 1.5),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const Icon(Icons.eco_outlined, color: _lime, size: 13),
                      const SizedBox(width: 4),
                      Text(
                        '${widget.shoe.ecoCo2.toStringAsFixed(1)} kg CO₂',
                        style: GoogleFonts.nunito(
                            fontSize: 11, color: _lime,
                            fontWeight: FontWeight.w700),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    )
        .animate()
        .fadeIn(delay: 380.ms, duration: 400.ms)
        .slideY(begin: 0.12, end: 0, delay: 380.ms, duration: 400.ms,
            curve: Curves.easeOutCubic);
  }

  Widget _buildCoinsCard(NikeColors c) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 20),
      decoration: BoxDecoration(
        color: _lime.withOpacity(0.08),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _lime.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.stars_rounded, color: _lime, size: 28),
              const SizedBox(width: 10),
              Text(
                '${widget.shoe.rwdAmt}',
                style: GoogleFonts.bebasNeue(
                    fontSize: 56, color: _lime, letterSpacing: 1.5),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            'NikeCoins you\'ll earn',
            style: GoogleFonts.nunito(
                fontSize: 14, color: c.sub,
                fontWeight: FontWeight.w600),
          ),
        ],
      ),
    )
        .animate()
        .fadeIn(delay: 460.ms, duration: 400.ms)
        .slideY(begin: 0.1, end: 0, delay: 460.ms, duration: 400.ms,
            curve: Curves.easeOutCubic);
  }

  Widget _buildButtons(NikeColors c) {
    return Column(
      children: [
        SizedBox(
          width: double.infinity,
          child: GestureDetector(
            onTap: _loading ? null : _confirmReturn,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.symmetric(vertical: 18),
              decoration: BoxDecoration(
                color: _loading ? _lime.withOpacity(0.65) : _lime,
                borderRadius: BorderRadius.circular(50),
                boxShadow: _loading
                    ? []
                    : [
                        BoxShadow(
                          color: _lime.withOpacity(0.3),
                          blurRadius: 20,
                          offset: const Offset(0, 6),
                        ),
                      ],
              ),
              child: _loading
                  ? const Center(
                      child: SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(
                            color: _black, strokeWidth: 2.5),
                      ),
                    )
                  : Text(
                      'CONFIRM RETURN',
                      style: GoogleFonts.bebasNeue(
                          fontSize: 20, color: _black, letterSpacing: 1.5),
                      textAlign: TextAlign.center,
                    ),
            ),
          ),
        )
            .animate()
            .fadeIn(delay: 540.ms, duration: 400.ms)
            .slideY(begin: 0.1, end: 0, delay: 540.ms, duration: 400.ms,
                curve: Curves.easeOutCubic),

        const SizedBox(height: 12),

        SizedBox(
          width: double.infinity,
          child: GestureDetector(
            onTap: () {
              HapticFeedback.lightImpact();
              Navigator.of(context).pop();
            },
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 16),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(50),
                border: Border.all(color: c.border),
              ),
              child: Text(
                'NOT YET',
                style: GoogleFonts.bebasNeue(
                    fontSize: 18, color: c.sub, letterSpacing: 1.5),
                textAlign: TextAlign.center,
              ),
            ),
          ),
        )
            .animate()
            .fadeIn(delay: 620.ms, duration: 350.ms),
      ],
    );
  }
}
