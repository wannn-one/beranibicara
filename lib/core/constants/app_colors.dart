import 'package:flutter/material.dart';

/// App-wide color constants
class AppColors {
  AppColors._(); // Private constructor to prevent instantiation

  // Primary Colors
  static const Color primary = Color(0xFF36A395); // Teal
  static const Color primaryDark = Color(0xFF2A8179);
  static const Color primaryLight = Color(0xFF4DB8AA);

  // Secondary Colors
  static const Color secondary = Color(0xFFF9C0C0); // Pink
  static const Color secondaryDark = Color(0xFFE8AEAE);
  static const Color secondaryLight = Color(0xFFFFD6D6);

  // Neutral Colors
  static const Color white = Color(0xFFFFFFFF);
  static const Color black = Color(0xFF000000);
  static const Color grey = Color(0xFF9E9E9E);
  static const Color greyLight = Color(0xFFE0E0E0);
  static const Color greyDark = Color(0xFF424242);

  // Status Colors
  static const Color success = Color(0xFF4CAF50);
  static const Color error = Color(0xFFF44336);
  static const Color warning = Color(0xFFFF9800);
  static const Color info = Color(0xFF2196F3);

  // Report Status Colors
  static const Color statusNew = Color(0xFF2196F3); // Blue - baru
  static const Color statusProcessing = Color(0xFFFF9800); // Orange - diproses
  static const Color statusCompleted = Color(0xFF4CAF50); // Green - selesai
  static const Color statusRejected = Color(0xFFF44336); // Red - ditolak
  static const Color statusSpam = Color(0xFF9E9E9E); // Grey - spam

  // Background Colors
  static const Color background = Color(0xFFF5F5F5);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color cardBackground = Color(0xFFFFFFFF);

  // Text Colors
  static const Color textPrimary = Color(0xFF212121);
  static const Color textSecondary = Color(0xFF757575);
  static const Color textHint = Color(0xFFBDBDBD);
  static const Color textOnPrimary = Color(0xFFFFFFFF);

  // Border Colors
  static const Color border = Color(0xFFE0E0E0);
  static const Color divider = Color(0xFFBDBDBD);

  // Role-based Colors
  static const Color roleSiswa = Color(0xFF2196F3); // Blue
  static const Color roleGuru = Color(0xFF4CAF50); // Green
  static const Color roleTPPK = Color(0xFFFF9800); // Orange
  static const Color roleAdmin = Color(0xFFF44336); // Red

  // Social Sign-In Colors
  static const Color google = Color(0xFFDB4437);
  static const Color googleBackground = Color(0xFFFFFFFF);
}
