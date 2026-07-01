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
