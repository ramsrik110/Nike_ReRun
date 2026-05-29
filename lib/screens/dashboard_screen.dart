import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'dart:math' as math;
import 'login_screen.dart';

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
// FIX 4: Local data map — three regional datasets
// ─────────────────────────────────────────────────────────────────────────────

class _RegionData {
  final int          co2t;
  final int          tsp;
  final int          rmp;
  final int          ahc;
  final List<double> trend;

  const _RegionData({
    required this.co2t,
    required this.tsp,
    required this.rmp,
    required this.ahc,
    required this.trend,
  });
}

const _regionDataMap = {
  'GLOBAL': _RegionData(
    co2t:  1284,
    tsp:   48392,
    rmp:   67,
    ahc:   23,
    trend: [1050, 1100, 1150, 1200, 1240, 1284],
  ),
  'EUROPE': _RegionData(
    co2t:  847,
    tsp:   31205,
    rmp:   71,
    ahc:   14,
    trend: [680, 710, 750, 790, 820, 847],
  ),
  'NORTH AMERICA': _RegionData(
    co2t:  437,
    tsp:   17187,
    rmp:   61,
    ahc:   9,
    trend: [350, 370, 380, 390, 410, 437],
  ),
};

// ─────────────────────────────────────────────────────────────────────────────
// Screen
// ─────────────────────────────────────────────────────────────────────────────

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  String _activeFilter = 'GLOBAL';
  final _filters = ['GLOBAL', 'EUROPE', 'NORTH AMERICA'];

  _RegionData get _data => _regionDataMap[_activeFilter]!;

  void _signOut() async {
    await FirebaseAuth.instance.signOut();
    if (mounted) {
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const LoginScreen()),
        (route) => false,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _black,
      body: Column(
        children: [
          // French Lime accent line
          Container(height: 2, color: _lime),
          Expanded(
            child: SafeArea(
              top: false,
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 40),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildHeader(),
                    const SizedBox(height: 20),
                    _buildFilters(),
                    const SizedBox(height: 24),
                    // FIX 4 + FIX 7: re-keyed on filter change → restarts all animations
                    _buildMetricGrid(),
                    const SizedBox(height: 24),
                    _buildChart(),
                    const SizedBox(height: 24),
                    _buildReportButton(),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Header ────────────────────────────────────────────────────────────────

  Widget _buildHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Nike ReRun\nDashboard', style: _heading(28))
            .animate()
            .fadeIn(duration: 400.ms),
        Row(
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text('Last updated', style: _body(11, color: _grey)),
                Text('21/05/2026', style: _body(12)),
              ],
            ).animate().fadeIn(delay: 100.ms),
            const SizedBox(width: 8),
            IconButton(
              icon: const Icon(Icons.logout, color: _grey, size: 20),
              onPressed: _signOut,
            ),
          ],
        ),
      ],
    );
  }

  // ── FIX 4: Filter pills — instant state update on tap ────────────────────

  Widget _buildFilters() {
    return Wrap(
      spacing: 10,
      children: _filters.map((f) {
        final active = f == _activeFilter;
        return GestureDetector(
          onTap: () => setState(() => _activeFilter = f),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: active ? _lime : Colors.transparent,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: active ? _lime : _border),
            ),
            child: Text(
              f,
              style: _body(12, color: active ? _black : _white).copyWith(
                fontWeight: active ? FontWeight.w700 : FontWeight.w400,
                letterSpacing: 0.5,
              ),
            ),
          ),
        );
      }).toList(),
    ).animate().fadeIn(delay: 150.ms, duration: 400.ms);
  }

  // ── Metric grid — keys change with filter → TweenAnimationBuilder restarts ─

  Widget _buildMetricGrid() {
    final d = _data;
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _MetricCard(
                filterKey: _activeFilter,
                label:     'Tonnes CO₂ Diverted',
                value:     d.co2t.toDouble(),
                suffix:    't',
                trend:     '+12% this month',
                icon:      Icons.eco_outlined,
                delay:     200,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _MetricCard(
                filterKey: _activeFilter,
                label:     'Shoes Processed',
                value:     d.tsp.toDouble(),
                suffix:    '',
                trend:     '+8% this month',
                icon:      Icons.directions_run,
                delay:     300,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _CircularMetricCard(
                filterKey: _activeFilter,
                label:     'Recycled Material',
                percent:   d.rmp,
                delay:     400,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _MetricCard(
                filterKey: _activeFilter,
                label:     'Active Hubs',
                value:     d.ahc.toDouble(),
                suffix:    '',
                trend:     'Across 3 regions',
                icon:      Icons.language,
                delay:     500,
              ),
            ),
          ],
        ),
      ],
    );
  }

  // ── FIX 7: Chart animates left to right 1500ms, restarts on filter change ─

  Widget _buildChart() {
    final points =
        _data.trend.map((v) => v.toDouble()).toList();

    return Container(
      decoration: BoxDecoration(
        color: _card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _border),
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Monthly Carbon Trend', style: _heading(18)),
          const SizedBox(height: 4),
          Text('Tonnes CO₂ diverted per month',
              style: _body(12, color: _grey)),
          const SizedBox(height: 20),
          // Key changes with filter → restarts the TweenAnimationBuilder
          TweenAnimationBuilder<double>(
            key: ValueKey('chart_$_activeFilter'),
            tween: Tween(begin: 0, end: 1),
            duration: const Duration(milliseconds: 1500),
            curve: Curves.easeOut,
            builder: (context, animVal, _) {
              return SizedBox(
                height: 140,
                child: CustomPaint(
                  size: Size.infinite,
                  painter: _LinechartPainter(
                      points: points, animationValue: animVal),
                ),
              );
            },
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: ['Dec', 'Jan', 'Feb', 'Mar', 'Apr', 'May']
                .map((m) => Text(m, style: _body(11, color: _grey)))
                .toList(),
          ),
        ],
      ),
    )
        .animate()
        .fadeIn(delay: 500.ms, duration: 500.ms)
        .slideY(begin: 0.1, end: 0, duration: 500.ms);
  }

  // ── Report button ─────────────────────────────────────────────────────────

  Widget _buildReportButton() {
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton.icon(
        onPressed: () {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              backgroundColor: _card,
              content: Text(
                'EU Compliance Report generated.',
                style: _body(13, color: _lime),
              ),
            ),
          );
        },
        icon: const Icon(Icons.download_outlined, color: _lime, size: 18),
        label: Text('Download Report.',
            style: _body(15, color: _lime)
                .copyWith(fontWeight: FontWeight.w700, letterSpacing: 0.5)),
        style: OutlinedButton.styleFrom(
          foregroundColor: _lime,
          side: const BorderSide(color: _lime, width: 1.5),
          padding: const EdgeInsets.symmetric(vertical: 14),
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12)),
        ),
      ),
    )
        .animate()
        .fadeIn(delay: 600.ms, duration: 400.ms)
        .slideY(begin: 0.2, end: 0, duration: 400.ms);
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// FIX 7: Metric card with count-up animation
// Key changes with filter → TweenAnimationBuilder counts from 0 to new value
// ─────────────────────────────────────────────────────────────────────────────

class _MetricCard extends StatelessWidget {
  final String   filterKey;
  final String   label;
  final double   value;
  final String   suffix;
  final String   trend;
  final IconData icon;
  final int      delay;

  const _MetricCard({
    required this.filterKey,
    required this.label,
    required this.value,
    required this.suffix,
    required this.trend,
    required this.icon,
    required this.delay,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _card,
        borderRadius: BorderRadius.circular(14),
        border: const Border(left: BorderSide(color: _lime, width: 3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: _lime, size: 20),
          const SizedBox(height: 10),
          // FIX 7: count-up from 0 to value over 1500ms
          TweenAnimationBuilder<double>(
            key: ValueKey('${filterKey}_$label'),
            tween: Tween(begin: 0, end: value),
            duration: const Duration(milliseconds: 1500),
            curve: Curves.easeOut,
            builder: (_, animVal, __) {
              final displayVal = animVal >= 1000
                  ? '${(animVal / 1000).toStringAsFixed(1)}k'
                  : animVal.round().toString();
              return Text(
                '$displayVal$suffix',
                style: GoogleFonts.bebasNeue(
                  fontSize: 26,
                  color: _white,
                  letterSpacing: 1,
                ),
              );
            },
          ),
          const SizedBox(height: 4),
          Text(label, style: GoogleFonts.nunito(color: _white, fontSize: 11)),
          const SizedBox(height: 4),
          Text(trend, style: GoogleFonts.nunito(color: _lime, fontSize: 11)),
        ],
      ),
    )
        .animate()
        .fadeIn(
            delay: Duration(milliseconds: delay), duration: 400.ms)
        .slideY(begin: 0.1, end: 0, duration: 400.ms);
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// FIX 7: Circular progress card — ring animates 0→% over 2000ms
// ─────────────────────────────────────────────────────────────────────────────

class _CircularMetricCard extends StatelessWidget {
  final String filterKey;
  final String label;
  final int    percent;
  final int    delay;

  const _CircularMetricCard({
    required this.filterKey,
    required this.label,
    required this.percent,
    required this.delay,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _card,
        borderRadius: BorderRadius.circular(14),
        border: const Border(left: BorderSide(color: _lime, width: 3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 4),
          Center(
            // FIX 7: ring draws from 0 to percent over 2000ms
            child: TweenAnimationBuilder<double>(
              key: ValueKey('${filterKey}_ring'),
              tween: Tween(begin: 0, end: percent / 100),
              duration: const Duration(milliseconds: 2000),
              curve: Curves.easeOut,
              builder: (_, animVal, __) {
                return SizedBox(
                  width: 64,
                  height: 64,
                  child: CustomPaint(
                    painter: _RingPainter(percent: animVal),
                    child: Center(
                      child: Text(
                        '${(animVal * 100).round()}%',
                        style: GoogleFonts.bebasNeue(
                          fontSize: 14,
                          color: _lime,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 10),
          Text(label, style: GoogleFonts.nunito(color: _white, fontSize: 11)),
          const SizedBox(height: 4),
          Text('Circular target: 80%',
              style: GoogleFonts.nunito(color: _lime, fontSize: 11)),
        ],
      ),
    )
        .animate()
        .fadeIn(
            delay: Duration(milliseconds: delay), duration: 400.ms)
        .slideY(begin: 0.1, end: 0, duration: 400.ms);
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Ring painter
// ─────────────────────────────────────────────────────────────────────────────

class _RingPainter extends CustomPainter {
  final double percent;
  const _RingPainter({required this.percent});

  @override
  void paint(Canvas canvas, Size size) {
    final centre = Offset(size.width / 2, size.height / 2);
    final radius = math.min(size.width, size.height) / 2 - 4;

    canvas.drawCircle(
      centre,
      radius,
      Paint()
        ..color       = _border
        ..style       = PaintingStyle.stroke
        ..strokeWidth = 5,
    );

    if (percent > 0) {
      canvas.drawArc(
        Rect.fromCircle(center: centre, radius: radius),
        -math.pi / 2,
        2 * math.pi * percent,
        false,
        Paint()
          ..color       = _lime
          ..style       = PaintingStyle.stroke
          ..strokeWidth = 5
          ..strokeCap   = StrokeCap.round,
      );
    }
  }

  @override
  bool shouldRepaint(_RingPainter old) => old.percent != percent;
}

// ─────────────────────────────────────────────────────────────────────────────
// FIX 7: Line chart painter — draws left to right via animationValue
// ─────────────────────────────────────────────────────────────────────────────

class _LinechartPainter extends CustomPainter {
  final List<double> points;
  final double       animationValue; // 0.0 → 1.0

  const _LinechartPainter({
    required this.points,
    required this.animationValue,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (points.isEmpty) return;

    final minVal = points.reduce(math.min);
    final maxVal = points.reduce(math.max);
    final range  = (maxVal - minVal) == 0 ? 1.0 : maxVal - minVal;

    Offset toOffset(int i) {
      final x = i / (points.length - 1) * size.width;
      final y = size.height -
          ((points[i] - minVal) / range * (size.height * 0.85) +
              size.height * 0.05);
      return Offset(x, y);
    }

    final allOffsets = List.generate(points.length, toOffset);

    // How many points to draw based on animation progress
    final visibleCount =
        ((points.length - 1) * animationValue).clamp(0.0, points.length - 1.0);
    final fullPoints = visibleCount.floor();
    final frac       = visibleCount - fullPoints;

    if (fullPoints == 0) return;

    // Interpolated end point
    final List<Offset> offsets = [...allOffsets.take(fullPoints + 1)];
    if (fullPoints < points.length - 1 && frac > 0) {
      final a = allOffsets[fullPoints];
      final b = allOffsets[fullPoints + 1];
      offsets[offsets.length - 1] = Offset(
        a.dx + (b.dx - a.dx) * frac,
        a.dy + (b.dy - a.dy) * frac,
      );
    }

    // Fill gradient
    final fillPath = Path()
      ..moveTo(offsets.first.dx, size.height);
    for (final o in offsets) {
      fillPath.lineTo(o.dx, o.dy);
    }
    fillPath
      ..lineTo(offsets.last.dx, size.height)
      ..close();

    canvas.drawPath(
      fillPath,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [_lime.withOpacity(0.25), _lime.withOpacity(0)],
        ).createShader(Rect.fromLTWH(0, 0, size.width, size.height)),
    );

    // Line
    final linePath = Path()
      ..moveTo(offsets.first.dx, offsets.first.dy);
    for (int i = 1; i < offsets.length; i++) {
      final cp1 = Offset((offsets[i - 1].dx + offsets[i].dx) / 2,
          offsets[i - 1].dy);
      final cp2 = Offset((offsets[i - 1].dx + offsets[i].dx) / 2,
          offsets[i].dy);
      linePath.cubicTo(
          cp1.dx, cp1.dy, cp2.dx, cp2.dy, offsets[i].dx, offsets[i].dy);
    }

    canvas.drawPath(
      linePath,
      Paint()
        ..color       = _lime
        ..style       = PaintingStyle.stroke
        ..strokeWidth = 2.5
        ..strokeCap   = StrokeCap.round,
    );

    // Dots
    for (final o in offsets) {
      canvas.drawCircle(o, 4, Paint()..color = _lime);
      canvas.drawCircle(
          o,
          4,
          Paint()
            ..color       = _black
            ..style       = PaintingStyle.stroke
            ..strokeWidth = 2);
    }
  }

  @override
  bool shouldRepaint(_LinechartPainter old) =>
      old.animationValue != animationValue || old.points != points;
}
