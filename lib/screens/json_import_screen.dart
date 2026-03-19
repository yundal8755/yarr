import 'dart:convert';
import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../providers/question_provider.dart';

class JsonImportScreen extends ConsumerStatefulWidget {
  /// isInitial: true이면 최초 진입(JSON 없음) 모드, false이면 교체 모드
  final bool isInitial;
  const JsonImportScreen({super.key, required this.isInitial});

  @override
  ConsumerState<JsonImportScreen> createState() => _JsonImportScreenState();
}

class _JsonImportScreenState extends ConsumerState<JsonImportScreen> {
  bool _isLoading = false;
  String? _errorMessage;

  Future<void> _processJsonString(String jsonString) async {
    final repository = ref.read(questionRepositoryProvider);
    await repository.saveQuestionsJson(jsonString);

    // 프로바이더 상태 갱신
    await ref.read(questionsProvider.notifier).reloadFromFile();
    ref.invalidate(hasUserJsonProvider);

    if (!mounted) return;

    if (widget.isInitial) {
      context.go('/');
    } else {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('JSON 데이터가 성공적으로 적용되었습니다.'),
          backgroundColor: Colors.green.shade700,
          behavior: SnackBarBehavior.floating,
        ),
      );
      context.pop();
    }
  }

  Future<void> _importFromText(String jsonString) async {
    if (!widget.isInitial) {
      final confirmed = await _showOverwriteDialog();
      if (!confirmed) return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      await _processJsonString(jsonString);
    } on FormatException catch (e) {
      setState(() {
        _errorMessage = e.message;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = '데이터를 처리하는 중 오류가 발생했습니다:\n$e';
        _isLoading = false;
      });
    }
  }

  Future<void> _pickAndImportFile() async {
    // 교체 모드인 경우 덮어쓰기 경고 먼저 표시
    if (!widget.isInitial) {
      final confirmed = await _showOverwriteDialog();
      if (!confirmed) return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['json'],
        allowMultiple: false,
        withData: true,
      );

      if (result == null || result.files.isEmpty) {
        setState(() => _isLoading = false);
        return;
      }

      final file = result.files.first;
      String jsonString;

      if (file.bytes != null) {
        jsonString = utf8.decode(file.bytes!);
      } else if (file.path != null) {
        jsonString = await File(file.path!).readAsString();
      } else {
        throw Exception('파일을 읽을 수 없습니다.');
      }

      await _processJsonString(jsonString);
    } on FormatException catch (e) {
      setState(() {
        _errorMessage = e.message;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = '파일을 처리하는 중 오류가 발생했습니다:\n$e';
        _isLoading = false;
      });
    }
  }

  void _showTextInputBottomSheet() {
    final textController = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (ctx) {
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(ctx).viewInsets.bottom,
            left: 24,
            right: 24,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                '직접 붙여넣기',
                style: GoogleFonts.notoSans(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: textController,
                maxLines: 8,
                style: GoogleFonts.notoSans(
                  fontSize: 14,
                  fontWeight: FontWeight.w400,
                  color: Theme.of(ctx).colorScheme.onSurface,
                ),
                decoration: InputDecoration(
                  hintText: '복사해 둔 questions.json 내용을 여기에 붙여넣어주세요.',
                  border: const OutlineInputBorder(),
                  focusedBorder: OutlineInputBorder(
                    borderSide: BorderSide(
                      color: Theme.of(ctx).colorScheme.primary.withValues(
                            alpha: 0.5,
                          ),
                      width: 2,
                    ),
                  ),
                  alignLabelWithHint: true,
                ),
              ),
              const SizedBox(height: 24),
              FilledButton(
                onPressed: () {
                  final text = textController.text.trim();
                  if (text.isEmpty) return;
                  Navigator.pop(ctx);
                  _importFromText(text);
                },
                style: FilledButton.styleFrom(
                  minimumSize: const Size(double.infinity, 56),
                ),
                child: const Text('입력된 텍스트로 적용하기'),
              ),
              const SizedBox(height: 24),
            ],
          ),
        );
      },
    );
  }

  Future<bool> _showOverwriteDialog() async {
    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        titleTextStyle: GoogleFonts.notoSans(
          fontSize: 20,
          fontWeight: FontWeight.w700,
          color: Theme.of(ctx).colorScheme.onSurface,
        ),
        contentTextStyle: GoogleFonts.notoSans(
          fontSize: 16,
          fontWeight: FontWeight.w400,
          color: Theme.of(ctx).colorScheme.onSurface,
        ),
        title: const Text('덮어쓰기 확인'),
        content: const Text('기존 JSON 데이터가 새로운 내용으로 완전히 교체됩니다.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('취소'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: FilledButton.styleFrom(
              backgroundColor: Colors.red,
            ),
            child: const Text('덮어쓰기'),
          ),
        ],
      ),
    );
    return result ?? false;
  }

  Future<void> _deleteData() async {
    final confirmed = await _showDeleteConfirmDialog();
    if (!confirmed) return;

    final repository = ref.read(questionRepositoryProvider);
    await repository.deleteQuestionsJson();

    await ref.read(questionsProvider.notifier).reloadFromFile();
    ref.invalidate(hasUserJsonProvider);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('기존 데이터가 모두 삭제되었습니다.'),
          backgroundColor: Colors.red.shade700,
          behavior: SnackBarBehavior.floating,
        ),
      );
      context.pop();
    }
  }

  Future<bool> _showDeleteConfirmDialog() async {
    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        titleTextStyle: GoogleFonts.notoSans(
          fontSize: 20,
          fontWeight: FontWeight.w700,
          color: Theme.of(ctx).colorScheme.onSurface,
        ),
        contentTextStyle: GoogleFonts.notoSans(
          fontSize: 16,
          fontWeight: FontWeight.w400,
          color: Theme.of(ctx).colorScheme.onSurface,
        ),
        title: const Text('데이터 삭제 확인'),
        content: const Text(
            '모든 JSON 데이터를 기기에서 시스템 폴더에서 완전히 삭제하시겠습니까? 삭제 즉시 초기 화면으로 이동합니다.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('취소'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: FilledButton.styleFrom(
              backgroundColor: Colors.red,
            ),
            child: const Text('삭제하기'),
          ),
        ],
      ),
    );
    return result ?? false;
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: widget.isInitial
          ? null
          : AppBar(
              title: const Text('JSON 데이터 교체'),
              centerTitle: true,
            ),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 40),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                if (widget.isInitial) ...[
                  const SizedBox(height: 40),
                  Container(
                    width: 96,
                    height: 96,
                    decoration: BoxDecoration(
                      color: colorScheme.primaryContainer,
                      borderRadius: BorderRadius.circular(24),
                    ),
                    child: Icon(
                      Icons.description_outlined,
                      size: 48,
                      color: colorScheme.onPrimaryContainer,
                    ),
                  ),
                  const SizedBox(height: 28),
                  Text(
                    '시작하려면 JSON 파일이 필요해요',
                    style: GoogleFonts.notoSans(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: colorScheme.onSurface,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    '질문/단어 카드가 정리된 JSON을\n파일로 불러오거나 텍스트로 붙여넣어주세요.',
                    style: TextStyle(
                      fontSize: 15,
                      color: colorScheme.onSurface.withValues(alpha: 0.6),
                      height: 1.6,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 20),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color:
                          colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'JSON 필수 필드',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: colorScheme.primary,
                          ),
                        ),
                        const SizedBox(height: 8),
                        const _FieldRow(label: 'id', desc: '고유 식별자'),
                        const _FieldRow(label: 'category', desc: '카테고리 이름'),
                        const _FieldRow(label: 'section', desc: '섹션 이름'),
                        const _FieldRow(label: 'question', desc: '질문 내용'),
                        const _FieldRow(label: 'answer', desc: '정답 내용 (선택)'),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                ] else ...[
                  const SizedBox(height: 24),
                  Container(
                    width: 72,
                    height: 72,
                    decoration: BoxDecoration(
                      color: colorScheme.primaryContainer,
                      borderRadius: BorderRadius.circular(18),
                    ),
                    child: Icon(
                      Icons.swap_horiz_rounded,
                      size: 36,
                      color: colorScheme.onPrimaryContainer,
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    '새로운 데이터로 교체합니다.',
                    style: GoogleFonts.notoSans(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: colorScheme.onSurface,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 10),
                  Text(
                    '기존 데이터는 삭제되고 새 내용으로\n완전히 교체됩니다.',
                    style: TextStyle(
                      fontSize: 14,
                      color: colorScheme.onSurface.withValues(alpha: 0.6),
                      height: 1.6,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 40),
                ],

                // 에러 메시지
                if (_errorMessage != null) ...[
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(14),
                    margin: const EdgeInsets.only(bottom: 20),
                    decoration: BoxDecoration(
                      color: colorScheme.errorContainer,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(Icons.error_outline,
                            color: colorScheme.onErrorContainer, size: 20),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            _errorMessage!,
                            style: TextStyle(
                              color: colorScheme.onErrorContainer,
                              fontSize: 13,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],

                SizedBox(
                  width: double.infinity,
                  child: _isLoading
                      ? const SizedBox(
                          height: 56,
                          child: Center(child: CircularProgressIndicator()),
                        )
                      : Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            FilledButton.icon(
                              onPressed: _pickAndImportFile,
                              icon: const Icon(Icons.folder_open_outlined),
                              style: FilledButton.styleFrom(
                                minimumSize: const Size(double.infinity, 56),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              label: Text(
                                widget.isInitial
                                    ? 'JSON 파일 불러오기'
                                    : '새 JSON 파일 선택',
                                style: GoogleFonts.notoSans(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w700,
                                  color: colorScheme.onPrimary,
                                ),
                              ),
                            ),
                            const SizedBox(height: 12),
                            OutlinedButton.icon(
                              onPressed: _showTextInputBottomSheet,
                              icon: const Icon(Icons.paste_rounded),
                              style: OutlinedButton.styleFrom(
                                minimumSize: const Size(double.infinity, 56),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              label: const Text('직접 텍스트 붙여넣기'),
                            ),
                          ],
                        ),
                ),

                if (!widget.isInitial) ...[
                  const SizedBox(height: 32),
                  TextButton.icon(
                    onPressed: _deleteData,
                    icon: const Icon(Icons.delete_outline, size: 20),
                    label: const Text(
                      '기존 데이터 모두 지우기',
                      style: TextStyle(fontWeight: FontWeight.w600),
                    ),
                    style: TextButton.styleFrom(
                      foregroundColor: colorScheme.error,
                    ),
                  ),
                  const SizedBox(height: 16),
                ] else
                  const SizedBox(height: 40),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _FieldRow extends StatelessWidget {
  final String label;
  final String desc;
  const _FieldRow({required this.label, required this.desc});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: colorScheme.primary.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              label,
              style: TextStyle(
                fontFamily: 'monospace',
                fontSize: 12,
                color: colorScheme.primary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Text(
            desc,
            style: TextStyle(
              fontSize: 13,
              color: colorScheme.onSurface.withValues(alpha: 0.7),
            ),
          ),
        ],
      ),
    );
  }
}
