import 'dart:async';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../models/shoe_model.dart';
import '../nike_colors.dart';
import '../utils/routing_algorithm.dart';
import 'login_screen.dart';

const _lime  = Color(0xFFCDFC49);
const _black = Color(0xFF111111);

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
  String _displayedDecision = '';
  Timer? _typewriterTimer;
  int    _charIndex = 0;

  late AnimationController _arrowCtrl;
  late Animation<double>   _arrowAnim;

  String get _hubLabel => 'Lane 1 — Berlin Hub';

  NikeColors get _c => context.nc;

  @override
  void initState() {
    super.initState();

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
    final c = _c;
    return Scaffold(
      backgroundColor: c.bg,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const SizedBox(height: 16),
              _buildTopBar(c),
              const SizedBox(height: 32),
              _buildNextStopLabel(c),
              const SizedBox(height: 12),
              _buildDecision(c),
              const SizedBox(height: 20),
              _buildArrow(),
              const SizedBox(height: 16),
              _buildHubBadge(),
              const SizedBox(height: 28),
              _buildLogicCard(c),
              const SizedBox(height: 32),
              _buildButtons(c),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTopBar(NikeColors c) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text('NIKE RERUN',
            style: GoogleFonts.bebasNeue(
                fontSize: 18, color: _lime, letterSpacing: 1.5)),
        IconButton(
          icon: Icon(Icons.logout, color: c.sub, size: 20),
          onPressed: _signOut,
        ),
      ],
    );
  }

  Widget _buildNextStopLabel(NikeColors c) {
    return Text('NEXT STOP.',
            style: GoogleFonts.nunito(
                fontSize: 13, color: c.sub, letterSpacing: 3))
        .animate()
        .fadeIn(duration: 400.ms);
  }

  Widget _buildDecision(NikeColors c) {
    return Text(
      _displayedDecision.isEmpty ? ' ' : _displayedDecision,
      textAlign: TextAlign.center,
      style: GoogleFonts.bebasNeue(
          fontSize: 60, color: c.text, letterSpacing: 1.5),
    );
  }

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
              style: GoogleFonts.nunito(
                  fontSize: 14, color: _black,
                  fontWeight: FontWeight.w700)),
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

  Widget _buildLogicCard(NikeColors c) {
    final rows = [
      _LogicRow('Material Match',  widget.result.materialMatch,     true),
      _LogicRow('Shoe Grade',      widget.result.conditionGrade,    false),
      _LogicRow('Wear Level',      widget.result.wearLevelLabel,    false),
      _LogicRow('Structure',       widget.result.structuralLabel,   false),
      _LogicRow('Estimated Age',   widget.result.estimatedAgeLabel, false),
      _LogicRow('Cleaning Needed', widget.result.cleaningRequired ? 'Yes' : 'No',
          widget.result.cleaningRequired),
      _LogicRow('NikeCoin Reward', '${widget.result.nikeCoinReward} coins', true),
      _LogicRow("What's Next",     widget.result.whatNext,          true),
    ];

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: c.card,
        borderRadius: const BorderRadius.all(Radius.circular(14)),
        border: Border(
          top:    const BorderSide(color: _lime, width: 2),
          left:   BorderSide(color: c.border),
          right:  BorderSide(color: c.border),
          bottom: BorderSide(color: c.border),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text("Here's The Call.",
              style: GoogleFonts.bebasNeue(
                  fontSize: 20, color: c.text, letterSpacing: 1.5)),
          const SizedBox(height: 14),
          Divider(color: c.border, height: 1),
          const SizedBox(height: 12),
          ...rows.asMap().entries.map((e) {
            final delayMs = 800 + e.key * 150;
            return _buildLogicRow(e.value, delayMs, c);
          }),
        ],
      ),
    )
        .animate()
        .fadeIn(delay: 700.ms, duration: 500.ms)
        .slideY(begin: 0.1, end: 0, duration: 500.ms);
  }

  Widget _buildLogicRow(_LogicRow row, int delayMs, NikeColors c) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(row.label,
                style: GoogleFonts.nunito(fontSize: 13, color: c.sub)),
          ),
          Expanded(
            child: Text(
              row.value,
              style: GoogleFonts.nunito(
                  fontSize: 13,
                  color: row.isLime ? _lime : c.text,
                  fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    )
        .animate()
        .fadeIn(delay: Duration(milliseconds: delayMs), duration: 300.ms)
        .slideX(
            begin: 0.1, end: 0,
            delay: Duration(milliseconds: delayMs),
            duration: 300.ms);
  }

  Widget _buildButtons(NikeColors c) {
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
                style: GoogleFonts.nunito(
                    fontSize: 15, color: _lime,
                    fontWeight: FontWeight.w700, letterSpacing: 0.5)),
          ),
        )
            .animate()
            .fadeIn(delay: 1800.ms, duration: 400.ms)
            .slideY(begin: 0.2, end: 0, duration: 400.ms),
        const SizedBox(height: 12),
        TextButton(
          onPressed: () => Navigator.of(context).popUntil((r) => r.isFirst),
          child: Text('See The Stats.',
              style: GoogleFonts.nunito(
                  fontSize: 14, color: _lime,
                  fontWeight: FontWeight.w600, letterSpacing: 0.3)),
        )
            .animate()
            .fadeIn(delay: 1950.ms, duration: 400.ms),
      ],
    );
  }
}

class _LogicRow {
  final String label;
  final String value;
  final bool   isLime;
  const _LogicRow(this.label, this.value, this.isLime);
}
