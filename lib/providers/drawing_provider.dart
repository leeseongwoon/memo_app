import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../models/drawing.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class DrawingProvider with ChangeNotifier {
  late Box<Drawing> _drawingBox;
  Map<String, Drawing> _drawings = {}; // memoId를 키로 사용
  final _drawingsCollection = FirebaseFirestore.instance.collection('drawings');
  
  // 마지막으로 변경된 memoId를 저장
  String _lastChangedMemoId = '';
  String get lastChangedMemoId => _lastChangedMemoId;
  
  DrawingProvider() {
    _initHive();
  }

  // 메모 ID에 해당하는 그림 변경 알림
  void notifyDrawingChanged(String memoId) {
    // 이전 값과 다를 때만 업데이트
    if (_lastChangedMemoId != memoId) {
      _lastChangedMemoId = memoId;
      notifyListeners();
    } else {
      // 같은 memoId라도 강제로 다시 알림
      _lastChangedMemoId = memoId + "_" + DateTime.now().millisecondsSinceEpoch.toString();
      notifyListeners();
    }
    
    // 약간의 지연 후 한 번 더 알림 (UI 갱신 보장)
    Future.delayed(const Duration(milliseconds: 100), () {
      notifyListeners();
    });
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
  
  Future<List<Drawing>> getAllDrawings() async {
    await _ensureBoxOpen();
    return _drawingBox.toMap().values.toList();
  }

  Future<Drawing?> getDrawingByMemoId(String memoId) async {
    await _ensureBoxOpen();
    final matchingDrawings = _drawingBox.toMap().values
        .where((d) => d.memoId == memoId)
        .toList();
    return matchingDrawings.isNotEmpty ? matchingDrawings.first : null;
  }

  Future<Drawing?> _getDrawingByMemoId(String memoId) async {
    await _ensureBoxOpen();
    final matchingDrawings = _drawingBox.toMap().values
        .where((d) => d.memoId == memoId)
        .toList();
    return matchingDrawings.isNotEmpty ? matchingDrawings.first : null;
  }
  
  Future<void> saveDrawing(Drawing drawing) async {
    try {
      // Hive에 저장 (로컬 저장소)
      await _drawingBox.put(drawing.id, drawing);
      _drawings[drawing.memoId] = drawing;
      
      // 변경된 memoId 저장
      _lastChangedMemoId = drawing.memoId;
      
      // UI 업데이트
      notifyListeners();
      
      // Firestore에 저장 시도 (비동기적으로 처리)
      _saveToFirestore(drawing).catchError((e) {
        print('Firebase에 그림 저장 오류 (무시됨): $e');
      });
    } catch (e) {
      print('그림 저장 오류: $e');
      // 오류가 발생해도 UI는 갱신
      notifyListeners();
    }
  }
  
  // Firestore에 저장하는 별도 메서드 (실패해도 앱 동작에 영향 없음)
  Future<void> _saveToFirestore(Drawing drawing) async {
    try {
      final Map<String, dynamic> drawingData = {
        'id': drawing.id,
        'memoId': drawing.memoId,
        'createdAt': Timestamp.fromDate(drawing.createdAt),
        'modifiedAt': Timestamp.fromDate(drawing.modifiedAt),
        'linesCount': drawing.lines.length,
      };
      
      await _drawingsCollection.doc(drawing.id).set(drawingData);
    } catch (e) {
      print('Firebase에 그림 저장 오류: $e');
    }
  }
  
  // 메모리 캐시에서 그림 강제 제거 (즉시 반영)
  void forceClearDrawing(String memoId) {
    if (_drawings.containsKey(memoId)) {
      print('메모리 캐시에서 그림 강제 제거: $memoId');
      _drawings.remove(memoId);
      
      // 제거 후 즉시 알림
      _lastChangedMemoId = memoId + "_forceClear_" + DateTime.now().millisecondsSinceEpoch.toString();
      notifyListeners();
    }
  }
  
  // 그림 ID로 직접 Hive에서 삭제 (memoId가 아닌 drawing.id로 삭제)
  Future<void> deleteDrawingDirectly(String drawingId) async {
    try {
      print('Hive에서 그림 직접 삭제: $drawingId');
      await _drawingBox.delete(drawingId);
    } catch (e) {
      print('Hive에서 그림 직접 삭제 오류: $e');
    }
  }
  
  // 기존 deleteDrawing 메서드 개선
  Future<void> deleteDrawing(String memoId) async {
    final drawing = await getDrawingByMemoId(memoId);
    if (drawing != null) {
      try {
        // 변경된 memoId 저장
        _lastChangedMemoId = memoId + "_deleted_" + DateTime.now().millisecondsSinceEpoch.toString();
        
        // 먼저 로컬 상태 즉시 업데이트
        _drawings.remove(memoId);
        notifyListeners();
        
        // Hive에서 삭제
        try {
          await _drawingBox.delete(drawing.id);
        } catch (e) {
          print('Hive에서 그림 삭제 오류 (이미 삭제됨): $e');
        }
        
        // Firestore에서 삭제 (별도 스레드에서 처리)
        _deleteFromFirestore(drawing.id).catchError((e) {
          print('Firebase에서 그림 삭제 오류 (무시됨): $e');
        });
        
        // 한 번 더 상태 업데이트 호출하여 UI 갱신 보장
        Future.delayed(const Duration(milliseconds: 200), () {
          _lastChangedMemoId = memoId + "_finalNotify_" + DateTime.now().millisecondsSinceEpoch.toString();
          notifyListeners();
        });
      } catch (e) {
        print('그림 삭제 중 일반 오류: $e');
        // 오류 발생 시에도 UI 갱신 시도
        notifyListeners();
      }
    } else {
      // 그림이 이미 없는 경우 - 업데이트만 발송
      _lastChangedMemoId = memoId + "_alreadyDeleted_" + DateTime.now().millisecondsSinceEpoch.toString();
      notifyListeners();
    }
  }
  
  // Firestore에서 삭제하는 별도 메서드 (실패해도 앱 동작에 영향 없음)
  Future<void> _deleteFromFirestore(String id) async {
    try {
      await _drawingsCollection.doc(id).delete();
    } catch (e) {
      print('Firebase에서 그림 삭제 오류: $e');
    }
  }

  Future<void> _ensureBoxOpen() async {
    if (!_drawingBox.isOpen) {
      await _initHive();
    }
  }
} 