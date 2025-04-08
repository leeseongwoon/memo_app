import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import '../models/drawing.dart';
import 'package:provider/provider.dart';
import '../providers/drawing_provider.dart';
import '../widgets/confirm_dialog.dart';

class DrawingScreen extends StatefulWidget {
  final String memoId;
  final Drawing? initialDrawing;

  const DrawingScreen({
    super.key, 
    required this.memoId,
    this.initialDrawing,
  });

  @override
  State<DrawingScreen> createState() => _DrawingScreenState();
}

class _DrawingScreenState extends State<DrawingScreen> {
  // 현재 진행 중인 선
  List<DrawingPoint>? _currentLine;
  
  // 완성된 모든 선들
  List<List<DrawingPoint>> _lines = [];
  
  // 선 색상
  Color _selectedColor = Colors.black;
  
  // 선 두께
  double _selectedWidth = 3.0;
  
  // 지우개 모드
  bool _isEraser = false;
  double _eraserWidth = 20.0; // 지우개 크기
  
  @override
  void initState() {
    super.initState();
    if (widget.initialDrawing != null) {
      _lines = widget.initialDrawing!.lines;
    }
  }
  
  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        // 뒤로가기 버튼을 눌렀을 때 현재 그림을 저장하고 반환
        if (_lines.isNotEmpty) {
          await _saveDrawing();
        } else if (widget.initialDrawing != null) {
          // 기존 그림이 있고 현재 라인이 비어있어도 기존 그림을 반환
          Navigator.of(context).pop(widget.initialDrawing);
          return false;
        }
        return true;
      },
      child: Scaffold(
        appBar: AppBar(
          title: const Text('그림 그리기'),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () async {
              // 뒤로가기 버튼을 눌렀을 때 현재 그림을 저장하고 반환
              if (_lines.isNotEmpty) {
                await _saveDrawing();
              } else if (widget.initialDrawing != null) {
                // 기존 그림이 있고 현재 라인이 비어있어도 기존 그림을 반환
                Navigator.of(context).pop(widget.initialDrawing);
                return;
              }
              Navigator.of(context).pop();
            },
          ),
          actions: [
            // 그림 삭제 버튼
            IconButton(
              icon: const Icon(Icons.delete_outline),
              onPressed: _showDeleteConfirmDialog,
              tooltip: '그림 삭제',
            ),
            // 저장 버튼
            IconButton(
              icon: const Icon(Icons.save),
              onPressed: _saveDrawing,
            ),
          ],
        ),
        body: Stack(
          children: [
            // 그림 그리기 영역
            Container(
              color: Colors.white,
              child: LayoutBuilder(
                builder: (context, constraints) {
                  return GestureDetector(
                    onPanStart: (details) => _onPanStart(details, constraints),
                    onPanUpdate: (details) => _onPanUpdate(details, constraints),
                    onPanEnd: _onPanEnd,
                    child: ClipRect(
                      child: CustomPaint(
                        painter: DrawingPainter(
                          lines: _lines,
                          currentLine: _currentLine,
                          isEraser: _isEraser,
                        ),
                        size: Size(constraints.maxWidth, constraints.maxHeight),
                      ),
                    ),
                  );
                },
              ),
            ),
            
            // 하단 도구 모음
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: Container(
                padding: const EdgeInsets.all(8.0),
                color: Colors.white.withAlpha(204), // 0.8 * 255 = 204
                child: Row(
                  children: [
                    // 색상 선택 버튼들
                    ..._buildColorButtons(),
                    
                    const SizedBox(width: 16),
                    
                    // 선 두께 조절 슬라이더
                    Expanded(
                      child: Slider(
                        value: _selectedWidth,
                        min: 1.0,
                        max: 10.0,
                        divisions: 9,
                        label: _selectedWidth.round().toString(),
                        onChanged: (value) {
                          setState(() {
                            _selectedWidth = value;
                            _isEraser = false; // 두께 변경 시 지우개 모드 해제
                          });
                        },
                      ),
                    ),
                    
                    // 지우개 버튼
                    Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: Icon(
                            Icons.cleaning_services_rounded,
                            color: _isEraser ? Colors.red : Colors.grey,
                          ),
                          tooltip: '지우개',
                          onPressed: () {
                            setState(() {
                              _isEraser = !_isEraser;
                            });
                          },
                        ),
                        if (_isEraser)
                          SizedBox(
                            width: 100,
                            child: Slider(
                              value: _eraserWidth,
                              min: 10.0,
                              max: 50.0,
                              divisions: 4,
                              label: _eraserWidth.round().toString(),
                              onChanged: (value) {
                                setState(() {
                                  _eraserWidth = value;
                                });
                              },
                            ),
                          ),
                      ],
                    ),
                    
                    // 초기화 버튼
                    IconButton(
                      icon: const Icon(Icons.refresh),
                      onPressed: () {
                        setState(() {
                          _lines = [];
                          _currentLine = null;
                        });
                      },
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  // 색상 선택 버튼 생성
  List<Widget> _buildColorButtons() {
    final colors = [
      Colors.black,
      Colors.red,
      Colors.green,
      Colors.blue,
      Colors.yellow,
      Colors.purple,
    ];
    
    return colors.map((color) {
      return GestureDetector(
        onTap: () {
          setState(() {
            _selectedColor = color;
            _isEraser = false; // 색상 변경 시 지우개 모드 해제
          });
        },
        child: Container(
          margin: const EdgeInsets.only(right: 8),
          width: 30,
          height: 30,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
            border: Border.all(
              color: color == _selectedColor ? Colors.blue : Colors.grey,
              width: color == _selectedColor ? 3 : 1,
            ),
          ),
        ),
      );
    }).toList();
  }
  
  // 오프셋 조정 메서드
  Offset _getAdjustedOffset(Offset localPosition, BoxConstraints constraints) {
    // 로컬 좌표를 그대로 사용하고 범위만 제한
    return Offset(
      localPosition.dx.clamp(0, constraints.maxWidth),
      localPosition.dy.clamp(0, constraints.maxHeight),
    );
  }

  // 그림 그리기 관련 메서드들
  void _onPanStart(DragStartDetails details, BoxConstraints constraints) {
    final adjustedOffset = _getAdjustedOffset(details.localPosition, constraints);
    setState(() {
      _currentLine = [
        DrawingPoint(
          dx: adjustedOffset.dx,
          dy: adjustedOffset.dy,
          strokeWidth: _isEraser ? _eraserWidth : _selectedWidth,
          color: _isEraser ? Colors.white.toARGB32() : _selectedColor.toARGB32(),
        ),
      ];
    });
  }

  void _onPanUpdate(DragUpdateDetails details, BoxConstraints constraints) {
    if (_currentLine == null) return;
    
    final adjustedOffset = _getAdjustedOffset(details.localPosition, constraints);
    setState(() {
      _currentLine!.add(
        DrawingPoint(
          dx: adjustedOffset.dx,
          dy: adjustedOffset.dy,
          strokeWidth: _isEraser ? _eraserWidth : _selectedWidth,
          color: _isEraser ? Colors.white.toARGB32() : _selectedColor.toARGB32(),
        ),
      );
    });
  }

  void _onPanEnd(DragEndDetails details) {
    if (_currentLine != null && _currentLine!.isNotEmpty) {
      setState(() {
        _lines.add(_currentLine!);
        _currentLine = [];
      });
      
      // 그림 저장
      final drawing = Drawing(
        id: widget.initialDrawing?.id ?? const Uuid().v4(),
        memoId: widget.memoId,
        lines: _lines,
        createdAt: widget.initialDrawing?.createdAt ?? DateTime.now(),
        modifiedAt: DateTime.now(),
      );
      context.read<DrawingProvider>().saveDrawing(drawing);
    }
  }
  
  // 그림 저장
  Future<void> _saveDrawing() async {
    final drawing = Drawing(
      id: widget.initialDrawing?.id ?? const Uuid().v4(),
      memoId: widget.memoId,
      lines: [..._lines],
      createdAt: widget.initialDrawing?.createdAt ?? DateTime.now(),
      modifiedAt: DateTime.now(),
    );
    
    // 드로잉 프로바이더에 저장
    final drawingProvider = Provider.of<DrawingProvider>(context, listen: false);
    await drawingProvider.saveDrawing(drawing);
    
    // 한 번 더 상태 갱신 신호 보내기
    drawingProvider.notifyDrawingChanged(widget.memoId);
    
    if (mounted) {
      // 결과 데이터를 반환하며 닫기
      Navigator.of(context).pop(drawing);
    }
  }
  
  // 그림 삭제 확인 다이얼로그
  Future<void> _showDeleteConfirmDialog() async {
    final confirmed = await showConfirmDialog(
      context: context,
      title: '그림 삭제',
      content: '이 그림을 삭제하시겠습니까?',
      confirmText: '삭제',
      isDangerous: true,
    );
    
    if (confirmed == true) {
      final drawingProvider = Provider.of<DrawingProvider>(context, listen: false);
      final memoId = widget.memoId;
      
      try {
        // 먼저 로컬 UI 상태 업데이트 (그림 즉시 제거)
        setState(() {
          _lines = [];
          _currentLine = null;
        });
        
        // 1. 현재 그림 ID 저장 (있을 경우)
        String? drawingId;
        final drawing = await drawingProvider.getDrawingByMemoId(memoId);
        if (drawing != null) {
          drawingId = drawing.id;
        }
        
        // 2. 메모리 캐시에서 강제 제거
        drawingProvider.forceClearDrawing(memoId);
        
        // 3. 상태 변경 즉시 알림
        drawingProvider.notifyDrawingChanged(memoId);
        
        // 4. 그림 ID로 직접 삭제 (알고 있는 경우)
        if (drawingId != null) {
          await drawingProvider.deleteDrawingDirectly(drawingId);
        }
        
        // 5. 기존 삭제 메서드 호출 (백그라운드에서 실행)
        await drawingProvider.deleteDrawing(memoId);
        
        // 6. 다시 한번 알림 (지연 적용)
        Future.delayed(const Duration(milliseconds: 100), () {
          drawingProvider.notifyDrawingChanged(memoId);
        });
        
        // 7. 화면 닫기 - null을 반환하여 그림이 삭제되었음을 알림
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('그림이 삭제되었습니다')),
          );
          Navigator.of(context).pop(null);
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
}

// 실제 그림을 그리는 CustomPainter
class DrawingPainter extends CustomPainter {
  final List<List<DrawingPoint>> lines;
  final List<DrawingPoint>? currentLine;
  final bool isEraser;
  
  DrawingPainter({
    required this.lines,
    this.currentLine,
    required this.isEraser,
  });
  
  @override
  void paint(Canvas canvas, Size size) {
    // 배경을 흰색으로 채우기
    canvas.drawRect(
      Offset.zero & size,
      Paint()..color = Colors.white,
    );
    
    // 완성된 선들 그리기
    for (final line in lines) {
      _drawLine(canvas, line);
    }
    
    // 현재 그리고 있는 선 그리기
    if (currentLine != null) {
      _drawLine(canvas, currentLine!);
    }
  }
  
  void _drawLine(Canvas canvas, List<DrawingPoint> points) {
    if (points.isEmpty) return;
    
    for (int i = 0; i < points.length - 1; i++) {
      final point1 = points[i];
      final point2 = points[i + 1];
      
      final paint = Paint()
        ..color = Color(point1.color)
        ..strokeWidth = point1.strokeWidth
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round
        ..style = PaintingStyle.stroke;
      
      canvas.drawLine(
        Offset(point1.dx, point1.dy),
        Offset(point2.dx, point2.dy),
        paint,
      );
    }
  }
  
  @override
  bool shouldRepaint(covariant DrawingPainter oldDelegate) {
    return true;
  }
} 