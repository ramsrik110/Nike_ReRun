import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../models/shoe_model.dart';
import '../models/customer_model.dart';

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

class CustomerScreen extends StatefulWidget {
  final String suid;
  final String customerId;

  const CustomerScreen({
    super.key,
    this.suid       = 'NR-2024-AM90-0006',
    this.customerId = 'CUST-001',
  });

  @override
  State<CustomerScreen> createState() => _CustomerScreenState();
}

class _CustomerScreenState extends State<CustomerScreen> {
  ShoeModel?     _shoe;
  CustomerModel? _customer;
  bool           _loading  = true;
  bool           _returning = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final shoeDoc = await FirebaseFirestore.instance
          .collection('Shoes') // capital S — always
          .doc(widget.suid)
          .get();

      final customerDoc = await FirebaseFirestore.instance
          .collection('customers')
          .doc(widget.customerId)
          .get();

      if (mounted) {
        setState(() {
          _shoe     = ShoeModel.fromFirestore(shoeDoc);
          _customer = CustomerModel.fromFirestore(customerDoc);
          _loading  = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _initiateReturn() async {
    if (_shoe == null || _returning) return;
    setState(() => _returning = true);

    try {
      await FirebaseFirestore.instance
          .collection('Shoes') // capital S — always
          .doc(widget.suid)
          .update({'LCS-STS': 'RETURN INITIATED.'});

      if (mounted) {
        _showReturnConfirmation();
      }
    } catch (e) {
      if (mounted) setState(() => _returning = false);
    }
  }

  void _showReturnConfirmation() {
    showModalBottomSheet(
      context: context,
      backgroundColor: _card,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => _ReturnConfirmationSheet(
        rwdAmt: _shoe!.rwdAmt,
        onDone: () => Navigator.pop(context),
      ),
    );
    setState(() => _returning = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _black,
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: _lime))
          : _shoe == null
              ? Center(
                  child: Text('Shoe not found.',
                      style: _body(16, color: _white)))
              : _buildContent(),
    );
  }

  Widget _buildContent() {
    final shoe = _shoe!;
    return Stack(
      children: [
        CustomScrollView(
          slivers: [
            _buildAppBar(shoe),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 120),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 24),
                    _buildHeadline(shoe),
                    const SizedBox(height: 20),
                    _buildPassportCard(shoe),
                    const SizedBox(height: 16),
                    _buildTimeline(shoe),
                  ],
                ),
              ),
            ),
          ],
        ),
        _buildBottomButton(shoe),
      ],
    );
  }

  // ── App bar with shoe image ───────────────────────────────────────────────

  Widget _buildAppBar(ShoeModel shoe) {
    return SliverAppBar(
      expandedHeight: 300,
      backgroundColor: _black,
      pinned: true,
      leading: const SizedBox.shrink(),
      flexibleSpace: FlexibleSpaceBar(
        background: Stack(
          children: [
            Positioned.fill(
              child: shoe.snmImg.isNotEmpty
                  ? Image.network(
                      shoe.snmImg,
                      fit: BoxFit.contain,
                      errorBuilder: (_, __, ___) => _shoePlaceholder(),
                    )
                  : _shoePlaceholder(),
            ),
            Positioned(
              top: 0, left: 0, right: 0,
              child: Container(
                color: _card,
                padding: EdgeInsets.only(
                  top: MediaQuery.of(context).padding.top + 10,
                  left: 20,
                  right: 20,
                  bottom: 12,
                ),
                child: Row(
                  children: [
                    ColorFiltered(
                      colorFilter: const ColorFilter.mode(
                          _lime, BlendMode.modulate),
                      child: Image.asset(
                          'assets/images/nikererun.png', height: 24),
                    ),
                    const SizedBox(width: 8),
                    Text('RERUN', style: _heading(22, color: _white)),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _shoePlaceholder() {
    return Container(
      color: _black,
      child: Center(
        child: Text(
          'NIKE',
          style: GoogleFonts.bebasNeue(
            fontSize: 48,
            color: _lime.withOpacity(0.12),
            letterSpacing: 14,
          ),
        ),
      ),
    );
  }

  // ── Headline + badge ──────────────────────────────────────────────────────

  Widget _buildHeadline(ShoeModel shoe) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(shoe.snmHdl, style: _heading(50))
            .animate()
            .fadeIn(duration: 500.ms)
            .slideY(begin: 0.2, end: 0, duration: 500.ms),
        const SizedBox(height: 10),
        Row(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: _lime,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                'Eco Tracked',
                style: _body(12, color: _black)
                    .copyWith(fontWeight: FontWeight.w700),
              ),
            )
                .animate(onPlay: (c) => c.repeat(reverse: true))
                .shimmer(duration: 2000.ms, color: _white.withOpacity(0.3)),
            const SizedBox(width: 10),
            Text(shoe.suid, style: _body(12, color: _grey)),
          ],
        ).animate().fadeIn(delay: 200.ms, duration: 400.ms),
      ],
    );
  }

  // ── Digital Product Passport card ─────────────────────────────────────────

  Widget _buildPassportCard(ShoeModel shoe) {
    return Container(
      decoration: const BoxDecoration(
        color: _card,
        borderRadius: BorderRadius.all(Radius.circular(14)),
        border: Border(top: BorderSide(color: _lime, width: 2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
            child: Row(
              children: [
                Container(width: 4, height: 20, color: _lime),
                const SizedBox(width: 10),
                Text("Your Shoe's Story", style: _heading(20)),
              ],
            ),
          ),
          const SizedBox(height: 12),
          const Divider(color: _border, height: 1),
          const SizedBox(height: 8),
          _passportRow('Built With', _buildMaterialString(shoe), isEco: false),
          _passportRow('Born In',    shoe.mfgCtr,                isEco: false),
          _passportRow('Powered By', shoe.mfgNrg,                isEco: false),
          _passportRow('You Saved',  '${shoe.ecoCo2} kg CO₂',   isEco: true),
          const SizedBox(height: 8),
        ],
      ),
    )
        .animate()
        .fadeIn(delay: 300.ms, duration: 500.ms)
        .slideY(begin: 0.1, end: 0, duration: 500.ms);
  }

  Widget _passportRow(String label, String value, {required bool isEco}) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: _body(14, color: _grey)),
          Text(
            value,
            style: _body(14, color: isEco ? _lime : _white)
                .copyWith(fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }

  String _buildMaterialString(ShoeModel shoe) {
    final parts = <String>[];
    if (shoe.mcpFlk > 0) parts.add('${shoe.mcpFlk.toInt()}% Flyknit');
    if (shoe.mcpRbr > 0) parts.add('${shoe.mcpRbr.toInt()}% Rubber');
    if (shoe.mcpFom > 0) parts.add('${shoe.mcpFom.toInt()}% Foam');
    if (shoe.mcpLth > 0) parts.add('${shoe.mcpLth.toInt()}% Leather');
    return parts.take(2).join(' · ');
  }

  // ── Journey timeline ──────────────────────────────────────────────────────

  Widget _buildTimeline(ShoeModel shoe) {
    return Container(
      decoration: const BoxDecoration(
        color: Color(0xFF1E1E1E),
        borderRadius: BorderRadius.all(Radius.circular(14)),
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('The Journey', style: _heading(22)),
          const SizedBox(height: 20),
          Row(
            children: [
              _timelineDot(active: false, done: true),
              _timelineLine(filled: true),
              _timelineDot(active: false, done: true),
              _timelineLine(filled: true),
              _timelineDot(active: true, done: false),
            ],
          ),
          const SizedBox(height: 10),
          const Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _TimelineLabel('MADE',            active: false),
              _TimelineLabel('YOURS',           active: false),
              _TimelineLabel('CLOSE\nTHE LOOP', active: true),
            ],
          ),
        ],
      ),
    )
        .animate()
        .fadeIn(delay: 400.ms, duration: 500.ms)
        .slideY(begin: 0.1, end: 0, duration: 500.ms);
  }

  Widget _timelineDot({required bool active, required bool done}) {
    return Container(
      width: 20,
      height: 20,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: active ? _lime : (done ? _lime.withOpacity(0.4) : _border),
        boxShadow: active
            ? [BoxShadow(
                color: _lime.withOpacity(0.5),
                blurRadius: 10,
                spreadRadius: 2)]
            : null,
      ),
    )
        .animate(onPlay: active ? (c) => c.repeat(reverse: true) : null)
        .scaleXY(
          begin: 1.0,
          end: active ? 1.3 : 1.0,
          duration: 1000.ms,
        );
  }

  Widget _timelineLine({required bool filled}) {
    return Expanded(
      child: Container(
        height: 2,
        color: filled ? _lime.withOpacity(0.4) : _border,
      ),
    );
  }

  // ── Bottom CTA button ─────────────────────────────────────────────────────

  Widget _buildBottomButton(ShoeModel shoe) {
    return Positioned(
      bottom: 0, left: 0, right: 0,
      child: Container(
        padding: EdgeInsets.only(
          left: 20,
          right: 20,
          top: 12,
          bottom: MediaQuery.of(context).padding.bottom + 12,
        ),
        decoration: BoxDecoration(
          color: _black,
          border: Border(top: BorderSide(color: _border)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _returning ? null : _initiateReturn,
                style: ElevatedButton.styleFrom(
                  backgroundColor: _lime,
                  foregroundColor: _black,
                  padding: const EdgeInsets.symmetric(vertical: 18),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10)),
                  elevation: 0,
                ),
                child: _returning
                    ? const SizedBox(
                        height: 20, width: 20,
                        child: CircularProgressIndicator(
                            color: _black, strokeWidth: 2),
                      )
                    : Text('Close The Loop.',
                        style: _heading(22, color: _black)),
              ),
            )
                .animate()
                .fadeIn(delay: 600.ms, duration: 400.ms)
                .slideY(begin: 0.3, end: 0, duration: 400.ms),
            const SizedBox(height: 6),
            Text(
              'Return It. Earn ${shoe.rwdAmt} NikeCoins.',
              style: _body(13, color: _lime),
            ).animate().fadeIn(delay: 700.ms, duration: 400.ms),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Timeline label widget
// ─────────────────────────────────────────────────────────────────────────────

class _TimelineLabel extends StatelessWidget {
  final String text;
  final bool   active;

  const _TimelineLabel(this.text, {required this.active});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 70,
      child: Text(
        text,
        textAlign: TextAlign.center,
        style: GoogleFonts.nunito(
          color: active ? _lime : _grey,
          fontSize: 11,
          fontWeight: active ? FontWeight.w700 : FontWeight.w400,
          letterSpacing: 0.5,
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Return confirmation bottom sheet
// ─────────────────────────────────────────────────────────────────────────────

class _ReturnConfirmationSheet extends StatelessWidget {
  final int          rwdAmt;
  final VoidCallback onDone;

  const _ReturnConfirmationSheet({
    required this.rwdAmt,
    required this.onDone,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(28),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 48, height: 4,
            decoration: BoxDecoration(
              color: _border,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 28),
          Container(
            width: 72, height: 72,
            decoration: BoxDecoration(
              color: _lime.withOpacity(0.15),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.check, color: _lime, size: 36),
          )
              .animate()
              .scale(begin: const Offset(0.5, 0.5), duration: 400.ms,
                  curve: Curves.elasticOut),
          const SizedBox(height: 20),
          Text('RETURN INITIATED.', style: _heading(32)),
          const SizedBox(height: 8),
          Text('You\'ve earned $rwdAmt NikeCoins.',
              style: _body(14, color: _lime)),
          const SizedBox(height: 8),
          Text('A confirmation email is on its way.',
              style: _body(13, color: _grey)),
          const SizedBox(height: 32),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: onDone,
              style: ElevatedButton.styleFrom(
                backgroundColor: _lime,
                foregroundColor: _black,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10)),
              ),
              child: Text('Done.', style: _heading(20, color: _black)),
            ),
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}
