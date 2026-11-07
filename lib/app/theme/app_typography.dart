import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'app_colors.dart';

/// Plus Jakarta Sans for headings, matching the geometric headline voice on
/// alueducation.com. IBM Plex Sans for body: drawn for technical interfaces
/// and holds up at 13px on mid-range Android screens.
class AppType {
  const AppType._();

  static TextStyle display({Color? color}) => GoogleFonts.plusJakartaSans(
        fontSize: 30,
        fontWeight: FontWeight.w800,
        height: 1.12,
        letterSpacing: -0.8,
        color: color ?? AppColors.ink,
      );

  static TextStyle headline({Color? color}) => GoogleFonts.plusJakartaSans(
        fontSize: 22,
        fontWeight: FontWeight.w700,
        height: 1.2,
        letterSpacing: -0.5,
        color: color ?? AppColors.ink,
      );

  static TextStyle title({Color? color}) => GoogleFonts.plusJakartaSans(
        fontSize: 17,
        fontWeight: FontWeight.w700,
        height: 1.3,
        letterSpacing: -0.3,
        color: color ?? AppColors.ink,
      );

  static TextStyle subtitle({Color? color}) => GoogleFonts.plusJakartaSans(
        fontSize: 15,
        fontWeight: FontWeight.w600,
        height: 1.35,
        letterSpacing: -0.2,
        color: color ?? AppColors.ink,
      );

  static TextStyle body({Color? color}) => GoogleFonts.ibmPlexSans(
        fontSize: 15,
        fontWeight: FontWeight.w400,
        height: 1.5,
        color: color ?? AppColors.ink,
      );

  static TextStyle bodyStrong({Color? color}) => GoogleFonts.ibmPlexSans(
        fontSize: 15,
        fontWeight: FontWeight.w600,
        height: 1.4,
        color: color ?? AppColors.ink,
      );

  static TextStyle small({Color? color}) => GoogleFonts.ibmPlexSans(
        fontSize: 13,
        fontWeight: FontWeight.w400,
        height: 1.45,
        color: color ?? AppColors.inkMuted,
      );

  static TextStyle smallStrong({Color? color}) => GoogleFonts.ibmPlexSans(
        fontSize: 13,
        fontWeight: FontWeight.w600,
        height: 1.35,
        color: color ?? AppColors.ink,
      );

  static TextStyle caption({Color? color}) => GoogleFonts.ibmPlexSans(
        fontSize: 11.5,
        fontWeight: FontWeight.w500,
        height: 1.3,
        letterSpacing: 0.1,
        color: color ?? AppColors.inkFaint,
      );

  /// Only used for incident reference codes, which people read aloud.
  static TextStyle code({Color? color}) => GoogleFonts.ibmPlexMono(
        fontSize: 12,
        fontWeight: FontWeight.w500,
        letterSpacing: 0.3,
        color: color ?? AppColors.inkMuted,
      );

  static TextStyle button() => GoogleFonts.plusJakartaSans(
        fontSize: 15,
        fontWeight: FontWeight.w700,
        letterSpacing: -0.1,
      );
}
