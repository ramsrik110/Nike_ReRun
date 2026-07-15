import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../models/shoe_model.dart';
import '../nike_colors.dart';
import '../services/chatbot_service.dart';
import '../widgets/chatbot_widget.dart';
import '../widgets/nav_controls.dart';
import 'customer_return_confirm_screen.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Constants that never change with theme
// ─────────────────────────────────────────────────────────────────────────────
const _lime  = NikeColors.lime;
const _black = NikeColors.black;
const _danger = Color(0xFFE24B4A);

TextStyle _heading(double size, {Color color = const Color(0xFFFFFFFF)}) =>
    GoogleFonts.bebasNeue(fontSize: size, color: color, letterSpacing: 1.5);
TextStyle _body(double size, {Color color = const Color(0xFFFFFFFF)}) =>
    GoogleFonts.nunito(fontSize: size, color: color);

// ─────────────────────────────────────────────────────────────────────────────
// Screen
// ─────────────────────────────────────────────────────────────────────────────

class CustomerLockerScreen extends StatefulWidget {
  final VoidCallback? onScanTap;
  final ValueChanged<int>? onNavSelect;
  final String? initialSuid;

  const CustomerLockerScreen({
    super.key,
    this.onScanTap,
    this.onNavSelect,
    this.initialSuid,
  });

  @override
  State<CustomerLockerScreen> createState() => _CustomerLockerScreenState();
}

class _CustomerLockerScreenState extends State<CustomerLockerScreen> {
  final _scaffoldKey = GlobalKey<ScaffoldState>();

  List<ShoeModel> _shoes   = [];
  bool            _loading = true;
  int             _page    = 0;

  final _heroCollapsed = ValueNotifier<bool>(false);
  final _pageCtrl = PageController();

  NikeColors get _c => context.nc;

  @override
  void initState() {
    super.initState();
    _load();
    _pageCtrl.addListener(() {
      final p = _pageCtrl.page?.round() ?? 0;
      if (p != _page) {
        setState(() => _page = p);
        _heroCollapsed.value = false;
      }
    });
  }

  @override
  void dispose() {
    _pageCtrl.dispose();
    _heroCollapsed.dispose();
    super.dispose();
  }

  // ── Data ──────────────────────────────────────────────────────────────────

  Future<void> _load() async {
    if (!mounted) return;
    setState(() => _loading = true);

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) { setState(() => _loading = false); return; }

    final userDoc = await FirebaseFirestore.instance
        .collection('users').doc(user.uid).get();
    final data = userDoc.data();

    final seen  = <String>{};
    final shoes = <ShoeModel>[];

    final linkedIds = data?['SUID-LNK'] as List<dynamic>? ?? [];
    for (final id in linkedIds) {
      final suid = id as String;
      if (seen.contains(suid)) continue;
      final doc = await FirebaseFirestore.instance
          .collection('Shoes').doc(suid).get();
      if (doc.exists) { shoes.add(ShoeModel.fromFirestore(doc)); seen.add(suid); }
    }

    final byLink = await FirebaseFirestore.instance
        .collection('Shoes').where('CUID-LNK', isEqualTo: user.uid).get();
    for (final d in byLink.docs) {
      final shoe = ShoeModel.fromFirestore(d);
      if (!seen.contains(shoe.suid)) { shoes.add(shoe); seen.add(shoe.suid); }
    }

    if (mounted) {
      if (shoes.isNotEmpty && _page >= shoes.length) {
        // A shoe was removed from underneath the current page. The
        // PageController must be moved to a valid index *before* the
        // rebuild below hands PageView a shorter itemCount — otherwise
        // the view tries to lay out the now-missing old page and throws
        // a RangeError. A postFrameCallback fires one frame too late to
        // avoid that, so this jump has to happen synchronously here.
        final lastPage = shoes.length - 1;
        if (_pageCtrl.hasClients) _pageCtrl.jumpToPage(lastPage);
        setState(() { _shoes = shoes; _loading = false; _page = lastPage; });
      } else {
        setState(() { _shoes = shoes; _loading = false; });
        if (widget.initialSuid != null) {
          final index = shoes.indexWhere((s) => s.suid == widget.initialSuid);
          if (index > 0) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (_pageCtrl.hasClients) _pageCtrl.jumpToPage(index);
            });
          }
        }
      }
    }
  }

  Future<void> _confirmDelete(ShoeModel shoe) async {
    HapticFeedback.mediumImpact();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: _c.card,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: _c.border),
        ),
        title: Text('DELETE SHOE?', style: _heading(20, color: _c.text)),
        content: Text(
          'This removes "${shoe.snm}" from your locker. This can\'t be undone.',
          style: _body(14, color: _c.sub),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: Text('CANCEL',
                style: _body(14, color: _c.text)
                    .copyWith(fontWeight: FontWeight.w700)),
          ),
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: Text('DELETE',
                style: _body(14, color: _danger)
                    .copyWith(fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );

    if (confirmed == true) _deleteShoe(shoe);
  }

  Future<void> _deleteShoe(ShoeModel shoe) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final batch = FirebaseFirestore.instance.batch();
    batch.update(
      FirebaseFirestore.instance.collection('users').doc(user.uid),
      {'SUID-LNK': FieldValue.arrayRemove([shoe.suid])},
    );
    batch.update(
      FirebaseFirestore.instance.collection('Shoes').doc(shoe.suid),
      {'CUID-LNK': ''},
    );
    await batch.commit();

    if (mounted) await _load();
  }

  void _goToConfirm(ShoeModel shoe) {
    HapticFeedback.mediumImpact();
    Navigator.of(context)
        .push(PageRouteBuilder(
          pageBuilder: (_, __, ___) => CustomerReturnConfirmScreen(shoe: shoe),
          transitionsBuilder: (_, anim, __, child) => SlideTransition(
            position: Tween<Offset>(begin: const Offset(0, 1), end: Offset.zero)
                .animate(CurvedAnimation(parent: anim, curve: Curves.easeOutCubic)),
            child: child,
          ),
          transitionDuration: const Duration(milliseconds: 420),
        ))
        .then((_) => _load());
  }

  // ── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return Scaffold(
        backgroundColor: _c.bg,
        body: const Center(child: CircularProgressIndicator(color: _lime)),
      );
    }

    if (_shoes.isEmpty) return _buildEmptyState();

    return PopScope(
      canPop: _page == 0,
      onPopInvoked: (didPop) {
        if (!didPop && _page > 0) {
          _pageCtrl.previousPage(
            duration: const Duration(milliseconds: 380),
            curve: Curves.easeOutCubic,
          );
        }
      },
      child: Scaffold(
        key: _scaffoldKey,
        backgroundColor: _c.bg,
        endDrawer: _buildNavDrawer(),
        body: Stack(
          children: [
            PageView.builder(
              controller: _pageCtrl,
              physics: const PageScrollPhysics(parent: ClampingScrollPhysics()),
              itemCount: _shoes.length,
              itemBuilder: (_, i) => _ShoeScrollPage(
                shoe: _shoes[i],
                onCloseLoop: () => _goToConfirm(_shoes[i]),
                onDelete: () => _confirmDelete(_shoes[i]),
                onCollapseChanged: (collapsed) {
                  if (_pageCtrl.page?.round() == i) {
                    _heroCollapsed.value = collapsed;
                  }
                },
              ),
            ),

            SafeArea(child: _buildTopBar()),

            if (_shoes.length > 1)
              Positioned(
                bottom: 130, left: 0, right: 0,
                child: _buildDots(),
              ),

            Positioned(
              bottom: 110, right: 24,
              child: _buildFab(),
            ),

            const ChatbotWidget(persona: ChatPersona.customer),
          ],
        ),
      ),
    );
  }

  // ── Top bar ────────────────────────────────────────────────────────────────

  Widget _buildTopBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 14, 20, 0),
      child: Row(
        children: [
          CircleIconButton(
            icon: Icons.arrow_back,
            c: _c,
            onTap: () { HapticFeedback.lightImpact(); Navigator.of(context).pop(); },
          ),
          const SizedBox(width: 14),

          Expanded(
            child: ValueListenableBuilder<bool>(
              valueListenable: _heroCollapsed,
              builder: (_, collapsed, __) {
                final label = collapsed && _shoes.isNotEmpty
                    ? _shoes[_page].snm
                    : 'YOUR LOCKER';
                return AnimatedSwitcher(
                  duration: const Duration(milliseconds: 300),
                  switchInCurve: Curves.easeOutCubic,
                  switchOutCurve: Curves.easeInCubic,
                  transitionBuilder: (child, anim) => FadeTransition(
                    opacity: anim,
                    child: SlideTransition(
                      position: Tween<Offset>(
                        begin: const Offset(0, 0.3),
                        end: Offset.zero,
                      ).animate(anim),
                      child: child,
                    ),
                  ),
                  child: Text(
                    label,
                    key: ValueKey(label),
                    style: collapsed
                        ? _heading(16, color: _c.text)
                        : _heading(20, color: _c.text),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                );
              },
            ),
          ),

          CircleIconButton(
            icon: Icons.menu_rounded,
            c: _c,
            onTap: () {
              HapticFeedback.lightImpact();
              _scaffoldKey.currentState?.openEndDrawer();
            },
          ),

        ],
      ),
    );
  }

  // ── Nav drawer ────────────────────────────────────────────────────────────

  Widget _buildNavDrawer() {
    return NavDrawer(
      c: _c,
      chatPersona: ChatPersona.customer,
      onSignOut: () => FirebaseAuth.instance.signOut(),
      items: [
        NavDrawerItem(icon: Icons.home, label: 'Home',
            onTap: () {
              Navigator.of(context).pop();
              Navigator.of(context).popUntil((r) => r.isFirst);
              widget.onNavSelect?.call(0);
            }),
        NavDrawerItem(icon: Icons.qr_code, label: 'Scan',
            onTap: () {
              Navigator.of(context).pop();
              Navigator.of(context).popUntil((r) => r.isFirst);
              widget.onNavSelect?.call(1);
            }),
        NavDrawerItem(icon: Icons.person, label: 'Profile',
            onTap: () {
              Navigator.of(context).pop();
              Navigator.of(context).popUntil((r) => r.isFirst);
              widget.onNavSelect?.call(2);
            }),
      ],
    );
  }

  // ── Page dots ─────────────────────────────────────────────────────────────

  Widget _buildDots() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(_shoes.length, (i) {
        final active = i == _page;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOutCubic,
          margin: const EdgeInsets.symmetric(horizontal: 3),
          width:  active ? 20 : 6,
          height: 6,
          decoration: BoxDecoration(
            color: active ? _lime : _c.sub.withOpacity(0.5),
            borderRadius: BorderRadius.circular(3),
          ),
        );
      }),
    ).animate().fadeIn(delay: 400.ms, duration: 350.ms);
  }

  // ── FAB ───────────────────────────────────────────────────────────────────

  Widget _buildFab() {
    return GestureDetector(
      onTap: () {
        HapticFeedback.mediumImpact();
        widget.onScanTap?.call();
        Navigator.of(context).popUntil((route) => route.isFirst);
      },
      child: Container(
        width: 52, height: 52,
        decoration: BoxDecoration(
          color: _lime,
          borderRadius: BorderRadius.circular(26),
          boxShadow: [
            BoxShadow(
              color: _lime.withOpacity(0.4),
              blurRadius: 16,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: const Icon(Icons.qr_code_scanner, color: _black, size: 24),
      ),
    )
        .animate()
        .fadeIn(delay: 500.ms, duration: 350.ms)
        .scale(
          begin: const Offset(0.7, 0.7),
          end: const Offset(1.0, 1.0),
          delay: 500.ms,
          duration: 400.ms,
          curve: Curves.elasticOut,
        );
  }

  // ── Empty state ───────────────────────────────────────────────────────────

  Widget _buildEmptyState() {
    return Scaffold(
      backgroundColor: _c.bg,
      body: SafeArea(
        child: Stack(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
              child: CircleIconButton(
                icon: Icons.arrow_back,
                c: _c,
                onTap: () => Navigator.of(context).pop(),
              ),
            ),
            Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 40),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      width: 100, height: 100,
                      decoration: BoxDecoration(
                        color: _c.card,
                        borderRadius: BorderRadius.circular(50),
                        border: Border.all(color: _c.border),
                        boxShadow: [
                          BoxShadow(color: _lime.withOpacity(0.12),
                              blurRadius: 40, spreadRadius: 8),
                        ],
                      ),
                      child: const Icon(Icons.directions_run_outlined,
                          color: _lime, size: 48),
                    )
                        .animate()
                        .fadeIn(duration: 500.ms)
                        .scale(begin: const Offset(0.8, 0.8),
                            end: const Offset(1.0, 1.0),
                            duration: 600.ms, curve: Curves.elasticOut),
                    const SizedBox(height: 32),
                    Text('YOUR LOCKER\nIS EMPTY.',
                        style: _heading(36, color: _c.text),
                        textAlign: TextAlign.center)
                        .animate()
                        .fadeIn(delay: 200.ms, duration: 400.ms)
                        .slideY(begin: 0.15, end: 0, delay: 200.ms,
                            duration: 400.ms, curve: Curves.easeOutCubic),
                    const SizedBox(height: 10),
                    Text('Scan your first pair to start the loop.',
                        style: _body(15, color: _c.sub),
                        textAlign: TextAlign.center)
                        .animate().fadeIn(delay: 320.ms, duration: 400.ms),
                    const SizedBox(height: 36),
                    SizedBox(
                      width: double.infinity,
                      child: GestureDetector(
                        onTap: () {
                          HapticFeedback.mediumImpact();
                          widget.onScanTap?.call();
                          Navigator.of(context).popUntil((r) => r.isFirst);
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 18),
                          decoration: BoxDecoration(
                            color: _lime,
                            borderRadius: BorderRadius.circular(50),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.qr_code_scanner,
                                  color: _black, size: 20),
                              const SizedBox(width: 10),
                              Text('SCAN YOUR KICKS',
                                  style: _heading(18, color: _black)),
                            ],
                          ),
                        ),
                      ),
                    )
                        .animate()
                        .fadeIn(delay: 440.ms, duration: 400.ms)
                        .slideY(begin: 0.1, end: 0, delay: 440.ms,
                            duration: 400.ms, curve: Curves.easeOutCubic),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Shoe scroll page
// ─────────────────────────────────────────────────────────────────────────────

class _ShoeScrollPage extends StatefulWidget {
  final ShoeModel          shoe;
  final VoidCallback       onCloseLoop;
  final VoidCallback       onDelete;
  final ValueChanged<bool> onCollapseChanged;

  const _ShoeScrollPage({
    required this.shoe,
    required this.onCloseLoop,
    required this.onDelete,
    required this.onCollapseChanged,
  });

  @override
  State<_ShoeScrollPage> createState() => _ShoeScrollPageState();
}

class _ShoeScrollPageState extends State<_ShoeScrollPage> {
  late final ScrollController _scrollCtrl;
  bool _wasCollapsed = false;

  NikeColors get _c => context.nc;

  @override
  void initState() {
    super.initState();
    _scrollCtrl = ScrollController();
    _scrollCtrl.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollCtrl.removeListener(_onScroll);
    _scrollCtrl.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (!_scrollCtrl.hasClients) return;
    final screenH = MediaQuery.of(context).size.height;
    final collapsed = _scrollCtrl.offset >= screenH * 0.70;
    if (collapsed != _wasCollapsed) {
      _wasCollapsed = collapsed;
      widget.onCollapseChanged(collapsed);
    }
  }

  double get _scrollOffset =>
      _scrollCtrl.hasClients ? _scrollCtrl.offset.clamp(0.0, double.infinity) : 0.0;

  // Scales up padding/icon/font sizes on wide viewports (desktop/projector)
  // so content fills the space instead of looking sparse — the app still
  // renders edge-to-edge, only the content inside grows to match.
  double get _scale {
    final w = MediaQuery.sizeOf(context).width;
    if (w >= 1000) return 1.4;
    if (w >= 600) return 1.15;
    return 1.0;
  }

  @override
  Widget build(BuildContext context) {
    final screenH = MediaQuery.of(context).size.height;
    final s = _scale;

    return SingleChildScrollView(
      controller: _scrollCtrl,
      physics: const ClampingScrollPhysics(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHero(screenH),
          Container(
            color: _c.bg,
            padding: EdgeInsets.fromLTRB(24 * s, 28 * s, 24 * s, 160 * s),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildDetailsSection(),
                SizedBox(height: 36 * s),
                _buildCTA(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── Hero ──────────────────────────────────────────────────────────────────

  Widget _buildHero(double screenH) {
    return SizedBox(
      height: screenH,
      child: Stack(
        fit: StackFit.expand,
        children: [
          Container(color: _c.bg),

          Positioned(
            top: screenH * 0.05, left: 0, right: 0,
            height: screenH * 0.55,
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: RadialGradient(
                  center: Alignment.center,
                  radius: 0.65,
                  colors: [_lime.withOpacity(0.06), Colors.transparent],
                ),
              ),
            ),
          ),

          AnimatedBuilder(
            animation: _scrollCtrl,
            builder: (_, child) {
              final parallax = _scrollOffset * 0.35;
              return Positioned(
                top: 72 - parallax,
                left: 0, right: 0,
                height: screenH * 0.60,
                child: child!,
              );
            },
            child: widget.shoe.snmImg.isNotEmpty
                ? Image.network(
                    widget.shoe.snmImg,
                    fit: BoxFit.contain,
                    loadingBuilder: (_, child, p) => p == null
                        ? child
                        : const Center(
                            child: CircularProgressIndicator(color: _lime)),
                    errorBuilder: (_, __, ___) =>
                        const Icon(Icons.directions_run, color: _lime, size: 80),
                  )
                : const Icon(Icons.directions_run, color: _lime, size: 80),
          ),

          Positioned(
            left: 0, right: 0, bottom: 0,
            height: screenH * 0.42,
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  stops: const [0.0, 0.45, 1.0],
                  colors: [
                    _c.bg.withOpacity(0.0),
                    _c.bg.withOpacity(0.8),
                    _c.bg,
                  ],
                ),
              ),
            ),
          ),

          AnimatedBuilder(
            animation: _scrollCtrl,
            builder: (_, child) {
              final opacity = (1.0 - _scrollOffset / (screenH * 0.4)).clamp(0.0, 1.0);
              return Positioned(
                left: 24, right: 24, bottom: 32,
                child: Opacity(opacity: opacity, child: child),
              );
            },
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                if (widget.shoe.snmHdl.isNotEmpty)
                  Text(widget.shoe.snmHdl,
                      style: _body(11, color: _c.sub).copyWith(letterSpacing: 0.6),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis),
                const SizedBox(height: 4),
                Text(widget.shoe.snm,
                    style: _heading(44, color: _c.text),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis),
                const SizedBox(height: 12),
                Container(width: 40, height: 2, color: _lime),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── Build + Your Loop (two-column on wide screens, stacked on phone) ───────

  Widget _buildDetailsSection() {
    final s = _scale;
    final wide = MediaQuery.sizeOf(context).width >= 700;

    final co2Tile = _impactTile(
        icon: Icons.eco_rounded,
        value: '${widget.shoe.ecoCo2.toStringAsFixed(1)} kg',
        label: 'CO₂ saved');
    final coinsTile = _impactTile(
        icon: Icons.monetization_on_rounded,
        value: '${widget.shoe.rwdAmt}',
        label: 'NikeCoins');
    final infoPanel = _buildInfoPanel();

    final content = wide
        ? IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(
                  child: Column(
                    children: [
                      Expanded(child: co2Tile),
                      SizedBox(height: 12 * s),
                      Expanded(child: coinsTile),
                    ],
                  ),
                ),
                SizedBox(width: 12 * s),
                Expanded(child: infoPanel),
              ],
            ),
          )
        : Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(child: co2Tile),
                  SizedBox(width: 12 * s),
                  Expanded(child: coinsTile),
                ],
              ),
              SizedBox(height: 20 * s),
              infoPanel,
            ],
          );

    return content
        .animate()
        .fadeIn(delay: 100.ms, duration: 400.ms)
        .slideY(begin: 0.08, end: 0, delay: 100.ms, duration: 400.ms,
            curve: Curves.easeOutCubic);
  }

  Widget _impactTile({
    required IconData icon,
    required String value,
    required String label,
  }) {
    final s = _scale;
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(20 * s),
      decoration: BoxDecoration(
        color: _lime.withOpacity(0.07),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _lime.withOpacity(0.25)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: _lime, size: 26 * s),
          SizedBox(height: 10 * s),
          Text(value, style: _heading(32 * s, color: _lime)),
          Text(label,
              style: _body(14 * s, color: _c.sub)
                  .copyWith(fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }

  // A single card listing whatever build/origin facts this shoe actually
  // has, each as its own labeled row separated by a divider. Any field can
  // be missing on a given shoe — only present fields get a row, and if none
  // are present the card shows a neutral placeholder instead of being empty.
  Widget _buildInfoPanel() {
    final s = _scale;

    final mats = <String, double>{};
    if (widget.shoe.mcpFlk > 0) mats['Flyknit'] = widget.shoe.mcpFlk;
    if (widget.shoe.mcpRbr > 0) mats['Rubber']  = widget.shoe.mcpRbr;
    if (widget.shoe.mcpFom > 0) mats['Foam']    = widget.shoe.mcpFom;
    if (widget.shoe.mcpLth > 0) mats['Leather'] = widget.shoe.mcpLth;

    final rows = <Widget>[
      if (mats.isNotEmpty)
        _infoBlock(
          label: 'THE BUILD',
          child: Text(
            mats.entries
                .map((e) => '${e.key} ${e.value.toStringAsFixed(0)}%')
                .join('   ·   '),
            style: _body(16 * s, color: _c.text)
                .copyWith(fontWeight: FontWeight.w600, height: 1.5),
          ),
        ),
      if (widget.shoe.mfgCtr.isNotEmpty)
        _infoBlock(
          label: 'MADE IN',
          child: Row(
            children: [
              Icon(Icons.public, color: _lime, size: 18 * s),
              SizedBox(width: 8 * s),
              Text(widget.shoe.mfgCtr,
                  style: _body(16 * s, color: _c.text)
                      .copyWith(fontWeight: FontWeight.w600)),
            ],
          ),
        ),
      if (widget.shoe.mfgNrg.isNotEmpty)
        _infoBlock(
          label: 'ENERGY SOURCE',
          child: Row(
            children: [
              Icon(Icons.recycling, color: _lime, size: 18 * s),
              SizedBox(width: 8 * s),
              Flexible(
                child: Text(widget.shoe.mfgNrg,
                    style: _body(16 * s, color: _c.text)
                        .copyWith(fontWeight: FontWeight.w600),
                    overflow: TextOverflow.ellipsis),
              ),
            ],
          ),
        ),
    ];

    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(20 * s),
      decoration: BoxDecoration(
        color: _c.card,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _c.border),
      ),
      child: rows.isEmpty
          ? Text('No build details available yet.',
              style: _body(14 * s, color: _c.sub))
          : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                for (var i = 0; i < rows.length; i++) ...[
                  if (i > 0) ...[
                    SizedBox(height: 18 * s),
                    Container(height: 0.5, color: _c.border),
                    SizedBox(height: 18 * s),
                  ],
                  rows[i],
                ],
              ],
            ),
    );
  }

  Widget _infoBlock({required String label, required Widget child}) {
    final s = _scale;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: _body(11 * s, color: _c.sub)
                .copyWith(fontWeight: FontWeight.w700, letterSpacing: 1.2)),
        SizedBox(height: 8 * s),
        child,
      ],
    );
  }

  // ── CTA ───────────────────────────────────────────────────────────────────

  Widget _buildCTA() {
    final s = _scale;
    return Column(
      children: [
        GestureDetector(
          onTap: widget.onCloseLoop,
          child: Container(
            width: double.infinity,
            padding: EdgeInsets.symmetric(vertical: 20 * s),
            decoration: BoxDecoration(
              color: _lime,
              borderRadius: BorderRadius.circular(50),
              boxShadow: [
                BoxShadow(
                  color: _lime.withOpacity(0.28),
                  blurRadius: 24,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text('CLOSE THE LOOP', style: _heading(22 * s, color: _black)),
                SizedBox(width: 10 * s),
                Icon(Icons.arrow_forward_rounded, color: _black, size: 22 * s),
              ],
            ),
          ),
        )
            .animate()
            .fadeIn(delay: 340.ms, duration: 400.ms)
            .slideY(begin: 0.08, end: 0, delay: 340.ms, duration: 400.ms,
                curve: Curves.easeOutCubic),

        SizedBox(height: 14 * s),

        GestureDetector(
          onTap: widget.onDelete,
          child: Padding(
            padding: EdgeInsets.symmetric(vertical: 8 * s),
            child: Text('DELETE SHOE',
                style: _body(13 * s, color: _danger)
                    .copyWith(fontWeight: FontWeight.w700, letterSpacing: 0.6)),
          ),
        )
            .animate()
            .fadeIn(delay: 420.ms, duration: 400.ms),
      ],
    );
  }

}
