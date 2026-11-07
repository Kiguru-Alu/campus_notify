import 'package:flutter/material.dart';

/// ALU navy carries structure and chrome. Red is reserved for actions that
/// commit something. Status colours are a separate scale so they never
/// compete with the brand.
class AppColors {
  const AppColors._();

  static const Color navy = Color(0xFF0A2A66);
  static const Color navyDeep = Color(0xFF061B45);
  static const Color navySoft = Color(0xFF1C458F);
  static const Color navyTint = Color(0xFFE9EDF6);

  static const Color red = Color(0xFFD0112B);
  static const Color redDark = Color(0xFFA30C21);
  static const Color redTint = Color(0xFFFBE7EA);

  static const Color ink = Color(0xFF14181F);
  static const Color inkMuted = Color(0xFF5A6472);
  static const Color inkFaint = Color(0xFF8D96A4);
  static const Color line = Color(0xFFDEE2E9);
  static const Color lineStrong = Color(0xFFC3CAD5);
  static const Color canvas = Color(0xFFF2F4F8);
  static const Color surface = Color(0xFFFFFFFF);

  static const Color submitted = Color(0xFF2E6BB8);
  static const Color submittedTint = Color(0xFFE6EFF9);
  static const Color inProgress = Color(0xFFB56A00);
  static const Color inProgressTint = Color(0xFFFBF0DD);
  static const Color resolved = Color(0xFF1F7A4D);
  static const Color resolvedTint = Color(0xFFE3F3EA);
  static const Color closed = Color(0xFF6B7480);
  static const Color closedTint = Color(0xFFEDEFF2);

  static const Color danger = Color(0xFFB3261E);
  static const Color dangerTint = Color(0xFFFBEAE9);
}
