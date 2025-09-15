import 'package:equatable/equatable.dart';

/// ハイライト表示領域エンティティ
/// Before/After画像でメイクが適用された箇所を視覚的に強調するための領域定義
class HighlightArea extends Equatable {
  const HighlightArea({
    required this.type,
    required this.relativeCoordinates,
    this.description,
    this.shape = HighlightShape.rectangle,
    this.animationType = HighlightAnimationType.fade,
    this.animationDuration = const Duration(seconds: 2),
    this.isVisible = true,
  });

  /// ハイライト対象の部位タイプ
  final HighlightType type;

  /// 相対座標系での領域定義（デバイス独立）
  final RelativeCoordinates relativeCoordinates;

  /// ハイライト部位の説明文（任意）
  final String? description;

  /// 表示形状（矩形・円・楕円）
  final HighlightShape shape;

  /// アニメーション種別
  final HighlightAnimationType animationType;

  /// アニメーション継続時間
  final Duration animationDuration;

  /// 表示/非表示フラグ
  final bool isVisible;

  @override
  List<Object?> get props => [
        type,
        relativeCoordinates,
        description,
        shape,
        animationType,
        animationDuration,
        isVisible,
      ];

  /// ハイライト領域のコピーを作成（一部フィールドを変更）
  HighlightArea copyWith({
    HighlightType? type,
    RelativeCoordinates? relativeCoordinates,
    String? description,
    HighlightShape? shape,
    HighlightAnimationType? animationType,
    Duration? animationDuration,
    bool? isVisible,
  }) {
    return HighlightArea(
      type: type ?? this.type,
      relativeCoordinates: relativeCoordinates ?? this.relativeCoordinates,
      description: description ?? this.description,
      shape: shape ?? this.shape,
      animationType: animationType ?? this.animationType,
      animationDuration: animationDuration ?? this.animationDuration,
      isVisible: isVisible ?? this.isVisible,
    );
  }

  /// 表示状態を切り替え
  HighlightArea toggleVisibility() {
    return copyWith(isVisible: !isVisible);
  }

  /// JSONからの生成
  factory HighlightArea.fromJson(Map<String, dynamic> json) {
    return HighlightArea(
      type: HighlightType.fromString(json['type'] as String),
      relativeCoordinates: RelativeCoordinates.fromJson(
        json['coordinates'] as Map<String, dynamic>,
      ),
      description: json['description'] as String?,
      shape: HighlightShape.fromString(
        (json['shape'] as String?) ?? 'rectangle',
      ),
      animationType: HighlightAnimationType.fromString(
        (json['animationType'] as String?) ?? (json['animation_type'] as String?) ?? 'fade',
      ),
      animationDuration: Duration(
        milliseconds: (json['animationDuration'] as int?) ?? 2000,
      ),
      isVisible: json['isVisible'] as bool? ?? true,
    );
  }

  /// JSONへの変換
  Map<String, dynamic> toJson() {
    return {
      'type': type.value,
      'coordinates': relativeCoordinates.toJson(),
      'description': description,
      'shape': shape.value,
      'animation_type': animationType.value,
      'animationDuration': animationDuration.inMilliseconds,
      'isVisible': isVisible,
    };
  }
}

/// ハイライト対象の部位タイプ
enum HighlightType {
  eye('eye'),
  eyebrow('eyebrow'),
  cheek('cheek'),
  lip('lip'),
  foundation('foundation'),
  highlight('highlight'),
  contour('contour');

  const HighlightType(this.value);

  final String value;

  /// 表示名を取得
  String get displayName {
    switch (this) {
      case HighlightType.eye:
        return 'アイメイク';
      case HighlightType.eyebrow:
        return 'アイブロウ';
      case HighlightType.cheek:
        return 'チーク';
      case HighlightType.lip:
        return 'リップ';
      case HighlightType.foundation:
        return 'ファンデーション';
      case HighlightType.highlight:
        return 'ハイライト';
      case HighlightType.contour:
        return 'コントゥア';
    }
  }

  /// 文字列からの変換
  static HighlightType fromString(String value) {
    return HighlightType.values.firstWhere(
      (type) => type.value == value,
      orElse: () => HighlightType.eye,
    );
  }
}

/// ハイライト形状
enum HighlightShape {
  rectangle('rectangle'),
  circle('circle'),
  oval('oval');

  const HighlightShape(this.value);
  final String value;

  static HighlightShape fromString(String value) {
    return HighlightShape.values.firstWhere(
      (s) => s.value == value,
      orElse: () => HighlightShape.rectangle,
    );
  }
}

/// ハイライトのアニメーションタイプ
enum HighlightAnimationType {
  none('none'),
  fade('fade'),
  pulse('pulse');

  const HighlightAnimationType(this.value);
  final String value;

  static HighlightAnimationType fromString(String value) {
    return HighlightAnimationType.values.firstWhere(
      (s) => s.value == value,
      orElse: () => HighlightAnimationType.fade,
    );
  }
}

/// 相対座標系での領域定義
/// 画像サイズに依存しない座標系（0.0-1.0の範囲）
class RelativeCoordinates extends Equatable {
  const RelativeCoordinates({
    required this.x,
    required this.y,
    required this.width,
    required this.height,
  });

  /// X座標（0.0-1.0の相対位置）
  final double x;

  /// Y座標（0.0-1.0の相対位置）
  final double y;

  /// 幅（0.0-1.0の相対サイズ）
  final double width;

  /// 高さ（0.0-1.0の相対サイズ）
  final double height;

  @override
  List<Object?> get props => [x, y, width, height];

  /// 絶対座標系への変換
  ///
  /// [imageWidth] 画像の実際の幅
  /// [imageHeight] 画像の実際の高さ
  /// Returns: 絶対座標での領域情報
  AbsoluteCoordinates toAbsolute(double imageWidth, double imageHeight) {
    return AbsoluteCoordinates(
      x: x * imageWidth,
      y: y * imageHeight,
      width: width * imageWidth,
      height: height * imageHeight,
    );
  }

  /// JSONからの生成
  factory RelativeCoordinates.fromJson(Map<String, dynamic> json) {
    return RelativeCoordinates(
      x: (json['x'] as num).toDouble(),
      y: (json['y'] as num).toDouble(),
      width: (json['width'] as num).toDouble(),
      height: (json['height'] as num).toDouble(),
    );
  }

  /// JSONへの変換
  Map<String, dynamic> toJson() {
    return {
      'x': x,
      'y': y,
      'width': width,
      'height': height,
    };
  }

  /// バリデーション
  bool get isValid {
    return x >= 0.0 && x <= 1.0 &&
           y >= 0.0 && y <= 1.0 &&
           width > 0.0 && width <= 1.0 &&
           height > 0.0 && height <= 1.0 &&
           (x + width) <= 1.0 &&
           (y + height) <= 1.0;
  }
}

/// 絶対座標系での領域定義
class AbsoluteCoordinates extends Equatable {
  const AbsoluteCoordinates({
    required this.x,
    required this.y,
    required this.width,
    required this.height,
  });

  /// X座標（ピクセル）
  final double x;

  /// Y座標（ピクセル）
  final double y;

  /// 幅（ピクセル）
  final double width;

  /// 高さ（ピクセル）
  final double height;

  @override
  List<Object?> get props => [x, y, width, height];

  /// 相対座標系への変換
  ///
  /// [imageWidth] 画像の実際の幅
  /// [imageHeight] 画像の実際の高さ
  /// Returns: 相対座標での領域情報
  RelativeCoordinates toRelative(double imageWidth, double imageHeight) {
    return RelativeCoordinates(
      x: x / imageWidth,
      y: y / imageHeight,
      width: width / imageWidth,
      height: height / imageHeight,
    );
  }
}
