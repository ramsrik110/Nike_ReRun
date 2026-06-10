import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../models/shoe_model.dart';
import 'customer_shoe_detail_screen.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Colours
// ─────────────────────────────────────────────────────────────────────────────
const _black  = Color(0xFF111111);
const _card   = Color(0xFF1A1A1A);
const _lime   = Color(0xFFCDFC49);
const _white  = Color(0xFFFFFFFF);
const _grey   = Color(0xFF888888);
const _border = Color(0xFF2A2A2A);

TextStyle _heading(double size, {Color color = _white}) =>
    GoogleFonts.bebasNeue(fontSize: size, color: color, letterSpacing: 1.5);
TextStyle _body(double size, {Color color = _white}) =>
    GoogleFonts.nunito(fontSize: size, color: color);

// ─────────────────────────────────────────────────────────────────────────────
// Screen — placeholder until full Nike Run Club redesign in next step
// ─────────────────────────────────────────────────────────────────────────────

class CustomerLockerScreen extends StatefulWidget {
  final VoidCallback? onScanTap;

  const CustomerLockerScreen({super.key, this.onScanTap});

  @override
  State<CustomerLockerScreen> createState() => _CustomerLockerScreenState();
}

class _CustomerLockerScreenState extends State<CustomerLockerScreen> {
  List<ShoeModel> _shoes   = [];
  bool            _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final userDoc = await FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .get();
    final data = userDoc.data();

    final seen  = <String>{};
    final shoes = <ShoeModel>[];

    // Primary: SUID-LNK array on user doc
    final linkedIds = data?['SUID-LNK'] as List<dynamic>? ?? [];
    for (final id in linkedIds) {
      final suid = id as String;
      if (seen.contains(suid)) continue;
      final doc = await FirebaseFirestore.instance
          .collection('Shoes')
          .doc(suid)
          .get();
      if (doc.exists) {
        shoes.add(ShoeModel.fromFirestore(doc));
        seen.add(suid);
      }
    }

    // Fallback: query by CUID-LNK
    final byLink = await FirebaseFirestore.instance
        .collection('Shoes')
        .where('CUID-LNK', isEqualTo: user.uid)
        .get();
    for (final d in byLink.docs) {
      final shoe = ShoeModel.fromFirestore(d);
      if (!seen.contains(shoe.suid)) {
        shoes.add(shoe);
        seen.add(shoe.suid);
      }
    }

    if (mounted) setState(() { _shoes = shoes; _loading = false; });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _black,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(),
            Expanded(
              child: _loading
                  ? const Center(child: CircularProgressIndicator(color: _lime))
                  : RefreshIndicator(
                      color: _lime,
                      backgroundColor: _card,
                      onRefresh: _load,
                      child: _buildBody(),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Header ────────────────────────────────────────────────────────────────

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
      decoration: const BoxDecoration(
        color: _card,
        border: Border(bottom: BorderSide(color: _border)),
      ),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => Navigator.of(context).pop(),
            child: const Icon(Icons.arrow_back, color: _white, size: 22),
          ),
          const SizedBox(width: 16),
          Text('YOUR LOCKER', style: _heading(24)),
          const Spacer(),
          GestureDetector(
            onTap: widget.onScanTap,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
              decoration: BoxDecoration(
                color: _lime,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.qr_code_scanner, color: _black, size: 16),
                  const SizedBox(width: 6),
                  Text('Scan', style: _body(13, color: _black)
                      .copyWith(fontWeight: FontWeight.w800)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Body ──────────────────────────────────────────────────────────────────

  Widget _buildBody() {
    if (_shoes.isEmpty) return _buildEmptyState();

    return SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 40),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '${_shoes.length} ${_shoes.length == 1 ? 'Kick' : 'Kicks'}',
            style: _body(14, color: _grey),
          )
              .animate()
              .fadeIn(duration: 400.ms),
          const SizedBox(height: 20),
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _shoes.length,
            separatorBuilder: (_, __) => const SizedBox(height: 16),
            itemBuilder: (context, i) => _buildShoeCard(_shoes[i], i),
          ),
        ],
      ),
    );
  }

  // ── Shoe card ─────────────────────────────────────────────────────────────

  Widget _buildShoeCard(ShoeModel shoe, int index) {
    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        PageRouteBuilder(
          pageBuilder: (_, __, ___) =>
              CustomerShoeDetailScreen(suid: shoe.suid),
          transitionsBuilder: (_, anim, __, child) => SlideTransition(
            position: Tween<Offset>(
                    begin: const Offset(1.0, 0.0), end: Offset.zero)
                .animate(CurvedAnimation(
                    parent: anim, curve: Curves.easeOutCubic)),
            child: child,
          ),
          transitionDuration: const Duration(milliseconds: 350),
        ),
      ),
      child: Container(
        height: 130,
        decoration: BoxDecoration(
          color: _card,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: _border),
        ),
        child: Row(
          children: [
            // Shoe image
            ClipRRect(
              borderRadius: const BorderRadius.horizontal(
                  left: Radius.circular(16)),
              child: SizedBox(
                width: 130,
                height: 130,
                child: shoe.snmImg.isNotEmpty
                    ? Image.network(
                        shoe.snmImg,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => Container(
                          color: _black,
                          child: const Icon(Icons.directions_run,
                              color: _lime, size: 40),
                        ),
                      )
                    : Container(
                        color: _black,
                        child: const Icon(Icons.directions_run,
                            color: _lime, size: 40),
                      ),
              ),
            ),
            // Info
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      shoe.snmHdl,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: _body(15, color: _white)
                          .copyWith(fontWeight: FontWeight.w800),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      shoe.snm,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: _body(13, color: _grey),
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        _chip('${shoe.ecoCo2} kg CO₂'),
                        const SizedBox(width: 8),
                        _chip('${shoe.rwdAmt} coins'),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const Padding(
              padding: EdgeInsets.only(right: 16),
              child: Icon(Icons.chevron_right, color: _grey, size: 20),
            ),
          ],
        ),
      ),
    )
        .animate()
        .fadeIn(delay: Duration(milliseconds: 100 + index * 80), duration: 400.ms)
        .slideY(begin: 0.1, end: 0, delay: Duration(milliseconds: 100 + index * 80), duration: 400.ms);
  }

  Widget _chip(String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: _lime.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(label, style: _body(11, color: _lime)
          .copyWith(fontWeight: FontWeight.w700)),
    );
  }

  // ── Empty state ───────────────────────────────────────────────────────────

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.directions_run_outlined, color: _grey, size: 64),
            const SizedBox(height: 20),
            Text('YOUR LOCKER IS EMPTY.',
                style: _heading(26), textAlign: TextAlign.center),
            const SizedBox(height: 8),
            Text(
              "Let's change that.\nScan your first shoe to start the loop.",
              style: _body(14, color: _grey),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 28),
            ElevatedButton.icon(
              onPressed: () {
                Navigator.of(context).pop();
                widget.onScanTap?.call();
              },
              icon: const Icon(Icons.qr_code_scanner, color: _black, size: 18),
              label: Text('Scan My First Shoe',
                  style: _body(15, color: _black)
                      .copyWith(fontWeight: FontWeight.w900)),
              style: ElevatedButton.styleFrom(
                backgroundColor: _lime,
                foregroundColor: _black,
                padding: const EdgeInsets.symmetric(
                    horizontal: 28, vertical: 14),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(50)),
                elevation: 0,
              ),
            ),
          ],
        ),
      ),
    ).animate().fadeIn(delay: 200.ms, duration: 400.ms);
  }
}
