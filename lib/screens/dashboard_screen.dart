import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../nike_colors.dart';
import '../models/hub_model.dart';
import '../utils/region_utils.dart';
import '../services/chatbot_service.dart';
import '../services/report_service.dart';
import '../widgets/nav_controls.dart';
import '../widgets/shoe_icon.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Constants
// ─────────────────────────────────────────────────────────────────────────────
const _lime  = NikeColors.lime;
const _black = NikeColors.black;
const _regions = ['GLOBAL', 'EUROPE', 'NORTH AMERICA'];

TextStyle _heading(double size, {Color color = const Color(0xFFFFFFFF)}) =>
    GoogleFonts.bebasNeue(fontSize: size, color: color, letterSpacing: 0.5);
TextStyle _body(double size, {Color color = const Color(0xFFFFFFFF)}) =>
    GoogleFonts.nunito(fontSize: size, color: color);

List<String> _lastSixMonthLabels() {
  final now = DateTime.now();
  const names = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug',
      'Sep', 'Oct', 'Nov', 'Dec'];
  return List.generate(6, (i) {
    final m = DateTime(now.year, now.month - (5 - i), 1);
    return names[m.month - 1];
  });
}

String _todayLabel() {
  final now = DateTime.now();
  return '${now.day.toString().padLeft(2, '0')}/'
      '${now.month.toString().padLeft(2, '0')}/${now.year}';
}

// ─────────────────────────────────────────────────────────────────────────────
// Region metrics — the single computed shape both GLOBAL (read from the
// authored snapshot doc) and EUROPE (computed live from real hub activity)
// get normalised into, so the UI never needs to know which region it's
// looking at.
// ─────────────────────────────────────────────────────────────────────────────

class _RegionMetrics {
  final bool   isLive;      // true = EUROPE (computed), false = GLOBAL (snapshot)
  final double co2Total;
  final String co2Unit;
  final int    shoesProcessed;
  final int    resoldCount;
  final int    recycledCount;
  final double recycledPercent;
  final int    activeHubs;
  final List<double> co2History;
  final List<int>    shoesHistory;
  final List<double> recycledHistory;
  final List<int>    hubsHistory;
  final List<int>    resoldHistory;
  final List<HubModel> hubs; // only populated for EUROPE, drives the hub list

  const _RegionMetrics({
    required this.isLive,
    required this.co2Total,
    required this.co2Unit,
    required this.shoesProcessed,
    required this.resoldCount,
    required this.recycledCount,
    required this.recycledPercent,
    required this.activeHubs,
    required this.co2History,
    required this.shoesHistory,
    required this.recycledHistory,
    required this.hubsHistory,
    required this.resoldHistory,
    required this.hubs,
  });

  static _RegionMetrics fromGlobalDoc(Map<String, dynamic> d) {
    final tsp = (d['OPS-TSP'] as num?)?.toInt() ?? 0;
    final rsl = (d['OPS-RSL'] as num?)?.toInt() ?? 0;
    List<double> asDoubleList(String key) =>
        ((d[key] as List<dynamic>?) ?? const [])
            .map((e) => (e as num).toDouble())
            .toList();
    List<int> asIntList(String key) => ((d[key] as List<dynamic>?) ?? const [])
        .map((e) => (e as num).toInt())
        .toList();

    return _RegionMetrics(
      isLive:          false,
      co2Total:        (d['ECO-CO2T'] as num?)?.toDouble() ?? 0,
      co2Unit:         't',
      shoesProcessed:  tsp,
      resoldCount:     rsl,
      recycledCount:   (tsp - rsl).clamp(0, tsp).toInt(),
      recycledPercent: (d['ECO-RMP'] as num?)?.toDouble() ?? 0,
      activeHubs:      (d['OPS-AHC'] as num?)?.toInt() ?? 0,
      co2History:      asDoubleList('RPT-MTD'),
      shoesHistory:    asIntList('RPT-MTD-TSP'),
      recycledHistory: asDoubleList('RPT-MTD-RMP'),
      hubsHistory:     asIntList('RPT-MTD-AHC'),
      resoldHistory:   asIntList('RPT-MTD-RSL'),
      hubs:            const [],
    );
  }

  static _RegionMetrics computeLive(List<HubModel> regionHubs) {
    final activeHubs = regionHubs.where((h) => h.isOperational).length;
    final shoesProcessed = regionHubs.fold<int>(0, (total, h) => total + h.hubTsp);

    // Flatten every hub's routing log into one list of real scan events.
    final entries = <Map<String, dynamic>>[];
    for (final hub in regionHubs) {
      for (final raw in hub.rteLog) {
        if (raw is Map) entries.add(raw.cast<String, dynamic>());
      }
    }

    double co2Total = 0;
    int resoldCount = 0, recycledCount = 0;
    for (final e in entries) {
      co2Total += (e['ECO-CO2'] as num?)?.toDouble() ?? 0;
      final decision = e['RTE-DCN'] as String? ?? '';
      if (isResaleDecision(decision)) resoldCount++;
      if (isRecycledDecision(decision)) recycledCount++;
    }
    final recycledPercent =
        entries.isEmpty ? 0.0 : recycledCount / entries.length * 100;

    // Bucket real events into the trailing 6 calendar months.
    final now = DateTime.now();
    final buckets = List.generate(6, (i) => DateTime(now.year, now.month - (5 - i), 1));
    final co2History      = List<double>.filled(6, 0);
    final shoesHistory    = List<int>.filled(6, 0);
    final resoldHistory   = List<int>.filled(6, 0);
    final recycledCounts  = List<int>.filled(6, 0);
    final bucketTotals    = List<int>.filled(6, 0);

    for (final e in entries) {
      final ts = e['TS'];
      DateTime? whenRaw;
      if (ts is Timestamp) whenRaw = ts.toDate();
      if (whenRaw == null) continue;
      final when = whenRaw;
      final idx = buckets.lastIndexWhere(
          (b) => when.year == b.year && when.month == b.month);
      if (idx == -1) continue;
      shoesHistory[idx]++;
      bucketTotals[idx]++;
      co2History[idx] += (e['ECO-CO2'] as num?)?.toDouble() ?? 0;
      final decision = e['RTE-DCN'] as String? ?? '';
      if (isResaleDecision(decision)) resoldHistory[idx]++;
      if (isRecycledDecision(decision)) recycledCounts[idx]++;
    }
    final recycledHistory = List.generate(6, (i) =>
        bucketTotals[i] == 0 ? 0.0 : recycledCounts[i] / bucketTotals[i] * 100);
    final hubsHistory = List.filled(6, activeHubs);

    return _RegionMetrics(
      isLive:          true,
      co2Total:        co2Total,
      co2Unit:         'kg',
      shoesProcessed:  shoesProcessed,
      resoldCount:     resoldCount,
      recycledCount:   recycledCount,
      recycledPercent: recycledPercent,
      activeHubs:      activeHubs,
      co2History:      co2History,
      shoesHistory:    shoesHistory,
      recycledHistory: recycledHistory,
      hubsHistory:     hubsHistory,
      resoldHistory:   resoldHistory,
      hubs:            regionHubs,
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Screen
// ─────────────────────────────────────────────────────────────────────────────

class DashboardScreen extends StatefulWidget {
  final ValueChanged<int>? onNavSelect;
  const DashboardScreen({super.key, this.onNavSelect});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final _scaffoldKey = GlobalKey<ScaffoldState>();

  String _activeFilter = 'GLOBAL';

  Map<String, dynamic>? _globalDoc;
  List<HubModel> _hubs = const [];
  bool _hubsLoaded = false;

  StreamSubscription? _globalSub;
  StreamSubscription? _hubsSub;

  NikeColors get _c => context.nc;

  // Same convention as CustomerLockerScreen: no width cap, no centered
  // "tab" — content stays edge-to-edge and scales up on wide viewports
  // (laptop/projector) so it fills the space instead of floating in a
  // narrow column with dead space on either side.
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
    _globalSub = FirebaseFirestore.instance
        .collection('dashboard')
        .doc('DASHBOARD-GLOBAL')
        .snapshots()
        .listen((snap) {
      if (mounted) setState(() => _globalDoc = snap.data());
    });
    _hubsSub = FirebaseFirestore.instance
        .collection('hubs')
        .snapshots()
        .listen((snap) {
      if (mounted) {
        setState(() {
          _hubs = snap.docs.map((d) => HubModel.fromFirestore(d)).toList();
          _hubsLoaded = true;
        });
      }
    });
  }

  @override
  void dispose() {
    _globalSub?.cancel();
    _hubsSub?.cancel();
    super.dispose();
  }

  List<HubModel> get _europeHubs => _hubs
      .where((h) => regionForCountry(h.hubCtr) == DashboardRegion.europe)
      .toList();
  List<HubModel> get _northAmericaHubs => _hubs
      .where((h) => regionForCountry(h.hubCtr) == DashboardRegion.northAmerica)
      .toList();

  void _signOut() async {
    await FirebaseAuth.instance.signOut();
    // Pop back to _AuthGate (the first route) instead of pushing a new
    // LoginScreen — pushAndRemoveUntil(..., (route) => false) would evict
    // _AuthGate itself, permanently breaking reactive auth routing for the
    // rest of the session.
    if (mounted) {
      Navigator.of(context).popUntil((route) => route.isFirst);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: _c.bg,
      endDrawer: NavDrawer(
        c: _c,
        chatPersona: ChatPersona.admin,
        onSignOut: _signOut,
        items: [
          NavDrawerItem(icon: Icons.dashboard, label: 'Dashboard', selected: true,
              onTap: () => Navigator.of(context).pop()),
          NavDrawerItem(icon: Icons.person, label: 'Profile',
              onTap: () {
                Navigator.of(context).pop();
                widget.onNavSelect?.call(1);
              }),
        ],
      ),
      body: Column(
        children: [
          Container(height: 2, color: _lime),
          Expanded(
            child: SafeArea(
              top: false,
              child: Builder(builder: (context) {
                final s = _scale;
                final wide = _wide;
                final crossAxisCount = wide ? 3 : 2;
                final aspectRatio = wide ? 2.4 : 1.55;

                return SingleChildScrollView(
                  child: Padding(
                    padding: EdgeInsets.fromLTRB(16 * s, 16 * s, 16 * s, 40 * s),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildHeader(s),
                        SizedBox(height: 16 * s),
                        _buildFilters(s),
                        SizedBox(height: 16 * s),
                        _buildBody(crossAxisCount, aspectRatio, s),
                      ],
                    ),
                  ),
                );
              }),
            ),
          ),
        ],
      ),
    );
  }

  // ── Header ────────────────────────────────────────────────────────────────

  Widget _buildHeader(double s) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 8 * s, height: 8 * s,
                    decoration: const BoxDecoration(shape: BoxShape.circle, color: _lime),
                  ),
                  SizedBox(width: 6 * s),
                  Text('ADMIN CONSOLE',
                      style: _body(10 * s, color: _lime)
                          .copyWith(fontWeight: FontWeight.w800, letterSpacing: 1.2)),
                ],
              ).animate().fadeIn(duration: 300.ms),
              SizedBox(height: 4 * s),
              Text('Sustainability Ops', style: _heading(30 * s, color: _c.text))
                  .animate()
                  .fadeIn(delay: 80.ms, duration: 300.ms),
              SizedBox(height: 4 * s),
              Text('Updated ${_todayLabel()}', style: _body(11 * s, color: _c.sub))
                  .animate()
                  .fadeIn(delay: 140.ms, duration: 300.ms),
            ],
          ),
        ),
        CircleIconButton(
          icon: Icons.menu_rounded,
          c: _c,
          onTap: () => _scaffoldKey.currentState?.openEndDrawer(),
        ),
      ],
    );
  }

  // ── Region segmented filter ──────────────────────────────────────────────

  Widget _buildFilters(double s) {
    return Container(
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: _c.card,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _c.border),
      ),
      child: Row(
        children: _regions.map((r) {
          final active = r == _activeFilter;
          return Expanded(
            child: GestureDetector(
              onTap: () => setState(() => _activeFilter = r),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: EdgeInsets.symmetric(vertical: 9 * s),
                decoration: BoxDecoration(
                  color: active ? _lime : Colors.transparent,
                  borderRadius: BorderRadius.circular(9),
                ),
                alignment: Alignment.center,
                child: Text(
                  r,
                  style: _body(11 * s, color: active ? _black : _c.sub).copyWith(
                      fontWeight: active ? FontWeight.w800 : FontWeight.w600,
                      letterSpacing: 0.3),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    ).animate().fadeIn(delay: 150.ms, duration: 300.ms);
  }

  // ── Body — branches on region availability ──────────────────────────────

  Widget _buildBody(int crossAxisCount, double aspectRatio, double s) {
    if (_activeFilter == 'GLOBAL') {
      if (_globalDoc == null) return _buildLoading();
      return _buildMetricsBody(_RegionMetrics.fromGlobalDoc(_globalDoc!),
          'GLOBAL', crossAxisCount, aspectRatio, s);
    }
    if (!_hubsLoaded) return _buildLoading();
    if (_activeFilter == 'EUROPE') {
      final hubs = _europeHubs;
      if (hubs.isEmpty) return _buildEmptyRegion('Europe');
      return _buildMetricsBody(_RegionMetrics.computeLive(hubs), 'EUROPE',
          crossAxisCount, aspectRatio, s);
    }
    // NORTH AMERICA
    final hubs = _northAmericaHubs;
    if (hubs.isEmpty) return _buildEmptyRegion('North America');
    return _buildMetricsBody(_RegionMetrics.computeLive(hubs),
        'NORTH AMERICA', crossAxisCount, aspectRatio, s);
  }

  Widget _buildLoading() => const Padding(
        padding: EdgeInsets.symmetric(vertical: 60),
        child: Center(child: CircularProgressIndicator(color: _lime)),
      );

  Widget _buildEmptyRegion(String name) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 20),
      decoration: BoxDecoration(
        color: _c.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _c.border),
      ),
      child: Column(
        children: [
          Icon(Icons.location_off_outlined, color: _c.sub, size: 34),
          const SizedBox(height: 14),
          Text('$name hub network launching soon.',
              textAlign: TextAlign.center,
              style: _heading(18, color: _c.text)),
          const SizedBox(height: 6),
          Text('0 hubs currently active in this region.',
              textAlign: TextAlign.center, style: _body(12, color: _c.sub)),
        ],
      ),
    ).animate().fadeIn(duration: 300.ms);
  }

  Widget _buildMetricsBody(_RegionMetrics m, String region,
      int crossAxisCount, double aspectRatio, double s) {
    final months = _lastSixMonthLabels();
    final co2Label = m.co2Total >= 1000
        ? '${(m.co2Total / 1000).toStringAsFixed(1)}k'
        : m.co2Total.toStringAsFixed(m.co2Total == m.co2Total.roundToDouble() ? 0 : 1);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              padding: EdgeInsets.symmetric(horizontal: 8 * s, vertical: 3 * s),
              decoration: BoxDecoration(
                color: (m.isLive ? _lime : _c.sub).withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (m.isLive)
                    Container(
                      width: 6 * s, height: 6 * s,
                      margin: EdgeInsets.only(right: 5 * s),
                      decoration: const BoxDecoration(shape: BoxShape.circle, color: _lime),
                    ),
                  Text(m.isLive ? 'LIVE' : 'SNAPSHOT',
                      style: _body(9 * s, color: m.isLive ? _lime : _c.sub)
                          .copyWith(fontWeight: FontWeight.w800, letterSpacing: 0.6)),
                ],
              ),
            ),
          ],
        ),
        SizedBox(height: 10 * s),
        GridView.count(
          crossAxisCount: crossAxisCount,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisSpacing: 10,
          mainAxisSpacing: 10,
          childAspectRatio: aspectRatio,
          children: [
            _MetricTile(
              icon: Icons.eco_outlined,
              label: 'CO₂ diverted',
              value: '$co2Label${m.co2Unit}',
              badge: '+${_deltaLabel(m.co2History)}',
              sparkline: m.co2History,
              onTap: () => _openDetail('CO₂ diverted', months, m.co2History,
                  unit: m.co2Unit),
              delay: 0,
              scale: s,
            ),
            _MetricTile(
              iconWidget: ShoeIcon(color: _lime, size: 16 * s),
              label: 'Shoes processed',
              value: _compact(m.shoesProcessed),
              badge: '+${_deltaLabel(m.shoesHistory.map((e) => e.toDouble()).toList())}',
              sparkline: m.shoesHistory.map((e) => e.toDouble()).toList(),
              onTap: () => _openDetail('Shoes processed', months,
                  m.shoesHistory.map((e) => e.toDouble()).toList()),
              delay: 60,
              scale: s,
            ),
            _RingTile(
              label: 'Recycled material',
              percent: m.recycledPercent,
              onTap: () => _openDetail('Recycled material %', months, m.recycledHistory,
                  unit: '%'),
              delay: 120,
              scale: s,
            ),
            _MetricTile(
              icon: Icons.factory_outlined,
              label: 'Active hubs',
              value: '${m.activeHubs}',
              badge: '${m.hubs.isNotEmpty ? m.hubs.length : m.activeHubs} known',
              sparkline: m.hubsHistory.map((e) => e.toDouble()).toList(),
              onTap: () => _openDetail('Active hubs', months,
                  m.hubsHistory.map((e) => e.toDouble()).toList()),
              delay: 180,
              scale: s,
            ),
            _MetricTile(
              icon: Icons.recycling_outlined,
              label: 'Shoes resold',
              value: _compact(m.resoldCount),
              badge: m.shoesProcessed == 0
                  ? '0%'
                  : '${(m.resoldCount / m.shoesProcessed * 100).round()}%',
              sparkline: m.resoldHistory.map((e) => e.toDouble()).toList(),
              onTap: () => _openDetail('Shoes resold', months,
                  m.resoldHistory.map((e) => e.toDouble()).toList()),
              delay: 240,
              scale: s,
            ),
            _MaterialOutcomesTile(
              resold: m.resoldCount,
              recycled: m.recycledCount,
              onTap: () => _openBreakdown(m),
              delay: 300,
              scale: s,
            ),
          ],
        ),
        if (m.isLive && m.hubs.isNotEmpty) ...[
          SizedBox(height: 16 * s),
          Text('HUBS FEEDING THIS VIEW',
              style: _body(10 * s, color: _c.sub)
                  .copyWith(fontWeight: FontWeight.w700, letterSpacing: 0.8)),
          SizedBox(height: 8 * s),
          ...m.hubs.map((h) => _HubStatusRow(hub: h, scale: s)),
        ],
        SizedBox(height: 20 * s),
        _buildReportButton(m, region, s),
      ],
    );
  }

  static String _compact(int v) =>
      v >= 1000 ? '${(v / 1000).toStringAsFixed(1)}k' : '$v';

  static String _deltaLabel(List<double> history) {
    if (history.length < 2) return '0';
    final delta = history.last - history[history.length - 2];
    if (delta.abs() >= 1000) return '${(delta / 1000).toStringAsFixed(1)}k';
    return delta.toStringAsFixed(delta == delta.roundToDouble() ? 0 : 1);
  }

  void _openDetail(String title, List<String> months, List<double> values,
      {String unit = ''}) {
    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: title,
      barrierColor: Colors.black.withValues(alpha: 0.55),
      transitionDuration: const Duration(milliseconds: 250),
      pageBuilder: (_, _, _) => _DetailPanel(
        title: title,
        months: months,
        values: values,
        unit: unit,
        c: _c,
      ),
      transitionBuilder: (_, anim, _, child) => FadeTransition(
        opacity: anim,
        child: SlideTransition(
          position: Tween(begin: const Offset(0, 0.06), end: Offset.zero)
              .animate(CurvedAnimation(parent: anim, curve: Curves.easeOut)),
          child: child,
        ),
      ),
    );
  }

  void _openBreakdown(_RegionMetrics m) {
    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'Material outcomes',
      barrierColor: Colors.black.withValues(alpha: 0.55),
      transitionDuration: const Duration(milliseconds: 250),
      pageBuilder: (_, _, _) => _BreakdownPanel(metrics: m, c: _c),
      transitionBuilder: (_, anim, _, child) => FadeTransition(
        opacity: anim,
        child: SlideTransition(
          position: Tween(begin: const Offset(0, 0.06), end: Offset.zero)
              .animate(CurvedAnimation(parent: anim, curve: Curves.easeOut)),
          child: child,
        ),
      ),
    );
  }

  Widget _buildReportButton(_RegionMetrics m, String region, double s) {
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton.icon(
        onPressed: () => _exportReport(m, region),
        icon: Icon(Icons.download_outlined, color: _lime, size: 16 * s),
        label: Text('Export report',
            style: _body(13 * s, color: _lime)
                .copyWith(fontWeight: FontWeight.w800, letterSpacing: 0.4)),
        style: OutlinedButton.styleFrom(
          foregroundColor: _lime,
          side: const BorderSide(color: _lime, width: 1.2),
          padding: EdgeInsets.symmetric(vertical: 12 * s),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      ),
    ).animate().fadeIn(delay: 400.ms, duration: 300.ms);
  }

  Future<void> _exportReport(_RegionMetrics m, String region) async {
    try {
      await ReportService.exportDashboardReport(DashboardReportData(
        region:          region,
        asOfDate:        _todayLabel(),
        isLive:          m.isLive,
        co2Total:        m.co2Total,
        co2Unit:         m.co2Unit,
        shoesProcessed:  m.shoesProcessed,
        recycledPercent: m.recycledPercent,
        activeHubs:      m.activeHubs,
        resoldCount:     m.resoldCount,
        recycledCount:   m.recycledCount,
        months:          _lastSixMonthLabels(),
        shoesHistory:    m.shoesHistory.map((e) => e.toDouble()).toList(),
        hubs: m.hubs
            .map((h) => ReportHubInfo(
                  name: h.hubNm,
                  city: h.hubCty,
                  country: h.hubCtr,
                  operational: h.isOperational,
                  throughput: h.hubTsp,
                ))
            .toList(),
      ));
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: _c.card,
            content: Text('Report failed: $e',
                style: _body(12, color: Colors.redAccent)),
          ),
        );
      }
    }
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Pressable — tap-scale feedback substituting for desktop hover on touch.
// ─────────────────────────────────────────────────────────────────────────────

class _Pressable extends StatefulWidget {
  final Widget child;
  final VoidCallback? onTap;
  const _Pressable({required this.child, this.onTap});

  @override
  State<_Pressable> createState() => _PressableState();
}

class _PressableState extends State<_Pressable> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: widget.onTap,
      onTapDown: (_) => setState(() => _pressed = true),
      onTapCancel: () => setState(() => _pressed = false),
      onTapUp: (_) => setState(() => _pressed = false),
      child: AnimatedScale(
        scale: _pressed ? 0.96 : 1.0,
        duration: const Duration(milliseconds: 120),
        child: widget.child,
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Metric tile — icon + big number + mini sparkline, tap to expand.
// ─────────────────────────────────────────────────────────────────────────────

class _MetricTile extends StatelessWidget {
  final IconData? icon;
  final Widget? iconWidget;
  final String label;
  final String value;
  final String badge;
  final List<double> sparkline;
  final VoidCallback onTap;
  final int delay;
  final double scale;

  const _MetricTile({
    this.icon,
    this.iconWidget,
    required this.label,
    required this.value,
    required this.badge,
    required this.sparkline,
    required this.onTap,
    required this.delay,
    required this.scale,
  });

  @override
  Widget build(BuildContext context) {
    final c = context.nc;
    final s = scale;
    return _Pressable(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.all(12 * s),
        decoration: BoxDecoration(
          color: c.card,
          borderRadius: BorderRadius.circular(14),
          border: const Border(left: BorderSide(color: _lime, width: 3)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                iconWidget ?? Icon(icon, color: _lime, size: 16 * s),
                Text(badge, style: _body(9 * s, color: c.sub)),
              ],
            ),
            SizedBox(height: 6 * s),
            Text(value, style: GoogleFonts.bebasNeue(fontSize: 24 * s, color: c.text)),
            Text(label, style: _body(10 * s, color: c.sub)),
            const Spacer(),
            SizedBox(
              height: 20 * s,
              child: CustomPaint(
                size: Size.infinite,
                painter: _SparklinePainter(values: sparkline, color: _lime),
              ),
            ),
          ],
        ),
      ),
    ).animate().fadeIn(delay: Duration(milliseconds: delay), duration: 300.ms)
        .slideY(begin: 0.08, end: 0, duration: 300.ms);
  }
}

class _SparklinePainter extends CustomPainter {
  final List<double> values;
  final Color color;
  const _SparklinePainter({required this.values, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final clean = values.where((v) => v.isFinite).toList();
    if (clean.length < 2 || clean.every((v) => v == clean.first)) {
      canvas.drawLine(Offset(0, size.height / 2), Offset(size.width, size.height / 2),
          Paint()..color = color.withValues(alpha: 0.3)..strokeWidth = 2);
      return;
    }
    final minV = clean.reduce(math.min);
    final maxV = clean.reduce(math.max);
    final range = (maxV - minV) == 0 ? 1.0 : maxV - minV;
    final path = Path();
    for (int i = 0; i < clean.length; i++) {
      final x = i / (clean.length - 1) * size.width;
      final y = size.height - ((clean[i] - minV) / range) * size.height;
      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }
    canvas.drawPath(
        path,
        Paint()
          ..color = color
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2
          ..strokeCap = StrokeCap.round);
  }

  @override
  bool shouldRepaint(_SparklinePainter old) => old.values != values;
}

// ─────────────────────────────────────────────────────────────────────────────
// Ring tile — recycled material %.
// ─────────────────────────────────────────────────────────────────────────────

class _RingTile extends StatelessWidget {
  final String label;
  final double percent;
  final VoidCallback onTap;
  final int delay;
  final double scale;

  const _RingTile({
    required this.label,
    required this.percent,
    required this.onTap,
    required this.delay,
    required this.scale,
  });

  @override
  Widget build(BuildContext context) {
    final c = context.nc;
    final s = scale;
    return _Pressable(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.all(12 * s),
        decoration: BoxDecoration(
          color: c.card,
          borderRadius: BorderRadius.circular(14),
          border: const Border(left: BorderSide(color: _lime, width: 3)),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            TweenAnimationBuilder<double>(
              key: ValueKey('ring_${percent.toStringAsFixed(1)}'),
              tween: Tween(begin: 0, end: percent / 100),
              duration: const Duration(milliseconds: 1200),
              curve: Curves.easeOut,
              builder: (_, v, _) => SizedBox(
                width: 58 * s, height: 58 * s,
                child: CustomPaint(
                  painter: _RingPainter(percent: v, trackColor: c.border),
                  child: Center(
                    child: Text('${(v * 100).round()}%',
                        style: GoogleFonts.bebasNeue(fontSize: 15 * s, color: _lime)),
                  ),
                ),
              ),
            ),
            SizedBox(height: 8 * s),
            Text(label, textAlign: TextAlign.center, style: _body(10 * s, color: c.sub)),
          ],
        ),
      ),
    ).animate().fadeIn(delay: Duration(milliseconds: delay), duration: 300.ms)
        .slideY(begin: 0.08, end: 0, duration: 300.ms);
  }
}

class _RingPainter extends CustomPainter {
  final double percent;
  final Color trackColor;
  const _RingPainter({required this.percent, required this.trackColor});

  @override
  void paint(Canvas canvas, Size size) {
    final centre = Offset(size.width / 2, size.height / 2);
    final radius = math.min(size.width, size.height) / 2 - 5;
    canvas.drawCircle(centre, radius,
        Paint()..color = trackColor..style = PaintingStyle.stroke..strokeWidth = 6);
    if (percent > 0) {
      canvas.drawArc(
        Rect.fromCircle(center: centre, radius: radius),
        -math.pi / 2,
        2 * math.pi * percent,
        false,
        Paint()
          ..color = _lime
          ..style = PaintingStyle.stroke
          ..strokeWidth = 6
          ..strokeCap = StrokeCap.round,
      );
    }
  }

  @override
  bool shouldRepaint(_RingPainter old) => old.percent != percent;
}

// ─────────────────────────────────────────────────────────────────────────────
// Material outcomes tile — resold vs recycled proportion bar.
// ─────────────────────────────────────────────────────────────────────────────

class _MaterialOutcomesTile extends StatelessWidget {
  final int resold;
  final int recycled;
  final VoidCallback onTap;
  final int delay;
  final double scale;

  const _MaterialOutcomesTile({
    required this.resold,
    required this.recycled,
    required this.onTap,
    required this.delay,
    required this.scale,
  });

  @override
  Widget build(BuildContext context) {
    final c = context.nc;
    final s = scale;
    final total = resold + recycled;
    final resoldFrac = total == 0 ? 0.0 : resold / total;

    return _Pressable(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.all(12 * s),
        decoration: BoxDecoration(
          color: c.card,
          borderRadius: BorderRadius.circular(14),
          border: const Border(left: BorderSide(color: _lime, width: 3)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(Icons.pie_chart_outline, color: _lime, size: 16 * s),
            SizedBox(height: 6 * s),
            Text('Material outcomes', style: _body(10 * s, color: c.sub)),
            SizedBox(height: 10 * s),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: SizedBox(
                height: 8 * s,
                child: total == 0
                    ? Container(color: c.border)
                    : Row(
                        children: [
                          Expanded(
                            flex: (resoldFrac * 1000).round().clamp(1, 999).toInt(),
                            child: Container(color: _lime.withValues(alpha: 0.55)),
                          ),
                          Expanded(
                            flex: ((1 - resoldFrac) * 1000).round().clamp(1, 999).toInt(),
                            child: Container(color: _lime),
                          ),
                        ],
                      ),
              ),
            ),
            SizedBox(height: 8 * s),
            Row(
              children: [
                _legendDot(_lime.withValues(alpha: 0.55), 'Resold', c, s),
                SizedBox(width: 10 * s),
                _legendDot(_lime, 'Recycled', c, s),
              ],
            ),
          ],
        ),
      ),
    ).animate().fadeIn(delay: Duration(milliseconds: delay), duration: 300.ms)
        .slideY(begin: 0.08, end: 0, duration: 300.ms);
  }

  Widget _legendDot(Color color, String label, NikeColors c, double s) => Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(width: 6 * s, height: 6 * s,
              decoration: BoxDecoration(shape: BoxShape.circle, color: color)),
          SizedBox(width: 4 * s),
          Text(label, style: _body(9 * s, color: c.sub)),
        ],
      );
}

// ─────────────────────────────────────────────────────────────────────────────
// Hub status row — real hub feeding the live region view.
// ─────────────────────────────────────────────────────────────────────────────

class _HubStatusRow extends StatelessWidget {
  final HubModel hub;
  final double scale;
  const _HubStatusRow({required this.hub, required this.scale});

  @override
  Widget build(BuildContext context) {
    final c = context.nc;
    final s = scale;
    return Container(
      margin: EdgeInsets.only(bottom: 8 * s),
      padding: EdgeInsets.symmetric(horizontal: 12 * s, vertical: 10 * s),
      decoration: BoxDecoration(
        color: c.card,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          Container(
            width: 7 * s, height: 7 * s,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: hub.isOperational ? _lime : c.sub,
            ),
          ),
          SizedBox(width: 10 * s),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(hub.hubNm, style: _body(12 * s, color: c.text).copyWith(fontWeight: FontWeight.w700)),
                Text('${hub.locationLabel} · ${hub.hubSts.replaceAll('.', '')}',
                    style: _body(10 * s, color: c.sub)),
              ],
            ),
          ),
          Text('${hub.hubTsp} routed',
              style: _body(11 * s, color: _lime).copyWith(fontWeight: FontWeight.w700)),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Detail panel — bar chart with drag/press-to-inspect month tooltip.
// ─────────────────────────────────────────────────────────────────────────────

class _DetailPanel extends StatelessWidget {
  final String title;
  final List<String> months;
  final List<double> values;
  final String unit;
  final NikeColors c;

  const _DetailPanel({
    required this.title,
    required this.months,
    required this.values,
    required this.unit,
    required this.c,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Material(
        color: Colors.transparent,
        child: Container(
          width: MediaQuery.of(context).size.width * 0.86,
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: c.card,
            borderRadius: BorderRadius.circular(16),
            border: const Border(top: BorderSide(color: _lime, width: 2)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(title, style: _heading(18, color: c.text)),
                  ),
                  GestureDetector(
                    onTap: () => Navigator.of(context).pop(),
                    child: Icon(Icons.close, color: c.sub, size: 18),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text('Last 6 months · press a bar for that month’s number',
                  style: _body(11, color: c.sub)),
              const SizedBox(height: 18),
              _InteractiveBarChart(months: months, values: values, unit: unit, c: c),
            ],
          ),
        ),
      ),
    );
  }
}

class _InteractiveBarChart extends StatefulWidget {
  final List<String> months;
  final List<double> values;
  final String unit;
  final NikeColors c;

  const _InteractiveBarChart({
    required this.months,
    required this.values,
    required this.unit,
    required this.c,
  });

  @override
  State<_InteractiveBarChart> createState() => _InteractiveBarChartState();
}

class _InteractiveBarChartState extends State<_InteractiveBarChart> {
  int? _selected;

  @override
  Widget build(BuildContext context) {
    final values = widget.values.isEmpty
        ? List.filled(widget.months.length, 0.0)
        : widget.values;
    final maxV = values.isEmpty ? 1.0 : values.reduce(math.max);
    final safeMax = maxV <= 0 ? 1.0 : maxV;
    final count = math.min(values.length, widget.months.length);

    return LayoutBuilder(builder: (context, constraints) {
      void updateFromDx(double dx) {
        final idx = (dx / constraints.maxWidth * count).floor().clamp(0, count - 1).toInt();
        setState(() => _selected = idx);
      }

      return GestureDetector(
        onPanDown: (d) => updateFromDx(d.localPosition.dx),
        onPanUpdate: (d) => updateFromDx(d.localPosition.dx),
        onPanEnd: (_) => setState(() => _selected = null),
        child: Column(
          children: [
            if (_selected != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: widget.c.card2,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    '${widget.months[_selected!]}: ${_fmt(values[_selected!])}${widget.unit}',
                    style: _body(12, color: _lime).copyWith(fontWeight: FontWeight.w700),
                  ),
                ),
              ),
            SizedBox(
              height: 110,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: List.generate(count, (i) {
                  final h = (values[i] / safeMax).clamp(0.02, 1.0).toDouble();
                  final isSelected = _selected == i;
                  return Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 3),
                      child: FractionallySizedBox(
                        heightFactor: h,
                        alignment: Alignment.bottomCenter,
                        child: Container(
                          decoration: BoxDecoration(
                            color: isSelected ? _lime : _lime.withValues(alpha: 0.5),
                            borderRadius: const BorderRadius.vertical(
                                top: Radius.circular(4)),
                          ),
                        ),
                      ),
                    ),
                  );
                }),
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: List.generate(count, (i) => Expanded(
                    child: Text(widget.months[i],
                        textAlign: TextAlign.center,
                        style: _body(10, color: widget.c.sub)),
                  )),
            ),
          ],
        ),
      );
    });
  }

  static String _fmt(double v) =>
      v == v.roundToDouble() ? v.toInt().toString() : v.toStringAsFixed(1);
}

// ─────────────────────────────────────────────────────────────────────────────
// Breakdown panel — material outcomes by routing decision.
// ─────────────────────────────────────────────────────────────────────────────

class _BreakdownPanel extends StatelessWidget {
  final _RegionMetrics metrics;
  final NikeColors c;
  const _BreakdownPanel({required this.metrics, required this.c});

  @override
  Widget build(BuildContext context) {
    final total = metrics.resoldCount + metrics.recycledCount;
    return Center(
      child: Material(
        color: Colors.transparent,
        child: Container(
          width: MediaQuery.of(context).size.width * 0.86,
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: c.card,
            borderRadius: BorderRadius.circular(16),
            border: const Border(top: BorderSide(color: _lime, width: 2)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Material outcomes', style: _heading(18, color: c.text)),
                  GestureDetector(
                    onTap: () => Navigator.of(context).pop(),
                    child: Icon(Icons.close, color: c.sub, size: 18),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              _row('Resold as-is', metrics.resoldCount, total, c),
              const SizedBox(height: 10),
              _row('Recycled into material', metrics.recycledCount, total, c),
            ],
          ),
        ),
      ),
    );
  }

  Widget _row(String label, int value, int total, NikeColors c) {
    final pct = total == 0 ? 0 : (value / total * 100).round();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label, style: _body(13, color: c.text)),
            Text('$value ($pct%)',
                style: _body(13, color: _lime).copyWith(fontWeight: FontWeight.w700)),
          ],
        ),
        const SizedBox(height: 6),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: total == 0 ? 0 : value / total,
            minHeight: 6,
            backgroundColor: c.border,
            color: _lime,
          ),
        ),
      ],
    );
  }
}
