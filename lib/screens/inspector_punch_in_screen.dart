import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_fonts/google_fonts.dart';
import '../nike_colors.dart';
import '../theme_notifier.dart';
import 'inspector_register_screen.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Inspector's real entry point — Employee ID + PIN, matching how a Zebra
// handheld actually gets used on a factory floor (big number pad, no
// keyboard, fast tap-in). Internally still maps to a real Firebase
// email/password account, so the rest of the app's currentUser plumbing
// keeps working unchanged — the ID/PIN pair is just a friendlier front end.
//
// PIN is a real TextField (obscured, digits-only) so both the on-screen
// keypad AND a physical keyboard write through the same controller — no
// custom raw-keyboard listener, same proven text-input path the Employee ID
// field and the Customer/Admin login form already use correctly.
//
// Two credential sources: the original hardcoded demo account (kept as a
// zero-risk fallback), and the `inspectors` Firestore collection that
// InspectorRegisterScreen writes to for every inspector who registers
// themselves — doc ID is the Employee ID, so lookup is a direct .doc(id).
// ─────────────────────────────────────────────────────────────────────────────

const _employeeCredentials = {
  'INS-1001': (pin: '1234', email: 'dev-inspector@nikererun.test', password: 'DevTest123!'),
};

class InspectorPunchInScreen extends StatefulWidget {
  const InspectorPunchInScreen({super.key});

  @override
  State<InspectorPunchInScreen> createState() => _InspectorPunchInScreenState();
}

class _InspectorPunchInScreenState extends State<InspectorPunchInScreen> {
  final _idController  = TextEditingController();
  final _pinController = TextEditingController();
  final _idFocus  = FocusNode();
  final _pinFocus = FocusNode();
  bool _loading = false;
  String? _error;

  bool get _isDark => inspectorDarkMode.value;
  NikeColors get _c => _isDark ? NikeColors.inspectorDark : NikeColors.inspectorLight;

  @override
  void dispose() {
    _idController.dispose();
    _pinController.dispose();
    _idFocus.dispose();
    _pinFocus.dispose();
    super.dispose();
  }

  static const _pinLength = 4;

  // On-screen keypad writes through the SAME controller the TextField uses,
  // so tapping and typing never fall out of sync.
  void _tapDigit(String d) {
    if (_pinController.text.length >= _pinLength || _loading) return;
    final next = _pinController.text + d;
    _pinController.value = TextEditingValue(
      text: next,
      selection: TextSelection.collapsed(offset: next.length),
    );
    setState(() => _error = null);
  }

  void _backspace() {
    final text = _pinController.text;
    if (text.isEmpty || _loading) return;
    final next = text.substring(0, text.length - 1);
    _pinController.value = TextEditingValue(
      text: next,
      selection: TextSelection.collapsed(offset: next.length),
    );
  }

  Future<void> _punchIn() async {
    final id  = _idController.text.trim().toUpperCase();
    final pin = _pinController.text;
    setState(() { _loading = true; _error = null; });

    // Check the hardcoded demo account first (zero-risk fallback), then
    // fall back to the Firestore inspectors directory for anyone who
    // registered themselves.
    String? email;
    String? password;
    String? name;

    final hardcoded = _employeeCredentials[id];
    if (hardcoded != null) {
      if (hardcoded.pin != pin) {
        setState(() { _loading = false; _error = 'Invalid Employee ID or PIN.'; });
        _pinController.clear();
        return;
      }
      email    = hardcoded.email;
      password = hardcoded.password;
      name     = 'Dev Inspector';
    } else {
      final doc =
          await FirebaseFirestore.instance.collection('inspectors').doc(id).get();
      final data = doc.data();
      if (data == null || data['PIN'] != pin) {
        setState(() { _loading = false; _error = 'Invalid Employee ID or PIN.'; });
        _pinController.clear();
        return;
      }
      email    = data['FB-EML'] as String;
      password = pin;
      name     = data['INS-NM'] as String? ?? 'Inspector';
    }

    try {
      UserCredential cred;
      try {
        cred = await FirebaseAuth.instance.signInWithEmailAndPassword(
            email: email, password: password);
      } on FirebaseAuthException catch (e) {
        if (e.code == 'user-not-found' || e.code == 'invalid-credential') {
          cred = await FirebaseAuth.instance.createUserWithEmailAndPassword(
              email: email, password: password);
        } else {
          rethrow;
        }
      }

      await FirebaseFirestore.instance.collection('users').doc(cred.user!.uid).set({
        'role':    'inspector',
        'CST-NM':  name,
        'EMP-ID':  id,
        'RWD-NCB': 0,
        'SUID-LNK': [],
        'LCS-RTN':  [],
      }, SetOptions(merge: true));

      // _AuthGate reactively swaps to InspectorShell underneath this pushed
      // route once authStateChanges fires — but this screen is still ON TOP
      // of it in the nav stack, so it has to pop itself to reveal it.
      if (mounted) Navigator.of(context).pop();
    } catch (e) {
      if (mounted) setState(() => _error = 'Punch in failed: $e');
    } finally {
      if (mounted) setState(() => _loading = false);
      _pinController.clear();
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
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('PUNCH IN.',
                    style: GoogleFonts.bebasNeue(
                        fontSize: 34, color: c.text, letterSpacing: 2)),
                const SizedBox(height: 6),
                Text('Nike ReRun Hub · Berlin',
                    style: GoogleFonts.nunito(fontSize: 13, color: c.sub)),
                const SizedBox(height: 32),

                Text('EMPLOYEE ID', style: _fieldLabel(c)),
                const SizedBox(height: 8),
                TextField(
                  controller: _idController,
                  focusNode: _idFocus,
                  autofocus: true,
                  textAlign: TextAlign.center,
                  textCapitalization: TextCapitalization.characters,
                  textInputAction: TextInputAction.next,
                  onSubmitted: (_) => _pinFocus.requestFocus(),
                  style: GoogleFonts.bebasNeue(
                      fontSize: 22, color: c.text, letterSpacing: 2),
                  decoration: InputDecoration(
                    hintText: 'INS-1001',
                    hintStyle: GoogleFonts.bebasNeue(
                        fontSize: 22, color: c.sub, letterSpacing: 2),
                    filled: true,
                    fillColor: c.card2,
                    contentPadding: const EdgeInsets.symmetric(vertical: 14),
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
                  ),
                ),

                const SizedBox(height: 24),
                Text('PIN', style: _fieldLabel(c)),
                const SizedBox(height: 8),
                TextField(
                  controller: _pinController,
                  focusNode: _pinFocus,
                  obscureText: true,
                  obscuringCharacter: '●',
                  textAlign: TextAlign.center,
                  keyboardType: TextInputType.number,
                  textInputAction: TextInputAction.done,
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly,
                    LengthLimitingTextInputFormatter(_pinLength),
                  ],
                  onChanged: (_) => setState(() => _error = null),
                  onSubmitted: (_) => _loading ? null : _punchIn(),
                  style: GoogleFonts.bebasNeue(
                      fontSize: 26, color: c.text, letterSpacing: 10),
                  decoration: InputDecoration(
                    counterText: '',
                    filled: true,
                    fillColor: c.card2,
                    contentPadding: const EdgeInsets.symmetric(vertical: 14),
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
                  ),
                ),

                if (_error != null) ...[
                  const SizedBox(height: 16),
                  Text(_error!,
                      style: GoogleFonts.nunito(fontSize: 12, color: Colors.redAccent)),
                ],

                const SizedBox(height: 24),
                _keypad(c),

                const SizedBox(height: 24),
                Row(
                  children: [
                    Expanded(
                      flex: 3,
                      child: GestureDetector(
                        onTap: _loading ? null : _punchIn,
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
                              : Text(
                                  'Punch In.',
                                  style: GoogleFonts.nunito(
                                    fontSize: 16,
                                    color: _isDark ? c.text : c.bg,
                                    fontWeight: FontWeight.w900,
                                    letterSpacing: 0.5,
                                  ),
                                ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      flex: 2,
                      child: GestureDetector(
                        onTap: _loading
                            ? null
                            : () => Navigator.of(context).push(MaterialPageRoute(
                                builder: (_) => const InspectorRegisterScreen())),
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: c.border),
                          ),
                          child: Text(
                            'Register.',
                            style: GoogleFonts.nunito(
                              fontSize: 14,
                              color: c.sub,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  TextStyle _fieldLabel(NikeColors c) => GoogleFonts.nunito(
      fontSize: 11, color: c.sub, fontWeight: FontWeight.w700, letterSpacing: 1);

  Widget _keypad(NikeColors c) {
    const layout = [
      ['1', '2', '3'],
      ['4', '5', '6'],
      ['7', '8', '9'],
      ['', '0', '⌫'],
    ];
    return Column(
      children: layout.map((row) {
        return Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: row.map((key) {
              if (key.isEmpty) return const SizedBox(width: 64, height: 56);
              final isBackspace = key == '⌫';
              return GestureDetector(
                onTap: () => isBackspace ? _backspace() : _tapDigit(key),
                child: Container(
                  width: 64,
                  height: 56,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: c.border),
                  ),
                  child: isBackspace
                      ? Icon(Icons.backspace_outlined, color: c.sub, size: 18)
                      : Text(key,
                          style: GoogleFonts.bebasNeue(fontSize: 22, color: c.text)),
                ),
              );
            }).toList(),
          ),
        );
      }).toList(),
    );
  }
}
