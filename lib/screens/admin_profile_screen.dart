import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Colours
// ─────────────────────────────────────────────────────────────────────────────
const _black  = Color(0xFF111111);
const _card   = Color(0xFF1A1A1A);
const _lime   = Color(0xFFCDFC49);
const _white  = Color(0xFFFFFFFF);
const _grey   = Color(0xFF888888);
const _border = Color(0xFF2A2A2A);

TextStyle _heading(double size, {Color color = _white}) =>
    GoogleFonts.bebasNeue(fontSize: size, color: color, letterSpacing: 1.5);
TextStyle _body(double size, {Color color = _white}) =>
    GoogleFonts.nunito(fontSize: size, color: color);

// ─────────────────────────────────────────────────────────────────────────────
// Screen
// ─────────────────────────────────────────────────────────────────────────────

class AdminProfileScreen extends StatelessWidget {
  const AdminProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final user     = FirebaseAuth.instance.currentUser;
    final name     = user?.displayName ??
        user?.email?.split('@').first ??
        'Admin';
    final email    = user?.email ?? '';
    final initials = name.trim().isNotEmpty
        ? name.trim()[0].toUpperCase()
        : 'A';

    return Scaffold(
      backgroundColor: _black,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(24, 40, 24, 110),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [

              // ── Avatar ──────────────────────────────────────────────────
              Container(
                width: 88,
                height: 88,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  color: _lime,
                ),
                child: Center(
                  child: Text(initials, style: _heading(40, color: _black)),
                ),
              )
                  .animate()
                  .scale(
                    begin: const Offset(0.5, 0.5),
                    duration: 500.ms,
                    curve: Curves.elasticOut,
                  ),

              const SizedBox(height: 16),

              Text(name.toUpperCase(), style: _heading(30))
                  .animate()
                  .fadeIn(delay: 200.ms, duration: 400.ms)
                  .slideY(begin: 0.2, end: 0, delay: 200.ms, duration: 400.ms),

              const SizedBox(height: 4),

              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                decoration: BoxDecoration(
                  color: _lime.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: _lime.withOpacity(0.4)),
                ),
                child: Text('Nike Admin', style: _body(12, color: _lime)
                    .copyWith(fontWeight: FontWeight.w700)),
              )
                  .animate()
                  .fadeIn(delay: 300.ms, duration: 400.ms),

              const SizedBox(height: 6),

              Text(email, style: _body(13, color: _grey))
                  .animate()
                  .fadeIn(delay: 350.ms, duration: 400.ms),

              const SizedBox(height: 40),

              // ── Info card ────────────────────────────────────────────────
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: _card,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: _border),
                ),
                child: Column(
                  children: [
                    const Icon(Icons.admin_panel_settings_outlined,
                        color: _lime, size: 36),
                    const SizedBox(height: 12),
                    Text('NIKE ADMIN', style: _heading(22, color: _lime)),
                    const SizedBox(height: 8),
                    Text(
                      'Total users · Total returns · App stats\nFull profile coming next.',
                      style: _body(14, color: _grey),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              )
                  .animate()
                  .fadeIn(delay: 450.ms, duration: 400.ms)
                  .slideY(begin: 0.1, end: 0, delay: 450.ms, duration: 400.ms),

              const SizedBox(height: 32),

              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: () => FirebaseAuth.instance.signOut(),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: _border),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                  child: Text(
                    'Sign Out',
                    style: _body(15, color: _grey)
                        .copyWith(fontWeight: FontWeight.w700),
                  ),
                ),
              )
                  .animate()
                  .fadeIn(delay: 550.ms, duration: 400.ms),
            ],
          ),
        ),
      ),
    );
  }
}
