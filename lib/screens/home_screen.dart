import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../providers/question_provider.dart';
import '../widgets/category_card.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final questionsAsync = ref.watch(questionsProvider);
    final categories = ref.watch(categoriesProvider);
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      body: SafeArea(
        child: questionsAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, st) => Center(child: Text('오류: $e')),
          data: (_) => CustomScrollView(
            slivers: [
              // 앱바
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(24, 24, 24, 8),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '야르',
                            style: TextStyle(
                              fontSize: 32,
                              fontWeight: FontWeight.w800,
                              color: colorScheme.onSurface,
                              letterSpacing: -0.5,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'json 기반 단어/질문 토글 노트 앱',
                            style: TextStyle(
                              fontSize: 14,
                              color: colorScheme.onSurface.withOpacity(0.5),
                            ),
                          ),
                        ],
                      ),
                      IconButton.filled(
                        onPressed: () => context.push('/bookmarks'),
                        icon: const Icon(Icons.bookmark_outline),
                        style: IconButton.styleFrom(
                          backgroundColor: colorScheme.surfaceContainerHighest,
                          foregroundColor: colorScheme.onSurface,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // 카테고리 그리드
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(24, 16, 24, 16),
                sliver: SliverGrid(
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    mainAxisSpacing: 12,
                    crossAxisSpacing: 12,
                    childAspectRatio: 1.3,
                  ),
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      final category = categories[index];
                      final count = ref.watch(
                        questionCountByCategoryProvider(category),
                      );
                      return CategoryCard(
                        category: category,
                        questionCount: count,
                        onTap: () => context.push(
                          '/category/${Uri.encodeComponent(category)}',
                        ),
                      );
                    },
                    childCount: categories.length,
                  ),
                ),
              ),

              // 전체 랜덤 시작 버튼
              SliverToBoxAdapter(
                child: Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                  child: SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: FilledButton.icon(
                      onPressed: () {
                        final allQuestions =
                            ref.read(questionsProvider).value?.toList() ?? [];
                        if (allQuestions.isNotEmpty) {
                          allQuestions.shuffle();
                          context.push('/cards', extra: allQuestions);
                        }
                      },
                      icon: const Icon(Icons.shuffle),
                      label: const Text('전체 랜덤 시작'),
                    ),
                  ),
                ),
              ),

              const SliverToBoxAdapter(
                child: SizedBox(height: 32),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
