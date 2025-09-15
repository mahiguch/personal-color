import 'dart:io';
import 'dart:math';
import '../../domain/services/age_estimation_service.dart';
import '../../../diagnosis/domain/entities/age_group.dart';

/// モック年齢推定サービス
/// 実際のAI分析の代わりにランダムな年齢を生成
class MockAgeEstimationService implements AgeEstimationService {
  final Random _random = Random();

  @override
  Future<int?> estimateAge(File imageFile) async {
    // 実際の処理時間をシミュレート
    await Future.delayed(const Duration(milliseconds: 500));

    try {
      // ファイルの存在確認
      if (!await imageFile.exists()) {
        return null;
      }

      // ファイルサイズが極端に小さい場合は分析不可
      final fileSize = await imageFile.length();
      if (fileSize < 1024) { // 1KB未満
        return null;
      }

      // デモ用のランダムな年齢生成（実際の実装では画像解析を行う）
      // より現実的な分布を作成
      final ageDistribution = _generateRealisticAge();

      return ageDistribution;
    } catch (e) {
      // エラーが発生した場合は推定不可
      return null;
    }
  }

  @override
  Future<double> getConfidence(File imageFile) async {
    await Future.delayed(const Duration(milliseconds: 200));

    try {
      if (!await imageFile.exists()) {
        return 0.0;
      }

      // ファイルサイズに基づく信頼度のシミュレート
      final fileSize = await imageFile.length();
      if (fileSize < 1024) return 0.0;
      if (fileSize < 10240) return 0.6; // 10KB未満は信頼度低
      if (fileSize < 102400) return 0.8; // 100KB未満は中程度
      return 0.9; // 100KB以上は高信頼度
    } catch (e) {
      return 0.0;
    }
  }

  @override
  AgeGroup getAgeGroup(int? estimatedAge) {
    if (estimatedAge == null) return AgeGroup.adult;
    if (estimatedAge <= 15) return AgeGroup.child;
    if (estimatedAge <= 25) return AgeGroup.student;
    return AgeGroup.adult;
  }

  /// より現実的な年齢分布を生成
  int _generateRealisticAge() {
    // 重み付きランダム生成
    final weights = <int, double>{
      12: 0.05,  // 小学生
      14: 0.10,
      16: 0.15,  // 中高生
      18: 0.20,
      20: 0.15,
      22: 0.10,
      25: 0.08,  // 大学生・社会人
      30: 0.07,  // 大人
      35: 0.05,
      40: 0.03,
      45: 0.02,
    };

    final random = _random.nextDouble();
    double cumulative = 0.0;

    for (final entry in weights.entries) {
      cumulative += entry.value;
      if (random <= cumulative) {
        // ±2歳の幅を持たせる
        final variance = _random.nextInt(5) - 2; // -2 to +2
        return (entry.key + variance).clamp(10, 50);
      }
    }

    // フォールバック
    return 20;
  }
}

/// 実際のAI年齢推定サービス（将来実装用）
class AIAgeEstimationService implements AgeEstimationService {

  @override
  Future<int?> estimateAge(File imageFile) async {
    // 現在はモックサービスにフォールバック
    final mockService = MockAgeEstimationService();
    return await mockService.estimateAge(imageFile);
  }

  @override
  Future<double> getConfidence(File imageFile) async {
    // 現在はモックサービスにフォールバック
    final mockService = MockAgeEstimationService();
    return await mockService.getConfidence(imageFile);
  }

  @override
  AgeGroup getAgeGroup(int? estimatedAge) {
    if (estimatedAge == null) return AgeGroup.adult;
    if (estimatedAge <= 15) return AgeGroup.child;
    if (estimatedAge <= 25) return AgeGroup.student;
    return AgeGroup.adult;
  }
}

/// ファクトリーメソッド
class AgeEstimationServiceFactory {
  static AgeEstimationService create({bool useMock = true}) {
    if (useMock) {
      return MockAgeEstimationService();
    } else {
      return AIAgeEstimationService();
    }
  }
}
