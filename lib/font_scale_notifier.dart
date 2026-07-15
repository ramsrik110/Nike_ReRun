import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

// 5 steps — 100% up to 160% — for reading the app on a projector.
const fontScaleSteps = [1.0, 1.15, 1.3, 1.45, 1.6];

final fontScale = ValueNotifier<double>(1.0);

Future<void> loadFontScalePreference() async {
  final prefs = await SharedPreferences.getInstance();
  fontScale.value = prefs.getDouble('fontScale') ?? 1.0;
  fontScale.addListener(() async {
    final p = await SharedPreferences.getInstance();
    await p.setDouble('fontScale', fontScale.value);
  });
}
