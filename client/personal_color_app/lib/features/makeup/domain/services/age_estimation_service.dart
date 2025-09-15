import 'dart:io';
import '../entities/makeup_step.dart';

/// 年齢推定サービス抽象クラス
abstract class AgeEstimationService {
  /// 画像から年齢を推定
  ///
  /// [imageFile] 分析対象の画像ファイル
  /// Returns: 推定年齢（歳）、推定できない場合はnull
  Future<int?> estimateAge(File imageFile);

  /// 推定年齢から年齢グループを決定
  ///
  /// [estimatedAge] 推定年齢
  /// Returns: 対応する年齢グループ
  AgeGroup getAgeGroup(int? estimatedAge) {
    if (estimatedAge == null) return AgeGroup.adult;
    if (estimatedAge <= 15) return AgeGroup.child;
    if (estimatedAge <= 25) return AgeGroup.student;
    return AgeGroup.adult;
  }

  /// 年齢推定の信頼度を取得
  ///
  /// [imageFile] 分析対象の画像ファイル
  /// Returns: 信頼度（0.0-1.0）、分析できない場合は0.0
  Future<double> getConfidence(File imageFile);
}