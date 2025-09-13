import '../../../../core/network/api_client.dart';
import '../../../../core/network/api_config.dart';
import '../models/diagnosis_request_model.dart';
import '../models/diagnosis_result_model.dart';

/// 診断APIのリモートデータソース抽象クラス
abstract class DiagnosisRemoteDataSource {
  Future<DiagnosisResultModel> diagnosePerson(DiagnosisRequestModel request);
  Future<DiagnosisResultModel> diagnosePersonalColorEnhanced(DiagnosisRequestModel request);
  Future<bool> checkApiHealth();
  Future<Map<String, dynamic>> testConnection();
}

/// 診断APIのリモートデータソース実装
class DiagnosisRemoteDataSourceImpl implements DiagnosisRemoteDataSource {
  const DiagnosisRemoteDataSourceImpl(this._apiClient);

  final ApiClient _apiClient;

  @override
  Future<DiagnosisResultModel> diagnosePerson(
    DiagnosisRequestModel request,
  ) async {
    try {
      final response = await _apiClient.post(
        ApiConfig.diagnosisEndpoint,
        data: request.toApiJson(),
        headers: {
          'Content-Type': 'application/json',
        },
      );

      if (response.data == null) {
        throw Exception('レスポンスデータが空です');
      }

      return DiagnosisResultModel.fromJson(response.data!);
    } catch (e) {
      throw Exception('診断リクエストに失敗しました: $e');
    }
  }

  @override
  Future<DiagnosisResultModel> diagnosePersonalColorEnhanced(
    DiagnosisRequestModel request,
  ) async {
    try {
      final response = await _apiClient.post(
        ApiConfig.diagnosisEnhancedEndpoint,
        data: request.toApiJson(),
        headers: {
          'Content-Type': 'application/json',
        },
      );

      if (response.data == null) {
        throw Exception('レスポンスデータが空です');
      }

      return DiagnosisResultModel.fromJson(response.data!);
    } catch (e) {
      throw Exception('拡張診断リクエストに失敗しました: $e');
    }
  }

  @override
  Future<bool> checkApiHealth() async {
    try {
      final response = await _apiClient.get(ApiConfig.healthCheckEndpoint);
      
      // 200番台のレスポンスが返ってくればAPI健全とみなす
      return response.statusCode != null && 
             response.statusCode! >= 200 && 
             response.statusCode! < 300;
    } catch (e) {
      return false;
    }
  }

  @override
  Future<Map<String, dynamic>> testConnection() async {
    try {
      final response = await _apiClient.get(ApiConfig.healthCheckEndpoint);
      
      return {
        'status': 'success',
        'statusCode': response.statusCode,
        'timestamp': DateTime.now().toIso8601String(),
        'baseUrl': ApiConfig.currentBaseUrl,
        'data': response.data,
      };
    } catch (e) {
      return {
        'status': 'error',
        'error': e.toString(),
        'timestamp': DateTime.now().toIso8601String(),
        'baseUrl': ApiConfig.currentBaseUrl,
      };
    }
  }
}