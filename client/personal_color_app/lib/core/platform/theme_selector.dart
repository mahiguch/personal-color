import 'dart:io';
import 'package:flutter/material.dart';
import '../../shared/theme/app_theme.dart';
import '../../shared/theme/android_theme.dart';

/// プラットフォームに応じたテーマ選択クラス
class ThemeSelector {
  /// 現在のプラットフォーム用のライトテーマを取得
  static ThemeData getLightTheme() {
    if (Platform.isAndroid) {
      return AndroidTheme.lightTheme.copyWith(
        extensions: [
          PersonalColorExtension.light,
        ],
      );
    } else if (Platform.isIOS) {
      return AppTheme.lightTheme;
    }
    
    // フォールバック: デフォルトMaterial Design 3テーマ
    return ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
    );
  }
  
  /// 現在のプラットフォーム用のダークテーマを取得
  static ThemeData getDarkTheme() {
    if (Platform.isAndroid) {
      return AndroidTheme.darkTheme.copyWith(
        extensions: [
          PersonalColorExtension.dark,
        ],
      );
    } else if (Platform.isIOS) {
      // iOS版でもダークテーマが実装されている場合は対応
      return AppTheme.lightTheme; // 現在はライトテーマのみ
    }
    
    // フォールバック: デフォルトMaterial Design 3ダークテーマ
    return ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: Colors.blue,
        brightness: Brightness.dark,
      ),
    );
  }
  
  /// システム設定に基づいてテーマモードを決定
  static ThemeMode getThemeMode() {
    // 現在はシステム設定に従う
    return ThemeMode.system;
  }
  
  /// プラットフォーム固有のテーマ拡張を取得
  static T? getThemeExtension<T extends ThemeExtension<T>>(BuildContext context) {
    return Theme.of(context).extension<T>();
  }
  
  /// パーソナルカラー結果用の色を取得
  static Color getPersonalColorContainer(BuildContext context, bool isYellowBase) {
    if (Platform.isAndroid) {
      final extension = getThemeExtension<PersonalColorExtension>(context);
      if (extension != null) {
        return isYellowBase 
            ? extension.yellowBaseContainer
            : extension.blueBaseContainer;
      }
    }
    
    // フォールバック: 既存のiOS版カラー使用
    return isYellowBase 
        ? AppTheme.yellowBaseColor
        : AppTheme.blueBaseColor;
  }
  
  /// パーソナルカラー結果用のテキスト色を取得
  static Color getPersonalColorOnContainer(BuildContext context, bool isYellowBase) {
    if (Platform.isAndroid) {
      final extension = getThemeExtension<PersonalColorExtension>(context);
      if (extension != null) {
        return isYellowBase 
            ? extension.onYellowBaseContainer
            : extension.onBlueBaseContainer;
      }
    }
    
    // フォールバック: 既存のiOS版カラー使用
    return AppTheme.textPrimary;
  }
  
  /// プラットフォーム固有のアニメーション設定を取得
  static Duration getAnimationDuration({bool isShort = false, bool isLong = false}) {
    if (Platform.isAndroid) {
      if (isShort) return AndroidConstants.shortDuration;
      if (isLong) return AndroidConstants.longDuration;
      return AndroidConstants.mediumDuration;
    } else if (Platform.isIOS) {
      if (isShort) return AppConstants.fastAnimation;
      if (isLong) return AppConstants.slowAnimation;
      return AppConstants.animationDuration;
    }
    
    // フォールバック
    return const Duration(milliseconds: 300);
  }
  
  /// プラットフォーム固有のアニメーションカーブを取得
  static Curve getAnimationCurve({bool isAccelerate = false, bool isDecelerate = false}) {
    if (Platform.isAndroid) {
      if (isAccelerate) return AndroidConstants.accelerateCurve;
      if (isDecelerate) return AndroidConstants.decelerateCurve;
      return AndroidConstants.standardCurve;
    }
    
    // フォールバック: 標準的なcurve
    return Curves.easeInOut;
  }
}