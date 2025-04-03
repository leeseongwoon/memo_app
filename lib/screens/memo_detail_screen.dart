import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/memo.dart';
import '../providers/memo_provider.dart';
import '../utils/date_formatter.dart';

// 한글 입력을 위한 특수 컨트롤러
class KoreanTextEditingController extends TextEditingController {
  KoreanTextEditingController({String? text}) : super(text: text);

  @override
  TextSpan buildTextSpan({
    required BuildContext context,
    TextStyle? style,
    required bool withComposing,
  }) {
    // 항상 composing 표시를 보여주지 않도록 설정
    return super.buildTextSpan(
      context: context,
      style: style,
      withComposing: false,
    );
  }
}

class MemoDetailScreen extends StatefulWidget {
  final String memoId;
  final String folderId;

  const MemoDetailScreen({
    super.key, 
    required this.memoId,
    this.folderId = '',
  });

  @override
  State<MemoDetailScreen> createState() => _MemoDetailScreenState();
}

class _MemoDetailScreenState extends State<MemoDetailScreen> {
  late KoreanTextEditingController _titleController;
  late KoreanTextEditingController _contentController;
  late MemoProvider _memoProvider;
  Memo? _memo;
  bool _isLoading = true;
  int _colorIndex = 0;
  String _folderId = '';

  @override
  void initState() {
    super.initState();
    _titleController = KoreanTextEditingController();
    _contentController = KoreanTextEditingController();
    _memoProvider = Provider.of<MemoProvider>(context, listen: false);
    _folderId = widget.folderId;
    _loadMemo();
  }

  @override
  void dispose() {
    _titleController.dispose();
    _contentController.dispose();
    super.dispose();
  }

  Future<void> _loadMemo() async {
    final memo = await _memoProvider.getMemoById(widget.memoId);
    setState(() {
      _memo = memo;
      if (memo != null) {
        _titleController.text = memo.title;
        _contentController.text = memo.content;
        _colorIndex = memo.colorIndex;
      }
      _isLoading = false;
    });
  }

  Future<void> _saveMemo() async {
    print("저장 시도 중...");
    try {
      if (_memo != null) {
        if (_titleController.text.isEmpty && _contentController.text.isEmpty) {
          print("메모가 비어있어 삭제합니다: ${_memo!.id}");
          await _memoProvider.deleteMemo(_memo!.id);
        } else {
          print("메모 업데이트: ${_memo!.id}");
          final updatedMemo = _memo!.copyWith(
            title: _titleController.text,
            content: _contentController.text,
            colorIndex: _colorIndex,
            folderId: _folderId,
          );
          await _memoProvider.updateMemo(updatedMemo);
        }
      } else if (_titleController.text.isNotEmpty || _contentController.text.isNotEmpty) {
        print("새 메모 추가");
        final newMemo = Memo(
          title: _titleController.text,
          content: _contentController.text,
          colorIndex: _colorIndex,
          folderId: _folderId,
        );
        await _memoProvider.addMemo(newMemo);
      } else {
        print("저장할 내용 없음");
      }
      print("저장 성공");
    } catch (e) {
      print("저장 실패: $e");
    }
  }

  void _changeColor() {
    setState(() {
      _colorIndex = (_colorIndex + 1) % _memoProvider.memoColors.length;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _isLoading
          ? Colors.white
          : _memoProvider.getColorForMemo(_colorIndex),
      appBar: AppBar(
        backgroundColor: _isLoading
            ? Colors.white
            : _memoProvider.getColorForMemo(_colorIndex),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () async {
            print("뒤로가기 버튼 클릭");
            await _saveMemo();
            if (context.mounted) {
              Navigator.pop(context);
            }
          },
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.palette_outlined),
            onPressed: _changeColor,
            tooltip: '색상 변경',
          ),
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert),
            onSelected: (value) {
              if (value == 'delete') {
                _showDeleteConfirmDialog();
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'delete',
                child: Row(
                  children: [
                    Icon(Icons.delete_outline, color: Colors.grey),
                    SizedBox(width: 8),
                    Text('삭제'),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (_memo != null)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 16.0),
                      child: Row(
                        children: [
                          Icon(
                            Icons.access_time,
                            size: 14,
                            color: Colors.grey[600],
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '마지막 수정: ${DateFormatter.formatFullDate(_memo!.modifiedAt)}',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    ),
                  TextField(
                    controller: _titleController,
                    decoration: const InputDecoration(
                      hintText: '제목',
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.zero,
                      hintStyle: TextStyle(
                        color: Colors.grey,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                    cursorColor: Colors.deepPurple,
                    keyboardType: TextInputType.text,
                    enableSuggestions: true,
                    textCapitalization: TextCapitalization.sentences,
                    textInputAction: TextInputAction.next,
                    autocorrect: false,
                    onSubmitted: (_) => FocusScope.of(context).nextFocus(),
                  ),
                  const SizedBox(height: 16),
                  Expanded(
                    child: TextField(
                      controller: _contentController,
                      decoration: const InputDecoration(
                        hintText: '내용을 입력하세요',
                        border: InputBorder.none,
                        contentPadding: EdgeInsets.zero,
                        hintStyle: TextStyle(
                          color: Colors.grey,
                        ),
                      ),
                      style: const TextStyle(
                        fontSize: 18,
                        height: 1.5,
                      ),
                      maxLines: null,
                      expands: true,
                      textAlignVertical: TextAlignVertical.top,
                      cursorColor: Colors.deepPurple,
                      keyboardType: TextInputType.multiline,
                      enableSuggestions: true,
                      autocorrect: false,
                      textInputAction: TextInputAction.newline,
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  Future<void> _saveAndShowFeedback() async {
    await _saveMemo();
    
    if (!context.mounted) return;
    
    // 저장 완료 피드백 표시
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('메모가 저장되었습니다'),
        duration: Duration(seconds: 1),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _showDeleteConfirmDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('메모 삭제'),
        content: const Text('이 메모를 삭제하시겠습니까?'),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
            },
            child: const Text('취소'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              if (_memo != null) {
                await _memoProvider.deleteMemo(_memo!.id);
                if (context.mounted) {
                  Navigator.pop(context);
                }
              } else {
                Navigator.pop(context);
              }
            },
            child: const Text('삭제'),
          ),
        ],
      ),
    );
  }
} 