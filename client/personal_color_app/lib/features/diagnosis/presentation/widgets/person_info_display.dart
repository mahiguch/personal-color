import 'package:flutter/material.dart';
import '../../domain/entities/age_group.dart';
import '../../domain/entities/gender.dart';
import '../services/content_adaptation_service.dart';

/// 人物情報表示ウィジェット
/// プライバシー設定に基づいて年代・性別情報を表示
class PersonInfoDisplay extends StatelessWidget {
  final PersonDisplayInfo displayInfo;
  final AdaptiveUiTheme theme;

  const PersonInfoDisplay({
    super.key,
    required this.displayInfo,
    required this.theme,
  });

  @override
  Widget build(BuildContext context) {
    if (!displayInfo.hasDisplayInfo) {
      return const SizedBox.shrink();
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Color(theme.primaryColor).withValues(alpha: 0.2),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Icon(
            Icons.person,
            color: Color(theme.primaryColor),
            size: 24 * theme.fontScale,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '診断対象',
                  style: TextStyle(
                    fontSize: 12 * theme.fontScale,
                    color: Colors.grey[600],
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    if (displayInfo.showAgeGroup) ...[
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Color(theme.primaryColor).withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          _getAgeGroupText(displayInfo.ageGroup!),
                          style: TextStyle(
                            fontSize: 12 * theme.fontScale,
                            color: Color(theme.primaryColor),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      if (displayInfo.showGender) const SizedBox(width: 8),
                    ],
                    if (displayInfo.showGender) ...[
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Color(theme.accentColor).withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          _getGenderText(displayInfo.gender!),
                          style: TextStyle(
                            fontSize: 12 * theme.fontScale,
                            color: Color(theme.accentColor),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
          if (displayInfo.showConfidence) ...[
            const SizedBox(width: 12),
            Column(
              children: [
                Text(
                  '信頼度',
                  style: TextStyle(
                    fontSize: 10 * theme.fontScale,
                    color: Colors.grey[600],
                  ),
                ),
                Text(
                  '${displayInfo.confidence}%',
                  style: TextStyle(
                    fontSize: 16 * theme.fontScale,
                    fontWeight: FontWeight.bold,
                    color: _getConfidenceColor(displayInfo.confidence),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  String _getAgeGroupText(AgeGroup ageGroup) {
    switch (ageGroup) {
      case AgeGroup.child:
        return '子供';
      case AgeGroup.student:
        return '学生';
      case AgeGroup.adult:
        return '大人';
      case AgeGroup.middleAge:
        return '中年';
      case AgeGroup.senior:
        return 'シニア';
    }
  }

  String _getGenderText(Gender gender) {
    switch (gender) {
      case Gender.male:
        return '男性';
      case Gender.female:
        return '女性';
      case Gender.unknown:
        return '不明';
    }
  }

  Color _getConfidenceColor(int confidence) {
    if (confidence >= 80) {
      return Colors.green;
    } else if (confidence >= 60) {
      return Colors.orange;
    } else {
      return Colors.red;
    }
  }
}