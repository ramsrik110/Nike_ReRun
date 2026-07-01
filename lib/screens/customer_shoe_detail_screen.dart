import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../nike_colors.dart';
import '../models/shoe_model.dart';
import 'customer_return_confirm_screen.dart';

const _lime  = Color(0xFFCDFC49);
const _black = Color(0xFF111111);

// ─────────────────────────────────────────────────────────────────────────────
// Screen
// ─────────────────────────────────────────────────────────────────────────────

class CustomerShoeDetailScreen extends StatefulWidget {
  final String suid;

  const CustomerShoeDetailScreen({super.key, required this.suid});

  @override
  State<CustomerShoeDetailScreen> createState() =>
      _CustomerShoeDetailScreenState();
}

class _CustomerShoeDetailScreenState extends State<CustomerShoeDetailScreen> {
  ShoeModel? _shoe;
  bool       _loading = true;
  String?    _error;

  NikeColors get _c => context.nc;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    debugPrint('[ShoeDetail] received SUID: ${widget.suid}');
    try {
      final doc = await FirebaseFirestore.instance
          .collection('Shoes')
          .doc(widget.suid)
          .get();

      final shoe = doc.exists ? ShoeModel.fromFirestore(doc) : null;

      final currentUser = FirebaseAuth.instance.currentUser;
      if (shoe != null && currentUser != null) {
        final existingOwner = shoe.cuidLnk;
        if (existingOwner == currentUser.uid) {
          // Already owned — no-op
        } else if (existingOwner.isNotEmpty) {
          if (mounted) {
            setState(() {
              _shoe    = null;
              _loading = false;
              _error   = 'This shoe is already registered to another customer.';
            });
          }
          return;
        } else {
          await FirebaseFirestore.instance
              .collection('Shoes')
              .doc(widget.suid)
              .update({'CUID-LNK': currentUser.uid});
          await FirebaseFirestore.instance
              .collection('users')
              .doc(currentUser.uid)
              .update({'SUID-LNK': FieldValue.arrayUnion([widget.suid])});
          debugPrint('[ShoeDetail] linked ${widget.suid} to ${currentUser.uid}');
        }
      }

      if (mounted) {
        setState(() {
          _shoe    = shoe;
          _loading = false;
          _error   = null;
        });
      }
    } catch (e) {
      debugPrint('[ShoeDetail] Firestore error: $e');
      if (mounted) {
        setState(() {
          _shoe    = null;
          _loading = false;
          _error   = e.toString();
        });
      }
    }
  }

  void _signOut() async {
    await FirebaseAuth.instance.signOut();
  }

  // ── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final c = _c;
    return Scaffold(
      backgroundColor: c.bg,
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: _lime))
          : _error != null
              ? _buildError(_error!, c)
              : _shoe == null
                  ? _buildNotFound(c)
                  : _buildContent(_shoe!, c),
    );
  }

  Widget _buildError(String message, NikeColors c) {
    final isOwnershipError =
        message == 'This shoe is already registered to another customer.';
    return Scaffold(
      backgroundColor: c.bg,
      appBar: AppBar(
        backgroundColor: c.card,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios, color: c.text),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(isOwnershipError ? 'Already Registered' : 'Load Error',
            style: GoogleFonts.bebasNeue(
                fontSize: 20, color: c.text, letterSpacing: 1.5)),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                isOwnershipError ? Icons.lock_outline : Icons.wifi_off,
                color: _lime,
                size: 48,
              ),
              const SizedBox(height: 16),
              Text(
                isOwnershipError
                    ? 'This shoe belongs to someone else.'
                    : 'Could not load shoe data.',
                style: GoogleFonts.nunito(fontSize: 16, color: c.text),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                isOwnershipError
                    ? 'This shoe has already been registered by another customer and cannot be claimed.'
                    : 'Check Firestore security rules allow authenticated reads on the Shoes collection.\n\n$message',
                style: GoogleFonts.nunito(fontSize: 12, color: c.sub),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              if (!isOwnershipError)
                ElevatedButton(
                  onPressed: () {
                    setState(() { _loading = true; _error = null; });
                    _load();
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _lime,
                    foregroundColor: _black,
                  ),
                  child: Text('Retry',
                      style: GoogleFonts.nunito(fontSize: 14, color: _black)),
                )
              else
                ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _lime,
                    foregroundColor: _black,
                  ),
                  child: Text('Go Back',
                      style: GoogleFonts.nunito(fontSize: 14, color: _black)),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNotFound(NikeColors c) {
    return Scaffold(
      backgroundColor: c.bg,
      appBar: AppBar(
        backgroundColor: c.card,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios, color: c.text),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text('Shoe Not Found',
            style: GoogleFonts.bebasNeue(
                fontSize: 20, color: c.text, letterSpacing: 1.5)),
      ),
      body: Center(
          child: Text('No shoe with ID ${widget.suid}',
              style: GoogleFonts.nunito(fontSize: 14, color: c.sub))),
    );
  }

  Widget _buildContent(ShoeModel shoe, NikeColors c) {
    return Stack(
      children: [
        CustomScrollView(
          slivers: [
            _buildAppBar(shoe, c),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 120),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 20),
                    _buildHeadline(shoe, c),
                    const SizedBox(height: 16),
                    _buildPassportCard(shoe, c),
                    const SizedBox(height: 16),
                    _buildTimeline(c),
                  ],
                ),
              ),
            ),
          ],
        ),
        _buildBottomButton(shoe, c),
      ],
    );
  }

  Widget _buildAppBar(ShoeModel shoe, NikeColors c) {
    return SliverAppBar(
      expandedHeight: 280,
      backgroundColor: c.bg,
      pinned: true,
      leading: IconButton(
        icon: Icon(Icons.arrow_back_ios, color: c.text),
        onPressed: () => Navigator.pop(context),
      ),
      actions: [
        IconButton(
          icon: Icon(Icons.logout, color: c.sub, size: 20),
          onPressed: _signOut,
          tooltip: 'Sign Out',
        ),
      ],
      flexibleSpace: FlexibleSpaceBar(
        background: Stack(
          children: [
            Positioned.fill(
              child: shoe.snmImg.isNotEmpty
                  ? Image.network(
                      shoe.snmImg,
                      fit: BoxFit.contain,
                      errorBuilder: (_, __, ___) =>
                          Container(
                            color: c.bg,
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
                          ),
                    )
                      .animate()
                      .scale(
                        begin: const Offset(0.8, 0.8),
                        end: const Offset(1.0, 1.0),
                        duration: 800.ms,
                        curve: Curves.elasticOut,
                      )
                  : const Icon(Icons.directions_run, color: _lime, size: 80),
            ),
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: Container(
                color: c.card,
                padding: EdgeInsets.only(
                  top: MediaQuery.of(context).padding.top + 8,
                  left: 56,
                  right: 56,
                  bottom: 10,
                ),
                child: Center(
                  child: Text('NIKE RERUN',
                      style: GoogleFonts.bebasNeue(
                          fontSize: 20, color: _lime, letterSpacing: 1.5)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeadline(ShoeModel shoe, NikeColors c) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(shoe.snmHdl,
            style: GoogleFonts.bebasNeue(
                fontSize: 48, color: c.text, letterSpacing: 1.5))
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
              child: Text('Eco Tracked',
                  style: GoogleFonts.nunito(
                      fontSize: 13, color: _black,
                      fontWeight: FontWeight.w700)),
            )
                .animate(onPlay: (c) => c.repeat(reverse: true))
                .shimmer(
                    duration: 2000.ms,
                    color: Colors.white.withOpacity(0.3)),
            const SizedBox(width: 10),
            Text(shoe.suid,
                style: GoogleFonts.nunito(fontSize: 12, color: c.sub))
                .animate()
                .fadeIn(delay: 200.ms),
          ],
        ).animate().fadeIn(delay: 200.ms),
      ],
    );
  }

  Widget _buildPassportCard(ShoeModel shoe, NikeColors c) {
    final rows = [
      _PassportRow('Built With', _materialString(shoe), false),
      _PassportRow('Born In',    shoe.mfgCtr,           false),
      _PassportRow('Powered By', shoe.mfgNrg,           false),
      _PassportRow('You Saved',  '${shoe.ecoCo2} kg CO₂', true),
    ];

    return Container(
      decoration: BoxDecoration(
        color: c.card,
        borderRadius: const BorderRadius.all(Radius.circular(14)),
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
                Text("Your Shoe's Story",
                    style: GoogleFonts.bebasNeue(
                        fontSize: 20, color: c.text, letterSpacing: 1.5)),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Divider(color: c.border, height: 1),
          const SizedBox(height: 8),
          ...rows.asMap().entries.map((e) {
            final delay = 300 + e.key * 150;
            return _buildPassportRow(e.value, delay, c);
          }),
          const SizedBox(height: 8),
        ],
      ),
    )
        .animate()
        .fadeIn(delay: 200.ms, duration: 400.ms);
  }

  Widget _buildPassportRow(_PassportRow row, int delayMs, NikeColors c) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(row.label,
              style: GoogleFonts.nunito(fontSize: 15, color: c.sub)),
          Text(row.value,
              style: GoogleFonts.nunito(
                  fontSize: 15,
                  color: row.isEco ? _lime : c.text,
                  fontWeight: FontWeight.w600)),
        ],
      ),
    )
        .animate()
        .fadeIn(delay: Duration(milliseconds: delayMs), duration: 300.ms)
        .slideY(
            begin: 0.3,
            end: 0,
            delay: Duration(milliseconds: delayMs),
            duration: 300.ms);
  }

  String _materialString(ShoeModel shoe) {
    final parts = <String>[];
    if (shoe.mcpFlk > 0) parts.add('${shoe.mcpFlk.toInt()}% Flyknit');
    if (shoe.mcpRbr > 0) parts.add('${shoe.mcpRbr.toInt()}% Rubber');
    if (shoe.mcpFom > 0) parts.add('${shoe.mcpFom.toInt()}% Foam');
    if (shoe.mcpLth > 0) parts.add('${shoe.mcpLth.toInt()}% Leather');
    return parts.take(2).join(' · ');
  }

  Widget _buildTimeline(NikeColors c) {
    return Container(
      decoration: BoxDecoration(
        color: c.card2,
        borderRadius: const BorderRadius.all(Radius.circular(14)),
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('The Journey',
              style: GoogleFonts.bebasNeue(
                  fontSize: 22, color: c.text, letterSpacing: 1.5)),
          const SizedBox(height: 20),
          Row(
            children: [
              _timelineDot(active: false, done: true, delayMs: 0),
              _timelineLine(filled: true),
              _timelineDot(active: false, done: true, delayMs: 300),
              _timelineLine(filled: true),
              _timelineDot(active: true, done: false, delayMs: 600),
            ],
          ),
          const SizedBox(height: 10),
          Row(
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
        .fadeIn(delay: 700.ms, duration: 500.ms)
        .slideY(begin: 0.1, end: 0, duration: 500.ms);
  }

  Widget _timelineDot({
    required bool active,
    required bool done,
    required int  delayMs,
  }) {
    final dot = Container(
      width: 20,
      height: 20,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: active
            ? _lime
            : done
                ? _lime.withOpacity(0.4)
                : _c.border,
        boxShadow: active
            ? [BoxShadow(color: _lime.withOpacity(0.5), blurRadius: 10, spreadRadius: 2)]
            : null,
      ),
    );

    if (active) {
      return dot
          .animate(onPlay: (c) => c.repeat(reverse: true))
          .scaleXY(begin: 1.0, end: 1.3, duration: 1000.ms)
          .animate()
          .fadeIn(delay: Duration(milliseconds: delayMs), duration: 300.ms);
    }

    return dot
        .animate()
        .fadeIn(delay: Duration(milliseconds: delayMs), duration: 300.ms)
        .scale(
            begin: const Offset(0.5, 0.5),
            end: const Offset(1.0, 1.0),
            delay: Duration(milliseconds: delayMs),
            duration: 400.ms,
            curve: Curves.elasticOut);
  }

  Widget _timelineLine({required bool filled}) {
    return Expanded(
      child: Container(
        height: 2,
        color: filled ? _lime.withOpacity(0.4) : _c.border,
      ),
    );
  }

  Widget _buildBottomButton(ShoeModel shoe, NikeColors c) {
    return Positioned(
      bottom: 0,
      left: 0,
      right: 0,
      child: Container(
        padding: EdgeInsets.only(
          left: 16,
          right: 16,
          top: 12,
          bottom: MediaQuery.of(context).padding.bottom + 12,
        ),
        decoration: BoxDecoration(
          color: c.bg,
          border: Border(top: BorderSide(color: c.border)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => Navigator.push(
                  context,
                  PageRouteBuilder(
                    pageBuilder: (_, __, ___) =>
                        CustomerReturnConfirmScreen(shoe: shoe),
                    transitionsBuilder: (_, anim, __, child) =>
                        SlideTransition(
                      position: Tween<Offset>(
                              begin: const Offset(0, 1), end: Offset.zero)
                          .animate(CurvedAnimation(
                              parent: anim, curve: Curves.easeOutCubic)),
                      child: child,
                    ),
                    transitionDuration: const Duration(milliseconds: 400),
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: _lime,
                  foregroundColor: _black,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                  elevation: 0,
                ),
                child: Text('Close The Loop.',
                    style: GoogleFonts.nunito(
                        fontSize: 17, color: _black,
                        fontWeight: FontWeight.w900)),
              ),
            )
                .animate(onPlay: (c) => c.repeat(reverse: true))
                .scaleXY(begin: 1.0, end: 1.03, duration: 1000.ms,
                    curve: Curves.easeInOut)
                .animate()
                .fadeIn(delay: 800.ms, duration: 400.ms),
            const SizedBox(height: 6),
            Text('Return It. Earn ${shoe.rwdAmt} NikeCoins.',
                    style: GoogleFonts.nunito(fontSize: 13, color: _lime))
                .animate()
                .fadeIn(delay: 900.ms, duration: 400.ms),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Data class for passport rows
// ─────────────────────────────────────────────────────────────────────────────

class _PassportRow {
  final String label;
  final String value;
  final bool   isEco;
  const _PassportRow(this.label, this.value, this.isEco);
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
          fontSize: 12,
          color: active ? _lime : context.nc.sub,
          fontWeight: active ? FontWeight.w700 : FontWeight.w600,
          letterSpacing: 0.3,
        ),
      ),
    );
  }
}
