import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/memo.dart';
import '../models/drawing.dart';
import '../providers/memo_provider.dart';
import '../providers/drawing_provider.dart';
import '../utils/date_formatter.dart';
import '../painters/drawing_preview_painter.dart';
import 'drawing_screen.dart';

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
  late DrawingProvider _drawingProvider;
  Memo? _memo;
  bool _isLoading = true;
  int _colorIndex = 0;
  String _folderId = '';
  
  // 드로잉 관련 상태
  Drawing? _drawing;

  @override
  void initState() {
    super.initState();
    _titleController = KoreanTextEditingController();
    _contentController = KoreanTextEditingController();
    _memoProvider = Provider.of<MemoProvider>(context, listen: false);
    _drawingProvider = Provider.of<DrawingProvider>(context, listen: false);
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
    
    Drawing? drawing;
    if (memo != null) {
      drawing = await _drawingProvider.getDrawingByMemoId(memo.id);
    }
    
    setState(() {
      _memo = memo;
      if (memo != null) {
        _titleController.text = memo.title;
        _contentController.text = memo.content;
        _colorIndex = memo.colorIndex;
        _folderId = memo.folderId;
        _drawing = drawing;
      }
      _isLoading = false;
    });
  }

  Future<void> _saveMemo() async {
    print("저장 시도 중...");
    try {
      if (_memo != null) {
        if (_titleController.text.isEmpty && _contentController.text.isEmpty && (_drawing == null || _drawing!.lines.isEmpty)) {
          print("메모가 비어있어 삭제합니다: ${_memo!.id}");
          await _memoProvider.deleteMemo(_memo!.id);
          await _drawingProvider.deleteDrawing(_memo!.id);
        } else {
          print("메모 업데이트: ${_memo!.id}");
          final updatedMemo = _memo!.copyWith(
            title: _titleController.text,
            content: _contentController.text,
            colorIndex: _colorIndex,
            folderId: _folderId,
          );
          await _memoProvider.updateMemo(updatedMemo);
          
          if (_drawing != null) {
            await _drawingProvider.saveDrawing(_drawing!);
          }
        }
      } else if (_titleController.text.isNotEmpty || _contentController.text.isNotEmpty || (_drawing != null && _drawing!.lines.isNotEmpty)) {
        print("새 메모 추가");
        final newMemo = Memo(
          title: _titleController.text,
          content: _contentController.text,
          colorIndex: _colorIndex,
          folderId: _folderId,
        );
        await _memoProvider.addMemo(newMemo);
        
        if (_drawing != null) {
          final updatedDrawing = _drawing!.copyWith(memoId: newMemo.id);
          await _drawingProvider.saveDrawing(updatedDrawing);
        }
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

  void _navigateToDrawing() async {
    String memoId;
    
    if (_memo == null) {
      // 메모가 없는 경우, 그림을 위한 빈 메모 생성 (실제 DB에는 아직 저장 안함)
      final tempMemo = Memo(
        title: _titleController.text,
        content: _contentController.text,
        colorIndex: _colorIndex,
        folderId: _folderId,
      );
      
      // 임시 메모 생성 (id만 있으면 됨)
      _memo = tempMemo;
      memoId = tempMemo.id;
    } else {
      memoId = _memo!.id;
    }
    
    final result = await Navigator.push<Drawing>(
      context,
      MaterialPageRoute(
        builder: (context) => DrawingScreen(
          memoId: memoId,
          initialDrawing: _drawing,
        ),
      ),
    );
    
    if (result != null) {
      setState(() {
        _drawing = result;
      });
      
      // 그림이 추가/수정되었으므로 메모도 저장
      // 메모가 DB에 없는 임시 메모일 경우 실제로 생성
      if (_memo != null && !await _memoProvider.memoExists(_memo!.id)) {
        await _memoProvider.addMemo(_memo!);
      }
      
      // 메모 저장
      await _saveMemo();
    }
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
          IconButton(
            icon: const Icon(Icons.draw_outlined),
            onPressed: _navigateToDrawing,
            tooltip: '그림 그리기',
          ),
          // 그림이 있을 경우 그림 삭제 버튼 표시
          if (_drawing != null && _drawing!.lines.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.image_not_supported_outlined),
              tooltip: '그림 삭제',
              onPressed: _showDeleteDrawingDialog,
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
                      contentPadding: EdgeInsets.symmetric(vertical: 8),
                    ),
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Expanded(
                    child: TextField(
                      controller: _contentController,
                      decoration: const InputDecoration(
                        hintText: '내용을 입력하세요',
                        border: InputBorder.none,
                      ),
                      style: const TextStyle(fontSize: 16),
                      maxLines: null,
                      expands: true,
                    ),
                  ),
                  // 그림이 있으면 미리보기 표시
                  if (_drawing != null)
                    GestureDetector(
                      onTap: _navigateToDrawing,
                      child: Container(
                        height: 150,
                        margin: const EdgeInsets.only(top: 16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.grey.withOpacity(0.3)),
                        ),
                        child: _drawing!.lines.isEmpty
                            ? const Center(child: Text('그림이 비어 있습니다'))
                            : ClipRRect(
                                borderRadius: BorderRadius.circular(12),
                                child: Stack(
                                  children: [
                                    CustomPaint(
                                      painter: DrawingPreviewPainter(_drawing!.lines),
                                      size: const Size(double.infinity, 150),
                                    ),
                                    // 반투명한 오버레이
                                    Positioned.fill(
                                      child: Container(
                                        color: Colors.black.withOpacity(0.05),
                                        // child: const Center(
                                        //   child: Text(
                                        //     '탭하여 편집',
                                        //     style: TextStyle(
                                        //       color: Colors.black54,
                                        //       fontSize: 14,
                                        //       fontWeight: FontWeight.w500,
                                        //     ),
                                        //   ),
                                        // ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
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

  // 그림 삭제 확인 대화상자
  void _showDeleteDrawingDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('그림 삭제'),
        content: const Text('이 메모에서 그림을 삭제하시겠습니까?'),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
            },
            child: const Text('취소'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _deleteDrawing();
            },
            child: const Text('삭제'),
          ),
        ],
      ),
    );
  }
  
  // 그림 삭제
  Future<void> _deleteDrawing() async {
    try {
      if (_memo != null && _drawing != null) {
        await _drawingProvider.deleteDrawing(_memo!.id);
        setState(() {
          _drawing = null;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('그림이 삭제되었습니다')),
        );
      }
    } catch (e) {
      print('그림 삭제 오류: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('그림 삭제 중 오류가 발생했습니다')),
      );
    }
  }
} 