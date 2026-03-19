import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import 'data/models/question.dart';
import 'screens/home_screen.dart';
import 'screens/category_screen.dart';
import 'screens/card_screen.dart';
import 'screens/bookmark_screen.dart';

final _router = GoRouter(
  initialLocation: '/',
  routes: [
    GoRoute(
      path: '/',
      builder: (context, state) => const HomeScreen(),
    ),
    GoRoute(
      path: '/category/:name',
      builder: (context, state) {
        final name = state.pathParameters['name']!;
        return CategoryScreen(category: name);
      },
    ),
    GoRoute(
      path: '/cards',
      builder: (context, state) {
        final questions = state.extra as List<Question>;
        return CardScreen(questions: questions);
      },
    ),
    GoRoute(
      path: '/bookmarks',
      builder: (context, state) => const BookmarkScreen(),
    ),
  ],
);

// 카테고리 색상 팔레트
const List<Color> _categoryColorPalette = [
  Color(0xFFE57373), Color(0xFFF06292), Color(0xFFBA68C8), Color(0xFF9575CD),
  Color(0xFF7986CB), Color(0xFF64B5F6), Color(0xFF4FC3F7), Color(0xFF4DD0E1),
  Color(0xFF4DB6AC), Color(0xFF81C784), Color(0xFFAED581), Color(0xFFFF8A65),
  Color(0xFFD4E157), Color(0xFFFFD54F), Color(0xFFFFB74D), Color(0xFFA1887F),
  Color(0xFF90A4AE), Color(0xFFF77272), Color(0xFFDA70D6), Color(0xFF9370DB),
  Color(0xFF5C6BC0), Color(0xFF42A5F5), Color(0xFF26C6DA), Color(0xFF26A69A),
  Color(0xFF66BB6A), Color(0xFF9CCC65), Color(0xFFFFCA28), Color(0xFFFFA726),
  Color(0xFFFF7043), Color(0xFF8D6E63),
];

final Map<String, Color> _assignedCategoryColors = {};

Color getCategoryColor(String category) {
  if (_assignedCategoryColors.containsKey(category)) {
    return _assignedCategoryColors[category]!;
  }
  
  final usedColors = _assignedCategoryColors.values.toSet();
  final availableColors = _categoryColorPalette.where((c) => !usedColors.contains(c)).toList();
  
  if (availableColors.isNotEmpty) {
    availableColors.shuffle();
    _assignedCategoryColors[category] = availableColors.first;
  } else {
    final allColors = List<Color>.from(_categoryColorPalette)..shuffle();
    _assignedCategoryColors[category] = allColors.first;
  }
  
  return _assignedCategoryColors[category]!;
}

// 우선순위 색상
Color priorityColor(int priority) {
  switch (priority) {
    case 1:
      return Colors.redAccent;
    case 2:
      return Colors.amber;
    case 3:
      return Colors.grey;
    default:
      return Colors.grey;
  }
}

class YarrApp extends StatelessWidget {
  const YarrApp({super.key});

  @override
  Widget build(BuildContext context) {
    final textTheme = GoogleFonts.notoSansTextTheme();

    return MaterialApp.router(
      title: 'yarr',
      debugShowCheckedModeBanner: false,
      routerConfig: _router,
      themeMode: ThemeMode.system,
      theme: ThemeData(
        useMaterial3: true,
        colorSchemeSeed: const Color(0xFF4A90D9),
        brightness: Brightness.light,
        textTheme: textTheme,
        filledButtonTheme: FilledButtonThemeData(
          style: FilledButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
            textStyle: GoogleFonts.notoSans(
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ),
      darkTheme: ThemeData(
        useMaterial3: true,
        colorSchemeSeed: const Color(0xFF4A90D9),
        brightness: Brightness.dark,
        textTheme: textTheme,
        filledButtonTheme: FilledButtonThemeData(
          style: FilledButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
            textStyle: GoogleFonts.notoSans(
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ),
    );
  }
}
