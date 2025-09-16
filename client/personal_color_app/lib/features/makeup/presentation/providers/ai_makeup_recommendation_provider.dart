import 'dart:io';
import 'package:flutter/material.dart';
import '../../../../core/error/failures.dart';
import '../../../diagnosis/domain/entities/diagnosis_result.dart';
import '../../../diagnosis/domain/entities/gender.dart';
import '../../domain/entities/makeup_recommendation.dart';
import '../../domain/entities/makeup_step.dart';
import '../../domain/entities/highlight_area.dart';
import '../../domain/entities/diagnosis_context.dart';
import '../../domain/usecases/get_ai_makeup_recommendations.dart';

/// AI画像生成付きメイクアップ推奨データの状態管理プロバイダー
/// 
/// 画像ファイルとパーソナルカラータイプに基づいて、
/// AI生成画像付きのメイクアップ推奨データを取得・管理します。
class AIMakeupRecommendationProvider extends ChangeNotifier {
  AIMakeupRecommendationProvider({
    required this.getAIMakeupRecommendations,
  });

  final GetAIMakeupRecommendations getAIMakeupRecommendations;

  /// 現在の推奨データ
  MakeupRecommendation? _recommendation;
  MakeupRecommendation? get recommendation => _recommendation;

  /// エラーメッセージ
  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  /// ローディング状態
  bool _isLoading = false;
  bool get isLoading => _isLoading;

  /// 推奨データが存在するかどうか
  bool get hasRecommendation => _recommendation != null;

  /// エラー状態かどうか
  bool get hasError => _errorMessage != null;

  /// AI生成画像が利用可能かどうか
  bool get hasGeneratedImage => _recommendation?.hasGeneratedImage ?? false;

  /// 進行状況メッセージ
  String? _progressMessage;
  String? get progressMessage => _progressMessage;

  /// ハイライト表示状態（UI制御用）
  bool _showHighlights = true;
  bool get showHighlights => _showHighlights;
  void toggleHighlights() {
    _showHighlights = !_showHighlights;
    debugPrint('✨ [AIMakeupRecommendationProvider] showHighlights=$_showHighlights');
    if (!_disposed) notifyListeners();
  }

  /// 選択中のステップ（UI連動用）
  int? _selectedStepIndex;
  int? get selectedStepIndex => _selectedStepIndex;
  void setSelectedStepIndex(int? index) {
    _selectedStepIndex = index;
    if (!_disposed) notifyListeners();
  }

  /// ステップに応じたハイライトフォーカス
  HighlightType? _focusedHighlightType;
  DateTime? _focusUntil;

  /// フォーカス中のハイライトのみを表示
  List<HighlightArea> get highlightAreasForDisplay {
    final areas = _recommendation?.highlightAreas ?? const [];
    if (_focusedHighlightType == null) return areas;
    return areas.where((a) => a.type == _focusedHighlightType).toList();
  }

  /// ステップに応じてハイライトをフォーカス表示（一定時間）
  void focusHighlightForStep(MakeupStep step, {Duration duration = const Duration(seconds: 3)}) {
    final type = _mapStepCategoryToHighlight(step.category);
    if (type == null) return;
    _focusedHighlightType = type;
    _focusUntil = DateTime.now().add(duration);
    if (!_disposed) notifyListeners();

    Future.delayed(duration).then((_) {
      if (_disposed) return;
      if (_focusUntil != null && DateTime.now().isAfter(_focusUntil!)) {
        _focusedHighlightType = null;
        if (!_disposed) notifyListeners();
      }
    });
  }

  void clearHighlightFocus() {
    _focusedHighlightType = null;
    _focusUntil = null;
    if (!_disposed) notifyListeners();
  }

  HighlightType? _mapStepCategoryToHighlight(StepCategory cat) {
    switch (cat) {
      case StepCategory.eyeshadow:
      case StepCategory.eyeliner:
      case StepCategory.mascara:
        return HighlightType.eye;
      case StepCategory.eyebrow:
        return HighlightType.eyebrow;
      case StepCategory.cheek:
        return HighlightType.cheek;
      case StepCategory.lip:
        return HighlightType.lip;
      case StepCategory.highlight:
        return HighlightType.highlight;
      case StepCategory.contour:
        return HighlightType.contour;
      case StepCategory.base:
      case StepCategory.setting:
        return null;
    }
  }

  /// 推定年齢（APIから提供される場合）
  int? get estimatedAge => _recommendation?.estimatedAge;
  
  /// 推定年齢グループ（エンティティ計算をラップ）
  AgeGroup get ageGroup => _recommendation?.ageGroup ?? AgeGroup.adult;

  /// 診断コンテキスト付きでAI画像生成付きメイクアップ推奨データを取得
  /// 
  /// [diagnosisContext] 診断コンテキスト（パーソナルカラータイプ、画像、診断結果を含む）
  Future<void> fetchAIMakeupRecommendationsWithDiagnosisContext(
    DiagnosisContext diagnosisContext,
  ) async {
    try {
      debugPrint('🤖 [AIMakeupRecommendationProvider] 診断コンテキスト付きAI推奨データ取得開始');
      debugPrint('   診断コンテキスト: $diagnosisContext');
      debugPrint('   パーソナルカラータイプ: ${diagnosisContext.colorType}');
      debugPrint('   画像ファイル: ${diagnosisContext.originalImagePath}');
      debugPrint('   診断信頼度: ${diagnosisContext.confidence}%');
      debugPrint('   診断から経過時間: ${diagnosisContext.minutesSinceDiagnosis}分');

      // 診断コンテキストの妥当性検証
      final validationError = _validateDiagnosisContext(diagnosisContext);
      if (validationError != null) {
        _setError(validationError);
        return;
      }

      _setLoading(true);
      _clearError();
      _setProgressMessage('診断結果を分析中...');

      await Future.delayed(const Duration(milliseconds: 500)); // UI更新のための少し待機

      _setProgressMessage('AI画像生成中...');
      await Future.delayed(const Duration(milliseconds: 500));

      // 画像ファイルを作成
      final imageFile = File(diagnosisContext.originalImagePath);

      final params = GetAIMakeupRecommendationsParams(
        personalColorType: diagnosisContext.colorType,
        imageFile: imageFile,
        diagnosisResult: diagnosisContext.diagnosisResult,
      );

      final result = await getAIMakeupRecommendations.call(params);

      result.fold(
        (failure) {
          debugPrint('❌ [AIMakeupRecommendationProvider] エラー: ${failure.message}');
          _setError(_getErrorMessage(failure));
          _setProgressMessage(null);
        },
        (recommendation) {
          debugPrint('✅ [AIMakeupRecommendationProvider] 診断コンテキスト付きデータ取得成功');
          debugPrint('   総商品数: ${recommendation.totalProductCount}');
          debugPrint('   AI生成画像: ${recommendation.hasGeneratedImage ? '有り' : '無し'}');
          debugPrint('   推定年齢: ${recommendation.estimatedAge}');
          debugPrint('   年齢グループ: ${recommendation.ageGroup}');
          
          _recommendation = recommendation;
          _setProgressMessage(null);
          
          // 成功通知
          _setProgressMessage('完了！');
          Future.delayed(const Duration(milliseconds: 1000), () {
            _setProgressMessage(null);
          });
        },
      );
    } catch (e) {
      debugPrint('❌ [AIMakeupRecommendationProvider] 予期しないエラー: $e');
      _setError('予期しないエラーが発生しました: $e');
      _setProgressMessage(null);
    } finally {
      _setLoading(false);
    }
  }

  /// 診断コンテキスト付きでAI画像生成付きメイクアップ推奨データを取得（後方互換性のため）
  /// 
  /// [personalColorType] 対象のパーソナルカラータイプ
  /// [imageFile] AI画像生成に使用する画像ファイル
  /// [diagnosisResult] 診断結果（コンテキスト情報として使用）
  @Deprecated('Use fetchAIMakeupRecommendationsWithDiagnosisContext instead')
  Future<void> fetchAIMakeupRecommendationsWithContext(
    PersonalColorType personalColorType,
    File imageFile,
    DiagnosisResult diagnosisResult,
  ) async {
    // 診断コンテキストを作成して新しいメソッドを呼び出し
    final diagnosisContext = DiagnosisContext(
      colorType: personalColorType,
      originalImagePath: imageFile.path,
      diagnosisResult: diagnosisResult,
      diagnosisTimestamp: DateTime.now(),
      confidence: diagnosisResult.confidence,
      personAnalysis: diagnosisResult.personAnalysis,
    );

    await fetchAIMakeupRecommendationsWithDiagnosisContext(diagnosisContext);
  }

  /// AI画像生成付きメイクアップ推奨データを取得
  /// 
  /// [personalColorType] 対象のパーソナルカラータイプ
  /// [imageFile] AI画像生成に使用する画像ファイル
  Future<void> fetchAIMakeupRecommendations(
    PersonalColorType personalColorType,
    File imageFile,
  ) async {
    try {
      debugPrint('🤖 [AIMakeupRecommendationProvider] AI推奨データ取得開始');
      debugPrint('   パーソナルカラータイプ: $personalColorType');
      debugPrint('   画像ファイル: ${imageFile.path}');

      // 事前検証
      final validationError = _validateImageFile(imageFile);
      if (validationError != null) {
        _setError(validationError);
        return;
      }

      _setLoading(true);
      _clearError();
      _setProgressMessage('画像をアップロード中...');

      await Future.delayed(const Duration(milliseconds: 500)); // UI更新のための少し待機

      _setProgressMessage('AI画像生成中...');
      await Future.delayed(const Duration(milliseconds: 500));

      final params = GetAIMakeupRecommendationsParams(
        personalColorType: personalColorType,
        imageFile: imageFile,
      );

      final result = await getAIMakeupRecommendations.call(params);

      result.fold(
        (failure) {
          debugPrint('❌ [AIMakeupRecommendationProvider] エラー: ${failure.message}');
          _setError(_getErrorMessage(failure));
          _setProgressMessage(null);
        },
        (recommendation) {
          debugPrint('✅ [AIMakeupRecommendationProvider] データ取得成功');
          debugPrint('   総商品数: ${recommendation.totalProductCount}');
          debugPrint('   AI生成画像: ${recommendation.hasGeneratedImage ? '有り' : '無し'}');
          
          _recommendation = recommendation;
          _setProgressMessage(null);
          
          // 成功通知
          _setProgressMessage('完了！');
          Future.delayed(const Duration(milliseconds: 1000), () {
            _setProgressMessage(null);
          });
        },
      );
    } catch (e) {
      debugPrint('❌ [AIMakeupRecommendationProvider] 予期しないエラー: $e');
      _setError('予期しないエラーが発生しました: $e');
      _setProgressMessage(null);
    } finally {
      _setLoading(false);
    }
  }

  /// エラー状態をクリア
  void clearError() {
    _clearError();
  }

  /// データをクリア
  void clearRecommendation() {
    _recommendation = null;
    _clearError();
    _setProgressMessage(null);
    debugPrint('🧹 [AIMakeupRecommendationProvider] データクリア完了');
    notifyListeners();
  }

  /// ローディング状態を設定
  void _setLoading(bool loading) {
    if (_isLoading != loading) {
      _isLoading = loading;
      debugPrint('⏳ [AIMakeupRecommendationProvider] ローディング状態: $loading');
      if (!_disposed) {
        notifyListeners();
      }
    }
  }

  bool _disposed = false;

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }

  /// エラーを設定
  void _setError(String message) {
    _errorMessage = message;
    debugPrint('❌ [AIMakeupRecommendationProvider] エラー設定: $message');
    if (!_disposed) {
      notifyListeners();
    }
  }

  /// エラーをクリア
  void _clearError() {
    if (_errorMessage != null) {
      _errorMessage = null;
      debugPrint('🧹 [AIMakeupRecommendationProvider] エラークリア');
      if (!_disposed) {
        notifyListeners();
      }
    }
  }

  /// 進行状況メッセージを設定
  void _setProgressMessage(String? message) {
    if (_progressMessage != message) {
      _progressMessage = message;
      debugPrint('💬 [AIMakeupRecommendationProvider] 進行状況: $message');
      if (!_disposed) {
        notifyListeners();
      }
    }
  }

  /// Failureを適切なエラーメッセージに変換
  String _getErrorMessage(Failure failure) {
    switch (failure.runtimeType) {
      case const (NetworkFailure):
        return 'ネットワーク接続を確認してください';
      case const (ValidationFailure):
        // バリデーションエラーの詳細メッセージを活用
        if (failure.message.contains('Image file does not exist')) {
          return '診断画像が見つかりません。再度診断を実行してください';
        } else if (failure.message.contains('Image file is too large')) {
          return '画像ファイルが大きすぎます。10MB以下の画像を使用してください';
        } else if (failure.message.contains('Diagnosis result does not match')) {
          return '診断結果とパーソナルカラータイプが一致しません';
        } else if (failure.message.contains('No face detected')) {
          return '顔が検出されませんでした。顔がはっきり写った画像を使用してください';
        } else if (failure.message.contains('Unsupported image format')) {
          return 'サポートされていない画像形式です。JPEG、PNG、WebPを使用してください';
        }
        return failure.message.isNotEmpty ? failure.message : 'バリデーションエラーが発生しました';
      case const (DataFailure):
        return 'データの取得に失敗しました';
      case const (ServerFailure):
        if (failure.message.contains('AI service temporarily unavailable')) {
          return 'AI画像生成サービスが一時的に利用できません。しばらく時間をおいてから再試行してください';
        } else if (failure.message.contains('Rate limit exceeded')) {
          return 'リクエスト制限に達しました。しばらく時間をおいてから再試行してください';
        }
        return 'サーバーエラーが発生しました。しばらく時間をおいてから再試行してください';
      default:
        return failure.message.isNotEmpty ? failure.message : '不明なエラーが発生しました';
    }
  }

  /// 診断コンテキストの妥当性を検証
  /// 
  /// [diagnosisContext] 検証対象の診断コンテキスト
  /// 
  /// エラーがある場合はエラーメッセージを返し、問題がない場合はnullを返します。
  String? _validateDiagnosisContext(DiagnosisContext diagnosisContext) {
    // 基本的な妥当性チェック
    if (!diagnosisContext.isValid) {
      return '診断コンテキストが無効です';
    }

    // 画像ファイルの存在チェック
    final imageFile = File(diagnosisContext.originalImagePath);
    if (!imageFile.existsSync()) {
      return '診断画像が見つかりません。再度診断を実行してください';
    }

    // 画像ファイルの詳細検証
    try {
      final fileSize = imageFile.lengthSync();
      if (fileSize > 10 * 1024 * 1024) { // 10MB制限
        return '画像ファイルが大きすぎます。10MB以下の画像を使用してください';
      }
      if (fileSize < 1024) { // 1KB未満は無効
        return '画像ファイルが無効または破損している可能性があります';
      }
    } catch (e) {
      debugPrint('❌ [AIMakeupRecommendationProvider] 画像ファイルアクセスエラー: $e');
      return '画像ファイルにアクセスできません';
    }

    // 診断の新しさチェック（24時間以内）
    if (diagnosisContext.minutesSinceDiagnosis > 24 * 60) {
      return '診断結果が古すぎます。新しい診断を実行してください';
    }

    // 信頼度チェック（低すぎる場合は警告）
    if (diagnosisContext.isLowConfidence) {
      debugPrint('⚠️ [AIMakeupRecommendationProvider] 低信頼度の診断結果: ${diagnosisContext.confidence}%');
      // 低信頼度でも処理は続行するが、ログに記録
    }

    // パーソナルカラータイプと診断結果の整合性チェック
    if (diagnosisContext.diagnosisResult.diagnosisType != diagnosisContext.colorType) {
      return '診断結果とパーソナルカラータイプが一致しません';
    }

    return null; // 検証成功
  }

  /// 診断コンテキストが利用可能かどうかをチェック
  /// 
  /// [diagnosisContext] チェック対象の診断コンテキスト
  /// 
  /// 利用可能な場合はtrue、そうでなければfalseを返します。
  bool isDiagnosisContextAvailable(DiagnosisContext? diagnosisContext) {
    if (diagnosisContext == null) {
      return false;
    }

    return _validateDiagnosisContext(diagnosisContext) == null;
  }

  /// 現在の推奨データに診断コンテキスト情報が含まれているかどうか
  bool get hasContextualRecommendation {
    return _recommendation != null && 
           _recommendation!.reasoningExplanation != null &&
           _recommendation!.reasoningExplanation!.isNotEmpty;
  }

  /// 診断結果から診断コンテキストを作成するヘルパーメソッド
  /// 
  /// [personalColorType] パーソナルカラータイプ
  /// [imageFile] 診断に使用した画像ファイル
  /// [diagnosisResult] 診断結果
  /// [diagnosisTimestamp] 診断実行日時（省略時は現在時刻）
  /// 
  /// 診断コンテキストを返します。
  static DiagnosisContext createDiagnosisContext({
    required PersonalColorType personalColorType,
    required File imageFile,
    required DiagnosisResult diagnosisResult,
    DateTime? diagnosisTimestamp,
    String? sessionId,
  }) {
    return DiagnosisContext(
      colorType: personalColorType,
      originalImagePath: imageFile.path,
      diagnosisResult: diagnosisResult,
      diagnosisTimestamp: diagnosisTimestamp ?? DateTime.now(),
      confidence: diagnosisResult.confidence,
      personAnalysis: diagnosisResult.personAnalysis,
      sessionId: sessionId,
    );
  }

  /// 診断コンテキストの詳細情報を取得
  /// 
  /// [diagnosisContext] 対象の診断コンテキスト
  /// 
  /// デバッグ用の詳細情報を返します。
  Map<String, dynamic> getDiagnosisContextInfo(DiagnosisContext diagnosisContext) {
    return {
      'colorType': diagnosisContext.colorType.displayName,
      'confidence': diagnosisContext.confidence,
      'isHighConfidence': diagnosisContext.isHighConfidence,
      'isMediumConfidence': diagnosisContext.isMediumConfidence,
      'isLowConfidence': diagnosisContext.isLowConfidence,
      'minutesSinceDiagnosis': diagnosisContext.minutesSinceDiagnosis,
      'isRecentDiagnosis': diagnosisContext.isRecentDiagnosis,
      'hasPersonAnalysis': diagnosisContext.hasPersonAnalysis,
      'ageGroup': diagnosisContext.ageGroup?.displayName,
      'estimatedGender': diagnosisContext.estimatedGender?.displayName,
      'isValid': diagnosisContext.isValid,
    };
  }

  /// 画像ファイルの妥当性を検証
  /// 
  /// [imageFile] 検証対象の画像ファイル
  /// 
  /// エラーがある場合はエラーメッセージを返し、問題がない場合はnullを返します。
  String? _validateImageFile(File imageFile) {
    // ファイルの存在チェック
    if (!imageFile.existsSync()) {
      return '画像ファイルが見つかりません。再度診断を実行してください';
    }

    try {
      // ファイルサイズチェック
      final fileSize = imageFile.lengthSync();
      if (fileSize > 10 * 1024 * 1024) { // 10MB制限
        return '画像ファイルが大きすぎます。10MB以下の画像を使用してください';
      }
      if (fileSize < 1024) { // 1KB未満は無効
        return '画像ファイルが無効または破損している可能性があります';
      }

      // ファイル拡張子チェック
      final extension = imageFile.path.toLowerCase().split('.').last;
      if (!['jpg', 'jpeg', 'png', 'webp'].contains(extension)) {
        return 'サポートされていない画像形式です。JPEG、PNG、WebPを使用してください';
      }

    } catch (e) {
      debugPrint('❌ [AIMakeupRecommendationProvider] 画像ファイル検証エラー: $e');
      return '画像ファイルにアクセスできません';
    }

    return null; // 検証成功
  }

  /// サービス利用可能性をチェック
  /// 
  /// AI生成メイクサービスが利用可能かどうかを確認します。
  /// 実際の実装では、サーバーのヘルスチェックAPIを呼び出すことができます。
  Future<bool> isServiceAvailable() async {
    try {
      // 簡単なヘルスチェック（実際の実装では適切なAPIエンドポイントを使用）
      // 現在はダミー実装
      await Future.delayed(const Duration(milliseconds: 500));
      return true;
    } catch (e) {
      debugPrint('❌ [AIMakeupRecommendationProvider] サービス利用可能性チェックエラー: $e');
      return false;
    }
  }

  /// エラー回復を試行
  /// 
  /// 一時的なエラーの場合、自動的に回復を試行します。
  Future<void> attemptErrorRecovery() async {
    if (!hasError) return;

    debugPrint('🔄 [AIMakeupRecommendationProvider] エラー回復を試行中...');
    
    // エラーをクリアして再試行の準備
    _clearError();
    
    // サービス利用可能性をチェック
    final isAvailable = await isServiceAvailable();
    if (!isAvailable) {
      _setError('AI生成メイクサービスが一時的に利用できません。しばらく時間をおいてから再試行してください');
      return;
    }

    debugPrint('✅ [AIMakeupRecommendationProvider] エラー回復準備完了');
  }

  /// 推奨データの品質をチェック
  /// 
  /// [recommendation] チェック対象の推奨データ
  /// 
  /// データの品質に問題がある場合は警告を返します。
  List<String> checkRecommendationQuality(MakeupRecommendation recommendation) {
    final warnings = <String>[];

    // AI生成画像の品質チェック
    if (!recommendation.hasGeneratedImage) {
      warnings.add('AI生成画像が利用できませんでした');
    }

    // 推奨データの完全性チェック
    if (recommendation.totalProductCount < 5) {
      warnings.add('推奨商品数が少ない可能性があります');
    }

    // 説明の品質チェック
    if (recommendation.reasoningExplanation == null || 
        recommendation.reasoningExplanation!.length < 50) {
      warnings.add('AI説明が不完全な可能性があります');
    }

    return warnings;
  }

  /// 現在の推奨データの品質警告を取得
  List<String> get currentRecommendationWarnings {
    if (_recommendation == null) return [];
    return checkRecommendationQuality(_recommendation!);
  }

  /// 推奨データに品質の問題があるかどうか
  bool get hasQualityIssues {
    return currentRecommendationWarnings.isNotEmpty;
  }

  /// テスト用ヘルパー（Widgetテスト向け）
  void setRecommendationForTest(MakeupRecommendation rec) {
    _recommendation = rec;
    _isLoading = false;
    _errorMessage = null;
    if (!_disposed) notifyListeners();
  }
}
