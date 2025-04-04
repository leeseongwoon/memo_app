import 'package:flutter/material.dart';
import '../models/drawing.dart';

class DrawingPreviewPainter extends CustomPainter {
  final List<List<DrawingPoint>> lines;

  DrawingPreviewPainter(this.lines);

  @override
  void paint(Canvas canvas, Size size) {
    if (lines.isEmpty) return;

    // 모든 점의 최소/최대 좌표를 찾아서 스케일 계산
    double minX = double.infinity;
    double minY = double.infinity;
    double maxX = -double.infinity;
    double maxY = -double.infinity;

    for (final line in lines) {
      for (final point in line) {
        minX = minX < point.dx ? minX : point.dx;
        minY = minY < point.dy ? minY : point.dy;
        maxX = maxX > point.dx ? maxX : point.dx;
        maxY = maxY > point.dy ? maxY : point.dy;
      }
    }

    // 그림의 너비와 높이 계산
    final drawingWidth = maxX - minX;
    final drawingHeight = maxY - minY;

    // 스케일 계산 (가로, 세로 중 더 큰 비율 사용)
    final scaleX = size.width / drawingWidth;
    final scaleY = size.height / drawingHeight;
    final scale = scaleX < scaleY ? scaleX : scaleY;

    // 중앙 정렬을 위한 오프셋 계산
    final offsetX = (size.width - drawingWidth * scale) / 2 - minX * scale;
    final offsetY = (size.height - drawingHeight * scale) / 2 - minY * scale;

    // 각 선 그리기
    for (final line in lines) {
      if (line.isEmpty) continue;

      final paint = Paint()
        ..color = Color(line[0].color)
        ..strokeWidth = line[0].strokeWidth * scale * 0.5 // 미리보기에서는 선 두께를 절반으로
        ..strokeCap = StrokeCap.round
        ..style = PaintingStyle.stroke;

      final path = Path();
      path.moveTo(
        line[0].dx * scale + offsetX,
        line[0].dy * scale + offsetY,
      );

      for (int i = 1; i < line.length; i++) {
        path.lineTo(
          line[i].dx * scale + offsetX,
          line[i].dy * scale + offsetY,
        );
      }

      canvas.drawPath(path, paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
} 