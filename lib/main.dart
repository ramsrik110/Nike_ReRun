import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:lottie/lottie.dart';
import 'firebase_options.dart';
import 'nike_colors.dart';
import 'theme_notifier.dart';
import 'screens/login_screen.dart';
import 'screens/customer_home_screen.dart';
import 'screens/customer_landing_screen.dart';
import 'screens/customer_shoe_detail_screen.dart';
import 'screens/customer_profile_screen.dart';
import 'screens/hub_inspector_screen.dart';
import 'screens/inspector_profile_screen.dart';
import 'screens/dashboard_screen.dart';
import 'screens/admin_profile_screen.dart';
import 'widgets/chatbot_widget.dart';
import 'services/chatbot_service.dart';

// NOTE: bulkUploadEverything() is intentionally commented out.
// Database is already fully populated — do not uncomment.
// import 'services/firebase_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  await loadThemePreference();
  // final firebaseService = FirebaseService();
  // await firebaseService.bulkUploadEverything();
  runApp(const NikeReRunApp());
}

// ─────────────────────────────────────────────────────────────────────────────
// App root
// ─────────────────────────────────────────────────────────────────────────────

final _darkTheme = ThemeData(
  brightness: Brightness.dark,
  scaffoldBackgroundColor: const Color(0xFF111111),
  primaryColor: const Color(0xFFCDFC49),
  colorScheme: const ColorScheme.dark(
    primary: Color(0xFFCDFC49),
    surface: Color(0xFF1A1A1A),
  ),
  splashColor: Colors.transparent,
  highlightColor: Colors.transparent,
  textTheme: GoogleFonts.nunitoTextTheme(ThemeData.dark().textTheme),
  extensions: const [NikeColors.dark],
);

final _lightTheme = ThemeData(
  brightness: Brightness.light,
  scaffoldBackgroundColor: const Color(0xFFFFFFFF),
  primaryColor: const Color(0xFFCDFC49),
  colorScheme: const ColorScheme.light(
    primary: Color(0xFFCDFC49),
    surface: Color(0xFFF2F2F2),
  ),
  splashColor: Colors.transparent,
  highlightColor: Colors.transparent,
  textTheme: GoogleFonts.nunitoTextTheme(ThemeData.light().textTheme),
  extensions: const [NikeColors.light],
);

class NikeReRunApp extends StatelessWidget {
  const NikeReRunApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<bool>(
      valueListenable: isDarkMode,
      builder: (_, dark, __) => MaterialApp(
        title: 'Nike ReRun',
        debugShowCheckedModeBanner: false,
        theme: dark ? _darkTheme : _lightTheme,
        home: const _AuthGate(),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Auth gate — listens to Firebase Auth state and routes by role
// ─────────────────────────────────────────────────────────────────────────────

class _AuthGate extends StatelessWidget {
  const _AuthGate();

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, authSnap) {
        if (authSnap.connectionState == ConnectionState.waiting) {
          return const _SplashScreen();
        }
        if (authSnap.data == null) {
          return const LoginScreen();
        }
        return FutureBuilder<DocumentSnapshot>(
          future: FirebaseFirestore.instance
              .collection('users')
              .doc(authSnap.data!.uid)
              .get(),
          builder: (context, userSnap) {
            if (!userSnap.hasData) return const _SplashScreen();
            final data = userSnap.data?.data() as Map<String, dynamic>?;
            final role = data?['role'] as String? ?? 'unknown';
            switch (role) {
              case 'inspector':
                return const InspectorShell();
              case 'admin':
                return const AdminShell();
              default:
                return const CustomerShell();
            }
          },
        );
      },
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Splash / loading screen
// ─────────────────────────────────────────────────────────────────────────────

class _SplashScreen extends StatelessWidget {
  const _SplashScreen();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF111111),
      body: Center(
        child: kIsWeb ? _buildWebSplash() : _buildNativeSplash(),
      ),
    );
  }

  // ── Web: branded splash (Lottie AE expressions don't work on Chrome)
  Widget _buildWebSplash() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Text starts fully visible, then pulses between full and 50% opacity
        Text(
          'NIKE RERUN',
          style: GoogleFonts.bebasNeue(
            fontSize: 48,
            color: const Color(0xFFCDFC49),
            letterSpacing: 5,
          ),
        )
            .animate(onPlay: (c) => c.repeat(reverse: true))
            .fadeIn(duration: 1.ms)          // appear instantly
            .then()
            .fade(                            // pulse 1.0 → 0.45 → 1.0
              begin: 1.0,
              end: 0.45,
              duration: 900.ms,
              curve: Curves.easeInOut,
            ),
        const SizedBox(height: 28),
        const SizedBox(
          width: 32,
          height: 32,
          child: CircularProgressIndicator(
            color: Color(0xFFCDFC49),
            strokeWidth: 2.5,
          ),
        ),
      ],
    );
  }

  // ── Native (Android / iOS): Lottie swoosh with Nike ReRun colour palette
  Widget _buildNativeSplash() {
    // French Lime  #CDFC49  →  [0.8039, 0.9882, 0.2863]
    // Dark charcoal background is handled by the Scaffold, not the animation.
    final Widget animation = Lottie.asset(
      'assets/lottie/splash_animation.json',
      width: 300,
      height: 300,
      fit: BoxFit.contain,
      delegates: LottieDelegates(
        values: [
          // Swoosh fill — white → French Lime
          ValueDelegate.color(
            const ['shape logo', 'Shape 1', 'Fill 1'],
            value: const Color(0xFFCDFC49),
          ),
          // Outline strokes — white → French Lime
          ValueDelegate.strokeColor(
            const ['**', 'Stroke 1'],
            value: const Color(0xFFCDFC49),
          ),
          // Sparkle / repeater fills
          ValueDelegate.color(
            const ['**', 'Fill 1'],
            value: const Color(0xFFCDFC49),
          ),
        ],
      ),
    );

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Zoom-out entry: starts large, settles to natural size
        animation
            .animate()
            .scale(
              begin: const Offset(2.0, 2.0),
              end: const Offset(1.0, 1.0),
              duration: 800.ms,
              curve: Curves.easeOutCubic,
            )
            .fadeIn(duration: 400.ms),

        const SizedBox(height: 12),

        // Brand name slides up after animation starts
        Text(
          'NIKE RERUN',
          style: GoogleFonts.bebasNeue(
            fontSize: 32,
            color: const Color(0xFFCDFC49),
            letterSpacing: 5,
          ),
        )
            .animate()
            .fadeIn(delay: 350.ms, duration: 500.ms)
            .slideY(
              begin: 0.4,
              end: 0.0,
              delay: 350.ms,
              duration: 500.ms,
              curve: Curves.easeOut,
            ),

        const SizedBox(height: 6),

        // Subtle tagline
        Text(
          'SUSTAINABLE SNEAKERS',
          style: GoogleFonts.nunito(
            fontSize: 12,
            color: const Color(0xFF888888),
            letterSpacing: 2.5,
          ),
        )
            .animate()
            .fadeIn(delay: 550.ms, duration: 500.ms),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Customer shell — 3 tabs: Home + Scan + Profile  |  floating pill nav bar
// ─────────────────────────────────────────────────────────────────────────────

class CustomerShell extends StatefulWidget {
  const CustomerShell({super.key});

  @override
  State<CustomerShell> createState() => _CustomerShellState();
}

class _CustomerShellState extends State<CustomerShell> {
  int _index = 0;

  @override
  Widget build(BuildContext context) {
    final c = context.nc;
    return Scaffold(
      backgroundColor: c.bg,
      body: Stack(
        children: [
          IndexedStack(
            index: _index,
            children: [
              CustomerLandingScreen(onScanTap: () => setState(() => _index = 1)),
              CustomerScanScreen(isActive: _index == 1),
              CustomerProfileScreen(onScanTap: () => setState(() => _index = 1)),
            ],
          ),
          Positioned(
            left: 16,
            right: 16,
            bottom: 24,
            child: _buildFloatingNavBar(c),
          ),
          const ChatbotWidget(persona: ChatPersona.customer),
        ],
      ),
    );
  }

  Widget _buildFloatingNavBar(NikeColors c) {
    return SafeArea(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
        decoration: BoxDecoration(
          color: c.card,
          borderRadius: BorderRadius.circular(30),
          border: Border.all(color: c.border),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.6),
              blurRadius: 24,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _NavItem(
              icon: Icons.home_outlined,
              activeIcon: Icons.home,
              label: 'Home',
              index: 0,
              current: _index,
              onTap: () => setState(() => _index = 0),
            ),
            _NavItem(
              icon: Icons.qr_code_outlined,
              activeIcon: Icons.qr_code,
              label: 'Scan',
              index: 1,
              current: _index,
              onTap: () => setState(() => _index = 1),
            ),
            _NavItem(
              icon: Icons.person_outline,
              activeIcon: Icons.person,
              label: 'Profile',
              index: 2,
              current: _index,
              onTap: () => setState(() => _index = 2),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Inspector shell — 2 tabs: Inspect + Profile  |  floating pill nav bar
// ─────────────────────────────────────────────────────────────────────────────

class InspectorShell extends StatefulWidget {
  const InspectorShell({super.key});

  @override
  State<InspectorShell> createState() => _InspectorShellState();
}

class _InspectorShellState extends State<InspectorShell> {
  int _index = 0;

  @override
  Widget build(BuildContext context) {
    final c = context.nc;
    return Scaffold(
      backgroundColor: c.bg,
      body: Stack(
        children: [
          IndexedStack(
            index: _index,
            children: const [
              HubInspectorScreen(),
              InspectorProfileScreen(),
            ],
          ),
          Positioned(
            left: 16,
            right: 16,
            bottom: 24,
            child: _buildFloatingNavBar(c),
          ),
          const ChatbotWidget(persona: ChatPersona.inspector),
        ],
      ),
    );
  }

  Widget _buildFloatingNavBar(NikeColors c) {
    return SafeArea(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
        decoration: BoxDecoration(
          color: c.card,
          borderRadius: BorderRadius.circular(30),
          border: Border.all(color: c.border),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.6),
              blurRadius: 24,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _NavItem(
              icon: Icons.qr_code_scanner_outlined,
              activeIcon: Icons.qr_code_scanner,
              label: 'Inspect',
              index: 0,
              current: _index,
              onTap: () => setState(() => _index = 0),
            ),
            _NavItem(
              icon: Icons.person_outline,
              activeIcon: Icons.person,
              label: 'Profile',
              index: 1,
              current: _index,
              onTap: () => setState(() => _index = 1),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Admin shell — 2 tabs: Dashboard + Profile  |  floating pill nav bar
// ─────────────────────────────────────────────────────────────────────────────

class AdminShell extends StatefulWidget {
  const AdminShell({super.key});

  @override
  State<AdminShell> createState() => _AdminShellState();
}

class _AdminShellState extends State<AdminShell> {
  int _index = 0;

  @override
  Widget build(BuildContext context) {
    final c = context.nc;
    return Scaffold(
      backgroundColor: c.bg,
      body: Stack(
        children: [
          IndexedStack(
            index: _index,
            children: const [
              DashboardScreen(),
              AdminProfileScreen(),
            ],
          ),
          Positioned(
            left: 16,
            right: 16,
            bottom: 24,
            child: _buildFloatingNavBar(c),
          ),
          const ChatbotWidget(persona: ChatPersona.admin),
        ],
      ),
    );
  }

  Widget _buildFloatingNavBar(NikeColors c) {
    return SafeArea(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
        decoration: BoxDecoration(
          color: c.card,
          borderRadius: BorderRadius.circular(30),
          border: Border.all(color: c.border),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.6),
              blurRadius: 24,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _NavItem(
              icon: Icons.dashboard_outlined,
              activeIcon: Icons.dashboard,
              label: 'Dashboard',
              index: 0,
              current: _index,
              onTap: () => setState(() => _index = 0),
            ),
            _NavItem(
              icon: Icons.person_outline,
              activeIcon: Icons.person,
              label: 'Profile',
              index: 1,
              current: _index,
              onTap: () => setState(() => _index = 1),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Customer scan screen
// Uses mobile_scanner for real camera QR scanning on Chrome and mobile.
// Camera starts when this tab becomes active and stops when user leaves.
// Manual SUID entry is always available as a fallback text link.
// ─────────────────────────────────────────────────────────────────────────────

class CustomerScanScreen extends StatefulWidget {
  final bool isActive;

  const CustomerScanScreen({super.key, required this.isActive});

  @override
  State<CustomerScanScreen> createState() => _CustomerScanScreenState();
}

class _CustomerScanScreenState extends State<CustomerScanScreen>
    with TickerProviderStateMixin {
  late final MobileScannerController _scanner;
  late final AnimationController _scanLineCtrl;
  late final Animation<double> _scanLineAnim;

  bool _navigating  = false;
  bool _fetchLoading = false;
  bool _cameraError  = false;

  @override
  void initState() {
    super.initState();

    _scanner = MobileScannerController(
      detectionSpeed: DetectionSpeed.noDuplicates,
      facing: CameraFacing.back,
      autoStart: false,
    );

    _scanLineCtrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);
    _scanLineAnim = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _scanLineCtrl, curve: Curves.easeInOut),
    );

    if (widget.isActive) _startCamera();
  }

  @override
  void didUpdateWidget(CustomerScanScreen old) {
    super.didUpdateWidget(old);
    if (widget.isActive && !old.isActive) {
      _startCamera();
    } else if (!widget.isActive && old.isActive) {
      _scanner.stop();
    }
  }

  @override
  void dispose() {
    _scanner.dispose();
    _scanLineCtrl.dispose();
    super.dispose();
  }

  void _startCamera() {
    setState(() => _cameraError = false);
    _scanner.start().catchError((_) {
      if (mounted) setState(() => _cameraError = true);
    });
  }

  // Called when mobile_scanner detects a barcode
  void _onDetect(BarcodeCapture capture) async {
    if (_navigating) return;
    final raw = capture.barcodes.firstOrNull?.rawValue;
    if (raw == null || raw.isEmpty) return;
    _navigating = true;
    await _scanner.stop();
    await _navigateToShoe(raw);
  }

  // Navigate to shoe detail — verifies doc exists first
  Future<void> _navigateToShoe(String suid) async {
    if (!mounted) return;
    setState(() => _fetchLoading = true);
    final c = context.nc;
    try {
      final doc = await FirebaseFirestore.instance
          .collection('Shoes') // capital S — always
          .doc(suid)
          .get();

      if (!mounted) return;
      setState(() => _fetchLoading = false);

      if (!doc.exists) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('No shoe found for ID: $suid',
                style: GoogleFonts.nunito(color: Colors.white, fontSize: 14)),
            backgroundColor: c.card,
          ),
        );
        _navigating = false;
        if (widget.isActive) _scanner.start();
        return;
      }

      await Navigator.of(context).push(
        PageRouteBuilder(
          pageBuilder: (_, __, ___) => CustomerShoeDetailScreen(suid: suid),
          transitionsBuilder: (_, anim, __, child) => SlideTransition(
            position: Tween<Offset>(
                    begin: const Offset(1.0, 0.0), end: Offset.zero)
                .animate(CurvedAnimation(parent: anim, curve: Curves.easeOutCubic)),
            child: child,
          ),
          transitionDuration: const Duration(milliseconds: 350),
        ),
      );
    } catch (e) {
      if (mounted) setState(() => _fetchLoading = false);
      _navigating = false;
    }

    // Resume camera when returning from shoe detail
    _navigating = false;
    if (mounted && widget.isActive) _startCamera();
  }

  void _openManualEntry() {
    final ctrl = TextEditingController();
    final c = context.nc;
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: c.card,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text('Enter Shoe ID',
            style: GoogleFonts.bebasNeue(
                fontSize: 22, color: c.text, letterSpacing: 1.2)),
        content: TextField(
          controller: ctrl,
          autofocus: true,
          style: GoogleFonts.nunito(color: c.text),
          decoration: InputDecoration(
            hintText: 'e.g. NR-2024-AM90-0006',
            hintStyle: GoogleFonts.nunito(color: c.sub),
            enabledBorder: OutlineInputBorder(
                borderSide: BorderSide(color: c.border)),
            focusedBorder: const OutlineInputBorder(
                borderSide: BorderSide(color: Color(0xFFCDFC49), width: 2)),
            filled: true,
            fillColor: c.bg,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel',
                style: GoogleFonts.nunito(color: c.sub)),
          ),
          TextButton(
            onPressed: () async {
              final val = ctrl.text.trim();
              Navigator.pop(context);
              if (val.isNotEmpty) await _navigateToShoe(val);
            },
            child: Text('View Shoe',
                style: GoogleFonts.nunito(
                    color: const Color(0xFFCDFC49),
                    fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
  }

  void _signOut() async {
    await FirebaseAuth.instance.signOut();
  }

  // ── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final c = context.nc;
    return Scaffold(
      backgroundColor: c.bg,
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(c),
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'Scan The Label.',
                    style: GoogleFonts.bebasNeue(
                        fontSize: 38,
                        color: c.text,
                        letterSpacing: 1),
                  ).animate().fadeIn(duration: 400.ms),
                  const SizedBox(height: 8),
                  Text(
                    'Point your camera at the shoe\'s QR code.',
                    style: GoogleFonts.nunito(
                        fontSize: 14, color: c.sub),
                  ).animate().fadeIn(delay: 150.ms, duration: 400.ms),
                  const SizedBox(height: 32),
                  _buildScannerBox(),
                  const SizedBox(height: 20),
                  if (_fetchLoading)
                    const Padding(
                      padding: EdgeInsets.only(bottom: 8),
                      child: CircularProgressIndicator(
                          color: Color(0xFFCDFC49), strokeWidth: 2),
                    ),
                  GestureDetector(
                    onTap: _openManualEntry,
                    child: Text(
                      'Enter SUID manually',
                      style: GoogleFonts.nunito(
                        fontSize: 14,
                        color: const Color(0xFFCDFC49),
                        decoration: TextDecoration.underline,
                        decorationColor: const Color(0xFFCDFC49),
                      ),
                    ),
                  ).animate().fadeIn(delay: 300.ms),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(NikeColors c) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      color: c.card,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Text('Scan Mode',
                  style: GoogleFonts.bebasNeue(
                      fontSize: 22, color: c.text, letterSpacing: 1.2)),
              const SizedBox(width: 10),
              const Icon(Icons.qr_code_scanner,
                  color: Color(0xFFCDFC49), size: 20),
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

  // The scanner box: real camera feed + French Lime corner brackets + scan line overlay
  Widget _buildScannerBox() {
    return SizedBox(
      width: 260,
      height: 260,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Stack(
          children: [
            // Real camera feed (or error/init state)
            if (_cameraError)
              _buildCameraError()
            else
              MobileScanner(
                controller: _scanner,
                onDetect: _onDetect,
                errorBuilder: (context, error, child) {
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    if (mounted) setState(() => _cameraError = true);
                  });
                  return _buildCameraError();
                },
              ),

            // Dark overlay vignette around edges
            Container(
              decoration: BoxDecoration(
                gradient: RadialGradient(
                  center: Alignment.center,
                  radius: 1.0,
                  colors: [
                    Colors.transparent,
                    Colors.black.withOpacity(0.3),
                  ],
                ),
              ),
            ),

            // French Lime corner brackets
            ..._buildCorners(),

            // Animated French Lime scan line
            AnimatedBuilder(
              animation: _scanLineAnim,
              builder: (_, __) => Positioned(
                top: 12 + _scanLineAnim.value * 228,
                left: 12,
                right: 12,
                child: Container(
                  height: 2,
                  decoration: BoxDecoration(
                    color: const Color(0xFFCDFC49),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFFCDFC49).withOpacity(0.8),
                        blurRadius: 12,
                        spreadRadius: 4,
                      ),
                      BoxShadow(
                        color: const Color(0xFFCDFC49).withOpacity(0.4),
                        blurRadius: 24,
                        spreadRadius: 8,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCameraError() {
    final c = context.nc;
    return Container(
      color: c.card,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.camera_alt_outlined, color: c.sub, size: 48),
          const SizedBox(height: 12),
          Text(
            'Camera unavailable.',
            style: GoogleFonts.nunito(color: c.sub, fontSize: 14),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 4),
          Text(
            'Allow camera in browser\nor use manual entry below.',
            style: GoogleFonts.nunito(
                color: c.sub.withOpacity(0.6), fontSize: 12),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  List<Widget> _buildCorners() {
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
              painter: _CornerPainter(
                color: const Color(0xFFCDFC49),
                strokeWidth: 3.5,
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

// ─────────────────────────────────────────────────────────────────────────────
// Nav item (shared bottom nav widget)
// ─────────────────────────────────────────────────────────────────────────────

class _NavItem extends StatelessWidget {
  final IconData     icon;
  final IconData     activeIcon;
  final String       label;
  final int          index;
  final int          current;
  final VoidCallback onTap;

  const _NavItem({
    required this.icon,
    required this.activeIcon,
    required this.label,
    required this.index,
    required this.current,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final active = index == current;
    final sub = context.nc.sub;
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: SizedBox(
        width: 80,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 200),
              child: Icon(
                active ? activeIcon : icon,
                key: ValueKey(active),
                color: active ? const Color(0xFFCDFC49) : sub,
                size: 22,
              ),
            ),
            const SizedBox(height: 3),
            Text(
              label,
              style: GoogleFonts.nunito(
                fontSize: 11,
                color: active ? const Color(0xFFCDFC49) : sub,
                fontWeight: active ? FontWeight.w700 : FontWeight.w400,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
