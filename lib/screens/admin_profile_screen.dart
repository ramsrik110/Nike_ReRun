import 'dart:async';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../nike_colors.dart';
import '../services/chatbot_service.dart';
import '../widgets/nav_controls.dart';
import '../widgets/shoe_icon.dart';

const _lime  = Color(0xFFCDFC49);
const _black = Color(0xFF111111);

class AdminProfileScreen extends StatefulWidget {
  final VoidCallback? onHomeTap;
  const AdminProfileScreen({super.key, this.onHomeTap});

  @override
  State<AdminProfileScreen> createState() => _AdminProfileScreenState();
}

class _AdminProfileScreenState extends State<AdminProfileScreen> {
  int? _userCount;
  int? _shoeCount;
  int? _closedLoopCount;
  int? _resoldCount;

  StreamSubscription? _usersSub;
  StreamSubscription? _shoesSub;
  StreamSubscription? _closedSub;
  StreamSubscription? _resoldSub;

  final _scaffoldKey = GlobalKey<ScaffoldState>();

  // Same convention as CustomerLockerScreen / DashboardScreen: no width
  // cap, no centered "tab" — content stays edge-to-edge and scales up on
  // wide viewports (laptop/projector) so it fills the space.
  double get _scale {
    final w = MediaQuery.sizeOf(context).width;
    if (w >= 1000) return 1.4;
    if (w >= 600) return 1.15;
    return 1.0;
  }

  bool get _wide => MediaQuery.sizeOf(context).width >= 700;

  @override
  void initState() {
    super.initState();
    _listenStats();
  }

  @override
  void dispose() {
    _usersSub?.cancel();
    _shoesSub?.cancel();
    _closedSub?.cancel();
    _resoldSub?.cancel();
    super.dispose();
  }

  // Live streams instead of one-time fetches — a shoe an inspector routes
  // elsewhere now updates this screen the moment it happens, same as the
  // Dashboard, rather than only refreshing when the screen re-mounts.
  //
  // "Loop closed" reads LCS-STS == 'ROUTED.' — a shoe's status is
  // 'LOOP CLOSED.' only while it's returned and sitting in the hub queue
  // awaiting inspection (see HUB-STS on InspectorProfileScreen); once an
  // inspector actually processes it, LCS-STS flips to 'ROUTED.' — that's
  // the real "this loop is finished" state, so that's what this stat
  // should count, not the queued/pending status.
  void _listenStats() {
    _usersSub = FirebaseFirestore.instance
        .collection('users')
        .snapshots()
        .listen((snap) {
      if (mounted) setState(() => _userCount = snap.docs.length);
    });
    _shoesSub = FirebaseFirestore.instance
        .collection('Shoes')
        .snapshots()
        .listen((snap) {
      if (mounted) setState(() => _shoeCount = snap.docs.length);
    });
    _closedSub = FirebaseFirestore.instance
        .collection('Shoes')
        .where('LCS-STS', isEqualTo: 'ROUTED.')
        .snapshots()
        .listen((snap) {
      if (mounted) setState(() => _closedLoopCount = snap.docs.length);
    });
    _resoldSub = FirebaseFirestore.instance
        .collection('Shoes')
        .where('RTE-DCN', whereIn: ['To resale.', 'To cleaning.'])
        .snapshots()
        .listen((snap) {
      if (mounted) setState(() => _resoldCount = snap.docs.length);
    });
  }

  @override
  Widget build(BuildContext context) {
    final c        = context.nc;
    final user     = FirebaseAuth.instance.currentUser;
    final name     = user?.displayName ?? user?.email?.split('@').first ?? 'Admin';
    final email    = user?.email ?? '';
    final initials = name.trim().isNotEmpty ? name.trim()[0].toUpperCase() : 'A';
    final s        = _scale;
    final statColumns     = _wide ? 4 : 2;
    final statAspectRatio = _wide ? 1.6 : 2.1;

    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: c.bg,
      endDrawer: NavDrawer(
        c: c,
        chatPersona: ChatPersona.admin,
        onSignOut: () => FirebaseAuth.instance.signOut(),
        items: [
          NavDrawerItem(icon: Icons.dashboard, label: 'Dashboard',
              onTap: () { Navigator.of(context).pop(); widget.onHomeTap?.call(); }),
          NavDrawerItem(icon: Icons.person, label: 'Profile', selected: true,
              onTap: () => Navigator.of(context).pop()),
        ],
      ),
      body: Stack(
        children: [
          SafeArea(
            child: SingleChildScrollView(
              child: Padding(
                padding: EdgeInsets.fromLTRB(20 * s, 60 * s, 20 * s, 32 * s),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [

                    // ── Identity header — left-aligned, settings-page style ──
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: 56 * s,
                          height: 56 * s,
                          decoration: const BoxDecoration(
                            shape: BoxShape.circle,
                            color: _lime,
                          ),
                          child: Center(
                            child: Text(initials,
                                style: GoogleFonts.bebasNeue(
                                    fontSize: 24 * s, color: _black, letterSpacing: 1)),
                          ),
                        ).animate().scale(
                              begin: const Offset(0.6, 0.6),
                              duration: 400.ms,
                              curve: Curves.elasticOut,
                            ),
                        SizedBox(width: 14 * s),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(name.toUpperCase(),
                                  style: GoogleFonts.bebasNeue(
                                      fontSize: 22 * s, color: c.text, letterSpacing: 1))
                                  .animate()
                                  .fadeIn(delay: 150.ms, duration: 350.ms),
                              SizedBox(height: 6 * s),
                              Container(
                                padding: EdgeInsets.symmetric(
                                    horizontal: 10 * s, vertical: 3 * s),
                                decoration: BoxDecoration(
                                  color: _lime.withValues(alpha: 0.12),
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(color: _lime.withValues(alpha: 0.4)),
                                ),
                                child: Text('NIKE ADMIN',
                                    style: GoogleFonts.nunito(
                                        fontSize: 10 * s, color: _lime,
                                        fontWeight: FontWeight.w800,
                                        letterSpacing: 0.5)),
                              ).animate().fadeIn(delay: 220.ms, duration: 350.ms),
                              SizedBox(height: 6 * s),
                              Text(email,
                                  style: GoogleFonts.nunito(fontSize: 12 * s, color: c.sub))
                                  .animate()
                                  .fadeIn(delay: 260.ms, duration: 350.ms),
                            ],
                          ),
                        ),
                      ],
                    ),

                    SizedBox(height: 32 * s),

                    Text('PLATFORM STATS',
                        style: GoogleFonts.nunito(
                            fontSize: 10 * s, color: c.sub,
                            fontWeight: FontWeight.w700, letterSpacing: 0.8))
                        .animate()
                        .fadeIn(delay: 320.ms, duration: 300.ms),
                    SizedBox(height: 10 * s),

                    GridView.count(
                      crossAxisCount: statColumns,
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      crossAxisSpacing: 10 * s,
                      mainAxisSpacing: 10 * s,
                      childAspectRatio: statAspectRatio,
                      children: [
                        _StatTile(icon: Icons.people_outline,
                            label: 'Total users', value: _userCount, delay: 380, scale: s),
                        _StatTile(iconWidget: ShoeIcon(color: _lime, size: 16 * s),
                            label: 'Shoes tracked', value: _shoeCount, delay: 430, scale: s),
                        _StatTile(icon: Icons.all_inclusive,
                            label: 'Loops closed', value: _closedLoopCount, delay: 480, scale: s),
                        _StatTile(icon: Icons.recycling_outlined,
                            label: 'Shoes resold', value: _resoldCount, delay: 530, scale: s),
                      ],
                    ),

                    SizedBox(height: 28 * s),

                    Text('ACCOUNT',
                        style: GoogleFonts.nunito(
                            fontSize: 10 * s, color: c.sub,
                            fontWeight: FontWeight.w700, letterSpacing: 0.8))
                        .animate()
                        .fadeIn(delay: 580.ms, duration: 300.ms),
                    SizedBox(height: 10 * s),

                    Container(
                      decoration: BoxDecoration(
                        color: c.card,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: c.border),
                      ),
                      child: Column(
                        children: [
                          _AccountRow(
                            icon: Icons.shield_outlined,
                            label: 'Role',
                            trailing: 'Nike Admin',
                            c: c,
                            showBottomBorder: true,
                            scale: s,
                          ),
                          _AccountRow(
                            icon: Icons.logout,
                            label: 'Sign out',
                            labelColor: const Color(0xFFE24B4A),
                            iconColor: const Color(0xFFE24B4A),
                            onTap: () => FirebaseAuth.instance.signOut(),
                            c: c,
                            showBottomBorder: false,
                            scale: s,
                          ),
                        ],
                      ),
                    ).animate().fadeIn(delay: 620.ms, duration: 350.ms)
                        .slideY(begin: 0.08, end: 0, duration: 350.ms),
                  ],
                ),
              ),
            ),
          ),
          SafeArea(child: _buildHeaderBar(c)),
        ],
      ),
    );
  }

  Widget _buildHeaderBar(NikeColors c) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 14, 20, 0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          CircleIconButton(icon: Icons.arrow_back, c: c, onTap: widget.onHomeTap),
          CircleIconButton(
            icon: Icons.menu_rounded,
            c: c,
            onTap: () => _scaffoldKey.currentState?.openEndDrawer(),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Stat tile — same visual language as the Dashboard's metric tiles.
// ─────────────────────────────────────────────────────────────────────────────

class _StatTile extends StatelessWidget {
  final IconData? icon;
  final Widget? iconWidget;
  final String label;
  final int? value;
  final int delay;
  final double scale;

  const _StatTile({
    this.icon,
    this.iconWidget,
    required this.label,
    required this.value,
    required this.delay,
    required this.scale,
  });

  @override
  Widget build(BuildContext context) {
    final c = context.nc;
    final s = scale;
    return Container(
      padding: EdgeInsets.all(12 * s),
      decoration: BoxDecoration(
        color: c.card,
        borderRadius: BorderRadius.circular(14),
        border: const Border(left: BorderSide(color: _lime, width: 3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          iconWidget ?? Icon(icon, color: _lime, size: 16 * s),
          SizedBox(height: 6 * s),
          Text(value == null ? '—' : '$value',
              style: GoogleFonts.bebasNeue(fontSize: 24 * s, color: c.text)),
          Text(label, style: GoogleFonts.nunito(fontSize: 10 * s, color: c.sub)),
        ],
      ),
    )
        .animate()
        .fadeIn(delay: Duration(milliseconds: delay), duration: 300.ms)
        .slideY(begin: 0.08, end: 0, duration: 300.ms);
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Account settings row.
// ─────────────────────────────────────────────────────────────────────────────

class _AccountRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String? trailing;
  final Color? labelColor;
  final Color? iconColor;
  final VoidCallback? onTap;
  final NikeColors c;
  final bool showBottomBorder;
  final double scale;

  const _AccountRow({
    required this.icon,
    required this.label,
    required this.c,
    required this.showBottomBorder,
    required this.scale,
    this.trailing,
    this.labelColor,
    this.iconColor,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final s = scale;
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 16 * s, vertical: 14 * s),
        decoration: BoxDecoration(
          border: showBottomBorder
              ? Border(bottom: BorderSide(color: c.border))
              : null,
        ),
        child: Row(
          children: [
            Icon(icon, size: 16 * s, color: iconColor ?? c.sub),
            SizedBox(width: 12 * s),
            Expanded(
              child: Text(label,
                  style: GoogleFonts.nunito(
                      fontSize: 13 * s,
                      color: labelColor ?? c.text,
                      fontWeight: labelColor != null ? FontWeight.w700 : FontWeight.w400)),
            ),
            if (trailing != null)
              Text(trailing!, style: GoogleFonts.nunito(fontSize: 12 * s, color: c.sub)),
            if (onTap != null)
              Icon(Icons.chevron_right, size: 16 * s, color: c.sub),
          ],
        ),
      ),
    );
  }
}
