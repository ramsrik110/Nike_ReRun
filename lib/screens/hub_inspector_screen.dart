import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import '../models/shoe_model.dart';
import '../nike_colors.dart';
import '../theme_notifier.dart';
import '../utils/routing_algorithm.dart';
import '../services/chatbot_service.dart';
import '../widgets/nav_controls.dart';
import 'hub_result_screen.dart';

TextStyle _heading(double size, {Color color = const Color(0xFFFFFFFF)}) =>
    GoogleFonts.bebasNeue(fontSize: size, color: color, letterSpacing: 1.5);
TextStyle _body(double size, {Color color = const Color(0xFFFFFFFF)}) =>
    GoogleFonts.nunito(fontSize: size, color: color);

// ─────────────────────────────────────────────────────────────────────────────
// Screen
//
// Inspector's landing screen. Camera starts the instant this tab is active —
// no tap-to-scan. On detection the shoe opens immediately for grading; once
// routed, nothing about that shoe is kept on screen or in local state beyond
// a "Last Routed" summary card — the inspector processes far too many shoes
// to accumulate a visible history. Aggregate productivity (count + avg time)
// is written to the inspector's own user doc and surfaced only in the nav
// drawer, not here.
// ─────────────────────────────────────────────────────────────────────────────

class HubInspectorScreen extends StatefulWidget {
  final bool isActive;
  final ValueChanged<int>? onNavSelect;
  const HubInspectorScreen({super.key, required this.isActive, this.onNavSelect});

  @override
  State<HubInspectorScreen> createState() => _HubInspectorScreenState();
}

class _HubInspectorScreenState extends State<HubInspectorScreen> {
  final _scaffoldKey = GlobalKey<ScaffoldState>();

  bool       _scanned = false;
  bool       _loading = false;
  bool       _cameraError = false;
  bool       _processingScan = false;
  ShoeModel? _shoe;
  DateTime?  _scanStartTime;

  String? _lastRoutedName;
  String? _lastRoutedInstruction;

  late final MobileScannerController _scanner;

  String? _soleCondition;
  String? _fabricCondition;
  String? _wearLevel;
  String? _structural;
  bool    _cleaningReq   = false;

  bool get _isDark => inspectorDarkMode.value;
  NikeColors get _c => _isDark ? NikeColors.inspectorDark : NikeColors.inspectorLight;

  // Dark mode: outline emphasis (transparent fill, text-colored border/text).
  // Light mode: inverted-fill emphasis (solid fill, bg-colored text).
  // Used for buttons/selected pills instead of a lime accent.
  BoxDecoration _emphasisDecoration({double radius = 10, double borderWidth = 1}) =>
      BoxDecoration(
        color: _isDark ? Colors.transparent : _c.text,
        borderRadius: BorderRadius.circular(radius),
        border: Border.all(color: _c.text, width: borderWidth),
      );
  Color get _emphasisTextColor => _isDark ? _c.text : _c.bg;

  @override
  void initState() {
    super.initState();
    _scanner = MobileScannerController(
      detectionSpeed: DetectionSpeed.noDuplicates,
      // Laptops only have a front webcam — requesting the (nonexistent)
      // back camera can fail the constraint entirely on some browsers even
      // with permission granted. Front-facing matches what's actually
      // being tested and presented on.
      facing: CameraFacing.front,
      autoStart: false,
    );
    inspectorDarkMode.addListener(_onThemeChanged);

    // Deferred to after the first frame — unlike the Customer scan tab
    // (which isn't the default tab, so it's always already built by the
    // time it activates), Inspector's scan screen IS the default tab, so
    // starting the camera synchronously here would fire before the
    // MobileScanner widget has ever been attached to the page.
    if (widget.isActive) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && widget.isActive) _startCamera();
      });
    }
  }

  void _onThemeChanged() {
    if (mounted) setState(() {});
  }

  @override
  void didUpdateWidget(HubInspectorScreen old) {
    super.didUpdateWidget(old);
    if (widget.isActive && !old.isActive && !_scanned) {
      _startCamera();
    } else if (!widget.isActive && old.isActive) {
      _scanner.stop();
    }
  }

  @override
  void dispose() {
    _scanner.dispose();
    inspectorDarkMode.removeListener(_onThemeChanged);
    super.dispose();
  }

  void _startCamera() {
    setState(() => _cameraError = false);
    _scanner.start().catchError((Object e) {
      debugPrint('[Inspector] camera start failed: $e');
      if (mounted) setState(() => _cameraError = true);
    });
  }

  // ── Camera detection ──────────────────────────────────────────────────────

  void _onDetect(BarcodeCapture capture) {
    if (_processingScan || _scanned) return;
    final raw = capture.barcodes.firstOrNull?.rawValue;
    if (raw == null || raw.isEmpty) return;
    _processingScan = true;
    _scanner.stop();
    _fetchShoe(raw);
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
              content: Text('Shoe not recognized. Try again.',
                  style: _body(13, color: _c.text)),
              backgroundColor: _c.card2,
            ),
          );
          setState(() => _loading = false);
          _processingScan = false;
          if (widget.isActive) _startCamera();
        }
        return;
      }

      if (mounted) {
        setState(() {
          _shoe             = ShoeModel.fromFirestore(doc);
          _scanned          = true;
          _loading          = false;
          _scanStartTime    = DateTime.now();
          _soleCondition    = null;
          _fabricCondition  = null;
          _wearLevel        = null;
          _structural       = null;
          _cleaningReq      = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() => _loading = false);
        _processingScan = false;
      }
    }
  }

  void _openManualEntry() {
    final ctrl = TextEditingController();
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: _c.card,
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
            side: BorderSide(color: _c.border)),
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
            focusedBorder: OutlineInputBorder(
                borderSide: BorderSide(color: _c.text, width: 2)),
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
                _processingScan = true;
                _fetchShoe(ctrl.text.trim());
              }
            },
            child: Text('Fetch',
                style: _body(14, color: _c.accent)
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
      _cleaningReq     = false;
    });
    _processingScan = false;
    if (widget.isActive) _startCamera();
  }

  void _runRouting() {
    if (!_canRoute) return;

    final result = RoutingAlgorithm.run(
      shoe:                _shoe!,
      soleCondition:       _soleCondition!.toSoleCondition(),
      fabricCondition:     _fabricCondition!.toFabricCondition(),
      wearLevel:           _wearLevel!.toWearLevel(),
      structuralIntegrity: _structural!.toStructuralIntegrity(),
      cleaningRequired:    _cleaningReq,
    );

    FirebaseFirestore.instance
        .collection('Shoes')
        .doc(_shoe!.suid)
        .update({'RTE-DCN': result.routingInstruction, 'LCS-STS': 'ROUTED.'});

    _recordScanStats(result.routingInstruction);
    _recordHubThroughput(result.routingInstruction);

    setState(() {
      _lastRoutedName        = _shoe!.snm;
      _lastRoutedInstruction = result.routingInstruction;
    });

    Navigator.push(
      context,
      PageRouteBuilder(
        pageBuilder: (_, __, ___) => HubResultScreen(result: result),
        transitionsBuilder: (_, anim, __, child) =>
            FadeTransition(opacity: anim, child: child),
        transitionDuration: const Duration(milliseconds: 250),
      ),
    ).then((_) => _reset());
  }

  // INS-SCN/INS-TTM are the permanent lifetime totals (Profile). INS-SHF-*
  // are the current-shift totals (nav drawer) — reset to zero on sign out,
  // see resetInspectorShiftStats(). INS-OUT-* are lifetime per-outcome
  // counts feeding the Profile breakdown.
  void _recordScanStats(String routingInstruction) {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null || _scanStartTime == null) return;
    final elapsedSeconds =
        DateTime.now().difference(_scanStartTime!).inMilliseconds / 1000.0;
    FirebaseFirestore.instance.collection('users').doc(uid).update({
      'INS-SCN':     FieldValue.increment(1),
      'INS-TTM':     FieldValue.increment(elapsedSeconds),
      'INS-SHF-SCN': FieldValue.increment(1),
      'INS-SHF-TTM': FieldValue.increment(elapsedSeconds),
      _outcomeField(routingInstruction): FieldValue.increment(1),
    });
  }

  // Feeds the HQ Admin Dashboard's live Europe view — the only hub in the
  // system today is Berlin (HUB-001), same hub the chatbot and inspector
  // profile screen already hardcode. HUB-TSP is the running shoes-processed
  // count for the hub; RTE-LOG is the per-scan detail (decision + CO2 +
  // timestamp) the dashboard sums/buckets by month to build its live charts.
  void _recordHubThroughput(String routingInstruction) {
    if (_shoe == null) return;
    FirebaseFirestore.instance.collection('hubs').doc('HUB-001').update({
      'HUB-TSP': FieldValue.increment(1),
      'RTE-LOG': FieldValue.arrayUnion([
        {
          'SUID':    _shoe!.suid,
          'RTE-DCN': routingInstruction,
          'ECO-CO2': _shoe!.ecoCo2,
          'TS':      Timestamp.fromDate(DateTime.now()),
        }
      ]),
    });
  }

  static String _outcomeField(String routingInstruction) {
    switch (routingInstruction) {
      case 'To resale.':          return 'INS-OUT-RSL';
      case 'To cleaning.':        return 'INS-OUT-CLN';
      case 'To fabric rework.':   return 'INS-OUT-FAB';
      case 'To sole rework.':     return 'INS-OUT-SOL';
      case 'To full recycle.':    return 'INS-OUT-RCY';
      default:                    return 'INS-OUT-RSL';
    }
  }

  bool get _canRoute =>
      _scanned &&
      _soleCondition   != null &&
      _fabricCondition != null &&
      _wearLevel       != null &&
      _structural      != null;

  void _punchOut() async {
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

  // ── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: _c.bg,
      endDrawer: NavDrawer(
        c: _c,
        chatPersona: ChatPersona.inspector,
        onSignOut: _punchOut,
        signOutLabel: 'Punch Out',
        themeNotifier: inspectorDarkMode,
        extra: InspectorStatsRow(c: _c),
        items: [
          NavDrawerItem(icon: Icons.qr_code_scanner, label: 'Inspect', selected: true,
              onTap: () => Navigator.of(context).pop()),
          NavDrawerItem(icon: Icons.person, label: 'Profile',
              onTap: () {
                Navigator.of(context).pop();
                widget.onNavSelect?.call(1);
              }),
        ],
      ),
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
            child: Text('INSPECT.', style: _heading(20, color: _c.text)),
          ),
          CircleIconButton(
            icon: Icons.menu_rounded,
            c: _c,
            onTap: () => _scaffoldKey.currentState?.openEndDrawer(),
          ),
        ],
      ),
    );
  }

  // ── Scan panel — split console: live camera + "Last Routed" console ───────

  Widget _buildScanPanel() {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
      child: Column(
        children: [
          _buildCameraCard().animate().fadeIn(duration: 300.ms),
          const SizedBox(height: 16),
          GestureDetector(
            onTap: _openManualEntry,
            child: Text(
              'Enter SUID manually',
              style: _body(13, color: _c.accent)
                  .copyWith(decoration: TextDecoration.underline),
            ),
          ).animate().fadeIn(delay: 200.ms),
          if (_loading) ...[
            const SizedBox(height: 16),
            CircularProgressIndicator(color: _c.accent),
          ],
          const SizedBox(height: 16),
          _buildLastRoutedCard().animate().fadeIn(delay: 250.ms),
        ],
      ),
    );
  }

  // Same 260x260 scanner box as the Customer screen — just Inspector's
  // monochrome palette instead of dark+lime.
  Widget _buildCameraCard() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          width: 260,
          height: 260,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Stack(
              children: [
                _cameraError
                    ? _buildCameraError()
                    : MobileScanner(
                        controller: _scanner,
                        fit: BoxFit.cover,
                        onDetect: _onDetect,
                        errorBuilder: (context, error, child) {
                          WidgetsBinding.instance.addPostFrameCallback((_) {
                            if (mounted) setState(() => _cameraError = true);
                          });
                          return _buildCameraError();
                        },
                      ),
                IgnorePointer(child: Stack(children: _corners())),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        Text(
          'Scanning...',
          style: _body(12, color: _c.text).copyWith(fontWeight: FontWeight.w700),
        ),
      ],
    );
  }

  Widget _buildCameraError() {
    return Container(
      color: _c.card,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.camera_alt_outlined, color: _c.sub, size: 40),
          const SizedBox(height: 10),
          Text('Camera unavailable.',
              style: _body(13, color: _c.sub), textAlign: TextAlign.center),
          const SizedBox(height: 4),
          Text('Allow camera access\nor use manual entry below.',
              style: _body(11, color: _c.sub.withOpacity(0.7)),
              textAlign: TextAlign.center),
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
            width: 28,
            height: 28,
            child: CustomPaint(
              painter: _CornerPainter(color: _c.text, strokeWidth: 3.5, radius: 4),
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

  Widget _buildLastRoutedCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: _c.card,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _c.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('LAST ROUTED', style: _body(11, color: _c.sub).copyWith(letterSpacing: 1)),
          const SizedBox(height: 6),
          if (_lastRoutedName == null)
            Text('Nothing scanned yet this session.',
                style: _body(13, color: _c.sub))
          else ...[
            Text(_lastRoutedName!,
                style: _body(14, color: _c.text).copyWith(fontWeight: FontWeight.w700)),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: _emphasisDecoration(radius: 20),
              child: Text(_lastRoutedInstruction!.toUpperCase(),
                  style: _body(11, color: _emphasisTextColor)
                      .copyWith(fontWeight: FontWeight.w800)),
            ),
          ],
        ],
      ),
    );
  }

  // ── Inspection panel — persistent shoe strip ───────────────────────────────

  Widget _buildInspectionPanel() {
    final shoe = _shoe!;
    return Column(
      children: [
        _buildShoeStrip(shoe)
            .animate()
            .fadeIn(duration: 300.ms),
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildMaterialBreakdown(shoe)
                    .animate()
                    .fadeIn(delay: 50.ms, duration: 300.ms),
                const SizedBox(height: 16),
                _buildConditionSelector(
                  title:    'Sole',
                  pills:    const ['Fresh', 'Worn', 'Damaged'],
                  selected: _soleCondition,
                  onSelect: (v) => setState(() => _soleCondition = v),
                ).animate().fadeIn(delay: 100.ms, duration: 300.ms),
                const SizedBox(height: 14),
                _buildConditionSelector(
                  title:    'Fabric',
                  pills:    const ['Fresh', 'Worn', 'Damaged'],
                  selected: _fabricCondition,
                  onSelect: (v) => setState(() => _fabricCondition = v),
                ).animate().fadeIn(delay: 150.ms, duration: 300.ms),
                const SizedBox(height: 14),
                _buildConditionSelector(
                  title:    'Wear Level',
                  pills:    const ['Light', 'Moderate', 'Heavy'],
                  selected: _wearLevel,
                  onSelect: (v) => setState(() => _wearLevel = v),
                ).animate().fadeIn(delay: 200.ms, duration: 300.ms),
                const SizedBox(height: 14),
                _buildConditionSelector(
                  title:    'Structural Integrity',
                  pills:    const ['Intact', 'Minor Damage', 'Major Damage'],
                  selected: _structural,
                  onSelect: (v) => setState(() => _structural = v),
                ).animate().fadeIn(delay: 250.ms, duration: 300.ms),
                const SizedBox(height: 14),
                _buildCleaningToggle()
                    .animate()
                    .fadeIn(delay: 300.ms, duration: 300.ms),
                const SizedBox(height: 24),
                _buildRouteButton()
                    .animate()
                    .fadeIn(delay: 350.ms, duration: 300.ms),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildShoeStrip(ShoeModel shoe) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: _c.card,
        border: Border(bottom: BorderSide(color: _c.border)),
      ),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: SizedBox(
              width: 44,
              height: 34,
              child: shoe.snmImg.isNotEmpty
                  ? Image.network(shoe.snmImg, fit: BoxFit.contain,
                      errorBuilder: (_, __, ___) => Container(color: _c.card2))
                  : Container(color: _c.card2),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(shoe.snm,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: _body(13, color: _c.text).copyWith(fontWeight: FontWeight.w700)),
                Text(shoe.suid, style: _body(11, color: _c.sub)),
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
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _c.border),
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
                        color: colors[e.key] ?? _c.accent,
                        borderRadius: BorderRadius.circular(3),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(child: Text(e.key, style: _body(14, color: _c.text))),
                    Text('${e.value.toInt()}%',
                        style: _body(14, color: _c.accent)
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
        border: Border.all(
          color: selected != null ? _c.text : _c.border,
          width: selected != null ? 1.5 : 1,
        ),
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
                  child: GestureDetector(
                    onTap: () => onSelect(pill),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      decoration: isSelected
                          ? _emphasisDecoration()
                          : BoxDecoration(
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(color: _c.border),
                            ),
                      child: Text(
                        pill,
                        textAlign: TextAlign.center,
                        style: _body(13,
                                color: isSelected ? _emphasisTextColor : _c.text)
                            .copyWith(
                                fontWeight: isSelected
                                    ? FontWeight.w700
                                    : FontWeight.w400),
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

  Widget _buildCleaningToggle() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: _c.card,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _c.border),
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
                    color: _cleaningReq ? _c.accent : _c.sub),
              ),
              const SizedBox(width: 10),
              Switch(
                value: _cleaningReq,
                onChanged: (v) => setState(() => _cleaningReq = v),
                activeColor: _c.text,
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
      child: GestureDetector(
        onTap: _canRoute ? _runRouting : null,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 16),
          alignment: Alignment.center,
          decoration: _canRoute
              ? _emphasisDecoration(radius: 12, borderWidth: 1.5)
              : BoxDecoration(
                  color: _c.card2,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: _c.border),
                ),
          child: Text(
            'Route It.',
            style: _body(16, color: _canRoute ? _emphasisTextColor : _c.sub)
                .copyWith(fontWeight: FontWeight.w900, letterSpacing: 0.5),
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Corner bracket painter — used to overlay scan-frame corners on the live
// camera feed.
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
