import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/memo.dart';
import '../models/drawing.dart';
import '../providers/memo_provider.dart';
import '../providers/drawing_provider.dart';
import '../utils/date_formatter.dart';
import '../painters/drawing_preview_painter.dart';
import '../widgets/confirm_dialog.dart';
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
      
      // 그림 상태 변경 알림 (메인 화면에서의 미리보기 업데이트를 위해)
      _drawingProvider.notifyDrawingChanged(memoId);
    } else if (result == null && _drawing != null) {
      // result가 null이고 기존에 그림이 있었다면 그림이 삭제된 것임
      setState(() {
        _drawing = null;
      });
      
      // 메모가 DB에 없는 임시 메모일 경우 실제로 생성
      if (_memo != null && !await _memoProvider.memoExists(_memo!.id)) {
        await _memoProvider.addMemo(_memo!);
      }
      
      // 메모 저장
      await _saveMemo();
      
      // 그림 상태 변경 알림 (미리보기 업데이트를 위해)
      _drawingProvider.notifyDrawingChanged(memoId);
      
      // 삭제 알림 표시
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('그림이 삭제되었습니다')),
        );
      }
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
            
            // 그림 상태 변경 알림 (메인 화면에서의 미리보기 업데이트를 위해)
            if (_memo != null && _drawing != null) {
              _drawingProvider.notifyDrawingChanged(_memo!.id);
            }
            
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
          IconButton(
            icon: const Icon(Icons.delete_outline),
            onPressed: () => _showDeleteConfirmDialog(),
            tooltip: '메모 삭제',
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
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.05),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ],
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
                                        color: Colors.black.withAlpha(13),
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

  Future<void> _showDeleteConfirmDialog() {
    return showConfirmDialog(
      context: context,
      title: '메모 삭제',
      content: '이 메모를 삭제하시겠습니까?',
      confirmText: '삭제',
      isDangerous: true,
      onConfirm: () async {
        if (_memo != null) {
          await _memoProvider.deleteMemo(_memo!.id);
          if (context.mounted) {
            Navigator.pop(context);
          }
        } else {
          Navigator.pop(context);
        }
      },
    );
  }

  // 그림 삭제 확인 대화상자
  void _showDeleteDrawingDialog() {
    showConfirmDialog(
      context: context,
      title: '그림 삭제',
      content: '이 메모에서 그림을 삭제하시겠습니까?',
      confirmText: '삭제',
      isDangerous: true,
      onConfirm: () {
        _deleteDrawing();
      },
    );
  }
  
  // 그림 삭제
  Future<void> _deleteDrawing() async {
    try {
      if (_memo != null && _drawing != null) {
        final String memoId = _memo!.id;
        final drawingId = _drawing!.id; // 그림 ID 저장
        
        // 먼저 로컬 참조 제거
        Drawing? oldDrawing = _drawing;
        
        // 로컬 UI 즉시 업데이트
        setState(() {
          _drawing = null;
        });
        
        // 먼저 그림 제공자에서 메모리 캐시 강제 삭제
        _drawingProvider.forceClearDrawing(memoId);
        
        // 상태 변경 즉시 알림 (미리보기 업데이트를 위한 첫 번째 알림)
        _drawingProvider.notifyDrawingChanged(memoId);
        
        // Hive에서 직접 삭제
        await _drawingProvider.deleteDrawingDirectly(drawingId);
        
        // 백그라운드에서 실제 삭제 수행 (자체 로직 추가로 호출)
        await _drawingProvider.deleteDrawing(memoId);
        
        // 메모도 함께 저장하여 업데이트
        await _saveMemo();
        
        // 한 번 더 알림 (모든 작업 완료 후 최종 알림)
        _drawingProvider.notifyDrawingChanged(memoId);
        
        // 약간의 지연 후 다시 한번 알림 (UI 갱신 보장)
        Future.delayed(const Duration(milliseconds: 300), () {
          if (mounted) {
            _drawingProvider.notifyDrawingChanged(memoId);
          }
        });
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('그림이 삭제되었습니다')),
          );
        }
      }
    } catch (e) {
      print('그림 삭제 오류: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('그림 삭제 중 오류가 발생했습니다')),
        );
      }
    }
  }
} 