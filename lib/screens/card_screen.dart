import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../app.dart';
import '../data/models/question.dart';
import '../providers/question_provider.dart';
import '../widgets/answer_reveal.dart';

class CardScreen extends ConsumerStatefulWidget {
  final List<Question> questions;

  const CardScreen({super.key, required this.questions});

  @override
  ConsumerState<CardScreen> createState() => _CardScreenState();
}

class _CardScreenState extends ConsumerState<CardScreen> {
  late List<Question> _shuffledQuestions;
  late PageController _pageController;
  int _currentIndex = 0;
  final Map<int, bool> _revealedAnswers = {};

  @override
  void initState() {
    super.initState();
    _shuffledQuestions = List.from(widget.questions)..shuffle();
    _pageController = PageController();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _goToNext() {
    if (_currentIndex < _shuffledQuestions.length - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    } else {
      context.pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final allQuestions = ref.watch(questionsProvider).value ?? [];

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          onPressed: () => context.pop(),
          icon: const Icon(Icons.close),
        ),
        title: Text(
          '${_currentIndex + 1} / ${_shuffledQuestions.length}',
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: true,
        actions: [
          Builder(
            builder: (context) {
              final q = _shuffledQuestions[_currentIndex];
              final liveQuestion = allQuestions.firstWhere(
                (aq) => aq.id == q.id,
                orElse: () => q,
              );
              return IconButton(
                onPressed: () {
                  ref.read(questionsProvider.notifier).toggleBookmark(q.id);
                },
                icon: Icon(
                  liveQuestion.isBookmarked
                      ? Icons.bookmark
                      : Icons.bookmark_border,
                  color: liveQuestion.isBookmarked ? Colors.amber : null,
                ),
              );
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // 진행 바
          LinearProgressIndicator(
            value: (_currentIndex + 1) / _shuffledQuestions.length,
            backgroundColor: colorScheme.surfaceContainerHighest,
            valueColor: AlwaysStoppedAnimation<Color>(
              getCategoryColor(_shuffledQuestions[_currentIndex].category),
            ),
            minHeight: 3,
          ),

          // 카드 영역
          Expanded(
            child: PageView.builder(
              controller: _pageController,
              itemCount: _shuffledQuestions.length,
              reverse: false, // 오른쪽 스와이프 = 다음
              onPageChanged: (index) {
                setState(() {
                  _currentIndex = index;
                });
              },
              itemBuilder: (context, index) {
                final question = _shuffledQuestions[index];
                final isRevealed = _revealedAnswers[index] ?? false;
                final color = getCategoryColor(question.category);
                final isDark = Theme.of(context).brightness == Brightness.dark;

                return SingleChildScrollView(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // 카테고리 + 섹션
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: color.withOpacity(isDark ? 0.3 : 0.12),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              question.category,
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: color,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              question.section,
                              style: TextStyle(
                                fontSize: 12,
                                color: colorScheme.onSurface.withOpacity(0.45),
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 32),

                      // 질문 카드
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(20),
                          color: colorScheme.surfaceContainerHighest
                              .withOpacity(0.4),
                          border: Border.all(
                            color: colorScheme.outline.withOpacity(0.1),
                          ),
                        ),
                        child: Text(
                          question.question,
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                            height: 1.5,
                            color: colorScheme.onSurface,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),

                      // 답변 영역
                      AnswerReveal(
                        isRevealed: isRevealed,
                        answer: question.answer,
                      ),

                      const SizedBox(height: 32),

                      // 답 보기 / 다음 버튼
                      SizedBox(
                        width: double.infinity,
                        height: 52,
                        child: isRevealed
                            ? FilledButton.icon(
                                onPressed: _goToNext,
                                icon: const Icon(Icons.arrow_forward, size: 18),
                                label: Text(
                                  _currentIndex < _shuffledQuestions.length - 1
                                      ? '다음'
                                      : '완료',
                                ),
                              )
                            : OutlinedButton.icon(
                                onPressed: () {
                                  setState(() {
                                    _revealedAnswers[index] = true;
                                  });
                                },
                                icon: const Icon(Icons.visibility_outlined,
                                    size: 18),
                                label: const Text('답 보기'),
                              ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
