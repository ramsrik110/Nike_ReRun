import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../nike_colors.dart';
import '../models/shoe_model.dart';
import 'customer_shoe_detail_screen.dart';

const _lime  = Color(0xFFCDFC49);
const _black = Color(0xFF111111);

// ─────────────────────────────────────────────────────────────────────────────
// Screen
// ─────────────────────────────────────────────────────────────────────────────

class CustomerHomeScreen extends StatefulWidget {
  final VoidCallback? onScanTap;

  const CustomerHomeScreen({super.key, this.onScanTap});

  @override
  State<CustomerHomeScreen> createState() => _CustomerHomeScreenState();
}

class _CustomerHomeScreenState extends State<CustomerHomeScreen> {
  List<ShoeModel> _shoes   = [];
  bool            _loading = true;
  String          _name    = '';

  NikeColors get _c => context.nc;

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
    _name = (data?['CST-NM'] as String? ?? user.displayName ?? 'Athlete')
        .split(' ')
        .first;

    final seen = <String>{};
    final shoes = <ShoeModel>[];

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

    final byLinkSnap = await FirebaseFirestore.instance
        .collection('Shoes')
        .where('CUID-LNK', isEqualTo: user.uid)
        .get();
    for (final d in byLinkSnap.docs) {
      final shoe = ShoeModel.fromFirestore(d);
      if (!seen.contains(shoe.suid)) {
        shoes.add(shoe);
        seen.add(shoe.suid);
      }
    }

    if (mounted) {
      setState(() {
        _shoes   = shoes;
        _loading = false;
      });
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
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(c),
            Expanded(
              child: _loading
                  ? const Center(
                      child: CircularProgressIndicator(color: _lime))
                  : RefreshIndicator(
                      color: _lime,
                      backgroundColor: c.card,
                      onRefresh: _load,
                      child: _buildBody(c),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(NikeColors c) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
      color: c.card,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              ColorFiltered(
                colorFilter: const ColorFilter.mode(_lime, BlendMode.modulate),
                child: Image.asset('assets/images/nikererun.png', height: 28),
              ),
              const SizedBox(width: 10),
              Text('RERUN',
                  style: GoogleFonts.bebasNeue(
                      fontSize: 22, color: c.text, letterSpacing: 1.5)),
            ],
          ),
          IconButton(
            icon: Icon(Icons.logout, color: c.sub, size: 20),
            onPressed: _signOut,
            tooltip: 'Sign Out',
          ),
        ],
      ),
    );
  }

  Widget _buildBody(NikeColors c) {
    return SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 8),
          _buildWelcome(c),
          const SizedBox(height: 28),
          _shoes.isEmpty ? _buildEmptyState(c) : _buildShoeList(c),
        ],
      ),
    );
  }

  Widget _buildWelcome(NikeColors c) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Hey $_name,',
            style: GoogleFonts.bebasNeue(
                fontSize: 44, color: _lime, letterSpacing: 1.5))
            .animate()
            .fadeIn(duration: 400.ms)
            .slideY(begin: 0.2, end: 0, duration: 400.ms),
        const SizedBox(height: 4),
        Text('Your kicks. Your story.',
            style: GoogleFonts.nunito(fontSize: 15, color: c.sub))
            .animate()
            .fadeIn(delay: 150.ms, duration: 400.ms),
      ],
    );
  }

  Widget _buildShoeList(NikeColors c) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Your Kicks',
            style: GoogleFonts.bebasNeue(
                fontSize: 28, color: c.text, letterSpacing: 1.5))
            .animate()
            .fadeIn(delay: 200.ms, duration: 400.ms),
        const SizedBox(height: 14),
        SizedBox(
          height: 220,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: _shoes.length,
            separatorBuilder: (_, __) => const SizedBox(width: 14),
            itemBuilder: (context, i) => _buildShoeCard(_shoes[i], i, c),
          ),
        ),
        const SizedBox(height: 28),
        _buildQuickStats(c),
      ],
    );
  }

  Widget _buildShoeCard(ShoeModel shoe, int index, NikeColors c) {
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
        width: 160,
        decoration: BoxDecoration(
          color: c.card,
          borderRadius: const BorderRadius.all(Radius.circular(14)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(16)),
              child: SizedBox(
                height: 120,
                width: double.infinity,
                child: shoe.snmImg.isNotEmpty
                    ? Image.network(
                        shoe.snmImg,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => Container(
                          color: c.bg,
                          child: const Icon(Icons.directions_run,
                              color: _lime, size: 40),
                        ),
                      )
                    : Container(
                        color: c.bg,
                        child: Center(
                          child: Text(
                            'NIKE',
                            style: GoogleFonts.bebasNeue(
                              fontSize: 24,
                              color: _lime.withOpacity(0.18),
                              letterSpacing: 6,
                            ),
                          ),
                        ),
                      ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    shoe.snmHdl,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.bebasNeue(
                        fontSize: 16, color: _lime, letterSpacing: 1.5),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    shoe.snm,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.nunito(fontSize: 13, color: c.sub),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    )
        .animate()
        .fadeIn(
          delay: Duration(milliseconds: 200 + index * 100),
          duration: 400.ms,
        )
        .slideX(
          begin: 0.3,
          end: 0,
          delay: Duration(milliseconds: 200 + index * 100),
          duration: 400.ms,
          curve: Curves.easeOutCubic,
        );
  }

  Widget _buildEmptyState(NikeColors c) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 60),
        child: Column(
          children: [
            Icon(Icons.directions_run_outlined, color: c.sub, size: 64),
            const SizedBox(height: 16),
            Text('No kicks registered yet.',
                style: GoogleFonts.nunito(fontSize: 16, color: c.text)),
            const SizedBox(height: 8),
            Text(
              'Scan your shoe to get started.',
              style: GoogleFonts.nunito(fontSize: 14, color: c.sub),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: widget.onScanTap,
              style: ElevatedButton.styleFrom(
                backgroundColor: _lime,
                foregroundColor: _black,
                padding: const EdgeInsets.symmetric(
                    horizontal: 28, vertical: 14),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
                elevation: 0,
              ),
              child: Text('Scan My Shoe',
                  style: GoogleFonts.nunito(
                      fontSize: 15, color: _black,
                      fontWeight: FontWeight.w900)),
            ),
          ],
        ),
      ),
    ).animate().fadeIn(delay: 200.ms, duration: 400.ms);
  }

  Widget _buildQuickStats(NikeColors c) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: c.card,
        borderRadius: BorderRadius.circular(14),
        border: Border(left: BorderSide(color: _lime, width: 3)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _stat('${_shoes.length}', 'Kicks', c),
          _statDivider(c),
          _stat(
            '${_shoes.fold<double>(0, (sum, s) => sum + s.ecoCo2).toStringAsFixed(1)} kg',
            'CO₂ Saved', c,
          ),
          _statDivider(c),
          _stat(
            '${_shoes.fold<int>(0, (sum, s) => sum + s.rwdAmt)}',
            'NikeCoins', c,
          ),
        ],
      ),
    )
        .animate()
        .fadeIn(delay: 400.ms, duration: 400.ms)
        .slideY(begin: 0.1, end: 0, duration: 400.ms);
  }

  Widget _stat(String value, String label, NikeColors c) {
    return Column(
      children: [
        Text(value,
            style: GoogleFonts.bebasNeue(
                fontSize: 22, color: _lime, letterSpacing: 1.5)),
        const SizedBox(height: 2),
        Text(label,
            style: GoogleFonts.nunito(fontSize: 12, color: c.sub)),
      ],
    );
  }

  Widget _statDivider(NikeColors c) {
    return Container(width: 1, height: 36, color: c.border);
  }
}
