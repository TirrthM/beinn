import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

// Global theme notifier
// True = Dark Mode (Default)
// False = Light Mode
final ValueNotifier<bool> isDarkModeNotifier = ValueNotifier<bool>(true);

// Initialize theme from SharedPreferences
Future<void> initTheme() async {
  final prefs = await SharedPreferences.getInstance();
  // Default to true (Dark Mode) if not set
  final isDark = prefs.getBool('isDarkMode') ?? true;
  isDarkModeNotifier.value = isDark;
}

// Update theme and save to SharedPreferences
Future<void> setTheme(bool isDark) async {
  isDarkModeNotifier.value = isDark;
  final prefs = await SharedPreferences.getInstance();
  await prefs.setBool('isDarkMode', isDark);
}
