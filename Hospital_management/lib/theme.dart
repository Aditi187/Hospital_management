import 'package:flutter/material.dart';

class AppTheme {
  // 🌿 Modern hospital-friendly palette
  static const Color primary = Color(0xFF1976D2);       // Deep Blue
  static const Color primaryVariant = Color(0xFF42A5F5); // Light Blue
  static const Color primaryLight = Color(0xFFE3F2FD);  // Soft Sky Blue
  static const Color surface = Colors.white;
  static const Color onPrimary = Colors.white;
  static const Color muted = Color(0xFF6E7582);         // Neutral gray
  static const Color background = Color(0xFFF5F7FA);    // Light off-white
  static const Color success = Color(0xFF28A745);       // Green
  static const Color warning = Color(0xFFFFC107);       // Amber
  static const Color error = Color(0xFFDC3545);         // Red

  static const List<Color> primaryGradient = [primaryLight, primaryVariant];
  static const List<Color> premiumGradient = [primaryVariant, primary];

  static ThemeData themeData = ThemeData(
    brightness: Brightness.light,
    primaryColor: primary,
    scaffoldBackgroundColor: background,
    
    colorScheme: ColorScheme.fromSeed(
      seedColor: primary,
      primary: primary,
      secondary: primaryVariant,
      background: background,
      surface: surface,
      onPrimary: onPrimary,
    ),

    appBarTheme: const AppBarTheme(
      backgroundColor: primary,
      foregroundColor: onPrimary,
      elevation: 0,
      centerTitle: true,
      titleTextStyle: TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
    ),

    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: primary,
        foregroundColor: onPrimary,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        elevation: 6,
        shadowColor: primaryVariant.withOpacity(0.4),
      ),
    ),

    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: primaryVariant,
        textStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
      ),
    ),

    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: primary,
        side: BorderSide(color: primary.withOpacity(0.8)),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      ),
    ),

    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: surface,
      contentPadding: const EdgeInsets.all(16),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: muted.withOpacity(0.3)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: muted.withOpacity(0.3)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: primary, width: 2),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: error),
      ),
      labelStyle: TextStyle(color: muted),
      hintStyle: TextStyle(color: muted.withOpacity(0.7)),
    ),

    floatingActionButtonTheme: FloatingActionButtonThemeData(
      backgroundColor: primary,
      foregroundColor: onPrimary,
      elevation: 6,
    ),

    dividerTheme: DividerThemeData(
      color: muted.withOpacity(0.2),
      thickness: 1,
      space: 1,
    ),

    bottomNavigationBarTheme: BottomNavigationBarThemeData(
      backgroundColor: surface,
      selectedItemColor: primary,
      unselectedItemColor: muted,
      elevation: 6,
      type: BottomNavigationBarType.fixed,
    ),
  );

  // ===================== ANIMATED CARDS & BUTTONS =====================

  static Widget animatedGradientCard({required Widget child, double borderRadius = 20}) {
    return TweenAnimationBuilder<double>(
      duration: const Duration(milliseconds: 200),
      curve: Curves.easeOut,
      tween: Tween<double>(begin: 1, end: 1),
      builder: (context, scale, _) {
        return MouseRegion(
          cursor: SystemMouseCursors.click,
          onEnter: (_) => scale = 1.02,
          onExit: (_) => scale = 1,
          child: AnimatedScale(
            scale: scale,
            duration: const Duration(milliseconds: 200),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: primaryGradient,
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(borderRadius),
                boxShadow: [
                  BoxShadow(
                    color: primary.withOpacity(0.2),
                    blurRadius: 12,
                    offset: const Offset(0, 5),
                  ),
                ],
              ),
              child: child,
            ),
          ),
        );
      },
    );
  }

  static Widget animatedStatusBadge(String status) {
    final color = getStatusColor(status);
    return TweenAnimationBuilder<double>(
      duration: const Duration(milliseconds: 150),
      tween: Tween<double>(begin: 1, end: 1),
      builder: (context, scale, _) {
        return GestureDetector(
          onTapDown: (_) {},
          child: AnimatedScale(
            scale: scale,
            duration: const Duration(milliseconds: 150),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: color.withOpacity(0.3), width: 1.5),
              ),
              child: Text(
                status,
                style: TextStyle(color: color, fontWeight: FontWeight.w600),
              ),
            ),
          ),
        );
      },
    );
  }

  static Widget animatedButton({required String label, required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: TweenAnimationBuilder<double>(
        tween: Tween<double>(begin: 1, end: 1),
        duration: const Duration(milliseconds: 150),
        builder: (context, scale, child) {
          return AnimatedScale(
            scale: scale,
            duration: const Duration(milliseconds: 150),
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 24),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [primary, primaryVariant],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: primary.withOpacity(0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Text(
                label,
                textAlign: TextAlign.center,
                style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                    fontSize: 16),
              ),
            ),
          );
        },
      ),
    );
  }

  // ===================== STATUS COLORS =====================
  static Color getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'completed':
      case 'approved':
      case 'confirmed':
      case 'success':
        return success;
      case 'pending':
      case 'waiting':
      case 'scheduled':
        return warning;
      case 'emergency':
      case 'critical':
      case 'cancelled':
      case 'rejected':
        return error;
      case 'in progress':
      case 'processing':
      case 'active':
        return primaryVariant;
      default:
        return muted;
    }
  }
}
