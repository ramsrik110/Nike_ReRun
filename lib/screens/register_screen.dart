import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
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
      // ── Step 1: Create Firebase Auth account ──────────────────────────────
      final credential = await FirebaseAuth.instance
          .createUserWithEmailAndPassword(
        email:    _emailCtrl.text.trim(),
        password: _passCtrl.text.trim(),
      );

      // ── Step 2: Set display name (non-critical, don't block on failure) ───
      try {
        await credential.user?.updateDisplayName(_nameCtrl.text.trim());
      } catch (_) {
        // display name update is optional — continue even if it fails
      }

      // ── Step 3: Write to Firestore users collection ───────────────────────
      // Collection name is 'users' (lowercase u)
      // Document ID is the Firebase Auth UID
      try {
        await FirebaseFirestore.instance
            .collection('users')           // lowercase u — correct
            .doc(credential.user!.uid)     // Firebase Auth UID as document ID
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
        // Firestore write failed — show the real error but Auth account was created
        setState(() {
          _loading  = false;
          _errorMsg = 'Account created but profile save failed.\n'
              'Firestore error: [${e.code}] ${e.message}';
        });
        return;
      }

      if (mounted) {
        _showSuccessAndNavigate();
      }

    } on FirebaseAuthException catch (e) {
      // Show the REAL Firebase error code so we can diagnose it
      setState(() {
        _loading  = false;
        _errorMsg = _friendlyError(e.code, e.message);
      });
    } catch (e) {
      // Catch any other unexpected error (network, etc.)
      setState(() {
        _loading  = false;
        _errorMsg = 'Unexpected error: ${e.toString()}';
      });
    }
  }

  void _showSuccessAndNavigate() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => Dialog(
        backgroundColor: _card,
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
              Text('Your account is ready.', style: _heading(22)),
              const SizedBox(height: 8),
              Text(
                "Let us get you in.",
                style: _body(14, color: _grey),
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
                  child: Text('Sign In', style: _body(15, color: _black)),
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
        // This fires when Email/Password sign-in is disabled in Firebase Console.
        // Fix: Firebase Console → Authentication → Sign-in method → Enable Email/Password
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
        // Always show the real code for unknown errors so we can diagnose
        return 'Firebase error [$code]: ${message ?? "Unknown error. Check Firebase Console."}';
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
                const SizedBox(height: 40),
                _buildLogo(),
                const SizedBox(height: 32),
                Text('WELCOME TO\nTHE LOOP.', style: _heading(32))
                    .animate()
                    .fadeIn(duration: 400.ms)
                    .slideY(begin: 0.2, end: 0, duration: 400.ms),
                const SizedBox(height: 8),
                Text('Create your Nike ReRun account.',
                        style: _body(14, color: _grey))
                    .animate()
                    .fadeIn(delay: 100.ms, duration: 400.ms),
                const SizedBox(height: 32),
                if (_errorMsg != null) _buildError(),
                _buildField(
                  controller: _nameCtrl,
                  label: 'Full Name',
                  icon: Icons.person_outline,
                  delay: 150,
                  validator: (v) =>
                      v == null || v.isEmpty ? 'Enter your name.' : null,
                ),
                const SizedBox(height: 14),
                _buildField(
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
                _buildSignInLink(),
                const SizedBox(height: 40),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLogo() {
    return Row(
      children: [
        Text('NIKE RERUN',
            style: _heading(24, color: _lime))
            .animate()
            .fadeIn(duration: 500.ms),
        const SizedBox(width: 8),
        const Icon(Icons.eco, color: _lime, size: 22)
            .animate()
            .fadeIn(delay: 200.ms, duration: 400.ms),
      ],
    );
  }

  Widget _buildError() {
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
              const Icon(Icons.error_outline,
                  color: Colors.redAccent, size: 16),
              const SizedBox(width: 6),
              Text('Registration Failed',
                  style: _body(13, color: Colors.redAccent)
                      .copyWith(fontWeight: FontWeight.w700)),
            ],
          ),
          const SizedBox(height: 6),
          // Shows the real Firebase error so we can diagnose it
          Text(_errorMsg!,
              style: _body(12, color: Colors.redAccent.withOpacity(0.9))),
        ],
      ),
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
      style: _body(16),
      validator: validator,
      decoration: InputDecoration(
        labelText:     label,
        labelStyle:    _body(14, color: _grey),
        prefixIcon:    Icon(icon, color: _grey, size: 20),
        suffixIcon:    toggleObscure != null
            ? IconButton(
                icon: Icon(
                  obscure ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                  color: _grey, size: 20,
                ),
                onPressed: toggleObscure,
              )
            : null,
        filled:        true,
        fillColor:     _card,
        border:        OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide:   const BorderSide(color: _border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide:   const BorderSide(color: _border),
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
            : Text('Join The Loop.', style: _body(16, color: _black)
                .copyWith(fontWeight: FontWeight.w800)),
      ),
    )
        .animate()
        .fadeIn(delay: 350.ms, duration: 400.ms)
        .slideY(begin: 0.1, end: 0, duration: 400.ms);
  }

  Widget _buildSignInLink() {
    return Center(
      child: GestureDetector(
        onTap: () => Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const LoginScreen()),
        ),
        child: RichText(
          text: TextSpan(
            style: _body(14, color: _grey),
            children: [
              const TextSpan(text: 'Already in the loop? '),
              TextSpan(
                text: 'Sign In',
                style: _body(14, color: _lime)
                    .copyWith(fontWeight: FontWeight.w700),
              ),
            ],
          ),
        ),
      ),
    ).animate().fadeIn(delay: 400.ms, duration: 400.ms);
  }
}
