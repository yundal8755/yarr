class Question {
  final String id;
  final String category;
  final String section;
  final String question;
  final String answer;
  final int priority;
  final bool isBookmarked;

  const Question({
    required this.id,
    required this.category,
    required this.section,
    required this.question,
    required this.answer,
    required this.priority,
    required this.isBookmarked,
  });

  factory Question.fromJson(Map<String, dynamic> json) {
    return Question(
      id: json['id'] as String,
      category: json['category'] as String,
      section: json['section'] as String,
      question: json['question'] as String,
      answer: json['answer'] as String? ?? '',
      priority: json['priority'] as int? ?? 2,
      isBookmarked: json['isBookmarked'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'category': category,
      'section': section,
      'question': question,
      'answer': answer,
      'priority': priority,
      'isBookmarked': isBookmarked,
    };
  }

  Question copyWith({
    String? id,
    String? category,
    String? section,
    String? question,
    String? answer,
    int? priority,
    bool? isBookmarked,
  }) {
    return Question(
      id: id ?? this.id,
      category: category ?? this.category,
      section: section ?? this.section,
      question: question ?? this.question,
      answer: answer ?? this.answer,
      priority: priority ?? this.priority,
      isBookmarked: isBookmarked ?? this.isBookmarked,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Question &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;
}
