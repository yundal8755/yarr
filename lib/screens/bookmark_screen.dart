import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../providers/question_provider.dart';
import '../widgets/question_list_tile.dart';

class BookmarkScreen extends ConsumerWidget {
  const BookmarkScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bookmarked = ref.watch(bookmarkedQuestionsProvider);
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          '북마크',
          style: TextStyle(fontWeight: FontWeight.w700),
        ),
      ),
      body: bookmarked.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.bookmark_outline,
                    size: 64,
                    color: colorScheme.onSurface.withOpacity(0.2),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    '북마크한 질문이 없습니다',
                    style: TextStyle(
                      fontSize: 16,
                      color: colorScheme.onSurface.withOpacity(0.4),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '학습 중 질문을 북마크해보세요',
                    style: TextStyle(
                      fontSize: 13,
                      color: colorScheme.onSurface.withOpacity(0.3),
                    ),
                  ),
                ],
              ),
            )
          : Column(
              children: [
                Expanded(
                  child: ListView.builder(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
                    itemCount: bookmarked.length,
                    itemBuilder: (context, index) {
                      final q = bookmarked[index];
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: QuestionListTile(
                          question: q,
                          onTap: () {
                            context.push('/cards', extra: [q]);
                          },
                          onBookmarkTap: () {
                            ref
                                .read(questionsProvider.notifier)
                                .toggleBookmark(q.id);
                          },
                          onLongPress: () {},
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
      floatingActionButton: bookmarked.isNotEmpty
          ? Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: SizedBox(
                width: double.infinity,
                height: 52,
                child: FilledButton.icon(
                  onPressed: () {
                    final shuffled = List.from(bookmarked)..shuffle();
                    context.push('/cards', extra: shuffled);
                  },
                  icon: const Icon(Icons.shuffle, size: 18),
                  label: const Text('북마크 랜덤 시작'),
                ),
              ),
            )
          : null,
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
    );
  }
}
