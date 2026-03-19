import 'package:flutter/material.dart';

import '../app.dart';
import '../data/models/question.dart';

class QuestionListTile extends StatelessWidget {
  final Question question;
  final VoidCallback onTap;
  final VoidCallback onBookmarkTap;
  final VoidCallback onLongPress;

  const QuestionListTile({
    super.key,
    required this.question,
    required this.onTap,
    required this.onBookmarkTap,
    required this.onLongPress,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final pColor = priorityColor(question.priority);

    return InkWell(
      onTap: onTap,
      onLongPress: onLongPress,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          color: colorScheme.surfaceContainerHighest.withOpacity(0.3),
        ),
        child: Row(
          children: [
            Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: pColor,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                question.question,
                style: TextStyle(
                  fontSize: 14,
                  height: 1.5,
                  color: colorScheme.onSurface,
                ),
              ),
            ),
            const SizedBox(width: 8),
            GestureDetector(
              onTap: onBookmarkTap,
              child: Icon(
                question.isBookmarked
                    ? Icons.bookmark
                    : Icons.bookmark_border,
                color: question.isBookmarked
                    ? Colors.amber
                    : colorScheme.onSurface.withOpacity(0.3),
                size: 22,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
