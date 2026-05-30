import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../models/shoe_model.dart';
import 'customer_return_success_screen.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Colours
// ─────────────────────────────────────────────────────────────────────────────
const _black  = Color(0xFF111111);
const _card   = Color(0xFF1A1A1A);
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

  // FIX 7: rotating recycling icon
  late AnimationController _rotateCtrl;

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

  // ── Confirm return ────────────────────────────────────────────────────────

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
      debugPrint('[Email] Confirmation sent to $email');
    } catch (e) {
      // Non-blocking — email failure should not stop the return flow
      debugPrint('[Email] Failed to send confirmation: $e');
    }
  }

  Future<void> _confirmReturn() async {
    setState(() => _loading = true);
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    try {
      // 1. Update shoe document in Firestore Shoes collection
      await FirebaseFirestore.instance
          .collection('Shoes') // capital S — always
          .doc(widget.shoe.suid)
          .update({
        'LCS-STS': 'LOOP CLOSED.',
        'RTE-DCN': 'RETURN INITIATED.',
      });

      // 2. Update user document — add SUID to LCS-RTN and increment RWD-NCB
      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .update({
        'LCS-RTN': FieldValue.arrayUnion([widget.shoe.suid]),
        'RWD-NCB': FieldValue.increment(widget.shoe.rwdAmt),
      });

      // 3. Fire confirmation email via Make.com webhook (non-blocking)
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
                scale: Tween<double>(begin: 0.9, end: 1.0).animate(
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
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error confirming return. Try again.',
                style: _body(13)),
            backgroundColor: _card,
          ),
        );
      }
    }
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
            children: [
              const SizedBox(height: 20),
              _buildTopBar(),
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _buildRotatingIcon(),
                    const SizedBox(height: 24),
                    Text('CLOSING\nTHE LOOP.',
                            style: _heading(32),
                            textAlign: TextAlign.center)
                        .animate()
                        .fadeIn(delay: 200.ms, duration: 400.ms)
                        .slideY(begin: 0.2, end: 0, duration: 400.ms),
                    const SizedBox(height: 32),
                    // FIX 7: summary card slides up from bottom with fade 600ms
                    _buildSummaryCard()
                        .animate()
                        .fadeIn(delay: 300.ms, duration: 600.ms)
                        .slideY(begin: 0.3, end: 0, duration: 600.ms,
                            curve: Curves.easeOutCubic),
                  ],
                ),
              ),
              _buildButtons(),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTopBar() {
    return Row(
      children: [
        IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: _white),
          onPressed: () => Navigator.pop(context),
        ),
        const Spacer(),
        Text('NIKE RERUN', style: _heading(18, color: _lime)),
        const Spacer(),
        const SizedBox(width: 48),
      ],
    );
  }

  // FIX 7: continuously rotating recycling icon
  Widget _buildRotatingIcon() {
    return RotationTransition(
      turns: _rotateCtrl,
      child: Container(
        width: 80,
        height: 80,
        decoration: BoxDecoration(
          color: _lime.withOpacity(0.15),
          shape: BoxShape.circle,
        ),
        child: const Icon(Icons.recycling, color: _lime, size: 44),
      ),
    )
        .animate()
        .scale(
          begin: const Offset(0.3, 0.3),
          duration: 600.ms,
          curve: Curves.elasticOut,
        );
  }

  Widget _buildSummaryCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: _card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _border),
      ),
      child: Column(
        children: [
          // Shoe image small
          if (widget.shoe.snmImg.isNotEmpty)
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: SizedBox(
                height: 80,
                child: Image.network(
                  widget.shoe.snmImg,
                  fit: BoxFit.contain,
                  errorBuilder: (_, __, ___) =>
                      const Icon(Icons.directions_run, color: _lime, size: 40),
                ),
              ),
            ),
          const SizedBox(height: 12),
          Text(widget.shoe.snm,
              textAlign: TextAlign.center,
              style: _body(14).copyWith(fontWeight: FontWeight.w700)),
          const SizedBox(height: 16),
          const Divider(color: _border, height: 1),
          const SizedBox(height: 14),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.stars, color: _lime, size: 20),
              const SizedBox(width: 8),
              Text(
                'You will earn ${widget.shoe.rwdAmt} NikeCoins.',
                style: _body(16, color: _lime)
                    .copyWith(fontWeight: FontWeight.w700),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildButtons() {
    return Column(
      children: [
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: _loading ? null : _confirmReturn,
            style: ElevatedButton.styleFrom(
              backgroundColor: _lime,
              foregroundColor: _black,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
              elevation: 0,
            ),
            child: _loading
                ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(
                        color: _black, strokeWidth: 2))
                : Text('Confirm Return.',
                    style: _body(16, color: _black)
                        .copyWith(fontWeight: FontWeight.w800)),
          ),
        )
            .animate()
            .fadeIn(delay: 500.ms, duration: 400.ms)
            .slideY(begin: 0.1, end: 0, duration: 400.ms),
        const SizedBox(height: 12),
        SizedBox(
          width: double.infinity,
          child: OutlinedButton(
            onPressed: () => Navigator.pop(context),
            style: OutlinedButton.styleFrom(
              foregroundColor: _white,
              side: const BorderSide(color: _border),
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
            ),
            child: Text('Not yet.',
                style: _body(15, color: _white)),
          ),
        )
            .animate()
            .fadeIn(delay: 600.ms, duration: 400.ms),
      ],
    );
  }
}
