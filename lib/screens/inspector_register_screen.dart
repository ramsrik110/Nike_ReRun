import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_fonts/google_fonts.dart';
import '../nike_colors.dart';
import '../theme_notifier.dart';

// ─────────────────────────────────────────────────────────────────────────────
// First-time Inspector registration. Writes a permanent record to the
// `inspectors` collection (doc ID = Employee ID, so Punch In can look it up
// directly) plus the usual `users/{uid}` doc so _AuthGate's role routing
// works. A synthetic Firebase email is generated from the Employee ID since
// inspectors authenticate by ID + PIN, not email — the PIN doubles as the
// underlying Firebase password.
//
// NOTE: storing the PIN in Firestore alongside the account is fine for a
// single-hub demo but isn't real production security practice — a real
// deployment would hash it or move the check server-side.
// ─────────────────────────────────────────────────────────────────────────────

class InspectorRegisterScreen extends StatefulWidget {
  const InspectorRegisterScreen({super.key});

  @override
  State<InspectorRegisterScreen> createState() => _InspectorRegisterScreenState();
}

class _InspectorRegisterScreenState extends State<InspectorRegisterScreen> {
  final _formKey    = GlobalKey<FormState>();
  final _idCtrl     = TextEditingController();
  final _nameCtrl   = TextEditingController();
  final _pinCtrl    = TextEditingController();
  final _confirmCtrl = TextEditingController();

  bool _loading = false;
  String? _error;

  bool get _isDark => inspectorDarkMode.value;
  NikeColors get _c => _isDark ? NikeColors.inspectorDark : NikeColors.inspectorLight;

  @override
  void dispose() {
    _idCtrl.dispose();
    _nameCtrl.dispose();
    _pinCtrl.dispose();
    _confirmCtrl.dispose();
    super.dispose();
  }

  Future<void> _register() async {
    if (!_formKey.currentState!.validate()) return;
    if (_pinCtrl.text != _confirmCtrl.text) {
      setState(() => _error = 'PINs don\'t match.');
      return;
    }

    final id   = _idCtrl.text.trim().toUpperCase();
    final name = _nameCtrl.text.trim();
    final pin  = _pinCtrl.text.trim();

    setState(() { _loading = true; _error = null; });

    try {
      final existing =
          await FirebaseFirestore.instance.collection('inspectors').doc(id).get();
      if (existing.exists) {
        setState(() {
          _loading = false;
          _error = 'Employee ID "$id" is already registered.';
        });
        return;
      }

      final email = '${id.toLowerCase()}@nikererun.inspector';
      final cred = await FirebaseAuth.instance
          .createUserWithEmailAndPassword(email: email, password: pin);

      await FirebaseFirestore.instance.collection('inspectors').doc(id).set({
        'EMP-ID': id,
        'INS-NM': name,
        'PIN':    pin,
        'FB-EML': email,
        'UID':    cred.user!.uid,
      });

      await FirebaseFirestore.instance.collection('users').doc(cred.user!.uid).set({
        'role':    'inspector',
        'CST-NM':  name,
        'EMP-ID':  id,
        'RWD-NCB': 0,
        'SUID-LNK': [],
        'LCS-RTN':  [],
      }, SetOptions(merge: true));

      // Account is created AND signed in at this point — _AuthGate picks it
      // up and swaps to InspectorShell underneath this pushed route.
      if (mounted) Navigator.of(context).pop();
    } on FirebaseAuthException catch (e) {
      setState(() {
        _loading = false;
        _error = e.code == 'email-already-in-use'
            ? 'Employee ID "$id" is already registered.'
            : 'Registration failed [${e.code}].';
      });
    } catch (e) {
      setState(() { _loading = false; _error = 'Registration failed: $e'; });
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = _c;
    return Scaffold(
      backgroundColor: c.bg,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      GestureDetector(
                        onTap: () => Navigator.of(context).pop(),
                        child: Icon(Icons.arrow_back, color: c.text, size: 22),
                      ),
                      const SizedBox(width: 12),
                      Text('REGISTER.',
                          style: GoogleFonts.bebasNeue(
                              fontSize: 28, color: c.text, letterSpacing: 2)),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text('New hub inspector — first-time setup.',
                      style: GoogleFonts.nunito(fontSize: 13, color: c.sub)),
                  const SizedBox(height: 28),

                  if (_error != null) ...[
                    Text(_error!,
                        style: GoogleFonts.nunito(fontSize: 12, color: Colors.redAccent)),
                    const SizedBox(height: 16),
                  ],

                  _field(c, controller: _idCtrl, label: 'Employee ID',
                      hint: 'INS-1002', capitalize: true,
                      validator: (v) => v == null || v.trim().isEmpty
                          ? 'Enter an Employee ID.' : null),
                  const SizedBox(height: 14),
                  _field(c, controller: _nameCtrl, label: 'Full Name',
                      hint: 'Jane Doe',
                      validator: (v) => v == null || v.trim().isEmpty
                          ? 'Enter your name.' : null),
                  const SizedBox(height: 14),
                  _field(c, controller: _pinCtrl, label: '4-Digit PIN',
                      hint: '1234', obscure: true,
                      keyboardType: TextInputType.number,
                      inputFormatters: [
                        FilteringTextInputFormatter.digitsOnly,
                        LengthLimitingTextInputFormatter(4),
                      ],
                      validator: (v) => v == null || v.length != 4
                          ? 'PIN must be 4 digits.' : null),
                  const SizedBox(height: 14),
                  _field(c, controller: _confirmCtrl, label: 'Confirm PIN',
                      hint: '1234', obscure: true,
                      keyboardType: TextInputType.number,
                      inputFormatters: [
                        FilteringTextInputFormatter.digitsOnly,
                        LengthLimitingTextInputFormatter(4),
                      ],
                      onSubmitted: (_) => _register(),
                      validator: (v) => v == null || v.length != 4
                          ? 'Re-enter your PIN.' : null),

                  const SizedBox(height: 24),
                  GestureDetector(
                    onTap: _loading ? null : _register,
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: _isDark ? Colors.transparent : c.text,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: c.text, width: 1.5),
                      ),
                      child: _loading
                          ? SizedBox(
                              width: 20, height: 20,
                              child: CircularProgressIndicator(
                                  color: _isDark ? c.text : c.bg, strokeWidth: 2),
                            )
                          : Text('Create Account.',
                              style: GoogleFonts.nunito(
                                fontSize: 16,
                                color: _isDark ? c.text : c.bg,
                                fontWeight: FontWeight.w900,
                                letterSpacing: 0.5,
                              )),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _field(
    NikeColors c, {
    required TextEditingController controller,
    required String label,
    required String hint,
    bool obscure = false,
    bool capitalize = false,
    TextInputType? keyboardType,
    List<TextInputFormatter>? inputFormatters,
    ValueChanged<String>? onSubmitted,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      obscureText: obscure,
      textCapitalization:
          capitalize ? TextCapitalization.characters : TextCapitalization.words,
      keyboardType: keyboardType,
      inputFormatters: inputFormatters,
      onFieldSubmitted: onSubmitted,
      validator: validator,
      style: GoogleFonts.nunito(fontSize: 15, color: c.text),
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        labelStyle: GoogleFonts.nunito(fontSize: 13, color: c.sub),
        hintStyle: GoogleFonts.nunito(fontSize: 13, color: c.sub.withOpacity(0.6)),
        filled: true,
        fillColor: c.card2,
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: c.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: c.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: c.text, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: Colors.redAccent),
        ),
      ),
    );
  }
}
