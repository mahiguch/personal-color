import 'package:flutter/material.dart';
import '../../domain/entities/makeup_step.dart';
import '../../domain/services/makeup_experience_service.dart';
import 'age_adaptive_container.dart';

/// メイク経験レベル判定アンケートウィジェット
class ExperienceLevelQuestionnaire extends StatefulWidget {
  const ExperienceLevelQuestionnaire({
    super.key,
    required this.ageGroup,
    required this.onCompleted,
    this.onProgressChanged,
  });

  /// 年齢グループ
  final AgeGroup ageGroup;

  /// アンケート完了時のコールバック
  final Function(ExperienceLevel level, Map<String, dynamic> answers) onCompleted;

  /// 進捗変更時のコールバック
  final Function(double progress)? onProgressChanged;

  @override
  State<ExperienceLevelQuestionnaire> createState() => _ExperienceLevelQuestionnaireState();
}

class _ExperienceLevelQuestionnaireState extends State<ExperienceLevelQuestionnaire>
    with TickerProviderStateMixin {
  late final MakeupExperienceService _experienceService;
  late final List<ExperienceQuestion> _questions;
  late final PageController _pageController;
  late final AnimationController _animationController;
  late final Animation<double> _slideAnimation;

  int _currentQuestionIndex = 0;
  final Map<String, dynamic> _answers = {};

  @override
  void initState() {
    super.initState();
    _experienceService = MakeupExperienceService();
    _questions = _experienceService.getExperienceQuestions(widget.ageGroup);
    _pageController = PageController();

    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _slideAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    );

    _animationController.forward();
  }

  @override
  void dispose() {
    _pageController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  void _nextQuestion() {
    if (_currentQuestionIndex < _questions.length - 1) {
      setState(() {
        _currentQuestionIndex++;
      });
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
      _updateProgress();
    } else {
      _completeQuestionnaire();
    }
  }

  void _previousQuestion() {
    if (_currentQuestionIndex > 0) {
      setState(() {
        _currentQuestionIndex--;
      });
      _pageController.previousPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
      _updateProgress();
    }
  }

  void _updateProgress() {
    final progress = (_currentQuestionIndex + 1) / _questions.length;
    widget.onProgressChanged?.call(progress);
  }

  void _completeQuestionnaire() {
    // 年齢グループを回答に含める
    _answers['age_group'] = widget.ageGroup;

    final experienceLevel = _experienceService.evaluateExperienceLevel(_answers);
    widget.onCompleted(experienceLevel, _answers);
  }

  void _updateAnswer(String questionId, dynamic value) {
    setState(() {
      _answers[questionId] = value;
    });
  }

  bool _canProceed() {
    final currentQuestion = _questions[_currentQuestionIndex];
    return _answers.containsKey(currentQuestion.id);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return AgeAdaptiveContainer(
      ageGroup: widget.ageGroup,
      child: Column(
        children: [
          _buildHeader(theme),
          _buildProgressIndicator(theme),
          Expanded(
            child: PageView.builder(
              controller: _pageController,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _questions.length,
              itemBuilder: (context, index) {
                return SlideTransition(
                  position: Tween<Offset>(
                    begin: const Offset(1.0, 0.0),
                    end: Offset.zero,
                  ).animate(_slideAnimation),
                  child: _buildQuestionPage(_questions[index]),
                );
              },
            ),
          ),
          _buildNavigationButtons(theme),
        ],
      ),
    );
  }

  Widget _buildHeader(ThemeData theme) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            theme.colorScheme.primary,
            theme.colorScheme.primary.withValues(alpha: 0.8),
          ],
        ),
      ),
      child: Column(
        children: [
          Icon(
            Icons.quiz,
            size: 32,
            color: theme.colorScheme.onPrimary,
          ),
          const SizedBox(height: 8),
          AgeAdaptiveText(
            _getHeaderTitle(),
            ageGroup: widget.ageGroup,
            style: theme.textTheme.headlineSmall?.copyWith(
              color: theme.colorScheme.onPrimary,
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 4),
          AgeAdaptiveText(
            _getHeaderSubtitle(),
            ageGroup: widget.ageGroup,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onPrimary.withValues(alpha: 0.9),
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildProgressIndicator(ThemeData theme) {
    final progress = (_currentQuestionIndex + 1) / _questions.length;

    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              AgeAdaptiveText(
                '質問 ${_currentQuestionIndex + 1}',
                ageGroup: widget.ageGroup,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              AgeAdaptiveText(
                '${_questions.length}問中',
                ageGroup: widget.ageGroup,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          LinearProgressIndicator(
            value: progress,
            backgroundColor: theme.colorScheme.surfaceContainerHighest,
            valueColor: AlwaysStoppedAnimation<Color>(theme.colorScheme.primary),
          ),
        ],
      ),
    );
  }

  Widget _buildQuestionPage(ExperienceQuestion question) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AgeAdaptiveText(
            question.question,
            ageGroup: widget.ageGroup,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 24),
          _buildQuestionInput(question),
        ],
      ),
    );
  }

  Widget _buildQuestionInput(ExperienceQuestion question) {
    switch (question.type) {
      case QuestionType.singleChoice:
        return _buildSingleChoice(question);
      case QuestionType.multipleChoice:
        return _buildMultipleChoice(question);
      case QuestionType.scale:
        return _buildScale(question);
    }
  }

  Widget _buildSingleChoice(ExperienceQuestion question) {
    final selectedValue = _answers[question.id] as String?;

    return Column(
      children: question.options.map((option) {
        final isSelected = selectedValue == option;
        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: AgeAdaptiveContainer(
            ageGroup: widget.ageGroup,
            onTap: () => _updateAnswer(question.id, option),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: isSelected
                    ? Theme.of(context).colorScheme.primaryContainer
                    : Theme.of(context).colorScheme.surface,
                border: Border.all(
                  color: isSelected
                      ? Theme.of(context).colorScheme.primary
                      : Theme.of(context).colorScheme.outline.withValues(alpha: 0.3),
                  width: 2,
                ),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Icon(
                    isSelected ? Icons.radio_button_checked : Icons.radio_button_off,
                    color: isSelected
                        ? Theme.of(context).colorScheme.primary
                        : Theme.of(context).colorScheme.outline,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: AgeAdaptiveText(
                      option,
                      ageGroup: widget.ageGroup,
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        color: isSelected
                            ? Theme.of(context).colorScheme.onPrimaryContainer
                            : Theme.of(context).colorScheme.onSurface,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildMultipleChoice(ExperienceQuestion question) {
    final selectedValues = _answers[question.id] as List<String>? ?? [];

    return Column(
      children: question.options.map((option) {
        final isSelected = selectedValues.contains(option);
        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: AgeAdaptiveContainer(
            ageGroup: widget.ageGroup,
            onTap: () {
              List<String> newValues = List.from(selectedValues);
              if (isSelected) {
                newValues.remove(option);
              } else {
                newValues.add(option);
              }
              _updateAnswer(question.id, newValues);
            },
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: isSelected
                    ? Theme.of(context).colorScheme.primaryContainer
                    : Theme.of(context).colorScheme.surface,
                border: Border.all(
                  color: isSelected
                      ? Theme.of(context).colorScheme.primary
                      : Theme.of(context).colorScheme.outline.withValues(alpha: 0.3),
                  width: 2,
                ),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Icon(
                    isSelected ? Icons.check_box : Icons.check_box_outline_blank,
                    color: isSelected
                        ? Theme.of(context).colorScheme.primary
                        : Theme.of(context).colorScheme.outline,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: AgeAdaptiveText(
                      option,
                      ageGroup: widget.ageGroup,
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        color: isSelected
                            ? Theme.of(context).colorScheme.onPrimaryContainer
                            : Theme.of(context).colorScheme.onSurface,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildScale(ExperienceQuestion question) {
    final value = _answers[question.id] as int? ?? question.minValue ?? 1;
    final minValue = question.minValue ?? 1;
    final maxValue = question.maxValue ?? 10;

    return Column(
      children: [
        AgeAdaptiveText(
          '現在の値: $value',
          ageGroup: widget.ageGroup,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
            color: Theme.of(context).colorScheme.primary,
          ),
        ),
        const SizedBox(height: 16),
        SliderTheme(
          data: SliderTheme.of(context).copyWith(
            trackHeight: widget.ageGroup == AgeGroup.child ? 8 : 4,
            thumbShape: RoundSliderThumbShape(
              enabledThumbRadius: widget.ageGroup == AgeGroup.child ? 16 : 12,
            ),
          ),
          child: Slider(
            value: value.toDouble(),
            min: minValue.toDouble(),
            max: maxValue.toDouble(),
            divisions: maxValue - minValue,
            label: value.toString(),
            onChanged: (newValue) {
              _updateAnswer(question.id, newValue.round());
            },
          ),
        ),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            AgeAdaptiveText(
              _getScaleLabel(minValue, widget.ageGroup),
              ageGroup: widget.ageGroup,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
            AgeAdaptiveText(
              _getScaleLabel(maxValue, widget.ageGroup),
              ageGroup: widget.ageGroup,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildNavigationButtons(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(20),
      child: Row(
        children: [
          if (_currentQuestionIndex > 0)
            Expanded(
              child: AgeAdaptiveButton(
                ageGroup: widget.ageGroup,
                onPressed: _previousQuestion,
                style: ElevatedButton.styleFrom(
                  backgroundColor: theme.colorScheme.surfaceContainerHighest,
                  foregroundColor: theme.colorScheme.onSurface,
                ),
                child: AgeAdaptiveText(
                  '戻る',
                  ageGroup: widget.ageGroup,
                ),
              ),
            ),
          if (_currentQuestionIndex > 0) const SizedBox(width: 16),
          Expanded(
            flex: 2,
            child: AgeAdaptiveButton(
              ageGroup: widget.ageGroup,
              onPressed: _canProceed() ? _nextQuestion : null,
              child: AgeAdaptiveText(
                _currentQuestionIndex == _questions.length - 1 ? '完了' : '次へ',
                ageGroup: widget.ageGroup,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _getHeaderTitle() {
    switch (widget.ageGroup) {
      case AgeGroup.child:
        return 'メイクのことを教えて！';
      case AgeGroup.student:
        return 'メイク経験を教えてください';
      case AgeGroup.adult:
        return 'メイク経験レベル診断';
      case AgeGroup.middleAge:
        return 'メイク経験レベル診断';
      case AgeGroup.senior:
        return 'メイク経験レベル診断';
    }
  }

  String _getHeaderSubtitle() {
    switch (widget.ageGroup) {
      case AgeGroup.child:
        return 'あなたにぴったりのメイクを見つけよう';
      case AgeGroup.student:
        return 'あなたに合ったメイクガイドを提供します';
      case AgeGroup.adult:
        return 'あなたのレベルに最適化されたコンテンツを提供';
      case AgeGroup.middleAge:
        return 'あなたのレベルに最適化されたコンテンツを提供';
      case AgeGroup.senior:
        return 'あなたのレベルに最適化されたコンテンツを提供';
    }
  }

  String _getScaleLabel(int value, AgeGroup ageGroup) {
    if (ageGroup == AgeGroup.child) {
      return value == 1 ? 'ぜんぜん' : 'とても';
    }
    return value == 1 ? '全く自信がない' : '非常に自信がある';
  }
}
