import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../models/shoe_model.dart';
import '../nike_colors.dart';
import '../theme_notifier.dart';
import 'customer_locker_screen.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Static consts (never themed — always lime or text-on-lime)
// ─────────────────────────────────────────────────────────────────────────────
const _lime  = Color(0xFFCDFC49);
const _black = Color(0xFF111111);

// ─────────────────────────────────────────────────────────────────────────────
// Tier system
// ─────────────────────────────────────────────────────────────────────────────
const _kEliteThreshold = 600;
const _kResetCoins     = 120;

class _Tier {
  final String   label;
  final int      threshold;
  final IconData icon;
  const _Tier(this.label, this.threshold, this.icon);
}

const _tiers = [
  _Tier('ROOKIE',   0,   Icons.directions_walk),
  _Tier('RUNNER',   150, Icons.directions_run),
  _Tier('ATHLETE',  300, Icons.fitness_center),
  _Tier('CHAMPION', 450, Icons.bolt),
  _Tier('ELITE',    600, Icons.workspace_premium),
];

// ─────────────────────────────────────────────────────────────────────────────
// Free products
// ─────────────────────────────────────────────────────────────────────────────
class _Product {
  final String   name;
  final String   sub;
  final IconData icon;
  const _Product(this.name, this.sub, this.icon);
}

const _freeProducts = [
  _Product('Nike Premium Gym Bag',    'Limited Drop',      Icons.backpack_outlined),
  _Product('Nike Stainless Bottle',   '750ml Insulated',   Icons.water_drop_outlined),
];

// ─────────────────────────────────────────────────────────────────────────────
// Achievement badge data
// ─────────────────────────────────────────────────────────────────────────────
class _Badge {
  final String   label;
  final IconData icon;
  final bool     unlocked;
  const _Badge(this.label, this.icon, this.unlocked);
}

// ─────────────────────────────────────────────────────────────────────────────
// Profile data holder
// ─────────────────────────────────────────────────────────────────────────────
class _ProfileData {
  final Map<String, dynamic> userData;
  final List<ShoeModel>      shoes;
  const _ProfileData({required this.userData, required this.shoes});
}

// ─────────────────────────────────────────────────────────────────────────────
// Screen
// ─────────────────────────────────────────────────────────────────────────────
class CustomerProfileScreen extends StatefulWidget {
  final VoidCallback onScanTap;
  const CustomerProfileScreen({super.key, required this.onScanTap});

  @override
  State<CustomerProfileScreen> createState() => _CustomerProfileScreenState();
}

class _CustomerProfileScreenState extends State<CustomerProfileScreen> {
  late Future<_ProfileData> _future;
  bool _claiming       = false;
  int? _selectedProduct;
  int? _demoCoins;

  NikeColors get _c => context.nc;

  @override
  void initState() {
    super.initState();
    _future = _loadData();
  }

  // ── Data fetch ─────────────────────────────────────────────────────────────

  Future<_ProfileData> _loadData() async {
    final uid = FirebaseAuth.instance.currentUser!.uid;
    final userDoc = await FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .get();
    final userData = userDoc.data() ?? {};

    final suidLnk = List<String>.from(userData['SUID-LNK'] ?? []);
    List<ShoeModel> shoes = [];

    if (suidLnk.isNotEmpty) {
      final snap = await FirebaseFirestore.instance
          .collection('Shoes')
          .where(FieldPath.documentId, whereIn: suidLnk)
          .get();
      shoes = snap.docs.map((d) => ShoeModel.fromFirestore(d)).toList();
    }

    if (shoes.isEmpty) {
      final snap = await FirebaseFirestore.instance
          .collection('Shoes')
          .where('CUID-LNK', isEqualTo: uid)
          .get();
      shoes = snap.docs.map((d) => ShoeModel.fromFirestore(d)).toList();
    }

    return _ProfileData(userData: userData, shoes: shoes);
  }

  // ── Claim reward ───────────────────────────────────────────────────────────

  Future<void> _claimReward(int productIdx) async {
    HapticFeedback.mediumImpact();
    setState(() => _claiming = true);
    final uid = FirebaseAuth.instance.currentUser!.uid;
    final c = _c;
    try {
      await FirebaseFirestore.instance.collection('users').doc(uid).update({
        'RWD-NCB':         _kResetCoins,
        'CLAIMED-PRODUCT': _freeProducts[productIdx].name,
      });
      if (mounted) {
        setState(() {
          _claiming        = false;
          _selectedProduct = null;
          _future          = _loadData();
        });
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(
            'Reward claimed! Check your Nike app.',
            style: GoogleFonts.nunito(fontSize: 14, color: c.text),
          ),
          backgroundColor: c.card,
        ));
      }
    } catch (_) {
      if (mounted) setState(() => _claiming = false);
    }
  }

  void _showClaimDialog(int productIdx) {
    HapticFeedback.mediumImpact();
    final c = _c;
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: c.card,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text('CLAIM REWARD',
            style: GoogleFonts.bebasNeue(
                fontSize: 22, color: _lime, letterSpacing: 1.5)),
        content: Text(
          'Claim "${_freeProducts[productIdx].name}"?\n\n'
          'Your NikeCoins balance resets to $_kResetCoins after claiming.',
          style: GoogleFonts.nunito(fontSize: 14, color: c.sub),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('NOT YET',
                style: GoogleFonts.nunito(
                    fontSize: 14, color: c.sub,
                    fontWeight: FontWeight.w700)),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _claimReward(productIdx);
            },
            child: Text('CLAIM IT',
                style: GoogleFonts.nunito(
                    fontSize: 14, color: _lime,
                    fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
  }

  // ── Build ──────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final c = _c;
    return Scaffold(
      backgroundColor: c.bg,
      body: SafeArea(
        child: FutureBuilder<_ProfileData>(
          future: _future,
          builder: (context, snap) {
            if (!snap.hasData) {
              return const Center(
                child: CircularProgressIndicator(color: _lime, strokeWidth: 2),
              );
            }
            return _buildContent(snap.data!, c);
          },
        ),
      ),
    );
  }

  Widget _buildContent(_ProfileData data, NikeColors c) {
    final user     = FirebaseAuth.instance.currentUser;
    final rawName  = user?.displayName ??
        user?.email?.split('@').first ??
        'Athlete';
    final name     = rawName.trim();
    final email    = user?.email ?? '';
    final initials = name.isNotEmpty ? name[0].toUpperCase() : 'A';

    final coins       = _demoCoins ?? (data.userData['RWD-NCB'] as num?)?.toInt() ?? 0;
    final returned    = data.shoes.where((s) => s.lcsSts == 'LOOP CLOSED.').toList();
    final returnCount = returned.length;
    final totalCo2    = returned.fold<double>(0, (s, shoe) => s + shoe.ecoCo2);
    final kmEquiv     = (totalCo2 * 4.5).round();

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(24, 40, 24, 110),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [

          _buildAvatar(initials, name, email, c),
          const SizedBox(height: 36),
          _buildCoinsSection(coins, c),
          const SizedBox(height: 20),
          _buildTierCard(coins, c),

          if (coins >= _kEliteThreshold) ...[
            const SizedBox(height: 16),
            _buildFreeProductCard(c),
          ],

          const SizedBox(height: 24),
          _buildImpactCard(totalCo2, kmEquiv, returnCount, c),
          const SizedBox(height: 24),
          _buildBadgesSection(returnCount, data.shoes.length, c),
          const SizedBox(height: 24),
          _buildLockerRow(data.shoes.length, c),
          const SizedBox(height: 24),
          _buildThemeToggle(c),
          const SizedBox(height: 16),
          _buildSignOut(c),
        ],
      ),
    );
  }

  // ── Avatar ─────────────────────────────────────────────────────────────────

  Widget _buildAvatar(String initials, String name, String email, NikeColors c) {
    return Column(
      children: [
        Container(
          width: 88, height: 88,
          decoration: const BoxDecoration(shape: BoxShape.circle, color: _lime),
          child: Center(
            child: Text(initials,
                style: GoogleFonts.bebasNeue(
                    fontSize: 40, color: _black, letterSpacing: 1.5)),
          ),
        )
            .animate()
            .scale(begin: const Offset(0.5, 0.5), duration: 500.ms,
                curve: Curves.elasticOut),

        const SizedBox(height: 16),

        Text(name.toUpperCase(),
            style: GoogleFonts.bebasNeue(
                fontSize: 30, color: c.text, letterSpacing: 1.5))
            .animate()
            .fadeIn(delay: 200.ms, duration: 400.ms)
            .slideY(begin: 0.2, end: 0, delay: 200.ms, duration: 400.ms),

        const SizedBox(height: 6),

        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          decoration: BoxDecoration(
            color: _lime.withOpacity(0.12),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: _lime.withOpacity(0.4)),
          ),
          child: Text('Nike Athlete',
              style: GoogleFonts.nunito(
                  fontSize: 12, color: _lime,
                  fontWeight: FontWeight.w700)),
        )
            .animate()
            .fadeIn(delay: 300.ms, duration: 400.ms),

        const SizedBox(height: 6),

        Text(email, style: GoogleFonts.nunito(fontSize: 13, color: c.sub))
            .animate()
            .fadeIn(delay: 350.ms, duration: 400.ms),
      ],
    );
  }

  // ── NikeCoins section ──────────────────────────────────────────────────────

  Widget _buildCoinsSection(int coins, NikeColors c) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.stars_rounded, color: _lime, size: 28),
            const SizedBox(width: 8),
            Text('$coins',
                style: GoogleFonts.bebasNeue(
                    fontSize: 64, color: _lime, letterSpacing: 1.5)),
          ],
        )
            .animate()
            .fadeIn(delay: 400.ms, duration: 400.ms)
            .slideY(begin: 0.15, end: 0, delay: 400.ms, duration: 400.ms,
                curve: Curves.easeOutCubic),

        const SizedBox(height: 4),

        Text('NIKECOINS EARNED',
            style: GoogleFonts.nunito(
                fontSize: 12, color: c.sub,
                letterSpacing: 1.5, fontWeight: FontWeight.w600))
            .animate()
            .fadeIn(delay: 480.ms, duration: 350.ms),
      ],
    );
  }

  // ── Tier card ──────────────────────────────────────────────────────────────

  Widget _buildTierCard(int coins, NikeColors c) {
    final currentTier = _tiers.lastWhere(
        (t) => t.threshold <= coins, orElse: () => _tiers.first);
    final nextIdx  = _tiers.indexOf(currentTier) + 1;
    final nextTier = nextIdx < _tiers.length ? _tiers[nextIdx] : null;
    final coinsToNext = nextTier != null ? nextTier.threshold - coins : 0;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: c.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: c.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('CURRENT TIER',
                      style: GoogleFonts.nunito(
                          fontSize: 11, color: c.sub,
                          letterSpacing: 1, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 4),
                  Row(children: [
                    Icon(currentTier.icon, color: _lime, size: 18),
                    const SizedBox(width: 6),
                    Text(currentTier.label,
                        style: GoogleFonts.bebasNeue(
                            fontSize: 22, color: _lime, letterSpacing: 1.5)),
                  ]),
                ],
              ),
              if (nextTier != null)
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text('NEXT TIER',
                        style: GoogleFonts.nunito(
                            fontSize: 11, color: c.sub,
                            letterSpacing: 1, fontWeight: FontWeight.w600)),
                    const SizedBox(height: 4),
                    Row(children: [
                      Text(nextTier.label,
                          style: GoogleFonts.bebasNeue(
                              fontSize: 18, color: c.sub, letterSpacing: 1.5)),
                      const SizedBox(width: 4),
                      Icon(nextTier.icon, color: c.sub, size: 16),
                    ]),
                  ],
                )
              else
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: _lime.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: _lime.withOpacity(0.5)),
                  ),
                  child: Text('UNLOCKED',
                      style: GoogleFonts.nunito(
                          fontSize: 11, color: _lime,
                          fontWeight: FontWeight.w800, letterSpacing: 0.5)),
                ),
            ],
          ),

          const SizedBox(height: 20),

          _buildProgressBar(coins, c),

          const SizedBox(height: 14),

          if (nextTier != null)
            Text(
              '$coinsToNext coins to ${nextTier.label}',
              style: GoogleFonts.nunito(
                  fontSize: 13, color: c.sub,
                  fontWeight: FontWeight.w600),
            )
          else
            Text(
              'FREE REWARD UNLOCKED — CLAIM BELOW',
              style: GoogleFonts.nunito(
                  fontSize: 13, color: _lime,
                  fontWeight: FontWeight.w800, letterSpacing: 0.3),
            ),
        ],
      ),
    )
        .animate()
        .fadeIn(delay: 540.ms, duration: 400.ms)
        .slideY(begin: 0.1, end: 0, delay: 540.ms, duration: 400.ms,
            curve: Curves.easeOutCubic);
  }

  Widget _buildProgressBar(int coins, NikeColors c) {
    final progress = (coins / _kEliteThreshold).clamp(0.0, 1.0);

    return LayoutBuilder(
      builder: (context, constraints) {
        final barW  = constraints.maxWidth;
        final fillW = (barW * progress).clamp(0.0, barW);

        return SizedBox(
          height: 48,
          child: Stack(
            clipBehavior: Clip.none,
            children: [

              // ── Track ────────────────────────────────────────────────────
              Positioned(
                top: 38, left: 0, right: 0,
                child: Container(
                  height: 6,
                  decoration: BoxDecoration(
                    color: c.border,
                    borderRadius: BorderRadius.circular(3),
                  ),
                ),
              ),

              // ── Lime fill ────────────────────────────────────────────────
              Positioned(
                top: 38, left: 0,
                width: fillW,
                child: Container(
                  height: 6,
                  decoration: BoxDecoration(
                    color: _lime,
                    borderRadius: BorderRadius.circular(3),
                    boxShadow: progress > 0
                        ? [BoxShadow(
                            color: _lime.withOpacity(0.5),
                            blurRadius: 8, spreadRadius: 1)]
                        : [],
                  ),
                ),
              ),

              // ── Milestone badges ─────────────────────────────────────────
              ..._tiers.map((tier) {
                final xFrac  = tier.threshold == 0
                    ? 0.0
                    : tier.threshold / _kEliteThreshold;
                final x      = barW * xFrac;
                final reached = coins >= tier.threshold;
                final left   = (x - 14).clamp(0.0, barW - 28);
                final lineX  = (x - 0.5).clamp(0.0, barW - 1);

                final connector = Positioned(
                  top: 28, left: lineX,
                  child: Container(
                    width: 1,
                    height: 10,
                    color: reached ? _lime.withOpacity(0.6) : c.border,
                  ),
                );

                Widget badge = GestureDetector(
                  onTap: () {
                    HapticFeedback.lightImpact();
                    setState(() => _demoCoins = tier.threshold);
                  },
                  child: _MilestoneBadge(tier: tier, reached: reached),
                );

                if (reached && tier.threshold > 0) {
                  final tierIdx = _tiers.indexOf(tier);
                  badge = badge
                      .animate(delay: (500 + tierIdx * 150).ms)
                      .shake(
                        hz: 4,
                        offset: const Offset(0.05, 0),
                        duration: 550.ms,
                        curve: Curves.easeInOut,
                      );
                }

                return <Widget>[
                  connector,
                  Positioned(top: 0, left: left, child: badge),
                ];
              }).expand((pair) => pair),
            ],
          ),
        );
      },
    );
  }

  // ── Free product card ──────────────────────────────────────────────────────

  Widget _buildFreeProductCard(NikeColors c) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: _lime.withOpacity(0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _lime.withOpacity(0.45), width: 1.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [

          Row(children: [
            const Icon(Icons.card_giftcard_outlined, color: _lime, size: 20),
            const SizedBox(width: 8),
            Text('YOUR FREE REWARD',
                style: GoogleFonts.bebasNeue(
                    fontSize: 18, color: _lime, letterSpacing: 1.5)),
          ]),
          const SizedBox(height: 4),
          Text('You hit ELITE. Choose one Nike product on us.',
              style: GoogleFonts.nunito(fontSize: 13, color: c.sub)),

          const SizedBox(height: 16),

          Row(
            children: _freeProducts.asMap().entries.map((e) {
              final idx      = e.key;
              final product  = e.value;
              final selected = _selectedProduct == idx;

              return Expanded(
                child: GestureDetector(
                  onTap: () {
                    HapticFeedback.lightImpact();
                    setState(() => _selectedProduct = idx);
                  },
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    margin: EdgeInsets.only(right: idx == 0 ? 8 : 0),
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: selected ? _lime.withOpacity(0.14) : c.card,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: selected ? _lime : c.border,
                        width: selected ? 1.5 : 1,
                      ),
                    ),
                    child: Column(
                      children: [
                        Icon(product.icon,
                            color: selected ? _lime : c.sub, size: 30),
                        const SizedBox(height: 8),
                        Text(product.name,
                            style: GoogleFonts.nunito(
                                fontSize: 12,
                                color: selected ? c.text : c.sub,
                                fontWeight: FontWeight.w700),
                            textAlign: TextAlign.center,
                            maxLines: 2),
                        const SizedBox(height: 2),
                        Text(product.sub,
                            style: GoogleFonts.nunito(
                                fontSize: 11,
                                color: selected ? _lime : c.sub,
                                letterSpacing: 0.3),
                            textAlign: TextAlign.center),
                      ],
                    ),
                  ),
                ),
              );
            }).toList(),
          ),

          const SizedBox(height: 16),

          SizedBox(
            width: double.infinity,
            child: GestureDetector(
              onTap: _selectedProduct == null || _claiming
                  ? null
                  : () => _showClaimDialog(_selectedProduct!),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(vertical: 16),
                decoration: BoxDecoration(
                  color: _selectedProduct != null
                      ? _lime
                      : _lime.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(50),
                  boxShadow: _selectedProduct != null
                      ? [BoxShadow(
                          color: _lime.withOpacity(0.3),
                          blurRadius: 16, offset: const Offset(0, 4))]
                      : [],
                ),
                child: _claiming
                    ? const Center(
                        child: SizedBox(
                          width: 20, height: 20,
                          child: CircularProgressIndicator(
                              color: _black, strokeWidth: 2),
                        ),
                      )
                    : Text(
                        _selectedProduct != null
                            ? 'CLAIM REWARD'
                            : 'SELECT A REWARD',
                        style: GoogleFonts.bebasNeue(
                            fontSize: 18, color: _black, letterSpacing: 1.5),
                        textAlign: TextAlign.center,
                      ),
              ),
            ),
          ),
        ],
      ),
    )
        .animate()
        .fadeIn(delay: 100.ms, duration: 400.ms)
        .slideY(begin: 0.08, end: 0, delay: 100.ms, duration: 400.ms,
            curve: Curves.easeOutCubic);
  }

  // ── Personal impact card ───────────────────────────────────────────────────

  Widget _buildImpactCard(double co2, int km, int returnCount, NikeColors c) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: c.card,
        borderRadius: BorderRadius.circular(16),
        border: Border(
          left:   const BorderSide(color: _lime, width: 3),
          top:    BorderSide(color: c.border),
          right:  BorderSide(color: c.border),
          bottom: BorderSide(color: c.border),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            const Icon(Icons.eco_outlined, color: _lime, size: 18),
            const SizedBox(width: 8),
            Text('PERSONAL IMPACT',
                style: GoogleFonts.bebasNeue(
                    fontSize: 18, color: c.text, letterSpacing: 1.5)),
          ]),
          const SizedBox(height: 16),
          _impactRow('CO₂ Saved',      '${co2.toStringAsFixed(1)} kg', _lime,  c),
          const SizedBox(height: 10),
          _impactRow('Equivalent To',  'Not driving ~$km km',           null,   c),
          const SizedBox(height: 10),
          _impactRow('Shoes Returned', '$returnCount pairs',             null,   c),
        ],
      ),
    )
        .animate()
        .fadeIn(delay: 620.ms, duration: 400.ms)
        .slideY(begin: 0.1, end: 0, delay: 620.ms, duration: 400.ms,
            curve: Curves.easeOutCubic);
  }

  Widget _impactRow(String label, String value, Color? valueColor, NikeColors c) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: GoogleFonts.nunito(fontSize: 14, color: c.sub)),
        Text(value,
            style: GoogleFonts.nunito(
                fontSize: 14,
                color: valueColor ?? c.text,
                fontWeight: FontWeight.w700)),
      ],
    );
  }

  // ── Achievement badges ─────────────────────────────────────────────────────

  Widget _buildBadgesSection(int returnCount, int totalShoes, NikeColors c) {
    final allReturned = totalShoes > 0 && returnCount >= totalShoes;
    final badges = [
      _Badge('FIRST LOOP',    Icons.loop,                     returnCount >= 1),
      _Badge('ECO WARRIOR',   Icons.eco_outlined,             returnCount >= 3),
      _Badge('LOOP LEGEND',   Icons.workspace_premium_outlined, returnCount >= 5),
      _Badge('NIKE CHAMPION', Icons.emoji_events_outlined,    allReturned),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('ACHIEVEMENTS',
            style: GoogleFonts.bebasNeue(
                fontSize: 18, color: c.text, letterSpacing: 1.5))
            .animate()
            .fadeIn(delay: 700.ms, duration: 350.ms),
        const SizedBox(height: 12),
        SizedBox(
          height: 108,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: badges.length,
            separatorBuilder: (_, __) => const SizedBox(width: 12),
            itemBuilder: (_, i) {
              return _BadgeTile(badge: badges[i])
                  .animate()
                  .fadeIn(delay: (720 + i * 80).ms, duration: 350.ms)
                  .scale(
                    begin: const Offset(0.8, 0.8),
                    delay: (720 + i * 80).ms,
                    duration: 400.ms,
                    curve: Curves.elasticOut,
                  );
            },
          ),
        ),
      ],
    );
  }

  // ── Your Locker row ────────────────────────────────────────────────────────

  Widget _buildLockerRow(int shoeCount, NikeColors c) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        Navigator.push(
          context,
          PageRouteBuilder(
            pageBuilder: (_, __, ___) =>
                CustomerLockerScreen(onScanTap: widget.onScanTap),
            transitionsBuilder: (_, anim, __, child) => SlideTransition(
              position: Tween<Offset>(
                  begin: const Offset(1.0, 0.0), end: Offset.zero)
                  .animate(CurvedAnimation(
                      parent: anim, curve: Curves.easeOutCubic)),
              child: child,
            ),
            transitionDuration: const Duration(milliseconds: 350),
          ),
        );
      },
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: c.card,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: c.border),
        ),
        child: Row(
          children: [
            const Icon(Icons.grid_view_outlined, color: _lime, size: 22),
            const SizedBox(width: 14),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('YOUR LOCKER',
                    style: GoogleFonts.bebasNeue(
                        fontSize: 18, color: c.text, letterSpacing: 1.5)),
                Text('$shoeCount kicks registered',
                    style: GoogleFonts.nunito(fontSize: 13, color: c.sub)),
              ],
            ),
            const Spacer(),
            Icon(Icons.chevron_right, color: c.sub, size: 22),
          ],
        ),
      ),
    )
        .animate()
        .fadeIn(delay: 920.ms, duration: 350.ms)
        .slideY(begin: 0.1, end: 0, delay: 920.ms, duration: 350.ms,
            curve: Curves.easeOutCubic);
  }

  // ── Appearance toggle ──────────────────────────────────────────────────────

  Widget _buildThemeToggle(NikeColors c) {
    return ValueListenableBuilder<bool>(
      valueListenable: isDarkMode,
      builder: (_, dark, __) => GestureDetector(
        onTap: () => isDarkMode.value = !isDarkMode.value,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
          decoration: BoxDecoration(
            color: c.card,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: c.border),
          ),
          child: Row(
            children: [
              Icon(
                dark ? Icons.light_mode_outlined : Icons.dark_mode_outlined,
                color: _lime, size: 22,
              ),
              const SizedBox(width: 14),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('APPEARANCE',
                      style: GoogleFonts.nunito(
                          fontSize: 11, color: c.sub,
                          letterSpacing: 1, fontWeight: FontWeight.w600)),
                  Text(dark ? 'Dark Mode' : 'Light Mode',
                      style: GoogleFonts.nunito(
                          fontSize: 14, color: c.text,
                          fontWeight: FontWeight.w700)),
                ],
              ),
              const Spacer(),
              Container(
                width: 48, height: 26,
                decoration: BoxDecoration(
                  color: dark ? _lime.withOpacity(0.2) : _lime,
                  borderRadius: BorderRadius.circular(13),
                  border: Border.all(color: _lime.withOpacity(0.6)),
                ),
                child: AnimatedAlign(
                  duration: const Duration(milliseconds: 200),
                  curve: Curves.easeOutCubic,
                  alignment: dark ? Alignment.centerLeft : Alignment.centerRight,
                  child: Container(
                    width: 20, height: 20,
                    margin: const EdgeInsets.symmetric(horizontal: 3),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: dark ? c.sub : _black,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    )
        .animate()
        .fadeIn(delay: 960.ms, duration: 350.ms);
  }

  // ── Sign out ───────────────────────────────────────────────────────────────

  Widget _buildSignOut(NikeColors c) {
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton(
        onPressed: () {
          HapticFeedback.lightImpact();
          FirebaseAuth.instance.signOut();
        },
        style: OutlinedButton.styleFrom(
          side: BorderSide(color: c.border),
          padding: const EdgeInsets.symmetric(vertical: 14),
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12)),
        ),
        child: Text('Sign Out',
            style: GoogleFonts.nunito(
                fontSize: 15, color: c.sub,
                fontWeight: FontWeight.w700)),
      ),
    )
        .animate()
        .fadeIn(delay: 1000.ms, duration: 350.ms);
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Milestone badge — small circle on the progress bar
// ─────────────────────────────────────────────────────────────────────────────
class _MilestoneBadge extends StatelessWidget {
  final _Tier tier;
  final bool  reached;
  const _MilestoneBadge({required this.tier, required this.reached});

  @override
  Widget build(BuildContext context) {
    final c = context.nc;
    return Container(
      width: 28, height: 28,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: reached ? _lime.withOpacity(0.18) : c.card,
        border: Border.all(
          color: reached ? _lime : c.border,
          width: reached ? 1.5 : 1,
        ),
        boxShadow: reached
            ? [BoxShadow(
                color: _lime.withOpacity(0.4),
                blurRadius: 10, spreadRadius: 1)]
            : [],
      ),
      child: Center(
        child: Icon(tier.icon,
            size: 14, color: reached ? _lime : c.sub),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Achievement badge tile
// ─────────────────────────────────────────────────────────────────────────────
class _BadgeTile extends StatelessWidget {
  final _Badge badge;
  const _BadgeTile({required this.badge});

  @override
  Widget build(BuildContext context) {
    final c = context.nc;
    return Container(
      width: 88,
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
      decoration: BoxDecoration(
        color: c.card,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: badge.unlocked ? _lime : c.border,
          width: badge.unlocked ? 1.5 : 1,
        ),
        boxShadow: badge.unlocked
            ? [BoxShadow(
                color: _lime.withOpacity(0.18),
                blurRadius: 14, spreadRadius: 0)]
            : [],
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(badge.icon,
                  color: badge.unlocked ? _lime : c.sub, size: 28),
              const SizedBox(height: 6),
              Text(
                badge.label,
                style: GoogleFonts.nunito(
                    fontSize: 10,
                    color: badge.unlocked ? c.text : c.sub,
                    fontWeight: FontWeight.w700),
                textAlign: TextAlign.center,
                maxLines: 2,
              ),
            ],
          ),
          if (!badge.unlocked)
            Positioned(
              top: 0, right: 0,
              child: Icon(Icons.lock_outline, color: c.sub, size: 13),
            ),
        ],
      ),
    );
  }
}
