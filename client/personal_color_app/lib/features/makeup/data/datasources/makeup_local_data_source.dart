import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../diagnosis/domain/entities/diagnosis_result.dart';
import '../models/makeup_recommendation_model.dart';

/// メイクアップ推奨データのローカルデータソース抽象インターフェース
abstract class MakeupLocalDataSource {
  /// キャッシュからメイクアップ推奨データを取得
  /// 
  /// [personalColorType] 対象のパーソナルカラータイプ
  /// 
  /// キャッシュが存在し有効期限内の場合は[MakeupRecommendationModel]を返します。
  /// キャッシュが存在しないか期限切れの場合は例外をスローします。
  Future<MakeupRecommendationModel> getCachedMakeupRecommendations(
    PersonalColorType personalColorType,
  );

  /// メイクアップ推奨データをキャッシュに保存
  /// 
  /// [personalColorType] 対象のパーソナルカラータイプ
  /// [recommendation] 保存するメイクアップ推奨データ
  Future<void> cacheMakeupRecommendations(
    PersonalColorType personalColorType,
    MakeupRecommendationModel recommendation,
  );

  /// 特定のパーソナルカラータイプのキャッシュをクリア
  /// 
  /// [personalColorType] 対象のパーソナルカラータイプ
  Future<void> clearCacheForType(PersonalColorType personalColorType);

  /// 全てのメイクアップキャッシュをクリア
  Future<void> clearAllCache();

  /// キャッシュが存在し有効期限内かどうかをチェック
  /// 
  /// [personalColorType] 対象のパーソナルカラータイプ
  Future<bool> hasCachedData(PersonalColorType personalColorType);

  /// キャッシュの最終更新時刻を取得
  /// 
  /// [personalColorType] 対象のパーソナルカラータイプ
  Future<DateTime?> getLastCacheUpdateTime(PersonalColorType personalColorType);
}

/// メイクアップ推奨データのローカルデータソース実装
/// 
/// SharedPreferencesを使用してJSON形式でデータをキャッシュします。
/// 設計書に従い、商品データは24時間、AI説明文は7日間キャッシュします。
class MakeupLocalDataSourceImpl implements MakeupLocalDataSource {
  MakeupLocalDataSourceImpl({required this.sharedPreferences});

  final SharedPreferences sharedPreferences;

  /// キャッシュの有効期限（商品データ: 24時間）
  static const Duration _cacheValidDuration = Duration(hours: 24);

  /// AI説明文の有効期限（7日間）
  // static const Duration _aiExplanationValidDuration = Duration(days: 7);

  @override
  Future<MakeupRecommendationModel> getCachedMakeupRecommendations(
    PersonalColorType personalColorType,
  ) async {
    try {
      // キャッシュキー生成
      final dataKey = _generateDataKey(personalColorType);
      final timestampKey = _generateTimestampKey(personalColorType);

      // キャッシュデータとタイムスタンプを取得
      final cachedJsonString = sharedPreferences.getString(dataKey);
      final cachedTimestamp = sharedPreferences.getInt(timestampKey);

      if (cachedJsonString == null || cachedTimestamp == null) {
        throw Exception('No cached data found for ${personalColorType.name}');
      }

      // キャッシュの有効期限チェック
      final cacheTime = DateTime.fromMillisecondsSinceEpoch(cachedTimestamp);
      final now = DateTime.now();

      if (now.difference(cacheTime) > _cacheValidDuration) {
        // 期限切れの場合は例外をスロー
        throw Exception('Cached data expired for ${personalColorType.name}');
      }

      // JSON文字列をデシリアライズ
      final cachedJson = json.decode(cachedJsonString) as Map<String, dynamic>;
      return MakeupRecommendationModel.fromJson(cachedJson);
    } catch (e) {
      throw Exception('Failed to retrieve cached makeup recommendations: $e');
    }
  }

  @override
  Future<void> cacheMakeupRecommendations(
    PersonalColorType personalColorType,
    MakeupRecommendationModel recommendation,
  ) async {
    try {
      // キャッシュキー生成
      final dataKey = _generateDataKey(personalColorType);
      final timestampKey = _generateTimestampKey(personalColorType);

      // データをJSONにシリアライズ
      final jsonString = json.encode(recommendation.toJson());
      final timestamp = DateTime.now().millisecondsSinceEpoch;

      // SharedPreferencesに保存
      await Future.wait([
        sharedPreferences.setString(dataKey, jsonString),
        sharedPreferences.setInt(timestampKey, timestamp),
      ]);
    } catch (e) {
      throw Exception('Failed to cache makeup recommendations: $e');
    }
  }

  @override
  Future<void> clearCacheForType(PersonalColorType personalColorType) async {
    try {
      final dataKey = _generateDataKey(personalColorType);
      final timestampKey = _generateTimestampKey(personalColorType);

      await Future.wait([
        sharedPreferences.remove(dataKey),
        sharedPreferences.remove(timestampKey),
      ]);
    } catch (e) {
      throw Exception('Failed to clear cache for ${personalColorType.name}: $e');
    }
  }

  @override
  Future<void> clearAllCache() async {
    try {
      // 全てのパーソナルカラータイプのキャッシュをクリア
      final clearTasks = PersonalColorType.values.map((type) => clearCacheForType(type));
      await Future.wait(clearTasks);
    } catch (e) {
      throw Exception('Failed to clear all makeup cache: $e');
    }
  }

  @override
  Future<bool> hasCachedData(PersonalColorType personalColorType) async {
    try {
      final dataKey = _generateDataKey(personalColorType);
      final timestampKey = _generateTimestampKey(personalColorType);

      // データとタイムスタンプの存在チェック
      final hasData = sharedPreferences.containsKey(dataKey);
      final hasTimestamp = sharedPreferences.containsKey(timestampKey);

      if (!hasData || !hasTimestamp) {
        return false;
      }

      // 有効期限チェック
      final cachedTimestamp = sharedPreferences.getInt(timestampKey);
      if (cachedTimestamp == null) {
        return false;
      }

      final cacheTime = DateTime.fromMillisecondsSinceEpoch(cachedTimestamp);
      final now = DateTime.now();

      return now.difference(cacheTime) <= _cacheValidDuration;
    } catch (e) {
      // エラーが発生した場合はキャッシュなしとみなす
      return false;
    }
  }

  @override
  Future<DateTime?> getLastCacheUpdateTime(PersonalColorType personalColorType) async {
    try {
      final timestampKey = _generateTimestampKey(personalColorType);
      final cachedTimestamp = sharedPreferences.getInt(timestampKey);

      if (cachedTimestamp == null) {
        return null;
      }

      return DateTime.fromMillisecondsSinceEpoch(cachedTimestamp);
    } catch (e) {
      return null;
    }
  }

  /// データキャッシュ用のキー生成
  String _generateDataKey(PersonalColorType personalColorType) {
    return 'makeup_recommendations_${personalColorType.name}';
  }

  /// タイムスタンプキャッシュ用のキー生成
  String _generateTimestampKey(PersonalColorType personalColorType) {
    return 'makeup_recommendations_timestamp_${personalColorType.name}';
  }
}