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
    bg:     Color(0xFFFFFFFF),
    card:   Color(0xFFF2F2F2),
    card2:  Color(0xFFE5E5E5),
    text:   Color(0xFF111111),
    sub:    Color(0xFF555555),
    border: Color(0xFFDDDDDD),
    accent: Color(0xFF1A1A1A), // near-black — no glow in light mode
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
