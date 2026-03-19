import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../app.dart';
import '../data/models/question.dart';
import '../providers/question_provider.dart';
import '../widgets/question_list_tile.dart';

class CategoryScreen extends ConsumerStatefulWidget {
  final String category;

  const CategoryScreen({super.key, required this.category});

  @override
  ConsumerState<CategoryScreen> createState() => _CategoryScreenState();
}

class _CategoryScreenState extends ConsumerState<CategoryScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  QuestionFilter _currentFilter = QuestionFilter.all;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _tabController.addListener(() {
      if (!_tabController.indexIsChanging) {
        setState(() {
          switch (_tabController.index) {
            case 0:
              _currentFilter = QuestionFilter.all;
            case 1:
              _currentFilter = QuestionFilter.priority1;
            case 2:
              _currentFilter = QuestionFilter.bookmarked;
          }
        });
      }
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _showPriorityBottomSheet(Question question) {
    final colorScheme = Theme.of(context).colorScheme;

    showModalBottomSheet(
      context: context,
      backgroundColor: colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  child: Text(
                    '우선순위 변경',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: colorScheme.onSurface,
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  child: Text(
                    question.question,
                    style: TextStyle(
                      fontSize: 13,
                      color: colorScheme.onSurface.withOpacity(0.5),
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(height: 20),
                ...List.generate(3, (index) {
                  final p = index + 1;
                  final labels = ['최고 우선순위', '보통', '낮음'];
                  final isSelected = question.priority == p;
                  return ListTile(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    leading: Container(
                      width: 12,
                      height: 12,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: priorityColor(p),
                      ),
                    ),
                    title: Text(
                      labels[index],
                      style: TextStyle(
                        fontWeight:
                            isSelected ? FontWeight.w700 : FontWeight.w400,
                      ),
                    ),
                    trailing: isSelected
                        ? Icon(Icons.check, color: colorScheme.primary)
                        : null,
                    onTap: () {
                      ref
                          .read(questionsProvider.notifier)
                          .updatePriority(question.id, p);
                      Navigator.pop(ctx);
                    },
                  );
                }),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final category = widget.category;
    final sections = ref.watch(
      questionsBySectionProvider((category: category, filter: _currentFilter)),
    );
    final color = getCategoryColor(category);
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          category,
          style: const TextStyle(fontWeight: FontWeight.w700),
        ),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: '전체'),
            Tab(text: '우선순위 1'),
            Tab(text: '북마크'),
          ],
          indicatorColor: color,
          labelColor: color,
        ),
      ),
      body: sections.isEmpty
          ? Center(
              child: Text(
                '해당하는 질문이 없습니다',
                style: TextStyle(
                  color: colorScheme.onSurface.withOpacity(0.4),
                ),
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
              itemCount: sections.entries.length,
              itemBuilder: (context, sectionIndex) {
                final entry = sections.entries.elementAt(sectionIndex);
                final sectionName = entry.key;
                final questions = entry.value;

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (sectionIndex > 0) const SizedBox(height: 24),
                    Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 4, vertical: 8),
                      child: Row(
                        children: [
                          Container(
                            width: 4,
                            height: 20,
                            decoration: BoxDecoration(
                              color: color,
                              borderRadius: BorderRadius.circular(2),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              sectionName,
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w700,
                                color: colorScheme.onSurface.withOpacity(0.8),
                              ),
                            ),
                          ),
                          Text(
                            '${questions.length}문항',
                            style: TextStyle(
                              fontSize: 12,
                              color: colorScheme.onSurface.withOpacity(0.4),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 4),
                    ...questions.map(
                      (q) => Padding(
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
                          onLongPress: () => _showPriorityBottomSheet(q),
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
      floatingActionButton: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: SizedBox(
          width: double.infinity,
          height: 52,
          child: FilledButton.icon(
            onPressed: () {
              final allFiltered =
                  sections.values.expand((list) => list).toList();
              if (allFiltered.isNotEmpty) {
                allFiltered.shuffle();
                context.push('/cards', extra: allFiltered);
              }
            },
            icon: const Icon(Icons.shuffle, size: 18),
            label: const Text('이 카테고리 랜덤 시작'),
            style: FilledButton.styleFrom(
              backgroundColor: color.withOpacity(isDark ? 0.8 : 1.0),
            ),
          ),
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
    );
  }
}
