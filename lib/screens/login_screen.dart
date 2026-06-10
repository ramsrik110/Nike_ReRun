import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'register_screen.dart';

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

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey   = GlobalKey<FormState>();
  final _emailCtrl = TextEditingController();
  final _passCtrl  = TextEditingController();

  bool    _loading     = false;
  bool    _obscurePass = true;
  String? _errorMsg;

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passCtrl.dispose();
    super.dispose();
  }

  // ── Sign in logic ─────────────────────────────────────────────────────────

  Future<void> _signIn() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() { _loading = true; _errorMsg = null; });

    try {
      final credential = await FirebaseAuth.instance.signInWithEmailAndPassword(
        email:    _emailCtrl.text.trim(),
        password: _passCtrl.text.trim(),
      );

      // Fetch role from Firestore users collection
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(credential.user!.uid)
          .get();

      final role = userDoc.data()?['role'] as String? ?? 'unknown';

      if (mounted) _routeByRole(role);
    } on FirebaseAuthException catch (e) {
      setState(() {
        _loading  = false;
        _errorMsg = _friendlyError(e.code);
      });
    } catch (e) {
      setState(() {
        _loading  = false;
        _errorMsg = 'Error: ${e.toString()}';
      });
    }
  }

  void _routeByRole(String role) {
    // Import here to avoid circular imports — main.dart handles this via
    // StreamBuilder, but direct nav from login also needs these imports.
    // We push replacement so back button can't return to login.
    Widget destination;
    switch (role) {
      case 'inspector':
        // Hub inspector gets a standalone screen with no nav bar
        destination = const _InspectorShell();
        break;
      case 'admin':
        // Admin gets standalone dashboard with no nav bar
        destination = const _AdminShell();
        break;
      default:
        // Customer (unknown, customer, or anything else)
        destination = const _CustomerShell();
    }

    Navigator.of(context).pushAndRemoveUntil(
      PageRouteBuilder(
        pageBuilder: (_, __, ___) => destination,
        transitionsBuilder: (_, anim, __, child) =>
            FadeTransition(opacity: anim, child: child),
        transitionDuration: const Duration(milliseconds: 400),
      ),
      (route) => false,
    );
  }

  String _friendlyError(String code) {
    switch (code) {
      case 'user-not-found':    return 'No account found with that email.';
      case 'wrong-password':    return 'Wrong password. Try again.';
      case 'invalid-credential':return 'Email or password is incorrect.';
      case 'invalid-email':     return 'Check that email address.';
      case 'user-disabled':     return 'This account has been disabled.';
      case 'too-many-requests': return 'Too many attempts. Wait a moment and try again.';
      case 'network-request-failed': return 'No internet connection.';
      default:                  return 'Sign-in failed [$code]. Try again.';
    }
  }

  // ── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _black,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 60),
                _buildLogo(),
                const SizedBox(height: 40),
                Text('BACK IN\nTHE GAME.', style: _heading(58))
                    .animate()
                    .fadeIn(duration: 400.ms)
                    .slideY(begin: 0.2, end: 0, duration: 400.ms),
                const SizedBox(height: 8),
                Text('Sign in to your Nike ReRun account.',
                        style: _body(15, color: _grey))
                    .animate()
                    .fadeIn(delay: 100.ms, duration: 400.ms),
                const SizedBox(height: 40),
                if (_errorMsg != null) _buildError(),
                _buildField(
                  controller:   _emailCtrl,
                  label:        'Email Address',
                  icon:         Icons.email_outlined,
                  delay:        150,
                  keyboardType: TextInputType.emailAddress,
                  validator:    (v) =>
                      v == null || !v.contains('@') ? 'Enter a valid email.' : null,
                ),
                const SizedBox(height: 14),
                _buildField(
                  controller:    _passCtrl,
                  label:         'Password',
                  icon:          Icons.lock_outline,
                  delay:         200,
                  obscure:       _obscurePass,
                  toggleObscure: () =>
                      setState(() => _obscurePass = !_obscurePass),
                  validator: (v) =>
                      v == null || v.isEmpty ? 'Enter your password.' : null,
                ),
                const SizedBox(height: 32),
                _buildSignInButton(),
                const SizedBox(height: 20),
                _buildRegisterLink(),
                const SizedBox(height: 40),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLogo() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            ColorFiltered(
              colorFilter: const ColorFilter.mode(_lime, BlendMode.modulate),
              child: Image.asset('assets/images/nikererun.png', height: 32),
            ).animate().fadeIn(duration: 500.ms),
            const SizedBox(width: 10),
            Text('RERUN', style: _heading(30, color: _white))
                .animate()
                .fadeIn(duration: 500.ms),
          ],
        ),
        const SizedBox(height: 6),
        Text('Circular. Tracked. Yours.',
            style: _body(14, color: _grey))
            .animate()
            .fadeIn(delay: 300.ms),
      ],
    );
  }

  Widget _buildError() {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.red.withOpacity(0.1),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.red.withOpacity(0.4)),
      ),
      child: Text(_errorMsg!, style: _body(14, color: Colors.redAccent)),
    );
  }

  Widget _buildField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    required int delay,
    TextInputType keyboardType = TextInputType.text,
    bool obscure = false,
    VoidCallback? toggleObscure,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller:   controller,
      obscureText:  obscure,
      keyboardType: keyboardType,
      style:        _body(16),
      validator:    validator,
      decoration: InputDecoration(
        labelText:     label,
        labelStyle:    _body(15, color: _grey),
        prefixIcon:    Icon(icon, color: _grey, size: 20),
        suffixIcon:    toggleObscure != null
            ? IconButton(
                icon: Icon(
                  obscure
                      ? Icons.visibility_outlined
                      : Icons.visibility_off_outlined,
                  color: _grey,
                  size: 20,
                ),
                onPressed: toggleObscure,
              )
            : null,
        filled:        true,
        fillColor:     _card,
        border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: const BorderSide(color: _border)),
        enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: const BorderSide(color: _border)),
        focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: const BorderSide(color: _lime, width: 2)),
        errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: const BorderSide(color: Colors.redAccent)),
        focusedErrorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: const BorderSide(color: Colors.redAccent, width: 2)),
      ),
    )
        .animate()
        .fadeIn(delay: Duration(milliseconds: delay), duration: 400.ms)
        .slideY(begin: 0.1, end: 0, duration: 400.ms);
  }

  Widget _buildSignInButton() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: _loading ? null : _signIn,
        style: ElevatedButton.styleFrom(
          backgroundColor: _lime,
          foregroundColor: _black,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12)),
          elevation: 0,
        ),
        child: _loading
            ? const SizedBox(
                height: 20,
                width: 20,
                child: CircularProgressIndicator(
                    color: _black, strokeWidth: 2))
            : Text("Let's Go.",
                style: _body(17, color: _black)
                    .copyWith(fontWeight: FontWeight.w800)),
      ),
    )
        .animate()
        .fadeIn(delay: 300.ms, duration: 400.ms)
        .slideY(begin: 0.1, end: 0, duration: 400.ms);
  }

  Widget _buildRegisterLink() {
    return Center(
      child: GestureDetector(
        onTap: () => Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => const RegisterScreen()),
        ),
        child: RichText(
          text: TextSpan(
            style: _body(15, color: _grey),
            children: [
              const TextSpan(text: 'New to ReRun? '),
              TextSpan(
                text: 'Register',
                style: _body(15, color: _lime)
                    .copyWith(fontWeight: FontWeight.w700),
              ),
            ],
          ),
        ),
      ),
    ).animate().fadeIn(delay: 400.ms, duration: 400.ms);
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Role-based shells (defined here to avoid circular imports)
// ─────────────────────────────────────────────────────────────────────────────

// These are thin wrappers; main.dart's StreamBuilder also handles routing.
// They exist so login_screen.dart can navigate directly after sign-in.

class _InspectorShell extends StatelessWidget {
  const _InspectorShell();
  @override
  Widget build(BuildContext context) {
    // Lazy import via builder — avoids circular dependency
    return const _RoleScaffold(role: 'inspector');
  }
}

class _AdminShell extends StatelessWidget {
  const _AdminShell();
  @override
  Widget build(BuildContext context) {
    return const _RoleScaffold(role: 'admin');
  }
}

class _CustomerShell extends StatelessWidget {
  const _CustomerShell();
  @override
  Widget build(BuildContext context) {
    return const _RoleScaffold(role: 'customer');
  }
}

// This widget just triggers a full app rebuild via Navigator.pushReplacement
// to the root, which will hit the StreamBuilder in main.dart and re-route.
class _RoleScaffold extends StatefulWidget {
  final String role;
  const _RoleScaffold({required this.role});

  @override
  State<_RoleScaffold> createState() => _RoleScaffoldState();
}

class _RoleScaffoldState extends State<_RoleScaffold> {
  @override
  void initState() {
    super.initState();
    // After the frame, pop everything and let main.dart StreamBuilder re-route
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => const _AppRoot()),
          (route) => false,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: Color(0xFF111111),
      body: Center(
        child: CircularProgressIndicator(color: Color(0xFFCDFC49)),
      ),
    );
  }
}

// Minimal re-export of the app root so login can trigger full StreamBuilder re-route
class _AppRoot extends StatelessWidget {
  const _AppRoot();
  @override
  Widget build(BuildContext context) {
    // This forces main.dart's MaterialApp to re-evaluate auth state
    // by rebuilding from the root. In practice, the StreamBuilder
    // in main.dart will immediately show the correct screen.
    return const SizedBox.shrink(); // replaced by main.dart stream
  }
}
