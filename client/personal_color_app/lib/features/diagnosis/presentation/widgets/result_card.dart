import 'package:flutter/material.dart';
import 'dart:io';
import '../../domain/entities/diagnosis_result.dart';

class ResultCard extends StatelessWidget {
  final DiagnosisResult result;
  final String originalImagePath;

  const ResultCard({
    super.key,
    required this.result,
    required this.originalImagePath,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.15),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          // 診断結果タイトル
          _buildResultHeader(),
          
          const SizedBox(height: 20),
          
          // 画像と結果の表示
          Row(
            children: [
              // オリジナル画像
              _buildOriginalImage(),
              
              const SizedBox(width: 20),
              
              // 診断結果詳細
              Expanded(
                child: _buildResultDetails(context),
              ),
            ],
          ),
          
          const SizedBox(height: 20),
          
          // 信頼度インジケーター
          _buildConfidenceIndicator(),
        ],
      ),
    );
  }

  Widget _buildResultHeader() {
    return Column(
      children: [
        Text(
          'あなたは...',
          style: TextStyle(
            fontSize: 16,
            color: Colors.grey[600],
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          decoration: BoxDecoration(
            color: _getTypeColor(result.diagnosisType).withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(25),
            border: Border.all(
              color: _getTypeColor(result.diagnosisType),
              width: 2,
            ),
          ),
          child: Text(
            result.diagnosisType.displayName,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: _getTypeColor(result.diagnosisType),
            ),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          result.diagnosisType.description,
          style: TextStyle(
            fontSize: 14,
            color: Colors.grey[600],
            fontStyle: FontStyle.italic,
          ),
        ),
      ],
    );
  }

  Widget _buildOriginalImage() {
    return Container(
      width: 120,
      height: 120,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: File(originalImagePath).existsSync()
            ? Image.file(
                File(originalImagePath),
                fit: BoxFit.cover,
              )
            : Container(
                color: Colors.grey[200],
                child: Icon(
                  Icons.person,
                  size: 60,
                  color: Colors.grey[400],
                ),
              ),
      ),
    );
  }

  Widget _buildResultDetails(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: _getTypeColor(result.diagnosisType).withValues(alpha: 0.05),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: _getTypeColor(result.diagnosisType).withValues(alpha: 0.3),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    _getTypeIcon(result.diagnosisType),
                    color: _getTypeColor(result.diagnosisType),
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'あなたのタイプ',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: _getTypeColor(result.diagnosisType),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                result.explanation,
                style: TextStyle(
                  fontSize: 13,
                  color: Colors.grey[700],
                  height: 1.4,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildConfidenceIndicator() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              '診断の確信度',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Colors.grey[700],
              ),
            ),
            Text(
              '${result.confidence}%',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: _getTypeColor(result.diagnosisType),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Container(
          height: 8,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(4),
            color: Colors.grey[200],
          ),
          child: FractionallySizedBox(
            alignment: Alignment.centerLeft,
            widthFactor: result.confidence / 100.0,
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(4),
                gradient: LinearGradient(
                  colors: [
                    _getTypeColor(result.diagnosisType).withValues(alpha: 0.7),
                    _getTypeColor(result.diagnosisType),
                  ],
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          _getConfidenceText(result.confidence),
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey[600],
          ),
        ),
      ],
    );
  }

  Color _getTypeColor(PersonalColorType type) {
    switch (type) {
      case PersonalColorType.spring:
        return const Color(0xFFFF9800); // 明るいオレンジ
      case PersonalColorType.summer:
        return const Color(0xFF9C27B0); // エレガントな紫
      case PersonalColorType.autumn:
        return const Color(0xFFFF5722); // 深いオレンジ
      case PersonalColorType.winter:
        return const Color(0xFF2E7D32); // 深い緑
    }
  }

  IconData _getTypeIcon(PersonalColorType type) {
    switch (type) {
      case PersonalColorType.spring:
        return Icons.wb_sunny; // 太陽
      case PersonalColorType.summer:
        return Icons.beach_access; // ビーチ
      case PersonalColorType.autumn:
        return Icons.eco; // 葉っぱ
      case PersonalColorType.winter:
        return Icons.ac_unit; // 雪の結晶
    }
  }


  String _getConfidenceText(int confidence) {
    if (confidence >= 90) {
      return 'とても高い確信度です！';
    } else if (confidence >= 80) {
      return '高い確信度です';
    } else if (confidence >= 70) {
      return '良い確信度です';
    } else {
      return '参考程度にお考えください';
    }
  }
}