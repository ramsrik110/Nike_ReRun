import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../nike_colors.dart';
import 'inspector_punch_in_screen.dart';
import 'register_screen.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Static / always-lime consts (never themed)
// ─────────────────────────────────────────────────────────────────────────────
const _lime  = Color(0xFFCDFC49);
const _black = Color(0xFF111111); // only used as text-on-lime

// ─────────────────────────────────────────────────────────────────────────────
// Background painter — dot grid with balanced lime glow
// ─────────────────────────────────────────────────────────────────────────────

class _DotGridPainter extends CustomPainter {
  const _DotGridPainter();

  @override
  void paint(Canvas canvas, Size size) {
    const step = 22.0;
    final dotPaint = Paint()..style = PaintingStyle.fill;

    // Glow origin: top-right corner
    final glowOrigin = Offset(size.width, 0);
    final maxDist = size.width * 1.1;

    for (double x = step; x < size.width; x += step) {
      for (double y = step; y < size.height; y += step) {
        final dist = (Offset(x, y) - glowOrigin).distance;
        final boost = (1 - (dist / maxDist)).clamp(0.0, 1.0);
        final alpha = 0.07 + boost * 0.14;
        dotPaint.color = _lime.withOpacity(alpha);
        canvas.drawCircle(Offset(x, y), 1.2, dotPaint);
      }
    }

    // Radial glow wash at top-right
    final glowPaint = Paint()
      ..shader = RadialGradient(
        colors: [
          _lime.withOpacity(0.12),
          _lime.withOpacity(0.04),
          Colors.transparent,
        ],
        stops: const [0.0, 0.45, 1.0],
      ).createShader(Rect.fromCircle(center: glowOrigin, radius: size.width * 0.85));
    canvas.drawRect(Offset.zero & size, glowPaint);
  }

  @override
  bool shouldRepaint(_DotGridPainter old) => false;
}

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
  final _passFocus = FocusNode();

  bool    _loading     = false;
  bool    _obscurePass = true;
  String? _errorMsg;

  NikeColors get _c => context.nc;

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passCtrl.dispose();
    _passFocus.dispose();
    super.dispose();
  }

  // ── Sign in logic ─────────────────────────────────────────────────────────

  Future<void> _signIn() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() { _loading = true; _errorMsg = null; });

    try {
      await FirebaseAuth.instance.signInWithEmailAndPassword(
        email:    _emailCtrl.text.trim(),
        password: _passCtrl.text.trim(),
      );
      // No manual navigation here — _AuthGate's authStateChanges stream
      // picks up the sign-in and routes to the right persona shell.
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
    final c = _c;
    return Scaffold(
      backgroundColor: c.bg,
      body: Stack(
        children: [
          Positioned.fill(
            child: CustomPaint(painter: const _DotGridPainter()),
          ),
          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 60),
                    _buildLogo(c),
                    const SizedBox(height: 40),
                    Text('BACK IN\nTHE GAME.',
                        style: GoogleFonts.bebasNeue(
                            fontSize: 58, color: c.text, letterSpacing: 1.5))
                        .animate()
                        .fadeIn(duration: 400.ms)
                        .slideY(begin: 0.2, end: 0, duration: 400.ms),
                    const SizedBox(height: 8),
                    Text('Sign in to your Nike ReRun account.',
                        style: GoogleFonts.nunito(fontSize: 15, color: c.sub))
                        .animate()
                        .fadeIn(delay: 100.ms, duration: 400.ms),
                    const SizedBox(height: 40),
                    if (_errorMsg != null) _buildError(c),
                    _buildField(
                      c:            c,
                      controller:   _emailCtrl,
                      label:        'Email Address',
                      icon:         Icons.email_outlined,
                      delay:        150,
                      keyboardType: TextInputType.emailAddress,
                      textInputAction: TextInputAction.next,
                      onFieldSubmitted: (_) => _passFocus.requestFocus(),
                      validator:    (v) =>
                          v == null || !v.contains('@') ? 'Enter a valid email.' : null,
                    ),
                    const SizedBox(height: 14),
                    _buildField(
                      c:             c,
                      controller:    _passCtrl,
                      focusNode:     _passFocus,
                      label:         'Password',
                      icon:          Icons.lock_outline,
                      delay:         200,
                      obscure:       _obscurePass,
                      toggleObscure: () =>
                          setState(() => _obscurePass = !_obscurePass),
                      textInputAction: TextInputAction.done,
                      onFieldSubmitted: (_) => _signIn(),
                      validator: (v) =>
                          v == null || v.isEmpty ? 'Enter your password.' : null,
                    ),
                    const SizedBox(height: 32),
                    _buildSignInButton(),
                    const SizedBox(height: 20),
                    _buildRegisterLink(c),
                    const SizedBox(height: 12),
                    _buildInspectorLink(c),
                    const SizedBox(height: 40),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLogo(NikeColors c) {
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
            Text('RERUN',
                style: GoogleFonts.bebasNeue(
                    fontSize: 30, color: c.text, letterSpacing: 1.5))
                .animate()
                .fadeIn(duration: 500.ms),
          ],
        ),
        const SizedBox(height: 6),
        Text('Circular. Tracked. Yours.',
            style: GoogleFonts.nunito(fontSize: 14, color: c.sub))
            .animate()
            .fadeIn(delay: 300.ms),
      ],
    );
  }

  Widget _buildError(NikeColors c) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.red.withOpacity(0.1),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.red.withOpacity(0.4)),
      ),
      child: Text(_errorMsg!,
          style: GoogleFonts.nunito(fontSize: 14, color: Colors.redAccent)),
    );
  }

  Widget _buildField({
    required NikeColors c,
    required TextEditingController controller,
    required String label,
    required IconData icon,
    required int delay,
    TextInputType keyboardType = TextInputType.text,
    bool obscure = false,
    VoidCallback? toggleObscure,
    String? Function(String?)? validator,
    FocusNode? focusNode,
    TextInputAction? textInputAction,
    ValueChanged<String>? onFieldSubmitted,
  }) {
    return TextFormField(
      controller:   controller,
      focusNode:    focusNode,
      obscureText:  obscure,
      keyboardType: keyboardType,
      textInputAction:  textInputAction,
      onFieldSubmitted: onFieldSubmitted,
      style:        GoogleFonts.nunito(fontSize: 16, color: c.text),
      validator:    validator,
      decoration: InputDecoration(
        labelText:     label,
        labelStyle:    GoogleFonts.nunito(fontSize: 15, color: c.sub),
        prefixIcon:    Icon(icon, color: c.sub, size: 20),
        suffixIcon:    toggleObscure != null
            ? IconButton(
                icon: Icon(
                  obscure
                      ? Icons.visibility_outlined
                      : Icons.visibility_off_outlined,
                  color: c.sub,
                  size: 20,
                ),
                onPressed: toggleObscure,
              )
            : null,
        filled:        true,
        fillColor:     c.card,
        border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: BorderSide(color: c.border)),
        enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: BorderSide(color: c.border)),
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
                child: CircularProgressIndicator(color: _black, strokeWidth: 2))
            : Text("Let's Go.",
                style: GoogleFonts.nunito(
                    fontSize: 17, color: _black,
                    fontWeight: FontWeight.w800)),
      ),
    )
        .animate()
        .fadeIn(delay: 300.ms, duration: 400.ms)
        .slideY(begin: 0.1, end: 0, duration: 400.ms);
  }

  Widget _buildRegisterLink(NikeColors c) {
    return Center(
      child: GestureDetector(
        onTap: () => Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => const RegisterScreen()),
        ),
        child: RichText(
          text: TextSpan(
            style: GoogleFonts.nunito(fontSize: 15, color: c.sub),
            children: [
              const TextSpan(text: 'New to ReRun? '),
              TextSpan(
                text: 'Register',
                style: GoogleFonts.nunito(
                    fontSize: 15, color: _lime,
                    fontWeight: FontWeight.w700),
              ),
            ],
          ),
        ),
      ),
    ).animate().fadeIn(delay: 400.ms, duration: 400.ms);
  }

  Widget _buildInspectorLink(NikeColors c) {
    return Center(
      child: GestureDetector(
        onTap: () => Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => const InspectorPunchInScreen()),
        ),
        child: RichText(
          text: TextSpan(
            style: GoogleFonts.nunito(fontSize: 13, color: c.sub),
            children: [
              const TextSpan(text: 'Hub inspector? '),
              TextSpan(
                text: 'Punch in here',
                style: GoogleFonts.nunito(
                    fontSize: 13, color: c.sub,
                    fontWeight: FontWeight.w700,
                    decoration: TextDecoration.underline),
              ),
            ],
          ),
        ),
      ),
    ).animate().fadeIn(delay: 450.ms, duration: 400.ms);
  }
}
