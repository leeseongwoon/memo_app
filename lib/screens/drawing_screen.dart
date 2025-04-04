import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import '../models/drawing.dart';

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
    return Scaffold(
      appBar: AppBar(
        title: const Text('그림 그리기'),
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
                  child: CustomPaint(
                    painter: DrawingPainter(
                      lines: _lines,
                      currentLine: _currentLine,
                      isEraser: _isEraser,
                    ),
                    size: Size(constraints.maxWidth, constraints.maxHeight),
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
              color: Colors.white.withOpacity(0.8),
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
  
  // 터치 시작 이벤트
  void _onPanStart(DragStartDetails details, BoxConstraints constraints) {
    final box = context.findRenderObject() as RenderBox;
    final offset = box.globalToLocal(details.globalPosition);
    final appBarHeight = MediaQuery.of(context).padding.top + kToolbarHeight;
    
    // AppBar 높이를 고려한 Y 좌표 조정
    final adjustedOffset = Offset(
      offset.dx,
      offset.dy - appBarHeight,
    );
    
    setState(() {
      _currentLine = [
        DrawingPoint(
          offset: adjustedOffset,
          paint: Paint()
            ..color = _isEraser ? Colors.white : _selectedColor
            ..strokeWidth = _isEraser ? _eraserWidth : _selectedWidth
            ..strokeCap = StrokeCap.round
            ..strokeJoin = StrokeJoin.round
            ..style = PaintingStyle.stroke
            ..blendMode = BlendMode.srcOver,
        ),
      ];
    });
  }
  
  // 터치 이동 이벤트
  void _onPanUpdate(DragUpdateDetails details, BoxConstraints constraints) {
    if (_currentLine == null) return;
    
    final box = context.findRenderObject() as RenderBox;
    final offset = box.globalToLocal(details.globalPosition);
    final appBarHeight = MediaQuery.of(context).padding.top + kToolbarHeight;
    
    // AppBar 높이를 고려한 Y 좌표 조정
    final adjustedOffset = Offset(
      offset.dx,
      offset.dy - appBarHeight,
    );
    
    setState(() {
      _currentLine!.add(
        DrawingPoint(
          offset: adjustedOffset,
          paint: Paint()
            ..color = _isEraser ? Colors.white : _selectedColor
            ..strokeWidth = _isEraser ? _eraserWidth : _selectedWidth
            ..strokeCap = StrokeCap.round
            ..strokeJoin = StrokeJoin.round
            ..style = PaintingStyle.stroke
            ..blendMode = BlendMode.srcOver,
        ),
      );
    });
  }
  
  // 터치 종료 이벤트
  void _onPanEnd(DragEndDetails details) {
    if (_currentLine == null) return;
    
    setState(() {
      _lines.add(_currentLine!);
      _currentLine = null;
    });
  }
  
  // 그림 저장
  void _saveDrawing() {
    // 여기서는 그림 데이터를 반환만 합니다.
    // 실제 구현 시에는 DB에 저장하는 로직이 필요합니다.
    final drawing = Drawing(
      id: widget.initialDrawing?.id ?? const Uuid().v4(),
      memoId: widget.memoId,
      lines: _lines,
      createdAt: widget.initialDrawing?.createdAt ?? DateTime.now(),
      modifiedAt: DateTime.now(),
    );
    
    Navigator.pop(context, drawing);
  }
  
  // 그림 삭제 확인 대화상자
  void _showDeleteConfirmDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('그림 삭제'),
        content: const Text('이 그림을 삭제하시겠습니까?'),
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
  void _deleteDrawing() {
    // 그림 삭제 후 화면 닫기 (null 반환)
    Navigator.pop(context, null);
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
    this.isEraser = false,
  });
  
  @override
  void paint(Canvas canvas, Size size) {
    // 배경은 흰색으로
    canvas.drawRect(
      Rect.fromLTWH(0, 0, size.width, size.height),
      Paint()..color = Colors.white,
    );
    
    // 완성된 선들 그리기
    for (final line in lines) {
      if (line.length < 2) continue;
      
      for (int i = 0; i < line.length - 1; i++) {
        final point1 = line[i];
        final point2 = line[i + 1];
        
        if (isEraser) {
          // 지우개일 경우 원형으로 지우기
          final path = Path()
            ..moveTo(point1.offset.dx, point1.offset.dy)
            ..lineTo(point2.offset.dx, point2.offset.dy);
          
          canvas.drawPath(
            path,
            point1.paint..strokeCap = StrokeCap.round,
          );
        } else {
          canvas.drawLine(
            point1.offset,
            point2.offset,
            point1.paint,
          );
        }
      }
    }
    
    // 현재 그리고 있는 선 그리기
    if (currentLine != null && currentLine!.length >= 2) {
      for (int i = 0; i < currentLine!.length - 1; i++) {
        final point1 = currentLine![i];
        final point2 = currentLine![i + 1];
        
        if (isEraser) {
          // 지우개일 경우 원형으로 지우기
          final path = Path()
            ..moveTo(point1.offset.dx, point1.offset.dy)
            ..lineTo(point2.offset.dx, point2.offset.dy);
          
          canvas.drawPath(
            path,
            point1.paint..strokeCap = StrokeCap.round,
          );
        } else {
          canvas.drawLine(
            point1.offset,
            point2.offset,
            point1.paint,
          );
        }
      }
    }
  }
  
  @override
  bool shouldRepaint(DrawingPainter oldDelegate) {
    return oldDelegate.lines != lines || 
           oldDelegate.currentLine != currentLine ||
           oldDelegate.isEraser != isEraser;
  }
} 