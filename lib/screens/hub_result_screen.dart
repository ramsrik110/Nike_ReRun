import 'dart:async';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../models/shoe_model.dart';
import '../utils/routing_algorithm.dart';
import 'login_screen.dart';

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

class HubResultScreen extends StatefulWidget {
  final ShoeModel     shoe;
  final RoutingResult result;

  const HubResultScreen({
    super.key,
    required this.shoe,
    required this.result,
  });

  @override
  State<HubResultScreen> createState() => _HubResultScreenState();
}

class _HubResultScreenState extends State<HubResultScreen>
    with TickerProviderStateMixin {
  // FIX 7: Typewriter animation for routing decision
  String _displayedDecision = '';
  Timer? _typewriterTimer;
  int    _charIndex = 0;

  // FIX 7: Bouncing arrow — increasing intensity
  late AnimationController _arrowCtrl;
  late Animation<double>   _arrowAnim;

  String get _hubLabel => 'Lane 1 — Berlin Hub';

  @override
  void initState() {
    super.initState();

    // Typewriter: reveal one character every ~50ms (1000ms total for ~20 chars)
    final text     = widget.result.decision;
    final interval = (1000 / text.length).round().clamp(30, 100);
    _typewriterTimer = Timer.periodic(Duration(milliseconds: interval), (t) {
      if (_charIndex < text.length) {
        setState(() {
          _charIndex++;
          _displayedDecision = text.substring(0, _charIndex);
        });
      } else {
        t.cancel();
      }
    });

    // Bouncing arrow — repeats with increasing intensity via repeat(reverse:true)
    _arrowCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    )..repeat(reverse: true);
    _arrowAnim = Tween<double>(begin: 0, end: 14)
        .animate(CurvedAnimation(parent: _arrowCtrl, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _typewriterTimer?.cancel();
    _arrowCtrl.dispose();
    super.dispose();
  }

  void _signOut() async {
    await FirebaseAuth.instance.signOut();
    if (mounted) {
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const LoginScreen()),
        (route) => false,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _black,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const SizedBox(height: 16),
              _buildTopBar(),
              const SizedBox(height: 32),
              _buildNextStopLabel(),
              const SizedBox(height: 12),
              _buildDecision(),
              const SizedBox(height: 20),
              _buildArrow(),
              const SizedBox(height: 16),
              _buildHubBadge(),
              const SizedBox(height: 28),
              _buildLogicCard(),
              const SizedBox(height: 32),
              _buildButtons(),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTopBar() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text('NIKE RERUN', style: _heading(18, color: _lime)),
        IconButton(
          icon: const Icon(Icons.logout, color: _grey, size: 20),
          onPressed: _signOut,
        ),
      ],
    );
  }

  // ── NEXT STOP. label ──────────────────────────────────────────────────────

  Widget _buildNextStopLabel() {
    return Text('NEXT STOP.',
            style: _body(13, color: _grey)
                .copyWith(letterSpacing: 3))
        .animate()
        .fadeIn(duration: 400.ms);
  }

  // ── FIX 7: Typewriter routing decision ───────────────────────────────────

  Widget _buildDecision() {
    return Text(
      _displayedDecision.isEmpty ? ' ' : _displayedDecision,
      textAlign: TextAlign.center,
      style: _heading(60),
    );
  }

  // ── FIX 7: Bouncing arrow with increasing intensity ───────────────────────

  Widget _buildArrow() {
    return AnimatedBuilder(
      animation: _arrowAnim,
      builder: (_, child) => Transform.translate(
        offset: Offset(0, _arrowAnim.value),
        child: child,
      ),
      child: const Icon(Icons.arrow_downward_rounded, color: _lime, size: 68),
    )
        .animate()
        .fadeIn(delay: 500.ms, duration: 400.ms);
  }

  // ── Hub location badge ────────────────────────────────────────────────────

  Widget _buildHubBadge() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
      decoration: BoxDecoration(
        color: _lime,
        borderRadius: BorderRadius.circular(30),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.location_on, color: _black, size: 16),
          const SizedBox(width: 6),
          Text(_hubLabel,
              style: _body(14, color: _black)
                  .copyWith(fontWeight: FontWeight.w700)),
        ],
      ),
    )
        .animate()
        .fadeIn(delay: 700.ms, duration: 400.ms)
        .scale(
          begin: const Offset(0.8, 0.8),
          end: const Offset(1.0, 1.0),
          delay: 700.ms,
          duration: 400.ms,
          curve: Curves.elasticOut,
        );
  }

  // ── FIX 7: Logic card rows stagger in with 150ms delays ──────────────────

  Widget _buildLogicCard() {
    // FIX 5: Full grading summary in result card
    final rows = [
      _LogicRow('Material Match',     widget.result.materialMatch,     true),
      _LogicRow('Shoe Grade',         widget.result.conditionGrade,    false),
      _LogicRow('Wear Level',         widget.result.wearLevelLabel,    false),
      _LogicRow('Structure',          widget.result.structuralLabel,   false),
      _LogicRow('Estimated Age',      widget.result.estimatedAgeLabel, false),
      _LogicRow('Cleaning Needed',    widget.result.cleaningRequired ? 'Yes' : 'No',
          widget.result.cleaningRequired),
      _LogicRow('NikeCoin Reward',    '${widget.result.nikeCoinReward} coins', true),
      _LogicRow("What's Next",        widget.result.whatNext,          true),
    ];

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: const BoxDecoration(
        color: _card,
        borderRadius: BorderRadius.all(Radius.circular(14)),
        border: Border(top: BorderSide(color: _lime, width: 2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text("Here's The Call.", style: _heading(20)),
          const SizedBox(height: 14),
          const Divider(color: _border, height: 1),
          const SizedBox(height: 12),
          // FIX 7: stagger each row 150ms apart
          ...rows.asMap().entries.map((e) {
            final delayMs = 800 + e.key * 150;
            return _buildLogicRow(e.value, delayMs);
          }),
        ],
      ),
    )
        .animate()
        .fadeIn(delay: 700.ms, duration: 500.ms)
        .slideY(begin: 0.1, end: 0, duration: 500.ms);
  }

  Widget _buildLogicRow(_LogicRow row, int delayMs) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(row.label, style: _body(13, color: _grey)),
          ),
          Expanded(
            child: Text(
              row.value,
              style: _body(13, color: row.isLime ? _lime : _white)
                  .copyWith(fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    )
        .animate()
        .fadeIn(delay: Duration(milliseconds: delayMs), duration: 300.ms)
        .slideX(
            begin: 0.1,
            end: 0,
            delay: Duration(milliseconds: delayMs),
            duration: 300.ms);
  }

  // ── Buttons ───────────────────────────────────────────────────────────────

  Widget _buildButtons() {
    return Column(
      children: [
        SizedBox(
          width: double.infinity,
          child: OutlinedButton(
            onPressed: () => Navigator.pop(context),
            style: OutlinedButton.styleFrom(
              foregroundColor: _lime,
              side: const BorderSide(color: _lime, width: 1.5),
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
            ),
            child: Text('Next Kick.',
                style: _body(15, color: _lime)
                    .copyWith(fontWeight: FontWeight.w700, letterSpacing: 0.5)),
          ),
        )
            .animate()
            .fadeIn(delay: 1800.ms, duration: 400.ms)
            .slideY(begin: 0.2, end: 0, duration: 400.ms),
        const SizedBox(height: 12),
        TextButton(
          onPressed: () => Navigator.of(context).popUntil((r) => r.isFirst),
          child: Text('See The Stats.',
              style: _body(14, color: _lime)
                  .copyWith(fontWeight: FontWeight.w600, letterSpacing: 0.3)),
        )
            .animate()
            .fadeIn(delay: 1950.ms, duration: 400.ms),
      ],
    );
  }
}

// Data class for logic card rows
class _LogicRow {
  final String label;
  final String value;
  final bool   isLime;
  const _LogicRow(this.label, this.value, this.isLime);
}
