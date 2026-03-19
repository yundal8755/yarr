import 'package:flutter/material.dart';

import '../app.dart';

class CategoryCard extends StatelessWidget {
  final String category;
  final int questionCount;
  final VoidCallback onTap;

  const CategoryCard({
    super.key,
    required this.category,
    required this.questionCount,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final color = getCategoryColor(category);
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              color.withOpacity(isDark ? 0.35 : 0.35),
              color.withOpacity(isDark ? 0.15 : 0.15),
            ],
          ),
          border: Border.all(
            color: color.withOpacity(isDark ? 0.4 : 0.25),
            width: 1,
          ),
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(16),
            onTap: onTap,
            splashColor: color.withOpacity(0.2),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Spacer(),
                  Text(
                    category,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: colorScheme.onSurface,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '$questionCount문항',
                    style: TextStyle(
                      fontSize: 13,
                      color: colorScheme.onSurface.withOpacity(0.6),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
