import 'package:flutter/material.dart';

abstract final class AppColors {
  /// Seed colour for the Material 3 colour scheme (brand blue).
  static const Color seed = Color(0xFF075CE6);

  /// Brand teal/green — from the BillSplit logo's right half.
  static const Color brandTeal = Color(0xFF00CDA4);

  /// Brand blue — from the BillSplit logo's left half.
  static const Color brandBlue = Color(0xFF075CE6);

  /// Brand navy — from the BillSplit logo's receipt/text accent.
  static const Color brandNavy = Color(0xFF011B44);

  /// Used for amounts a friend owes the user.
  static const Color positiveAmount = Color(0xFF2E7D32);

  /// Used for amounts the user owes a friend.
  static const Color negativeAmount = Color(0xFFC62828);

  /// Non-blocking warnings, e.g. items not matching the printed subtotal.
  static const Color warning = Color(0xFFB45309);

  // ---------------------------------------------------------------------
  // Light theme surface & text colours.
  // ---------------------------------------------------------------------

  static const Color lightBackground = Color(0xFFFAFAFD);
  static const Color lightSurface = Color(0xFFFFFFFF);
  static const Color lightSurfaceVariant = Color(0xFFF1F5F9);
  static const Color lightBorder = Color(0xFFE2E8F0);
  static const Color lightTextPrimary = Color(0xFF0F172A);
  static const Color lightTextSecondary = Color(0xFF64748B);
}
