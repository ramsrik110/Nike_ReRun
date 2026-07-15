import 'package:flutter/material.dart';

class NikeColors extends ThemeExtension<NikeColors> {
  final Color bg;
  final Color card;
  final Color card2;
  final Color text;
  final Color sub;
  final Color border;
  // accent = lime in dark mode, near-black in light mode.
  // Use for text/icon color only — never for background fills.
  final Color accent;

  static const lime  = Color(0xFFCDFC49);
  static const black = Color(0xFF111111);

  const NikeColors({
    required this.bg,
    required this.card,
    required this.card2,
    required this.text,
    required this.sub,
    required this.border,
    required this.accent,
  });

  static const dark = NikeColors(
    bg:     Color(0xFF111111),
    card:   Color(0xFF1A1A1A),
    card2:  Color(0xFF2A2A2A),
    text:   Color(0xFFFFFFFF),
    sub:    Color(0xFF888888),
    border: Color(0xFF2A2A2A),
    accent: Color(0xFFCDFC49), // lime
  );

  static const light = NikeColors(
    bg:     Color(0xFFF5F5F2), // soft off-white — pure white was too harsh
    card:   Color(0xFFECECE7),
    card2:  Color(0xFFDFDEDA),
    text:   Color(0xFF111111),
    sub:    Color(0xFF555555),
    border: Color(0xFFD8D7D2),
    accent: Color(0xFF1A1A1A), // near-black — no glow in light mode
  );

  // Inspector-only flat themes. Factory-floor tool, not a consumer screen:
  // uniform tone for bg/card/card2 (no elevation, no color-jump cards),
  // separation comes from hairline borders only. Purely monochrome — no
  // lime, no accent hue — this persona doesn't need brand decoration, only
  // legibility over a long shift. "accent" here just equals text/near-text
  // so selected/CTA states read via inverted contrast, not color. Toggled
  // by its own `inspectorDarkMode` notifier, independent of the app-wide
  // dark/light switch used by Customer and Admin.
  static const inspectorDark = NikeColors(
    bg:     Color(0xFF1A1A1A),
    card:   Color(0xFF1A1A1A),
    card2:  Color(0xFF1A1A1A),
    text:   Color(0xFFEDEDED),
    sub:    Color(0xFF888888),
    border: Color(0xFF333333),
    accent: Color(0xFFEDEDED),
  );

  static const inspectorLight = NikeColors(
    bg:     Color(0xFFC7C4BC),
    card:   Color(0xFFC7C4BC),
    card2:  Color(0xFFC7C4BC),
    text:   Color(0xFF1C1C1A),
    sub:    Color(0xFF6B6960),
    border: Color(0xFFA8A59A),
    accent: Color(0xFF1C1C1A),
  );

  @override
  NikeColors copyWith({
    Color? bg,
    Color? card,
    Color? card2,
    Color? text,
    Color? sub,
    Color? border,
    Color? accent,
  }) =>
      NikeColors(
        bg:     bg     ?? this.bg,
        card:   card   ?? this.card,
        card2:  card2  ?? this.card2,
        text:   text   ?? this.text,
        sub:    sub    ?? this.sub,
        border: border ?? this.border,
        accent: accent ?? this.accent,
      );

  @override
  NikeColors lerp(NikeColors? other, double t) {
    if (other == null) return this;
    return NikeColors(
      bg:     Color.lerp(bg,     other.bg,     t)!,
      card:   Color.lerp(card,   other.card,   t)!,
      card2:  Color.lerp(card2,  other.card2,  t)!,
      text:   Color.lerp(text,   other.text,   t)!,
      sub:    Color.lerp(sub,    other.sub,    t)!,
      border: Color.lerp(border, other.border, t)!,
      accent: Color.lerp(accent, other.accent, t)!,
    );
  }
}

extension NikeColorsX on BuildContext {
  NikeColors get nc => Theme.of(this).extension<NikeColors>()!;
}
