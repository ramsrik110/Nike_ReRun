import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

final isDarkMode = ValueNotifier<bool>(true);

Future<void> loadThemePreference() async {
  final prefs = await SharedPreferences.getInstance();
  isDarkMode.value = prefs.getBool('isDark') ?? true;
  isDarkMode.addListener(() async {
    final p = await SharedPreferences.getInstance();
    await p.setBool('isDark', isDarkMode.value);
  });
}

// Inspector's own dark/light toggle — deliberately separate from [isDarkMode]
// so flipping it never affects the Customer or Admin personas.
final inspectorDarkMode = ValueNotifier<bool>(true);

Future<void> loadInspectorThemePreference() async {
  final prefs = await SharedPreferences.getInstance();
  inspectorDarkMode.value = prefs.getBool('isInspectorDark') ?? true;
  inspectorDarkMode.addListener(() async {
    final p = await SharedPreferences.getInstance();
    await p.setBool('isInspectorDark', inspectorDarkMode.value);
  });
}
