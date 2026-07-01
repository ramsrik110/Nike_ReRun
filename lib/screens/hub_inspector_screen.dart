import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../models/shoe_model.dart';
import '../nike_colors.dart';
import '../theme_notifier.dart';
import '../utils/routing_algorithm.dart';
import 'hub_result_screen.dart';
import 'login_screen.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Constants that never change with theme
// ─────────────────────────────────────────────────────────────────────────────
const _lime  = NikeColors.lime;
const _black = NikeColors.black;

TextStyle _heading(double size, {Color color = const Color(0xFFFFFFFF)}) =>
    GoogleFonts.bebasNeue(fontSize: size, color: color, letterSpacing: 1.5);
TextStyle _body(double size, {Color color = const Color(0xFFFFFFFF)}) =>
    GoogleFonts.nunito(fontSize: size, color: color);

// ─────────────────────────────────────────────────────────────────────────────
// Screen
// ─────────────────────────────────────────────────────────────────────────────

class HubInspectorScreen extends StatefulWidget {
  const HubInspectorScreen({super.key});

  @override
  State<HubInspectorScreen> createState() => _HubInspectorScreenState();
}

class _HubInspectorScreenState extends State<HubInspectorScreen>
    with TickerProviderStateMixin {
  bool       _scanned = false;
  bool       _loading = false;
  ShoeModel? _shoe;

  late AnimationController _scanLineCtrl;
  late Animation<double>   _scanLineAnim;

  String? _soleCondition;
  String? _fabricCondition;
  String? _wearLevel;
  String? _structural;
  String  _estimatedAge  = 'Under 1 Year';
  bool    _cleaningReq   = false;

  final Map<String, int> _pillTapCount = {};

  final List<String> _demoSuids = [
    'NR-2024-AF1-0001',
    'NR-2024-PEG-0003',
    'NR-2024-STP-0005',
    'NR-2024-AM90-0006',
    'NR-2024-PEG-0007',
    'NR-2024-REV-0008',
    'NR-2024-AM270-0009',
    'NR-2024-MTC-0010',
    'NR-2024-FRN-0011',
  ];
  int _demoIndex = 0;

  NikeColors get _c => context.nc;

  @override
  void initState() {
    super.initState();
    _scanLineCtrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);
    _scanLineAnim = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _scanLineCtrl, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _scanLineCtrl.dispose();
    super.dispose();
  }

  // ── Fetch shoe from Firestore ─────────────────────────────────────────────

  Future<void> _fetchShoe(String suid) async {
    if (_loading) return;
    setState(() => _loading = true);

    try {
      final doc = await FirebaseFirestore.instance
          .collection('Shoes')
          .doc(suid)
          .get();

      if (!doc.exists) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Shoe $suid not found.',
                  style: _body(13, color: _c.text)),
              backgroundColor: _c.card,
            ),
          );
          setState(() => _loading = false);
        }
        return;
      }

      if (mounted) {
        setState(() {
          _shoe             = ShoeModel.fromFirestore(doc);
          _scanned          = true;
          _loading          = false;
          _soleCondition    = null;
          _fabricCondition  = null;
          _wearLevel        = null;
          _structural       = null;
          _estimatedAge     = 'Under 1 Year';
          _cleaningReq      = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _demoScan() {
    final suid = _demoSuids[_demoIndex % _demoSuids.length];
    _demoIndex++;
    _fetchShoe(suid);
  }

  void _openManualEntry() {
    final ctrl = TextEditingController();
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: _c.card,
        title: Text('Enter Shoe ID', style: _heading(20, color: _c.text)),
        content: TextField(
          controller: ctrl,
          style: _body(16, color: _c.text),
          autofocus: true,
          decoration: InputDecoration(
            hintText: 'e.g. NR-2024-AM90-0006',
            hintStyle: _body(14, color: _c.sub),
            enabledBorder: OutlineInputBorder(
                borderSide: BorderSide(color: _c.border)),
            focusedBorder: const OutlineInputBorder(
                borderSide: BorderSide(color: _lime, width: 2)),
            filled: true,
            fillColor: _c.bg,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel', style: _body(14, color: _c.sub)),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              if (ctrl.text.trim().isNotEmpty) {
                _fetchShoe(ctrl.text.trim());
              }
            },
            child: Text('Fetch',
                style: _body(14, color: _lime)
                    .copyWith(fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
  }

  void _reset() {
    setState(() {
      _scanned         = false;
      _shoe            = null;
      _soleCondition   = null;
      _fabricCondition = null;
      _wearLevel       = null;
      _structural      = null;
      _estimatedAge    = 'Under 1 Year';
      _cleaningReq     = false;
    });
  }

  void _runRouting() {
    if (!_canRoute) return;

    final result = RoutingAlgorithm.run(
      shoe:                _shoe!,
      soleCondition:       _soleCondition!.toSoleCondition(),
      fabricCondition:     _fabricCondition!.toFabricCondition(),
      wearLevel:           _wearLevel!.toWearLevel(),
      structuralIntegrity: _structural!.toStructuralIntegrity(),
      estimatedAge:        _estimatedAge.toEstimatedAge(),
      cleaningRequired:    _cleaningReq,
    );

    FirebaseFirestore.instance
        .collection('Shoes')
        .doc(_shoe!.suid)
        .update({'RTE-DCN': result.decision, 'LCS-STS': 'ROUTED.'});

    Navigator.push(
      context,
      PageRouteBuilder(
        pageBuilder: (_, a, __) =>
            HubResultScreen(shoe: _shoe!, result: result),
        transitionsBuilder: (_, anim, __, child) => FadeTransition(
          opacity: anim,
          child: ScaleTransition(
            scale: Tween<double>(begin: 0.95, end: 1.0).animate(anim),
            child: child,
          ),
        ),
        transitionDuration: const Duration(milliseconds: 400),
      ),
    ).then((_) => _reset());
  }

  bool get _canRoute =>
      _scanned &&
      _soleCondition   != null &&
      _fabricCondition != null &&
      _wearLevel       != null &&
      _structural      != null;

  void _signOut() async {
    await FirebaseAuth.instance.signOut();
    if (mounted) {
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const LoginScreen()),
        (route) => false,
      );
    }
  }

  // ── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _c.bg,
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            Expanded(
              child: _scanned ? _buildInspectionPanel() : _buildScanPanel(),
            ),
          ],
        ),
      ),
    );
  }

  // ── Header ────────────────────────────────────────────────────────────────

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      color: _c.card,
      child: Row(
        children: [
          if (_scanned)
            GestureDetector(
              onTap: _reset,
              child: Icon(Icons.arrow_back_ios, color: _c.text, size: 20),
            )
          else
            const SizedBox(width: 20),
          const SizedBox(width: 8),
          Expanded(
            child: Text('Scan Mode', style: _heading(20, color: _c.text)),
          ),
          Icon(Icons.qr_code_scanner, color: _lime, size: 24),
          const SizedBox(width: 4),
          IconButton(
            icon: Icon(Icons.logout, color: _c.sub, size: 20),
            onPressed: _signOut,
            tooltip: 'Sign Out',
          ),
        ],
      ),
    );
  }

  // ── Scan panel ────────────────────────────────────────────────────────────

  Widget _buildScanPanel() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text('Scan The Label.', style: _heading(38, color: _c.text))
            .animate()
            .fadeIn(duration: 400.ms),
        const SizedBox(height: 32),
        _buildWebViewfinder(),
        const SizedBox(height: 20),
        GestureDetector(
          onTap: _openManualEntry,
          child: Text(
            'Enter SUID manually',
            style: _body(13, color: _lime)
                .copyWith(decoration: TextDecoration.underline),
          ),
        ).animate().fadeIn(delay: 400.ms),
        if (_loading) ...[
          const SizedBox(height: 16),
          const CircularProgressIndicator(color: _lime),
        ],
      ],
    );
  }

  Widget _buildWebViewfinder() {
    return GestureDetector(
      onTap: _demoScan,
      child: _AnimatedViewfinder(
          scanLineAnim: _scanLineAnim, loading: _loading),
    ).animate().fadeIn(delay: 200.ms);
  }

  // ── Inspection panel ──────────────────────────────────────────────────────

  Widget _buildInspectionPanel() {
    final shoe = _shoe!;
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildShoeCard(shoe)
              .animate()
              .slideY(begin: 0.3, end: 0, duration: 400.ms)
              .fadeIn(duration: 400.ms),
          const SizedBox(height: 16),
          _buildMaterialBreakdown(shoe)
              .animate()
              .fadeIn(delay: 100.ms, duration: 400.ms),
          const SizedBox(height: 16),
          _buildConditionSelector(
            title:    'Check The Sole',
            pills:    const ['Fresh', 'Worn', 'Done.'],
            selected: _soleCondition,
            onSelect: (v) => setState(() => _soleCondition = v),
          ).animate().fadeIn(delay: 150.ms, duration: 400.ms),
          const SizedBox(height: 14),
          _buildConditionSelector(
            title:    'Check The Fabric',
            pills:    const ['Fresh', 'Worn', 'Done.'],
            selected: _fabricCondition,
            onSelect: (v) => setState(() => _fabricCondition = v),
          ).animate().fadeIn(delay: 200.ms, duration: 400.ms),
          const SizedBox(height: 14),
          _buildConditionSelector(
            title:    'Overall Wear Level',
            pills:    const ['Light', 'Moderate', 'Heavy'],
            selected: _wearLevel,
            onSelect: (v) => setState(() => _wearLevel = v),
          ).animate().fadeIn(delay: 250.ms, duration: 400.ms),
          const SizedBox(height: 14),
          _buildConditionSelector(
            title:    'Structural Integrity',
            pills:    const ['Intact', 'Minor Damage', 'Major Damage'],
            selected: _structural,
            onSelect: (v) => setState(() => _structural = v),
          ).animate().fadeIn(delay: 300.ms, duration: 400.ms),
          const SizedBox(height: 14),
          _buildAgeDropdown()
              .animate()
              .fadeIn(delay: 350.ms, duration: 400.ms),
          const SizedBox(height: 14),
          _buildCleaningToggle()
              .animate()
              .fadeIn(delay: 400.ms, duration: 400.ms),
          const SizedBox(height: 24),
          _buildRouteButton()
              .animate()
              .fadeIn(delay: 450.ms, duration: 400.ms)
              .slideY(begin: 0.2, end: 0, duration: 400.ms),
        ],
      ),
    );
  }

  Widget _buildShoeCard(ShoeModel shoe) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _c.card,
        borderRadius: const BorderRadius.all(Radius.circular(14)),
        border: const Border(left: BorderSide(color: _lime, width: 3)),
      ),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: SizedBox(
              width: 80,
              height: 60,
              child: shoe.snmImg.isNotEmpty
                  ? Image.network(shoe.snmImg, fit: BoxFit.contain,
                      errorBuilder: (_, __, ___) =>
                          Container(
                              color: _c.card2,
                              child: Center(
                                child: Text('NIKE',
                                    style: GoogleFonts.bebasNeue(
                                      fontSize: 18,
                                      color: _lime.withOpacity(0.2),
                                      letterSpacing: 4,
                                    )),
                              )))
                  : Container(
                      color: _c.card2,
                      child: Center(
                        child: Text('NIKE',
                            style: GoogleFonts.bebasNeue(
                              fontSize: 18,
                              color: _lime.withOpacity(0.2),
                              letterSpacing: 4,
                            )),
                      ),
                    ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(shoe.snm,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: _body(14, color: _c.text)
                        .copyWith(fontWeight: FontWeight.w700)),
                const SizedBox(height: 6),
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: _lime,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text('Verified.',
                      style: _body(11, color: _black)
                          .copyWith(fontWeight: FontWeight.w700)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMaterialBreakdown(ShoeModel shoe) {
    final materials = shoe.activeMaterials;
    final colors = {
      'Flyknit': const Color(0xFF4FC3F7),
      'Rubber':  const Color(0xFFFF7043),
      'Foam':    const Color(0xFFAB47BC),
      'Leather': const Color(0xFF8D6E63),
    };

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _c.card,
        borderRadius: const BorderRadius.all(Radius.circular(14)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Inside This Shoe', style: _heading(18, color: _c.text)),
          const SizedBox(height: 14),
          ...materials.entries.map((e) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Row(
                  children: [
                    Container(
                      width: 12,
                      height: 12,
                      decoration: BoxDecoration(
                        color: colors[e.key] ?? _lime,
                        borderRadius: BorderRadius.circular(3),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(child: Text(e.key, style: _body(14, color: _c.text))),
                    Text('${e.value.toInt()}%',
                        style: _body(14, color: _lime)
                            .copyWith(fontWeight: FontWeight.w700)),
                  ],
                ),
              )),
        ],
      ),
    );
  }

  Widget _buildConditionSelector({
    required String title,
    required List<String> pills,
    required String? selected,
    required ValueChanged<String> onSelect,
  }) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 250),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _c.card,
        borderRadius: BorderRadius.circular(14),
        border: selected != null
            ? const Border(left: BorderSide(color: _lime, width: 3))
            : Border.all(color: _c.border, width: 0.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: _heading(18, color: _c.text)),
          const SizedBox(height: 14),
          Row(
            children: pills.map((pill) {
              final isSelected = selected == pill;
              return Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 3),
                  child: AnimatedScale(
                    scale: isSelected ? 1.05 : 1.0,
                    duration: const Duration(milliseconds: 300),
                    curve: Curves.elasticOut,
                    child: GestureDetector(
                      onTap: () {
                        onSelect(pill);
                        setState(() {
                          _pillTapCount[pill] =
                              (_pillTapCount[pill] ?? 0) + 1;
                        });
                      },
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        decoration: BoxDecoration(
                          color: isSelected ? _lime : Colors.transparent,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: isSelected ? _lime : _c.border,
                          ),
                        ),
                        child: Text(
                          pill,
                          textAlign: TextAlign.center,
                          style: _body(13,
                                  color: isSelected ? _black : _c.text)
                              .copyWith(
                                  fontWeight: isSelected
                                      ? FontWeight.w700
                                      : FontWeight.w400),
                        ),
                      ),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildAgeDropdown() {
    const options = [
      'Under 1 Year',
      '1–2 Years',
      '2–3 Years',
      'Over 3 Years',
    ];

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _c.card,
        borderRadius: const BorderRadius.all(Radius.circular(14)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Estimated Age', style: _heading(18, color: _c.text)),
          const SizedBox(height: 14),
          DropdownButtonFormField<String>(
            value: _estimatedAge,
            dropdownColor: _c.card,
            style: _body(14, color: _c.text),
            decoration: InputDecoration(
              filled: true,
              fillColor: _c.bg,
              contentPadding: const EdgeInsets.symmetric(
                  horizontal: 14, vertical: 12),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide(color: _c.border),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide(color: _c.border),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: const BorderSide(color: _lime, width: 2),
              ),
            ),
            items: options
                .map((o) => DropdownMenuItem(
                      value: o,
                      child: Text(o, style: _body(14, color: _c.text)),
                    ))
                .toList(),
            onChanged: (v) {
              if (v != null) setState(() => _estimatedAge = v);
            },
            icon: const Icon(Icons.keyboard_arrow_down, color: _lime),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              const Icon(Icons.stars, color: _lime, size: 16),
              const SizedBox(width: 6),
              Text(
                '${_coinPreview(_estimatedAge)} NikeCoins for this age',
                style: _body(12, color: _lime),
              ),
            ],
          ),
        ],
      ),
    );
  }

  int _coinPreview(String age) {
    switch (age) {
      case 'Under 1 Year': return 150;
      case '1–2 Years':    return 120;
      case '2–3 Years':    return 80;
      default:             return 50;
    }
  }

  Widget _buildCleaningToggle() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: _c.card,
        borderRadius: const BorderRadius.all(Radius.circular(14)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text('Cleaning Required', style: _heading(18, color: _c.text)),
          Row(
            children: [
              Text(
                _cleaningReq ? 'Yes' : 'No',
                style: _body(14,
                    color: _cleaningReq ? _lime : _c.sub),
              ),
              const SizedBox(width: 10),
              Switch(
                value: _cleaningReq,
                onChanged: (v) => setState(() => _cleaningReq = v),
                activeColor: _lime,
                inactiveThumbColor: _c.sub,
                inactiveTrackColor: _c.card2,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildRouteButton() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: _canRoute ? _runRouting : null,
        style: ElevatedButton.styleFrom(
          backgroundColor: _canRoute ? _lime : _c.card2,
          foregroundColor: _black,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12)),
          elevation: 0,
        ),
        child: Text(
          'Route It.',
          style: _body(16, color: _canRoute ? _black : _c.sub)
              .copyWith(fontWeight: FontWeight.w900, letterSpacing: 0.5),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Animated viewfinder widget (web / demo mode)
// ─────────────────────────────────────────────────────────────────────────────

class _AnimatedViewfinder extends StatelessWidget {
  final Animation<double> scanLineAnim;
  final bool              loading;

  const _AnimatedViewfinder({
    required this.scanLineAnim,
    required this.loading,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 240,
      height: 240,
      child: Stack(
        children: [
          // Viewfinder always has dark background for QR scan readability
          Container(color: Colors.black.withOpacity(0.85)),
          ..._corners(),
          AnimatedBuilder(
            animation: scanLineAnim,
            builder: (_, __) => Positioned(
              top: scanLineAnim.value * 220,
              left: 8,
              right: 8,
              child: Container(
                height: 2,
                decoration: BoxDecoration(
                  color: _lime,
                  boxShadow: [
                    BoxShadow(
                      color: _lime.withOpacity(0.9),
                      blurRadius: 6,
                      spreadRadius: 1,
                    ),
                    BoxShadow(
                      color: _lime.withOpacity(0.5),
                      blurRadius: 16,
                      spreadRadius: 6,
                    ),
                    BoxShadow(
                      color: _lime.withOpacity(0.2),
                      blurRadius: 32,
                      spreadRadius: 10,
                    ),
                  ],
                ),
              ),
            ),
          ),
          if (loading)
            const Center(
              child: CircularProgressIndicator(color: _lime),
            ),
          if (!loading)
            Center(
              child: Text(
                'TAP TO SCAN',
                style: GoogleFonts.bebasNeue(
                  fontSize: 14,
                  color: _lime.withOpacity(0.6),
                  letterSpacing: 3,
                ),
              ),
            ),
        ],
      ),
    );
  }

  List<Widget> _corners() {
    Widget corner(Alignment align, bool flipX, bool flipY) {
      return Align(
        alignment: align,
        child: Transform(
          alignment: Alignment.center,
          transform: Matrix4.identity()
            ..scale(flipX ? -1.0 : 1.0, flipY ? -1.0 : 1.0),
          child: SizedBox(
            width: 24,
            height: 24,
            child: CustomPaint(
              painter: _CornerPainter(
                color: _lime,
                strokeWidth: 3,
                radius: 4,
              ),
            ),
          ),
        ),
      );
    }

    return [
      corner(Alignment.topLeft,     false, false),
      corner(Alignment.topRight,    true,  false),
      corner(Alignment.bottomLeft,  false, true),
      corner(Alignment.bottomRight, true,  true),
    ];
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Corner bracket painter
// ─────────────────────────────────────────────────────────────────────────────

class _CornerPainter extends CustomPainter {
  final Color  color;
  final double strokeWidth;
  final double radius;

  const _CornerPainter({
    required this.color,
    required this.strokeWidth,
    required this.radius,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color       = color
      ..strokeWidth = strokeWidth
      ..style       = PaintingStyle.stroke
      ..strokeCap   = StrokeCap.round;

    final path = Path()
      ..moveTo(0, size.height * 0.6)
      ..lineTo(0, radius)
      ..arcToPoint(Offset(radius, 0),
          radius: Radius.circular(radius), clockwise: true)
      ..lineTo(size.width * 0.6, 0);

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(_CornerPainter old) => false;
}
