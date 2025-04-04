import 'package:flutter/material.dart';
import '../models/drawing.dart';
import '../database/database_helper.dart';

class DrawingProvider with ChangeNotifier {
  Map<String, Drawing> _drawings = {}; // memoId를 키로 사용
  
  // 해당 메모의 그림 가져오기
  Future<Drawing?> getDrawingByMemoId(String memoId) async {
    if (_drawings.containsKey(memoId)) {
      return _drawings[memoId];
    }
    
    try {
      // 여기에 데이터베이스에서 드로잉을 가져오는 코드 추가 (실제 구현 시)
      // final drawing = await DatabaseHelper.instance.getDrawingByMemoId(memoId);
      // if (drawing != null) {
      //   _drawings[memoId] = drawing;
      // }
      // return drawing;
      
      // 현재는 null 반환 (아직 DB 구현 전)
      return null;
    } catch (e) {
      print('드로잉 로딩 오류: $e');
      return null;
    }
  }
  
  // 드로잉 저장
  Future<void> saveDrawing(Drawing drawing) async {
    try {
      // 여기에 데이터베이스에 드로잉을 저장하는 코드 추가 (실제 구현 시)
      // await DatabaseHelper.instance.insertOrUpdateDrawing(drawing);
      
      // 메모리에 저장
      _drawings[drawing.memoId] = drawing;
      notifyListeners();
    } catch (e) {
      print('드로잉 저장 오류: $e');
    }
  }
  
  // 드로잉 삭제
  Future<void> deleteDrawing(String memoId) async {
    try {
      // 여기에 데이터베이스에서 드로잉을 삭제하는 코드 추가 (실제 구현 시)
      // await DatabaseHelper.instance.deleteDrawing(memoId);
      
      // 메모리에서 삭제
      _drawings.remove(memoId);
      notifyListeners();
    } catch (e) {
      print('드로잉 삭제 오류: $e');
    }
  }
} 