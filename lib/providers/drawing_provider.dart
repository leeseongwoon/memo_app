import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../models/drawing.dart';

class DrawingProvider with ChangeNotifier {
  late Box<Drawing> _drawingBox;
  Map<String, Drawing> _drawings = {}; // memoId를 키로 사용
  
  DrawingProvider() {
    _initHive();
  }

  Future<void> _initHive() async {
    _drawingBox = await Hive.openBox<Drawing>('drawings');
    await _loadDrawings();
  }

  Future<void> _loadDrawings() async {
    final drawings = _drawingBox.values;
    for (final drawing in drawings) {
      _drawings[drawing.memoId] = drawing;
    }
    notifyListeners();
  }
  
  Future<Drawing?> getDrawingByMemoId(String memoId) async {
    if (_drawings.containsKey(memoId)) {
      return _drawings[memoId];
    }
    
    try {
      final drawing = _drawingBox.values.firstWhere(
        (d) => d.memoId == memoId,
      );
      _drawings[memoId] = drawing;
      return drawing;
    } catch (e) {
      return null;
    }
  }
  
  Future<void> saveDrawing(Drawing drawing) async {
    await _drawingBox.put(drawing.id, drawing);
    _drawings[drawing.memoId] = drawing;
    notifyListeners();
  }
  
  Future<void> deleteDrawing(String memoId) async {
    final drawing = await getDrawingByMemoId(memoId);
    if (drawing != null) {
      await _drawingBox.delete(drawing.id);
      _drawings.remove(memoId);
      notifyListeners();
    }
  }
} 