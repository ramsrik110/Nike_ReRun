import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../nike_colors.dart';
import '../theme_notifier.dart';
import '../services/chatbot_service.dart';
import '../widgets/nav_controls.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Inspector's permanent record — everything here is lifetime, never resets
// (unlike the nav drawer's "This Shift" numbers, which zero out on sign
// out). Personal activity (routed count, avg time, outcome breakdown) comes
// from this inspector's own INS-* fields; Hub Queue stays facility-wide
// since it's a shared queue, not personal.
// ─────────────────────────────────────────────────────────────────────────────

const _outcomeOrder = [
  'To resale.',
  'To cleaning.',
  'To fabric rework.',
  'To sole rework.',
  'To full recycle.',
];

class InspectorProfileScreen extends StatefulWidget {
  final VoidCallback? onHomeTap;
  const InspectorProfileScreen({super.key, this.onHomeTap});

  @override
  State<InspectorProfileScreen> createState() => _InspectorProfileScreenState();
}

class _InspectorProfileScreenState extends State<InspectorProfileScreen> {
  int?    _lifetimeScanned;
  double? _lifetimeSeconds;
  Map<String, int>? _outcomeCounts;
  int?    _pendingCount;
  String? _hubName;

  final _scaffoldKey = GlobalKey<ScaffoldState>();

  bool get _isDark => inspectorDarkMode.value;
  NikeColors get _c => _isDark ? NikeColors.inspectorDark : NikeColors.inspectorLight;

  @override
  void initState() {
    super.initState();
    _loadStats();
    inspectorDarkMode.addListener(_onThemeChanged);
  }

  void _onThemeChanged() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    inspectorDarkMode.removeListener(_onThemeChanged);
    super.dispose();
  }

  Future<void> _loadStats() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;

    final pending = await FirebaseFirestore.instance
        .collection('Shoes')
        .where('LCS-STS', isEqualTo: 'LOOP CLOSED.')
        .get();

    Map<String, dynamic>? userData;
    if (uid != null) {
      final userDoc =
          await FirebaseFirestore.instance.collection('users').doc(uid).get();
      userData = userDoc.data();
    }

    final hubDoc =
        await FirebaseFirestore.instance.collection('hubs').doc('HUB-001').get();

    if (mounted) {
      setState(() {
        _pendingCount    = pending.docs.length;
        _lifetimeScanned = (userData?['INS-SCN'] as num?)?.toInt() ?? 0;
        _lifetimeSeconds = (userData?['INS-TTM'] as num?)?.toDouble() ?? 0;
        _outcomeCounts = {
          'To resale.':        (userData?['INS-OUT-RSL'] as num?)?.toInt() ?? 0,
          'To cleaning.':      (userData?['INS-OUT-CLN'] as num?)?.toInt() ?? 0,
          'To fabric rework.': (userData?['INS-OUT-FAB'] as num?)?.toInt() ?? 0,
          'To sole rework.':   (userData?['INS-OUT-SOL'] as num?)?.toInt() ?? 0,
          'To full recycle.':  (userData?['INS-OUT-RCY'] as num?)?.toInt() ?? 0,
        };
        _hubName = hubDoc.data()?['HUB-NM'] as String? ?? 'Hub';
      });
    }
  }

  Future<void> _punchOut() async {
    await resetInspectorShiftStats();
    await FirebaseAuth.instance.signOut();
    // Pop back to _AuthGate (the first route) instead of pushing a new
    // LoginScreen — pushAndRemoveUntil(..., (route) => false) would evict
    // _AuthGate itself, permanently breaking reactive auth routing for the
    // rest of the session.
    if (mounted) {
      Navigator.of(context).popUntil((route) => route.isFirst);
    }
  }

  String _sinceLabel(DateTime? d) {
    if (d == null) return '—';
    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
                     'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return '${months[d.month - 1]} ${d.year}';
  }

  @override
  Widget build(BuildContext context) {
    final c        = _c;
    final user     = FirebaseAuth.instance.currentUser;
    final name     = user?.displayName ?? user?.email?.split('@').first ?? 'Inspector';
    final scanned  = _lifetimeScanned ?? 0;
    final avg = (_lifetimeScanned != null && _lifetimeScanned! > 0)
        ? _lifetimeSeconds! / _lifetimeScanned!
        : 0.0;

    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: c.bg,
      endDrawer: NavDrawer(
        c: c,
        chatPersona: ChatPersona.inspector,
        onSignOut: _punchOut,
        signOutLabel: 'Punch Out',
        themeNotifier: inspectorDarkMode,
        extra: InspectorStatsRow(c: c),
        items: [
          NavDrawerItem(icon: Icons.qr_code_scanner, label: 'Inspect',
              onTap: () { Navigator.of(context).pop(); widget.onHomeTap?.call(); }),
          NavDrawerItem(icon: Icons.person, label: 'Profile', selected: true,
              onTap: () => Navigator.of(context).pop()),
        ],
      ),
      body: Stack(
        children: [
          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(24, 64, 24, 32),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [

                  // ── Identity ─────────────────────────────────────────────
                  Text(name,
                      style: GoogleFonts.bebasNeue(
                          fontSize: 24, color: c.text, letterSpacing: 1))
                      .animate().fadeIn(duration: 300.ms),
                  const SizedBox(height: 4),
                  Text('Hub Inspector · ${_hubName ?? '—'}',
                      style: GoogleFonts.nunito(fontSize: 13, color: c.sub))
                      .animate().fadeIn(delay: 50.ms, duration: 300.ms),

                  const SizedBox(height: 18),
                  Divider(color: c.border, height: 1),
                  const SizedBox(height: 18),

                  // ── Your activity ────────────────────────────────────────
                  _sectionLabel('YOUR ACTIVITY', c)
                      .animate().fadeIn(delay: 100.ms, duration: 300.ms),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(child: _heroTile('$scanned', 'shoes routed', c)),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _heroTile(
                          scanned > 0 ? '${avg.toStringAsFixed(1)}s' : '—',
                          'avg time / shoe',
                          c,
                          emphasized: false,
                        ),
                      ),
                    ],
                  ).animate().fadeIn(delay: 150.ms, duration: 300.ms)
                      .slideY(begin: 0.1, end: 0, delay: 150.ms, duration: 300.ms),

                  const SizedBox(height: 20),
                  _sectionLabel('BREAKDOWN', c)
                      .animate().fadeIn(delay: 200.ms, duration: 300.ms),
                  const SizedBox(height: 8),
                  ..._outcomeOrderedRows(c),

                  const SizedBox(height: 18),
                  Divider(color: c.border, height: 1),
                  const SizedBox(height: 18),

                  // ── Hub context ──────────────────────────────────────────
                  _sectionLabel('HUB', c)
                      .animate().fadeIn(delay: 400.ms, duration: 300.ms),
                  const SizedBox(height: 8),
                  _infoRow('Hub queue', _pendingCount == null ? '—' : '${_pendingCount!} awaiting', c),
                  _infoRow('Assigned hub', _hubName ?? '—', c),
                  _infoRow('Inspector since', _sinceLabel(user?.metadata.creationTime), c),

                  const SizedBox(height: 28),

                  SizedBox(
                    width: double.infinity,
                    child: GestureDetector(
                      onTap: _punchOut,
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: c.border),
                        ),
                        child: Text(
                          'Punch Out',
                          style: GoogleFonts.nunito(
                              fontSize: 15, color: c.sub,
                              fontWeight: FontWeight.w700),
                        ),
                      ),
                    ),
                  ).animate().fadeIn(delay: 500.ms, duration: 300.ms),
                ],
              ),
            ),
          ),
          SafeArea(child: _buildHeaderBar(c)),
        ],
      ),
    );
  }

  Widget _sectionLabel(String text, NikeColors c) {
    return Text(text,
        style: GoogleFonts.bebasNeue(
            fontSize: 13, color: c.sub, letterSpacing: 1.5));
  }

  Widget _heroTile(String value, String label, NikeColors c, {bool emphasized = true}) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 18),
      alignment: Alignment.center,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: emphasized ? c.text : c.border, width: emphasized ? 1.5 : 1),
      ),
      child: Column(
        children: [
          Text(value,
              style: GoogleFonts.bebasNeue(fontSize: 26, color: c.text, letterSpacing: 1)),
          const SizedBox(height: 4),
          Text(label, style: GoogleFonts.nunito(fontSize: 11, color: c.sub)),
        ],
      ),
    );
  }

  List<Widget> _outcomeOrderedRows(NikeColors c) {
    return List.generate(_outcomeOrder.length, (i) {
      final key = _outcomeOrder[i];
      final value = _outcomeCounts?[key];
      return Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: _infoRow(key.replaceAll('.', ''), value == null ? '—' : '$value', c),
      ).animate().fadeIn(delay: Duration(milliseconds: 240 + i * 40), duration: 250.ms);
    });
  }

  Widget _infoRow(String label, String value, NikeColors c) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: GoogleFonts.nunito(fontSize: 13, color: c.sub)),
          Text(value,
              style: GoogleFonts.nunito(
                  fontSize: 13, color: c.text, fontWeight: FontWeight.w700)),
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
