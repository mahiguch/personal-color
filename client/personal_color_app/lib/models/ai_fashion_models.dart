import 'package:equatable/equatable.dart';

/// AI ファッションコーディネート API のモデル定義
/// 
/// サーバーAPIとの通信で使用するリクエスト・レスポンスモデル

/// ファッションアイテムモデル
class FashionItemModel extends Equatable {
  final String id;
  final String category;
  final String name;
  final String color;
  final String style;
  final bool seasonAppropriate;
  final bool ageAppropriate;

  const FashionItemModel({
    required this.id,
    required this.category,
    required this.name,
    required this.color,
    required this.style,
    required this.seasonAppropriate,
    required this.ageAppropriate,
  });

  factory FashionItemModel.fromJson(Map<String, dynamic> json) {
    return FashionItemModel(
      id: json['id'] as String,
      category: json['category'] as String,
      name: json['name'] as String,
      color: json['color'] as String,
      style: json['style'] as String,
      seasonAppropriate: json['season_appropriate'] as bool,
      ageAppropriate: json['age_appropriate'] as bool,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'category': category,
      'name': name,
      'color': color,
      'style': style,
      'season_appropriate': seasonAppropriate,
      'age_appropriate': ageAppropriate,
    };
  }

  @override
  List<Object?> get props => [
        id,
        category,
        name,
        color,
        style,
        seasonAppropriate,
        ageAppropriate,
      ];

  @override
  String toString() => 'FashionItemModel { '
      'id: $id, '
      'category: $category, '
      'name: $name, '
      'color: $color, '
      'style: $style, '
      'seasonAppropriate: $seasonAppropriate, '
      'ageAppropriate: $ageAppropriate '
      '}';
}

/// スタイリングポイントモデル
class StylingPointModel extends Equatable {
  final String category;
  final String point;
  final String reason;

  const StylingPointModel({
    required this.category,
    required this.point,
    required this.reason,
  });

  factory StylingPointModel.fromJson(Map<String, dynamic> json) {
    return StylingPointModel(
      category: json['category'] as String,
      point: json['point'] as String,
      reason: json['reason'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'category': category,
      'point': point,
      'reason': reason,
    };
  }

  @override
  List<Object?> get props => [category, point, reason];

  @override
  String toString() => 'StylingPointModel { '
      'category: $category, '
      'point: $point, '
      'reason: $reason '
      '}';
}

/// 生成画像データモデル
class GeneratedImageDataModel extends Equatable {
  final String imageUrl;
  final double generationTime;
  final String modelVersion;
  final String promptUsed;

  const GeneratedImageDataModel({
    required this.imageUrl,
    required this.generationTime,
    required this.modelVersion,
    required this.promptUsed,
  });

  factory GeneratedImageDataModel.fromJson(Map<String, dynamic> json) {
    return GeneratedImageDataModel(
      imageUrl: json['image_url'] as String,
      generationTime: (json['generation_time'] as num).toDouble(),
      modelVersion: json['model_version'] as String,
      promptUsed: json['prompt_used'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'image_url': imageUrl,
      'generation_time': generationTime,
      'model_version': modelVersion,
      'prompt_used': promptUsed,
    };
  }

  @override
  List<Object?> get props => [
        imageUrl,
        generationTime,
        modelVersion,
        promptUsed,
      ];

  @override
  String toString() => 'GeneratedImageDataModel { '
      'imageUrl: ${imageUrl.length > 50 ? '${imageUrl.substring(0, 50)}...' : imageUrl}, '
      'generationTime: $generationTime, '
      'modelVersion: $modelVersion, '
      'promptUsed: $promptUsed '
      '}';
}

/// AI コーディネート推薦レスポンスモデル
class AICoordinateRecommendationResponseModel extends Equatable {
  final String personalColorType;
  final String stylePreference;
  final List<FashionItemModel> fashionItems;
  final String recommendationReason;
  final List<StylingPointModel> stylingPoints;
  final GeneratedImageDataModel? generatedImage;
  final int? estimatedAge;
  final String? seasonContext;
  final Map<String, dynamic>? colorAnalysis;
  final String requestId;
  final String timestamp;

  const AICoordinateRecommendationResponseModel({
    required this.personalColorType,
    required this.stylePreference,
    required this.fashionItems,
    required this.recommendationReason,
    required this.stylingPoints,
    this.generatedImage,
    this.estimatedAge,
    this.seasonContext,
    this.colorAnalysis,
    required this.requestId,
    required this.timestamp,
  });

  factory AICoordinateRecommendationResponseModel.fromJson(Map<String, dynamic> json) {
    return AICoordinateRecommendationResponseModel(
      personalColorType: json['personal_color_type'] as String,
      stylePreference: json['style_preference'] as String,
      fashionItems: (json['fashion_items'] as List)
          .map((item) => FashionItemModel.fromJson(item as Map<String, dynamic>))
          .toList(),
      recommendationReason: json['recommendation_reason'] as String,
      stylingPoints: (json['styling_points'] as List)
          .map((point) => StylingPointModel.fromJson(point as Map<String, dynamic>))
          .toList(),
      generatedImage: json['generated_image'] != null
          ? GeneratedImageDataModel.fromJson(json['generated_image'] as Map<String, dynamic>)
          : null,
      estimatedAge: json['estimated_age'] as int?,
      seasonContext: json['season_context'] as String?,
      colorAnalysis: json['color_analysis'] as Map<String, dynamic>?,
      requestId: json['request_id'] as String,
      timestamp: json['timestamp'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'personal_color_type': personalColorType,
      'style_preference': stylePreference,
      'fashion_items': fashionItems.map((item) => item.toJson()).toList(),
      'recommendation_reason': recommendationReason,
      'styling_points': stylingPoints.map((point) => point.toJson()).toList(),
      'generated_image': generatedImage?.toJson(),
      'estimated_age': estimatedAge,
      'season_context': seasonContext,
      'color_analysis': colorAnalysis,
      'request_id': requestId,
      'timestamp': timestamp,
    };
  }

  @override
  List<Object?> get props => [
        personalColorType,
        stylePreference,
        fashionItems,
        recommendationReason,
        stylingPoints,
        generatedImage,
        estimatedAge,
        seasonContext,
        colorAnalysis,
        requestId,
        timestamp,
      ];

  @override
  String toString() => 'AICoordinateRecommendationResponseModel { '
      'personalColorType: $personalColorType, '
      'stylePreference: $stylePreference, '
      'fashionItems: ${fashionItems.length} items, '
      'recommendationReason: $recommendationReason, '
      'stylingPoints: ${stylingPoints.length} points, '
      'hasGeneratedImage: ${generatedImage != null}, '
      'estimatedAge: $estimatedAge, '
      'seasonContext: $seasonContext, '
      'requestId: $requestId, '
      'timestamp: $timestamp '
      '}';
}

/// API エラーレスポンスモデル
class APIErrorResponseModel extends Equatable {
  final String error;
  final Map<String, dynamic>? details;
  final String message;

  const APIErrorResponseModel({
    required this.error,
    this.details,
    required this.message,
  });

  factory APIErrorResponseModel.fromJson(Map<String, dynamic> json) {
    return APIErrorResponseModel(
      error: json['error'] as String,
      details: json['details'] as Map<String, dynamic>?,
      message: json['message'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'error': error,
      'details': details,
      'message': message,
    };
  }

  @override
  List<Object?> get props => [error, details, message];

  @override
  String toString() => 'APIErrorResponseModel { '
      'error: $error, '
      'message: $message, '
      'details: $details '
      '}';
}

/// コーディネート生成リクエストモデル  
class CoordinateGenerationRequestModel extends Equatable {
  final String personalColorType;
  final String? stylePreference;
  final String? season;
  final bool includeAccessories;
  final bool generateImage;

  const CoordinateGenerationRequestModel({
    required this.personalColorType,
    this.stylePreference,
    this.season,
    this.includeAccessories = true,
    this.generateImage = true,
  });

  factory CoordinateGenerationRequestModel.fromJson(Map<String, dynamic> json) {
    return CoordinateGenerationRequestModel(
      personalColorType: json['personal_color_type'] as String,
      stylePreference: json['style_preference'] as String?,
      season: json['season'] as String?,
      includeAccessories: json['include_accessories'] as bool? ?? true,
      generateImage: json['generate_image'] as bool? ?? true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'personal_color_type': personalColorType,
      'style_preference': stylePreference,
      'season': season,
      'include_accessories': includeAccessories,
      'generate_image': generateImage,
    };
  }

  @override
  List<Object?> get props => [
        personalColorType,
        stylePreference,
        season,
        includeAccessories,
        generateImage,
      ];

  @override
  String toString() => 'CoordinateGenerationRequestModel { '
      'personalColorType: $personalColorType, '
      'stylePreference: $stylePreference, '
      'season: $season, '
      'includeAccessories: $includeAccessories, '
      'generateImage: $generateImage '
      '}';
}
