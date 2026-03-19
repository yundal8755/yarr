import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/models/question.dart';
import '../data/repositories/question_repository.dart';

// Repository Provider
final questionRepositoryProvider = Provider<QuestionRepository>((ref) {
  return QuestionRepository();
});

// 전체 질문 로드
class QuestionsNotifier extends AsyncNotifier<List<Question>> {
  @override
  Future<List<Question>> build() async {
    final repository = ref.watch(questionRepositoryProvider);
    return repository.loadQuestions();
  }

  Future<void> toggleBookmark(String id) async {
    final repository = ref.read(questionRepositoryProvider);
    await repository.toggleBookmark(id);

    state = await AsyncValue.guard(() async {
      final questions = state.value ?? [];
      return questions.map((q) {
        if (q.id == id) {
          return q.copyWith(isBookmarked: !q.isBookmarked);
        }
        return q;
      }).toList();
    });
  }

  Future<void> updatePriority(String id, int priority) async {
    final repository = ref.read(questionRepositoryProvider);
    await repository.updatePriority(id, priority);

    state = await AsyncValue.guard(() async {
      final questions = state.value ?? [];
      return questions.map((q) {
        if (q.id == id) {
          return q.copyWith(priority: priority);
        }
        return q;
      }).toList();
    });
  }
}

final questionsProvider =
    AsyncNotifierProvider<QuestionsNotifier, List<Question>>(() {
  return QuestionsNotifier();
});

// 카테고리 목록
final categoriesProvider = Provider<List<String>>((ref) {
  final questionsAsync = ref.watch(questionsProvider);
  return questionsAsync.whenOrNull(
        data: (questions) {
          // questions.json에 등장하는 순서를 유지 (중복 제거)
          final seen = <String>{};
          final categories = <String>[];
          for (final q in questions) {
            if (seen.add(q.category)) {
              categories.add(q.category);
            }
          }
          return categories;
        },
      ) ??
      [];
});

// 카테고리별 질문 수
final questionCountByCategoryProvider =
    Provider.family<int, String>((ref, category) {
  final questionsAsync = ref.watch(questionsProvider);
  return questionsAsync.whenOrNull(
        data: (questions) =>
            questions.where((q) => q.category == category).length,
      ) ??
      0;
});

// 카테고리별 질문 (필터 포함)
enum QuestionFilter { all, priority1, bookmarked }

final filteredQuestionsProvider =
    Provider.family<List<Question>, ({String category, QuestionFilter filter})>(
        (ref, args) {
  final questionsAsync = ref.watch(questionsProvider);
  return questionsAsync.whenOrNull(
        data: (questions) {
          var filtered =
              questions.where((q) => q.category == args.category).toList();

          switch (args.filter) {
            case QuestionFilter.priority1:
              filtered = filtered.where((q) => q.priority == 1).toList();
              break;
            case QuestionFilter.bookmarked:
              filtered = filtered.where((q) => q.isBookmarked).toList();
              break;
            case QuestionFilter.all:
              break;
          }

          return filtered;
        },
      ) ??
      [];
});

// 북마크된 질문만
final bookmarkedQuestionsProvider = Provider<List<Question>>((ref) {
  final questionsAsync = ref.watch(questionsProvider);
  return questionsAsync.whenOrNull(
        data: (questions) => questions.where((q) => q.isBookmarked).toList(),
      ) ??
      [];
});

// 섹션별 그룹핑
final questionsBySectionProvider = Provider.family<Map<String, List<Question>>,
    ({String category, QuestionFilter filter})>((ref, args) {
  final questions = ref.watch(filteredQuestionsProvider(args));
  final Map<String, List<Question>> grouped = {};
  for (final q in questions) {
    grouped.putIfAbsent(q.section, () => []).add(q);
  }
  return grouped;
});
