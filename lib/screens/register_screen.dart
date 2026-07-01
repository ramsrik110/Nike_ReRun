import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../nike_colors.dart';
import 'login_screen.dart';

const _lime  = Color(0xFFCDFC49);
const _black = Color(0xFF111111);

// ─────────────────────────────────────────────────────────────────────────────
// Background painter — dot grid with lime glow (bottom-left origin)
// ─────────────────────────────────────────────────────────────────────────────

class _DotGridPainter extends CustomPainter {
  const _DotGridPainter();

  @override
  void paint(Canvas canvas, Size size) {
    const step = 22.0;
    final dotPaint = Paint()..style = PaintingStyle.fill;

    final glowOrigin = Offset(0, size.height);
    final maxDist = size.height * 1.1;

    for (double x = step; x < size.width; x += step) {
      for (double y = step; y < size.height; y += step) {
        final dist = (Offset(x, y) - glowOrigin).distance;
        final boost = (1 - (dist / maxDist)).clamp(0.0, 1.0);
        final alpha = 0.07 + boost * 0.14;
        dotPaint.color = _lime.withOpacity(alpha);
        canvas.drawCircle(Offset(x, y), 1.2, dotPaint);
      }
    }

    final glowPaint = Paint()
      ..shader = RadialGradient(
        colors: [
          _lime.withOpacity(0.12),
          _lime.withOpacity(0.04),
          Colors.transparent,
        ],
        stops: const [0.0, 0.45, 1.0],
      ).createShader(Rect.fromCircle(center: glowOrigin, radius: size.height * 0.85));
    canvas.drawRect(Offset.zero & size, glowPaint);
  }

  @override
  bool shouldRepaint(_DotGridPainter old) => false;
}

// ─────────────────────────────────────────────────────────────────────────────
// Screen
// ─────────────────────────────────────────────────────────────────────────────

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey         = GlobalKey<FormState>();
  final _nameCtrl        = TextEditingController();
  final _emailCtrl       = TextEditingController();
  final _passCtrl        = TextEditingController();
  final _confirmPassCtrl = TextEditingController();

  bool _loading      = false;
  bool _obscurePass  = true;
  bool _obscureConf  = true;
  String? _errorMsg;

  NikeColors get _c => context.nc;

  @override
  void dispose() {
    _nameCtrl.dispose();
    _emailCtrl.dispose();
    _passCtrl.dispose();
    _confirmPassCtrl.dispose();
    super.dispose();
  }

  // ── Registration logic ────────────────────────────────────────────────────

  Future<void> _register() async {
    if (!_formKey.currentState!.validate()) return;
    if (_passCtrl.text != _confirmPassCtrl.text) {
      setState(() => _errorMsg = 'Passwords do not match.');
      return;
    }
    setState(() { _loading = true; _errorMsg = null; });

    try {
      final credential = await FirebaseAuth.instance
          .createUserWithEmailAndPassword(
        email:    _emailCtrl.text.trim(),
        password: _passCtrl.text.trim(),
      );

      try {
        await credential.user?.updateDisplayName(_nameCtrl.text.trim());
      } catch (_) {}

      try {
        await FirebaseFirestore.instance
            .collection('users')
            .doc(credential.user!.uid)
            .set({
          'uid':       credential.user!.uid,
          'name':      _nameCtrl.text.trim(),
          'email':     _emailCtrl.text.trim(),
          'role':      'unknown',
          'createdAt': FieldValue.serverTimestamp(),
          'RWD-NCB':   0,
          'SUID-LNK':  [],
          'LCS-RTN':   [],
        });
      } on FirebaseException catch (e) {
        setState(() {
          _loading  = false;
          _errorMsg = 'Account created but profile save failed.\n'
              'Firestore error: [${e.code}] ${e.message}';
        });
        return;
      }

      if (mounted) _showSuccessAndNavigate();

    } on FirebaseAuthException catch (e) {
      setState(() {
        _loading  = false;
        _errorMsg = _friendlyError(e.code, e.message);
      });
    } catch (e) {
      setState(() {
        _loading  = false;
        _errorMsg = 'Unexpected error: ${e.toString()}';
      });
    }
  }

  void _showSuccessAndNavigate() {
    final c = _c;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => Dialog(
        backgroundColor: c.card,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Padding(
          padding: const EdgeInsets.all(28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  color: _lime.withOpacity(0.15),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.check, color: _lime, size: 32),
              ).animate().scale(
                    begin: const Offset(0.3, 0.3),
                    duration: 500.ms,
                    curve: Curves.elasticOut,
                  ),
              const SizedBox(height: 16),
              Text('Your account is ready.',
                  style: GoogleFonts.bebasNeue(
                      fontSize: 24, color: c.text, letterSpacing: 1.5)),
              const SizedBox(height: 8),
              Text(
                "Let us get you in.",
                style: GoogleFonts.nunito(fontSize: 14, color: c.sub),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                    Navigator.of(context).pushReplacement(
                      MaterialPageRoute(
                          builder: (_) => const LoginScreen()),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _lime,
                    foregroundColor: _black,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                  child: Text('Sign In',
                      style: GoogleFonts.nunito(
                          fontSize: 16, color: _black)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _friendlyError(String code, [String? message]) {
    switch (code) {
      case 'email-already-in-use':
        return 'That email is already in the loop. Try signing in.';
      case 'weak-password':
        return 'Password is too weak. Use at least 6 characters.';
      case 'invalid-email':
        return 'That email address looks wrong. Check it and try again.';
      case 'operation-not-allowed':
        return 'Email sign-in is not enabled yet.\n'
            'ACTION NEEDED: Go to Firebase Console → Authentication → '
            'Sign-in method → Email/Password → Enable it.\n'
            '[Error code: $code]';
      case 'network-request-failed':
        return 'No internet connection. Check your network and try again.';
      case 'too-many-requests':
        return 'Too many attempts. Wait a moment then try again.';
      case 'invalid-api-key':
        return 'Firebase configuration error. Check firebase_options.dart.\n'
            '[Error code: $code]';
      case 'app-not-authorized':
        return 'This app is not authorised to use Firebase Auth.\n'
            '[Error code: $code]';
      default:
        return 'Firebase error [$code]: ${message ?? "Unknown error. Check Firebase Console."}';
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
                    const SizedBox(height: 40),
                    _buildLogo(c),
                    const SizedBox(height: 32),
                    Text('WELCOME TO\nTHE LOOP.',
                        style: GoogleFonts.bebasNeue(
                            fontSize: 36, color: c.text, letterSpacing: 1.5))
                        .animate()
                        .fadeIn(duration: 400.ms)
                        .slideY(begin: 0.2, end: 0, duration: 400.ms),
                    const SizedBox(height: 8),
                    Text('Create your Nike ReRun account.',
                        style: GoogleFonts.nunito(fontSize: 15, color: c.sub))
                        .animate()
                        .fadeIn(delay: 100.ms, duration: 400.ms),
                    const SizedBox(height: 32),
                    if (_errorMsg != null) _buildError(c),
                    _buildField(
                      c: c,
                      controller: _nameCtrl,
                      label: 'Full Name',
                      icon: Icons.person_outline,
                      delay: 150,
                      validator: (v) =>
                          v == null || v.isEmpty ? 'Enter your name.' : null,
                    ),
                    const SizedBox(height: 14),
                    _buildField(
                      c: c,
                      controller: _emailCtrl,
                      label: 'Email Address',
                      icon: Icons.email_outlined,
                      delay: 200,
                      keyboardType: TextInputType.emailAddress,
                      validator: (v) =>
                          v == null || !v.contains('@') ? 'Enter a valid email.' : null,
                    ),
                    const SizedBox(height: 14),
                    _buildField(
                      c: c,
                      controller: _passCtrl,
                      label: 'Password',
                      icon: Icons.lock_outline,
                      delay: 250,
                      obscure: _obscurePass,
                      toggleObscure: () =>
                          setState(() => _obscurePass = !_obscurePass),
                      validator: (v) =>
                          v == null || v.length < 6 ? 'Min 6 characters.' : null,
                    ),
                    const SizedBox(height: 14),
                    _buildField(
                      c: c,
                      controller: _confirmPassCtrl,
                      label: 'Confirm Password',
                      icon: Icons.lock_outline,
                      delay: 300,
                      obscure: _obscureConf,
                      toggleObscure: () =>
                          setState(() => _obscureConf = !_obscureConf),
                      validator: (v) =>
                          v == null || v.isEmpty ? 'Confirm your password.' : null,
                    ),
                    const SizedBox(height: 28),
                    _buildRegisterButton(),
                    const SizedBox(height: 20),
                    _buildSignInLink(c),
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
    return Row(
      children: [
        ColorFiltered(
          colorFilter: const ColorFilter.mode(_lime, BlendMode.modulate),
          child: Image.asset('assets/images/nikererun.png', height: 30),
        ).animate().fadeIn(duration: 500.ms),
        const SizedBox(width: 10),
        Text('RERUN',
            style: GoogleFonts.bebasNeue(
                fontSize: 26, color: c.text, letterSpacing: 1.5))
            .animate()
            .fadeIn(duration: 500.ms),
      ],
    );
  }

  Widget _buildError(NikeColors c) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.red.withOpacity(0.1),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.red.withOpacity(0.4)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.error_outline, color: Colors.redAccent, size: 16),
              const SizedBox(width: 6),
              Text('Registration Failed',
                  style: GoogleFonts.nunito(
                      fontSize: 14, color: Colors.redAccent,
                      fontWeight: FontWeight.w700)),
            ],
          ),
          const SizedBox(height: 6),
          Text(_errorMsg!,
              style: GoogleFonts.nunito(
                  fontSize: 13,
                  color: Colors.redAccent.withOpacity(0.9))),
        ],
      ),
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
  }) {
    return TextFormField(
      controller:   controller,
      obscureText:  obscure,
      keyboardType: keyboardType,
      style: GoogleFonts.nunito(fontSize: 16, color: c.text),
      validator: validator,
      decoration: InputDecoration(
        labelText:     label,
        labelStyle:    GoogleFonts.nunito(fontSize: 15, color: c.sub),
        prefixIcon:    Icon(icon, color: c.sub, size: 20),
        suffixIcon:    toggleObscure != null
            ? IconButton(
                icon: Icon(
                  obscure ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                  color: c.sub, size: 20,
                ),
                onPressed: toggleObscure,
              )
            : null,
        filled:        true,
        fillColor:     c.card,
        border:        OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide:   BorderSide(color: c.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide:   BorderSide(color: c.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide:   const BorderSide(color: _lime, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide:   const BorderSide(color: Colors.redAccent),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide:   const BorderSide(color: Colors.redAccent, width: 2),
        ),
      ),
    )
        .animate()
        .fadeIn(delay: Duration(milliseconds: delay), duration: 400.ms)
        .slideY(begin: 0.1, end: 0, duration: 400.ms);
  }

  Widget _buildRegisterButton() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: _loading ? null : _register,
        style: ElevatedButton.styleFrom(
          backgroundColor: _lime,
          foregroundColor: _black,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          elevation: 0,
        ),
        child: _loading
            ? const SizedBox(
                height: 20,
                width: 20,
                child: CircularProgressIndicator(color: _black, strokeWidth: 2),
              )
            : Text('Join The Loop.',
                style: GoogleFonts.nunito(
                    fontSize: 17, color: _black,
                    fontWeight: FontWeight.w800)),
      ),
    )
        .animate()
        .fadeIn(delay: 350.ms, duration: 400.ms)
        .slideY(begin: 0.1, end: 0, duration: 400.ms);
  }

  Widget _buildSignInLink(NikeColors c) {
    return Center(
      child: GestureDetector(
        onTap: () => Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const LoginScreen()),
        ),
        child: RichText(
          text: TextSpan(
            style: GoogleFonts.nunito(fontSize: 15, color: c.sub),
            children: [
              const TextSpan(text: 'Already in the loop? '),
              TextSpan(
                text: 'Sign In',
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
}
