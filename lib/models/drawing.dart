import 'dart:ui';

class DrawingPoint {
  final Offset offset;
  final Paint paint;
  
  DrawingPoint({
    required this.offset,
    required this.paint,
  });
}

class Drawing {
  final String id;
  final String memoId;
  final List<List<DrawingPoint>> lines;
  final DateTime createdAt;
  final DateTime modifiedAt;
  
  Drawing({
    required this.id,
    required this.memoId,
    required this.lines,
    required this.createdAt,
    required this.modifiedAt,
  });
  
  Drawing copyWith({
    String? id,
    String? memoId,
    List<List<DrawingPoint>>? lines,
    DateTime? createdAt,
    DateTime? modifiedAt,
  }) {
    return Drawing(
      id: id ?? this.id,
      memoId: memoId ?? this.memoId,
      lines: lines ?? this.lines,
      createdAt: createdAt ?? this.createdAt,
      modifiedAt: modifiedAt ?? this.modifiedAt,
    );
  }
  
  Map<String, dynamic> toMap() {
    // 실제 구현 시에는 Offset과 Paint 객체를 저장 가능한 형태로 변환해야 합니다
    // 여기서는 개념적인 코드만 작성합니다
    return {
      'id': id,
      'memoId': memoId,
      'createdAt': createdAt.toIso8601String(),
      'modifiedAt': modifiedAt.toIso8601String(),
    };
  }
} 