import 'package:flutter/material.dart';

const String kAllNotesFolderId = 'all_notes';

class AppColors {
  // Primary colors - refined teal palette for security/trust feel
  static const Color primary = Color(
    0xFF00897B,
  ); // Teal 600 - slightly brighter
  static const Color primaryDark = Color(0xFF00695C); // Teal 800
  static const Color primaryLight = Color(0xFF4DB6AC); // Teal 300
  static const Color accent = Color(0xFF26A69A); // Teal 400

  // Background colors - deeper, richer dark theme
  static const Color background = Color(0xFF1A2327); // Darker custom blueGrey
  static const Color scaffoldBackground = Color(0xFF1A2327);
  static const Color surfaceDark = Color(0xFF232D32); // Card/surface color
  static const Color surfaceLight = Color(0xFF2C3940); // Elevated surface

  // Standard colors
  static const Color white = Colors.white;
  static const Color red = Color(0xFFEF5350); // Red 400 - softer red
  static const Color grey = Colors.grey;
  static final Color grey600 = Colors.grey[600]!;
  static final Color grey400 = Colors.grey[400]!;
  static const Color black54 = Colors.black54;
  static const Color black45 = Colors.black45;
  static const Color transparent = Colors.transparent;
  static const Color shadow = Color(0x40000000); // Stronger shadow

  // BlueGrey palette - refined
  static const Color blueGrey800 = Color(0xFF37474F);
  static const Color blueGrey900 = Color(0xFF263238);
  static const Color blueGrey700 = Color(0xFF455A64);
  static const Color blueGrey600 = Color(0xFF546E7A);
  static final Color teal700 = Colors.teal[700]!;

  // Text colors
  static const Color textPrimary = Color(0xFFFAFAFA); // Almost white
  static const Color textSecondary = Color(0xFFB0BEC5); // BlueGrey 200
  static const Color textHint = Color(0xFF78909C); // BlueGrey 400

  // Status colors
  static const Color success = Color(0xFF66BB6A); // Green 400
  static const Color warning = Color(0xFFFFB74D); // Orange 300
  static const Color error = Color(0xFFEF5350); // Red 400

  // Gradient colors
  static const List<Color> primaryGradient = [
    Color(0xFF00897B),
    Color(0xFF00695C),
  ];

  static const List<Color> surfaceGradient = [
    Color(0xFF2C3940),
    Color(0xFF232D32),
  ];
}

/// Design utilities for consistent styling
class AppDecorations {
  // Card decoration with subtle border
  static BoxDecoration cardDecoration({
    Color? color,
    double borderRadius = 16,
    bool hasBorder = true,
    Color? borderColor,
  }) {
    return BoxDecoration(
      color: color ?? AppColors.surfaceDark,
      borderRadius: BorderRadius.circular(borderRadius),
      border: hasBorder
          ? Border.all(
              color:
                  borderColor ?? AppColors.blueGrey700.withValues(alpha: 0.3),
              width: 1,
            )
          : null,
      boxShadow: [
        BoxShadow(
          color: AppColors.shadow,
          blurRadius: 8,
          offset: const Offset(0, 2),
        ),
      ],
    );
  }

  // Gradient decoration for accent areas
  static BoxDecoration gradientDecoration({
    List<Color>? colors,
    double borderRadius = 16,
  }) {
    return BoxDecoration(
      gradient: LinearGradient(
        colors: colors ?? AppColors.primaryGradient,
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
      borderRadius: BorderRadius.circular(borderRadius),
      boxShadow: [
        BoxShadow(
          color: (colors?.first ?? AppColors.primary).withValues(alpha: 0.3),
          blurRadius: 12,
          offset: const Offset(0, 4),
        ),
      ],
    );
  }

  // Input decoration theme
  static InputDecoration inputDecoration({
    required String labelText,
    String? hintText,
    Widget? prefixIcon,
    Widget? suffixIcon,
  }) {
    return InputDecoration(
      labelText: labelText,
      hintText: hintText,
      prefixIcon: prefixIcon,
      suffixIcon: suffixIcon,
      filled: true,
      fillColor: AppColors.surfaceDark,
      labelStyle: const TextStyle(color: AppColors.textSecondary),
      hintStyle: const TextStyle(color: AppColors.textHint),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(
          color: AppColors.blueGrey700.withValues(alpha: 0.3),
        ),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(
          color: AppColors.blueGrey700.withValues(alpha: 0.3),
        ),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.primary, width: 2),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.error),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
    );
  }
}

class AppSizes {
  // Padding
  static const EdgeInsets pagePadding = EdgeInsets.fromLTRB(20, 12, 20, 20);
  static const EdgeInsets searchResultsPadding = EdgeInsets.fromLTRB(
    20,
    0,
    20,
    20,
  );
  static const EdgeInsets noteCardPadding = EdgeInsets.symmetric(
    horizontal: 12,
    vertical: 10,
  );
  static const EdgeInsets folderCardPadding = EdgeInsets.all(16);
  static const EdgeInsets zeroPadding = EdgeInsets.zero;

  // Spacing
  static const double space_4 = 4.0;
  static const double space_8 = 8.0;
  static const double space_12 = 12.0;
  static const double space_14 = 14.0;
  static const double space_16 = 16.0;
  static const double space_20 = 20.0;
  static const double space_24 = 24.0;

  // Border Radius
  static final BorderRadius radius_12 = BorderRadius.circular(12);
  static final BorderRadius radius_16 = BorderRadius.circular(16);
  static final BorderRadius radius_20 = BorderRadius.circular(20);
  static final BorderRadius radius_28 = BorderRadius.circular(28);

  // Icon Sizes
  static const double icon_20 = 20.0;
  static const double icon_32 = 32.0;

  // Font Sizes
  static const double font_12 = 12.0;
  static const double font_14 = 14.0;
  static const double font_16 = 16.0;
  static const double font_18 = 18.0;
  static const double font_20 = 20.0;
  static const double font_24 = 24.0;
  static const double font_28 = 28.0;

  // Elevations
  static const double elevation_0 = 0.0;

  // Other
  static const double noteCardAspectRatio = 1.6;
  static const double folderCardWidth = 140.0;
  static const double folderListHeight = 124.0;
}
