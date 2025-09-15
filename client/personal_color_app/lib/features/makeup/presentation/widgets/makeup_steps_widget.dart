import 'package:flutter/material.dart';
import '../../domain/entities/makeup_step.dart';
import '../config/age_adaptive_ui_config.dart';

/// メイクアップステップ表示ウィジェット
/// ステップバイステップのメイク手順を年齢適応型で表示
class MakeupStepsWidget extends StatelessWidget {
  const MakeupStepsWidget({
    super.key,
    required this.steps,
    required this.ageGroup,
    this.onStepTap,
    this.showEstimatedTime = true,
    this.showDifficulty = true,
  });

  /// メイクステップリスト
  final List<MakeupStep> steps;

  /// 年齢グループ（説明文の適応に使用）
  final AgeGroup ageGroup;

  /// ステップタップ時のコールバック
  final Function(MakeupStep)? onStepTap;

  /// 所要時間表示フラグ
  final bool showEstimatedTime;

  /// 難易度表示フラグ
  final bool showDifficulty;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final sortedSteps = _sortStepsByPriority(steps);

    if (sortedSteps.isEmpty) {
      return _buildEmptyState(theme);
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildHeader(theme),
        const SizedBox(height: 16),
        _buildStepsList(theme, sortedSteps),
        if (showEstimatedTime && _getTotalTime() > 0) ...[
          const SizedBox(height: 12),
          _buildTotalTime(theme),
        ],
      ],
    );
  }

  Widget _buildHeader(ThemeData theme) {
    final ui = AgeAdaptiveUiPresets.of(ageGroup);
    return Row(
      children: [
        Icon(
          Icons.format_list_numbered,
          color: theme.colorScheme.primary,
          size: 24 * ui.iconScale,
        ),
        const SizedBox(width: 8),
        Text(
          _getAgeAdaptedTitle(),
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
            color: theme.colorScheme.onSurface,
          ),
        ),
        const Spacer(),
        if (steps.isNotEmpty)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: theme.colorScheme.primary,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              '${steps.length}ステップ',
              style: TextStyle(
                color: theme.colorScheme.onPrimary,
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildStepsList(ThemeData theme, List<MakeupStep> sortedSteps) {
    return Column(
      children: sortedSteps.asMap().entries.map((entry) {
        final index = entry.key;
        final step = entry.value;
        return Padding(
          padding: EdgeInsets.only(bottom: index < sortedSteps.length - 1 ? 12 : 0),
          child: _buildStepCard(theme, step),
        );
      }).toList(),
    );
  }

  Widget _buildStepCard(ThemeData theme, MakeupStep step) {
    return Card(
      elevation: 2,
      child: InkWell(
        onTap: onStepTap != null ? () => onStepTap!(step) : null,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildStepHeader(theme, step),
              const SizedBox(height: 8),
              _buildStepInstruction(theme, step),
              if (step.tips != null) ...[
                const SizedBox(height: 8),
                _buildStepTips(theme, step),
              ],
              if (step.requiredTools.isNotEmpty) ...[
                const SizedBox(height: 8),
                _buildRequiredTools(theme, step),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStepHeader(ThemeData theme, MakeupStep step) {
    final ui = AgeAdaptiveUiPresets.of(ageGroup);
    return Row(
      children: [
        // ステップ番号
        Container(
          width: 32 * ui.iconScale,
          height: 32 * ui.iconScale,
          decoration: BoxDecoration(
            color: theme.colorScheme.primary,
            shape: BoxShape.circle,
          ),
          child: Center(
            child: Text(
              step.step.toString(),
              style: TextStyle(
                color: theme.colorScheme.onPrimary,
                fontWeight: FontWeight.bold,
                fontSize: 14 * ui.iconScale,
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        // カテゴリ名
        Expanded(
          child: Text(
            step.category.displayName,
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.bold,
              color: theme.colorScheme.onSurface,
            ),
          ),
        ),
        // 所要時間・難易度バッジ
        Row(
          children: [
            if (showEstimatedTime && step.estimatedTime != null)
              _buildTimeBadge(theme, step),
            if (showDifficulty) ...[
              const SizedBox(width: 8),
              _buildDifficultyBadge(theme, step),
            ],
          ],
        ),
      ],
    );
  }

  Widget _buildStepInstruction(ThemeData theme, MakeupStep step) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        step.instruction,
        style: theme.textTheme.bodyMedium?.copyWith(
          color: theme.colorScheme.onSurfaceVariant,
          height: 1.4,
        ),
      ),
    );
  }

  Widget _buildStepTips(ThemeData theme, MakeupStep step) {
    final adaptedTips = step.getAgeAdaptedTips(ageGroup);
    if (adaptedTips.isEmpty) return const SizedBox.shrink();

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: theme.colorScheme.primaryContainer.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: theme.colorScheme.primary.withValues(alpha: 0.3),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.lightbulb_outline,
            size: 16,
            color: theme.colorScheme.primary,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              adaptedTips,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
                height: 1.3,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRequiredTools(ThemeData theme, MakeupStep step) {
    return Wrap(
      spacing: 6,
      runSpacing: 6,
      children: step.requiredTools.map((tool) {
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: theme.colorScheme.secondary.withValues(alpha: 0.2),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            tool,
            style: TextStyle(
              fontSize: 11,
              color: theme.colorScheme.onSurfaceVariant,
              fontWeight: FontWeight.w500,
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildTimeBadge(ThemeData theme, MakeupStep step) {
    final ui = AgeAdaptiveUiPresets.of(ageGroup);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: theme.colorScheme.tertiary.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.schedule,
            size: 12 * ui.iconScale,
            color: theme.colorScheme.tertiary,
          ),
          const SizedBox(width: 2),
          Text(
            step.estimatedTimeDisplay,
            style: TextStyle(
              fontSize: 10 * ui.iconScale,
              color: theme.colorScheme.tertiary,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDifficultyBadge(ThemeData theme, MakeupStep step) {
    final difficultyColor = _getDifficultyColor(theme, step.difficultyLevel);
    final ui = AgeAdaptiveUiPresets.of(ageGroup);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: difficultyColor.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        step.difficultyLevel.displayName,
        style: TextStyle(
          fontSize: 10 * ui.iconScale,
          color: difficultyColor,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _buildTotalTime(ThemeData theme) {
    final totalTime = _getTotalTime();
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: theme.colorScheme.primary.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.timer,
            size: 16,
            color: theme.colorScheme.primary,
          ),
          const SizedBox(width: 8),
          Text(
            '合計所要時間: 約$totalTime分',
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.primary,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(ThemeData theme) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Icon(
            Icons.format_list_numbered_outlined,
            size: 48,
            color: theme.colorScheme.outline,
          ),
          const SizedBox(height: 12),
          Text(
            'メイク手順が登録されていません',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.outline,
            ),
          ),
        ],
      ),
    );
  }

  List<MakeupStep> _sortStepsByPriority(List<MakeupStep> steps) {
    final sortedSteps = List<MakeupStep>.from(steps);
    sortedSteps.sort((a, b) {
      // まずカテゴリの優先順位で並び替え
      final categoryComparison = a.category.priority.compareTo(b.category.priority);
      if (categoryComparison != 0) return categoryComparison;

      // 同じカテゴリの場合は、ステップ番号で並び替え
      return a.step.compareTo(b.step);
    });
    return sortedSteps;
  }

  String _getAgeAdaptedTitle() {
    switch (ageGroup) {
      case AgeGroup.child:
        return 'メイクの手順';
      case AgeGroup.student:
        return 'メイクの手順';
      case AgeGroup.adult:
        return 'ステップバイステップ手順';
      case AgeGroup.middleAge:
        return 'ステップバイステップ手順';
      case AgeGroup.senior:
        return 'ステップバイステップ手順';
    }
  }

  Color _getDifficultyColor(ThemeData theme, DifficultyLevel level) {
    switch (level) {
      case DifficultyLevel.beginner:
        return Colors.green;
      case DifficultyLevel.intermediate:
        return Colors.orange;
      case DifficultyLevel.advanced:
        return Colors.red;
    }
  }

  int _getTotalTime() {
    return steps
        .where((step) => step.estimatedTime != null)
        .fold(0, (sum, step) => sum + step.estimatedTime!);
  }
}
