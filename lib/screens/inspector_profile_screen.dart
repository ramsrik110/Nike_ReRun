import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../nike_colors.dart';
import '../theme_notifier.dart';

const _lime  = Color(0xFFCDFC49);
const _black = Color(0xFF111111);

class InspectorProfileScreen extends StatelessWidget {
  const InspectorProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final c        = context.nc;
    final user     = FirebaseAuth.instance.currentUser;
    final name     = user?.displayName ?? user?.email?.split('@').first ?? 'Inspector';
    final email    = user?.email ?? '';
    final initials = name.trim().isNotEmpty ? name.trim()[0].toUpperCase() : 'I';

    return Scaffold(
      backgroundColor: c.bg,
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
                  child: Text(initials,
                      style: GoogleFonts.bebasNeue(
                          fontSize: 40, color: _black, letterSpacing: 1.5)),
                ),
              )
                  .animate()
                  .scale(
                    begin: const Offset(0.5, 0.5),
                    duration: 500.ms,
                    curve: Curves.elasticOut,
                  ),

              const SizedBox(height: 16),

              Text(name.toUpperCase(),
                  style: GoogleFonts.bebasNeue(
                      fontSize: 30, color: c.text, letterSpacing: 1.5))
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
                child: Text('Hub Inspector',
                    style: GoogleFonts.nunito(
                        fontSize: 12, color: _lime,
                        fontWeight: FontWeight.w700)),
              )
                  .animate()
                  .fadeIn(delay: 300.ms, duration: 400.ms),

              const SizedBox(height: 6),

              Text(email, style: GoogleFonts.nunito(fontSize: 13, color: c.sub))
                  .animate()
                  .fadeIn(delay: 350.ms, duration: 400.ms),

              const SizedBox(height: 40),

              // ── Info card ────────────────────────────────────────────────
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: c.card,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: c.border),
                ),
                child: Column(
                  children: [
                    const Icon(Icons.factory_outlined, color: _lime, size: 36),
                    const SizedBox(height: 12),
                    Text('HUB INSPECTOR',
                        style: GoogleFonts.bebasNeue(
                            fontSize: 22, color: _lime, letterSpacing: 1.5)),
                    const SizedBox(height: 8),
                    Text(
                      'Hub assignment · Shoes processed\nFull profile coming next.',
                      style: GoogleFonts.nunito(fontSize: 14, color: c.sub),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              )
                  .animate()
                  .fadeIn(delay: 450.ms, duration: 400.ms)
                  .slideY(begin: 0.1, end: 0, delay: 450.ms, duration: 400.ms),

              const SizedBox(height: 32),

              // ── Appearance toggle ────────────────────────────────────────
              ValueListenableBuilder<bool>(
                valueListenable: isDarkMode,
                builder: (_, dark, __) => GestureDetector(
                  onTap: () => isDarkMode.value = !isDarkMode.value,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 18, vertical: 14),
                    decoration: BoxDecoration(
                      color: c.card,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: c.border),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          dark
                              ? Icons.light_mode_outlined
                              : Icons.dark_mode_outlined,
                          color: _lime, size: 22,
                        ),
                        const SizedBox(width: 14),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('APPEARANCE',
                                style: GoogleFonts.nunito(
                                    fontSize: 11, color: c.sub,
                                    letterSpacing: 1,
                                    fontWeight: FontWeight.w600)),
                            Text(dark ? 'Dark Mode' : 'Light Mode',
                                style: GoogleFonts.nunito(
                                    fontSize: 14, color: c.text,
                                    fontWeight: FontWeight.w700)),
                          ],
                        ),
                        const Spacer(),
                        Container(
                          width: 48, height: 26,
                          decoration: BoxDecoration(
                            color: dark ? _lime.withOpacity(0.2) : _lime,
                            borderRadius: BorderRadius.circular(13),
                            border: Border.all(color: _lime.withOpacity(0.6)),
                          ),
                          child: AnimatedAlign(
                            duration: const Duration(milliseconds: 200),
                            curve: Curves.easeOutCubic,
                            alignment: dark
                                ? Alignment.centerLeft
                                : Alignment.centerRight,
                            child: Container(
                              width: 20, height: 20,
                              margin: const EdgeInsets.symmetric(horizontal: 3),
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: dark ? c.sub : _black,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              )
                  .animate()
                  .fadeIn(delay: 500.ms, duration: 400.ms),

              const SizedBox(height: 16),

              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: () => FirebaseAuth.instance.signOut(),
                  style: OutlinedButton.styleFrom(
                    side: BorderSide(color: c.border),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                  child: Text(
                    'Sign Out',
                    style: GoogleFonts.nunito(
                        fontSize: 15, color: c.sub,
                        fontWeight: FontWeight.w700),
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
