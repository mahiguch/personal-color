import 'package:equatable/equatable.dart';

/// 診断結果エンティティ
class DiagnosisResult extends Equatable {
  const DiagnosisResult({
    required this.diagnosisType,
    required this.confidence,
    required this.explanation,
    required this.recommendedColors,
    required this.avoidColors,
    required this.tips,
    this.requestId,
    this.processingTimeMs,
  });

  /// 診断されたパーソナルカラータイプ
  final PersonalColorType diagnosisType;

  /// 信頼度（0-100）
  final int confidence;

  /// 説明文
  final String explanation;

  /// おすすめの色
  final List<ColorRecommendation> recommendedColors;

  /// 避けた方が良い色
  final List<ColorRecommendation> avoidColors;

  /// アドバイス
  final String tips;

  /// リクエストID
  final String? requestId;

  /// 処理時間（ミリ秒）
  final int? processingTimeMs;

  @override
  List<Object?> get props => [
        diagnosisType,
        confidence,
        explanation,
        recommendedColors,
        avoidColors,
        tips,
        requestId,
        processingTimeMs,
      ];

  /// 高い信頼度かどうか（80%以上）
  bool get isHighConfidence => confidence >= 80;

  /// 中程度の信頼度かどうか（60-79%）
  bool get isMediumConfidence => confidence >= 60 && confidence < 80;

  /// 低い信頼度かどうか（60%未満）
  bool get isLowConfidence => confidence < 60;
}

/// パーソナルカラータイプ
enum PersonalColorType {
  spring,
  summer,
  autumn,
  winter,
}

extension PersonalColorTypeExtension on PersonalColorType {
  String get displayName {
    switch (this) {
      case PersonalColorType.spring:
        return 'スプリング（春）';
      case PersonalColorType.summer:
        return 'サマー（夏）';
      case PersonalColorType.autumn:
        return 'オータム（秋）';
      case PersonalColorType.winter:
        return 'ウィンター（冬）';
    }
  }

  String get description {
    switch (this) {
      case PersonalColorType.spring:
        return '明るく華やかな色が似合う';
      case PersonalColorType.summer:
        return '上品で涼しげな色が似合う';
      case PersonalColorType.autumn:
        return '深みのある暖かい色が似合う';
      case PersonalColorType.winter:
        return 'はっきりした鮮やかな色が似合う';
    }
  }

  String get apiValue {
    switch (this) {
      case PersonalColorType.spring:
        return 'スプリング';
      case PersonalColorType.summer:
        return 'サマー';
      case PersonalColorType.autumn:
        return 'オータム';
      case PersonalColorType.winter:
        return 'ウィンター';
    }
  }

  static PersonalColorType fromApiValue(String value) {
    switch (value) {
      case 'スプリング':
        return PersonalColorType.spring;
      case 'サマー':
        return PersonalColorType.summer;
      case 'オータム':
        return PersonalColorType.autumn;
      case 'ウィンター':
        return PersonalColorType.winter;
      default:
        throw ArgumentError('Unknown personal color type: $value');
    }
  }
}

/// 色の推奨情報
class ColorRecommendation extends Equatable {
  const ColorRecommendation({
    required this.colorName,
    required this.reason,
    this.hexColor,
  });

  /// 色の名前
  final String colorName;

  /// 推奨/非推奨の理由
  final String reason;

  /// 色のHEX値（オプション）
  final String? hexColor;

  @override
  List<Object?> get props => [colorName, reason, hexColor];

  /// JSONから作成
  factory ColorRecommendation.fromJson(Map<String, dynamic> json) {
    return ColorRecommendation(
      colorName: json['color_name'] as String,
      reason: json['reason'] as String,
      hexColor: json['hex_color'] as String?,
    );
  }

  /// JSONに変換
  Map<String, dynamic> toJson() {
    return {
      'color_name': colorName,
      'reason': reason,
      if (hexColor != null) 'hex_color': hexColor,
    };
  }
}