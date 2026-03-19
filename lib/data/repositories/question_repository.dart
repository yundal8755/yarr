import 'dart:convert';
import 'dart:io';

import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/question.dart';

class QuestionRepository {
  static const String _bookmarkPrefix = 'bookmark_';
  static const String _priorityPrefix = 'priority_';
  static const String _jsonFileName = 'questions.json';

  // 앱 문서 디렉토리의 questions.json 파일 경로
  Future<File> get _jsonFile async {
    final dir = await getApplicationDocumentsDirectory();
    return File('${dir.path}/$_jsonFileName');
  }

  // 사용자 JSON 파일이 존재하는지 확인
  Future<bool> hasUserJson() async {
    final file = await _jsonFile;
    return file.existsSync();
  }

  // 파일에서 질문 로드
  Future<List<Question>> loadQuestions() async {
    final file = await _jsonFile;
    if (!file.existsSync()) return [];

    final jsonString = await file.readAsString();
    final List<dynamic> jsonList = json.decode(jsonString) as List<dynamic>;
    final questions = jsonList
        .map((e) => Question.fromJson(e as Map<String, dynamic>))
        .toList();

    // SharedPreferences에서 저장된 북마크/우선순위 병합
    final prefs = await SharedPreferences.getInstance();
    return questions.map((q) {
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
  }

  // JSON 문자열을 검증하고 저장
  Future<void> saveQuestionsJson(String jsonString) async {
    // 유효성 검증 (파싱 가능 + 필수 필드 확인)
    final List<dynamic> parsed = json.decode(jsonString) as List<dynamic>;
    if (parsed.isEmpty) {
      throw FormatException('JSON 배열이 비어 있습니다.');
    }
    for (final item in parsed) {
      final map = item as Map<String, dynamic>;
      if (!map.containsKey('id') ||
          !map.containsKey('category') ||
          !map.containsKey('section') ||
          !map.containsKey('question')) {
        throw FormatException(
            'JSON 형식이 올바르지 않습니다. id, category, section, question 필드가 필요합니다.');
      }
    }

    final file = await _jsonFile;
    await file.writeAsString(jsonString, flush: true);
  }

  // 사용자 JSON 파일 삭제
  Future<void> deleteQuestionsJson() async {
    final file = await _jsonFile;
    if (file.existsSync()) {
      await file.delete();
    }
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
