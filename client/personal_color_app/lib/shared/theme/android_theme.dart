import 'package:flutter/material.dart';

/// Android版パーソナルカラー診断アプリのMaterial Design 3テーマ
/// Google Material Design Guidelines準拠
class AndroidTheme {
  // Personal Color Pink をシードカラーとしたカラーパレット
  static const Color seedColor = Color(0xFFF48FB1); // Personal Color Pink
  static const Color yellowBaseAccent = Color(0xFFFFC107); // Amber
  static const Color blueBaseAccent = Color(0xFF2196F3); // Blue
  
  /// Material Design 3 ライトテーマ
  static ThemeData get lightTheme {
    final ColorScheme lightColorScheme = ColorScheme.fromSeed(
      seedColor: seedColor,
      brightness: Brightness.light,
    );
    
    return ThemeData(
      useMaterial3: true,
      colorScheme: lightColorScheme,
      
      // Typography - Material Design 3準拠
      textTheme: TextTheme(
        displayLarge: const TextStyle(
          fontSize: 57,
          fontWeight: FontWeight.w400,
          letterSpacing: -0.25,
        ),
        displayMedium: const TextStyle(
          fontSize: 45,
          fontWeight: FontWeight.w400,
          letterSpacing: 0,
        ),
        displaySmall: const TextStyle(
          fontSize: 36,
          fontWeight: FontWeight.w400,
          letterSpacing: 0,
        ),
        headlineLarge: const TextStyle(
          fontSize: 32,
          fontWeight: FontWeight.w400,
          letterSpacing: 0,
        ),
        headlineMedium: const TextStyle(
          fontSize: 28,
          fontWeight: FontWeight.w400,
          letterSpacing: 0,
        ),
        headlineSmall: const TextStyle(
          fontSize: 24,
          fontWeight: FontWeight.w400,
          letterSpacing: 0,
        ),
        titleLarge: const TextStyle(
          fontSize: 22,
          fontWeight: FontWeight.w400,
          letterSpacing: 0,
        ),
        titleMedium: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w500,
          letterSpacing: 0.15,
        ),
        titleSmall: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w500,
          letterSpacing: 0.1,
        ),
        bodyLarge: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w400,
          letterSpacing: 0.5,
        ),
        bodyMedium: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w400,
          letterSpacing: 0.25,
        ),
        bodySmall: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w400,
          letterSpacing: 0.4,
        ),
        labelLarge: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w500,
          letterSpacing: 0.1,
        ),
        labelMedium: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w500,
          letterSpacing: 0.5,
        ),
        labelSmall: const TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w500,
          letterSpacing: 0.5,
        ),
      ),
      
      // AppBar - Material 3 準拠
      appBarTheme: AppBarTheme(
        centerTitle: false, // Android標準は左寄せ
        elevation: 0,
        scrolledUnderElevation: 3,
        backgroundColor: lightColorScheme.surface,
        surfaceTintColor: lightColorScheme.surfaceTint,
        foregroundColor: lightColorScheme.onSurface,
        titleTextStyle: TextStyle(
          fontSize: 22,
          fontWeight: FontWeight.w400,
          color: lightColorScheme.onSurface,
          letterSpacing: 0,
        ),
        iconTheme: IconThemeData(
          color: lightColorScheme.onSurface,
          size: 24,
        ),
      ),
      
      // FloatingActionButton - 撮影ボタン用
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: lightColorScheme.primaryContainer,
        foregroundColor: lightColorScheme.onPrimaryContainer,
        elevation: 6,
        focusElevation: 8,
        hoverElevation: 8,
        highlightElevation: 12,
        shape: const CircleBorder(),
        sizeConstraints: const BoxConstraints.tightFor(
          width: 56,
          height: 56,
        ),
        smallSizeConstraints: const BoxConstraints.tightFor(
          width: 40,
          height: 40,
        ),
        largeSizeConstraints: const BoxConstraints.tightFor(
          width: 96,
          height: 96,
        ),
        extendedSizeConstraints: const BoxConstraints.tightFor(
          height: 56,
        ),
      ),
      
      // Card - 結果表示用
      cardTheme: CardThemeData(
        elevation: 1,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        clipBehavior: Clip.hardEdge,
        color: lightColorScheme.surface,
        surfaceTintColor: lightColorScheme.surfaceTint,
      ),
      
      // FilledButton - 主要アクション用
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          minimumSize: const Size(64, 48),
          maximumSize: const Size(double.infinity, 48),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
        ),
      ),
      
      // OutlinedButton - 副次アクション用
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          minimumSize: const Size(64, 48),
          maximumSize: const Size(double.infinity, 48),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
        ),
      ),
      
      // TextButton
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          minimumSize: const Size(64, 48),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
        ),
      ),
      
      // IconButton
      iconButtonTheme: IconButtonThemeData(
        style: IconButton.styleFrom(
          minimumSize: const Size(48, 48),
          iconSize: 24,
        ),
      ),
      
      // Chip - 信頼度表示用
      chipTheme: ChipThemeData(
        side: BorderSide.none,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        labelStyle: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w500,
          color: lightColorScheme.onSecondaryContainer,
        ),
        backgroundColor: lightColorScheme.secondaryContainer,
        deleteIconColor: lightColorScheme.onSecondaryContainer,
        selectedColor: lightColorScheme.secondaryContainer,
        secondarySelectedColor: lightColorScheme.tertiary,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        labelPadding: const EdgeInsets.symmetric(horizontal: 4),
      ),
      
      // Dialog
      dialogTheme: DialogThemeData(
        elevation: 6,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(28),
        ),
        backgroundColor: lightColorScheme.surface,
        surfaceTintColor: lightColorScheme.surfaceTint,
        titleTextStyle: TextStyle(
          fontSize: 24,
          fontWeight: FontWeight.w400,
          color: lightColorScheme.onSurface,
        ),
        contentTextStyle: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w400,
          color: lightColorScheme.onSurfaceVariant,
          letterSpacing: 0.25,
        ),
      ),
      
      // SnackBar
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(4),
        ),
        backgroundColor: lightColorScheme.inverseSurface,
        contentTextStyle: TextStyle(
          fontSize: 14,
          color: lightColorScheme.onInverseSurface,
        ),
        actionTextColor: lightColorScheme.inversePrimary,
      ),
      
      // ProgressIndicator
      progressIndicatorTheme: ProgressIndicatorThemeData(
        color: lightColorScheme.primary,
        circularTrackColor: lightColorScheme.outline.withValues(alpha: 0.2),
        linearTrackColor: lightColorScheme.outline.withValues(alpha: 0.2),
      ),
      
      // NavigationBar (将来拡張用)
      navigationBarTheme: NavigationBarThemeData(
        height: 80,
        elevation: 3,
        backgroundColor: lightColorScheme.surface,
        surfaceTintColor: lightColorScheme.surfaceTint,
        indicatorColor: lightColorScheme.secondaryContainer,
        indicatorShape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        labelTextStyle: WidgetStateTextStyle.resolveWith((states) {
          return TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: states.contains(WidgetState.selected)
                ? lightColorScheme.onSurface
                : lightColorScheme.onSurfaceVariant,
          );
        }),
        iconTheme: WidgetStateProperty.resolveWith((states) {
          return IconThemeData(
            size: 24,
            color: states.contains(WidgetState.selected)
                ? lightColorScheme.onSecondaryContainer
                : lightColorScheme.onSurfaceVariant,
          );
        }),
      ),
    );
  }
  
  /// Material Design 3 ダークテーマ
  static ThemeData get darkTheme {
    final ColorScheme darkColorScheme = ColorScheme.fromSeed(
      seedColor: seedColor,
      brightness: Brightness.dark,
    );
    
    return lightTheme.copyWith(
      colorScheme: darkColorScheme,
      appBarTheme: lightTheme.appBarTheme.copyWith(
        backgroundColor: darkColorScheme.surface,
        surfaceTintColor: darkColorScheme.surfaceTint,
        foregroundColor: darkColorScheme.onSurface,
        titleTextStyle: TextStyle(
          fontSize: 22,
          fontWeight: FontWeight.w400,
          color: darkColorScheme.onSurface,
          letterSpacing: 0,
        ),
        iconTheme: IconThemeData(
          color: darkColorScheme.onSurface,
          size: 24,
        ),
      ),
      cardTheme: CardThemeData(
        elevation: 1,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        clipBehavior: Clip.hardEdge,
        color: darkColorScheme.surface,
        surfaceTintColor: darkColorScheme.surfaceTint,
      ),
      dialogTheme: DialogThemeData(
        elevation: 6,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(28),
        ),
        backgroundColor: darkColorScheme.surface,
        surfaceTintColor: darkColorScheme.surfaceTint,
        titleTextStyle: TextStyle(
          fontSize: 24,
          fontWeight: FontWeight.w400,
          color: darkColorScheme.onSurface,
        ),
        contentTextStyle: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w400,
          color: darkColorScheme.onSurfaceVariant,
          letterSpacing: 0.25,
        ),
      ),
      snackBarTheme: lightTheme.snackBarTheme.copyWith(
        backgroundColor: darkColorScheme.inverseSurface,
        contentTextStyle: TextStyle(
          fontSize: 14,
          color: darkColorScheme.onInverseSurface,
        ),
        actionTextColor: darkColorScheme.inversePrimary,
      ),
    );
  }
}

/// Android Material Design 3 固有の定数
class AndroidConstants {
  // Material Motion - Standard Easing
  static const Curve standardCurve = Curves.easeInOutCubicEmphasized;
  static const Curve accelerateCurve = Curves.easeInCubic;
  static const Curve decelerateCurve = Curves.easeOutCubic;
  
  // Material Motion - Duration
  static const Duration shortDuration = Duration(milliseconds: 150);
  static const Duration mediumDuration = Duration(milliseconds: 300);
  static const Duration longDuration = Duration(milliseconds: 500);
  
  // Elevation
  static const double elevationLevel0 = 0;
  static const double elevationLevel1 = 1;
  static const double elevationLevel2 = 3;
  static const double elevationLevel3 = 6;
  static const double elevationLevel4 = 8;
  static const double elevationLevel5 = 12;
  
  // Corner Radius
  static const double cornerXS = 4;
  static const double cornerS = 8;
  static const double cornerM = 12;
  static const double cornerL = 16;
  static const double cornerXL = 28;
  
  // Spacing
  static const double spaceXS = 4;
  static const double spaceS = 8;
  static const double spaceM = 16;
  static const double spaceL = 24;
  static const double spaceXL = 32;
  static const double spaceXXL = 40;
  static const double spaceXXXL = 48;
  
  // Touch Target Size (Android Accessibility Guidelines)
  static const double touchTargetSize = 48;
  static const double minTouchTargetSize = 44;
}

/// パーソナルカラー診断結果用のMaterial Design 3カラー拡張
class PersonalColorExtension extends ThemeExtension<PersonalColorExtension> {
  final Color yellowBaseContainer;
  final Color onYellowBaseContainer;
  final Color blueBaseContainer;
  final Color onBlueBaseContainer;
  
  const PersonalColorExtension({
    required this.yellowBaseContainer,
    required this.onYellowBaseContainer,
    required this.blueBaseContainer,
    required this.onBlueBaseContainer,
  });
  
  static PersonalColorExtension light = PersonalColorExtension(
    yellowBaseContainer: const Color(0xFFFFF8E1),
    onYellowBaseContainer: const Color(0xFF8A5A00),
    blueBaseContainer: const Color(0xFFE3F2FD),
    onBlueBaseContainer: const Color(0xFF0D47A1),
  );
  
  static PersonalColorExtension dark = PersonalColorExtension(
    yellowBaseContainer: const Color(0xFF3E2723),
    onYellowBaseContainer: const Color(0xFFFFE0B2),
    blueBaseContainer: const Color(0xFF1A237E),
    onBlueBaseContainer: const Color(0xFFBBDEFB),
  );
  
  @override
  PersonalColorExtension copyWith({
    Color? yellowBaseContainer,
    Color? onYellowBaseContainer,
    Color? blueBaseContainer,
    Color? onBlueBaseContainer,
  }) {
    return PersonalColorExtension(
      yellowBaseContainer: yellowBaseContainer ?? this.yellowBaseContainer,
      onYellowBaseContainer: onYellowBaseContainer ?? this.onYellowBaseContainer,
      blueBaseContainer: blueBaseContainer ?? this.blueBaseContainer,
      onBlueBaseContainer: onBlueBaseContainer ?? this.onBlueBaseContainer,
    );
  }
  
  @override
  PersonalColorExtension lerp(PersonalColorExtension? other, double t) {
    if (other is! PersonalColorExtension) {
      return this;
    }
    return PersonalColorExtension(
      yellowBaseContainer: Color.lerp(yellowBaseContainer, other.yellowBaseContainer, t)!,
      onYellowBaseContainer: Color.lerp(onYellowBaseContainer, other.onYellowBaseContainer, t)!,
      blueBaseContainer: Color.lerp(blueBaseContainer, other.blueBaseContainer, t)!,
      onBlueBaseContainer: Color.lerp(onBlueBaseContainer, other.onBlueBaseContainer, t)!,
    );
  }
}