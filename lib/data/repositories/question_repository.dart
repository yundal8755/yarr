import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/question.dart';

class QuestionRepository {
  static const String _bookmarkPrefix = 'bookmark_';
  static const String _priorityPrefix = 'priority_';

  Future<List<Question>> loadQuestions() async {
    final jsonString =
        await rootBundle.loadString('assets/data/questions.json');
    final List<dynamic> jsonList = json.decode(jsonString) as List<dynamic>;

    final questions = jsonList
        .map((e) => Question.fromJson(e as Map<String, dynamic>))
        .toList();

    // SharedPreferences에서 저장된 변경사항 병합
    final prefs = await SharedPreferences.getInstance();
    final mergedQuestions = questions.map((q) {
      final savedBookmark = prefs.getBool('$_bookmarkPrefix${q.id}');
      final savedPriority = prefs.getInt('$_priorityPrefix${q.id}');

      if (savedBookmark != null || savedPriority != null) {
        return q.copyWith(
          isBookmarked: savedBookmark ?? q.isBookmarked,
          priority: savedPriority ?? q.priority,
        );
      }
      return q;
    }).toList();

    return mergedQuestions;
  }

  Future<void> toggleBookmark(String id) async {
    final prefs = await SharedPreferences.getInstance();
    final currentValue = prefs.getBool('$_bookmarkPrefix$id') ?? false;
    await prefs.setBool('$_bookmarkPrefix$id', !currentValue);
  }

  Future<void> updatePriority(String id, int priority) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('$_priorityPrefix$id', priority);
  }

  Future<bool> getBookmarkStatus(String id) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool('$_bookmarkPrefix$id') ?? false;
  }

  Future<int> getPriority(String id) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt('$_priorityPrefix$id') ?? 2;
  }
}
