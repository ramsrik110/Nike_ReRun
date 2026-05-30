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

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    // Get customer document
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

    // Primary: fetch each shoe by SUID from the SUID-LNK array on the user doc
    final linkedIds = data?['SUID-LNK'] as List<dynamic>? ?? [];
    for (final id in linkedIds) {
      final suid = id as String;
      if (seen.contains(suid)) continue;
      final doc = await FirebaseFirestore.instance
          .collection('Shoes') // capital S — always
          .doc(suid)
          .get();
      if (doc.exists) {
        shoes.add(ShoeModel.fromFirestore(doc));
        seen.add(suid);
      }
    }

    // Secondary fallback: query Shoes where CUID-LNK == current user UID
    final byLinkSnap = await FirebaseFirestore.instance
        .collection('Shoes') // capital S — always
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
    return Scaffold(
      backgroundColor: _black,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(),
            Expanded(
              child: _loading
                  ? const Center(
                      child: CircularProgressIndicator(color: _lime))
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

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
      color: _card,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Text('NIKE RERUN', style: _heading(22, color: _white)),
              const SizedBox(width: 8),
              const Icon(Icons.eco, color: _lime, size: 20),
            ],
          ),
          IconButton(
            icon: const Icon(Icons.logout, color: _grey, size: 20),
            onPressed: _signOut,
            tooltip: 'Sign Out',
          ),
        ],
      ),
    );
  }

  Widget _buildBody() {
    return SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 8),
          _buildWelcome(),
          const SizedBox(height: 28),
          _shoes.isEmpty ? _buildEmptyState() : _buildShoeList(),
        ],
      ),
    );
  }

  Widget _buildWelcome() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Hey $_name,', style: _heading(28, color: _lime))
            .animate()
            .fadeIn(duration: 400.ms)
            .slideY(begin: 0.2, end: 0, duration: 400.ms),
        const SizedBox(height: 4),
        Text('Your kicks. Your story.', style: _body(16, color: _grey))
            .animate()
            .fadeIn(delay: 150.ms, duration: 400.ms),
      ],
    );
  }

  Widget _buildShoeList() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Your Kicks', style: _heading(20))
            .animate()
            .fadeIn(delay: 200.ms, duration: 400.ms),
        const SizedBox(height: 14),
        SizedBox(
          height: 220,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: _shoes.length,
            separatorBuilder: (_, __) => const SizedBox(width: 14),
            itemBuilder: (context, i) {
              return _buildShoeCard(_shoes[i], i);
            },
          ),
        ),
        const SizedBox(height: 28),
        _buildQuickStats(),
      ],
    );
  }

  // FIX 7: Shoe cards slide in from right with 100ms stagger
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
        width: 160,
        decoration: BoxDecoration(
          color: _card,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: _border),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Shoe image
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
            Padding(
              padding: const EdgeInsets.all(10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    shoe.snmHdl,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: _heading(13, color: _lime),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    shoe.snm,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: _body(11, color: _grey),
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

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 60),
        child: Column(
          children: [
            const Icon(Icons.directions_run_outlined,
                color: _grey, size: 64),
            const SizedBox(height: 16),
            Text('No kicks registered yet.',
                style: _body(16, color: _white)),
            const SizedBox(height: 8),
            Text(
              'Scan your shoe to get started.',
              style: _body(14, color: _grey),
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
                  style: _body(15, color: _black)
                      .copyWith(fontWeight: FontWeight.w900)),
            ),
          ],
        ),
      ),
    ).animate().fadeIn(delay: 200.ms, duration: 400.ms);
  }

  Widget _buildQuickStats() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _card,
        borderRadius: BorderRadius.circular(14),
        border: const Border(left: BorderSide(color: _lime, width: 3)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _stat('${_shoes.length}', 'Kicks'),
          _statDivider(),
          _stat(
            '${_shoes.fold<double>(0, (sum, s) => sum + s.ecoCo2).toStringAsFixed(1)} kg',
            'CO₂ Saved',
          ),
          _statDivider(),
          _stat(
            '${_shoes.fold<int>(0, (sum, s) => sum + s.rwdAmt)}',
            'NikeCoins',
          ),
        ],
      ),
    )
        .animate()
        .fadeIn(delay: 400.ms, duration: 400.ms)
        .slideY(begin: 0.1, end: 0, duration: 400.ms);
  }

  Widget _stat(String value, String label) {
    return Column(
      children: [
        Text(value, style: _heading(20, color: _lime)),
        const SizedBox(height: 2),
        Text(label, style: _body(12, color: _grey)),
      ],
    );
  }

  Widget _statDivider() {
    return Container(width: 1, height: 36, color: _border);
  }
}
