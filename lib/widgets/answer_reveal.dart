import 'package:flutter/material.dart';

class AnswerReveal extends StatefulWidget {
  final bool isRevealed;
  final String answer;

  const AnswerReveal({
    super.key,
    required this.isRevealed,
    required this.answer,
  });

  @override
  State<AnswerReveal> createState() => _AnswerRevealState();
}

class _AnswerRevealState extends State<AnswerReveal>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 350),
      vsync: this,
    );
    _animation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOut,
    );

    if (widget.isRevealed) {
      _controller.value = 1.0;
    }
  }

  @override
  void didUpdateWidget(covariant AnswerReveal oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isRevealed && !oldWidget.isRevealed) {
      _controller.forward();
    } else if (!widget.isRevealed && oldWidget.isRevealed) {
      _controller.reverse();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final hasAnswer = widget.answer.isNotEmpty;

    return SizeTransition(
      sizeFactor: _animation,
      axisAlignment: -1.0,
      child: FadeTransition(
        opacity: _animation,
        child: Container(
          width: double.infinity,
          margin: const EdgeInsets.only(top: 16),
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            color: colorScheme.surfaceContainerHighest.withOpacity(0.5),
            border: Border.all(
              color: colorScheme.outline.withOpacity(0.15),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.lightbulb_outline,
                    size: 18,
                    color: Colors.amber.shade600,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '모범 답안',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: colorScheme.onSurface.withOpacity(0.7),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                hasAnswer
                    ? widget.answer
                    : '아직 모범 답안이 준비되지 않았습니다.',
                style: TextStyle(
                  fontSize: 15,
                  height: 1.6,
                  color: hasAnswer
                      ? colorScheme.onSurface
                      : colorScheme.onSurface.withOpacity(0.45),
                  fontStyle: hasAnswer ? FontStyle.normal : FontStyle.italic,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
