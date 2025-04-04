import 'dart:ui';
import 'package:hive/hive.dart';

part 'drawing.g.dart';

@HiveType(typeId: 2)
class DrawingPoint {
  @HiveField(0)
  final double dx;
  
  @HiveField(1)
  final double dy;
  
  @HiveField(2)
  final double strokeWidth;
  
  @HiveField(3)
  final int color;
  
  DrawingPoint({
    required this.dx,
    required this.dy,
    required this.strokeWidth,
    required this.color,
  });
  
  Offset get offset => Offset(dx, dy);
  
  Paint get paint {
    return Paint()
      ..color = Color(color)
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;
  }
}

@HiveType(typeId: 3)
class Drawing extends HiveObject {
  @HiveField(0)
  final String id;
  
  @HiveField(1)
  final String memoId;
  
  @HiveField(2)
  final List<List<DrawingPoint>> lines;
  
  @HiveField(3)
  final DateTime createdAt;
  
  @HiveField(4)
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
    return {
      'id': id,
      'memoId': memoId,
      'createdAt': createdAt.toIso8601String(),
      'modifiedAt': modifiedAt.toIso8601String(),
    };
  }
} 