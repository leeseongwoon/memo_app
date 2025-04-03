import 'package:flutter/material.dart';
import '../models/memo.dart';
import '../database/database_helper.dart';

class MemoProvider with ChangeNotifier {
  List<Memo> _memos = [];
  final List<Color> memoColors = [
    const Color(0xFFF9FBE7), // 연한 라임
    const Color(0xFFFFEBEE), // 연한 분홍
    const Color(0xFFE1F5FE), // 연한 하늘
    const Color(0xFFF3E5F5), // 연한 라벤더
    const Color(0xFFE8F5E9), // 연한 민트
    const Color(0xFFFFF3E0), // 연한 살구
    const Color(0xFFE0F7FA), // 연한 청록
    const Color(0xFFE8EAF6), // 연한 인디고
    const Color(0xFFFCE4EC), // 연한 로즈
    const Color(0xFFF1F8E9), // 연한 연두
  ];

  List<Memo> get memos => _memos;

  MemoProvider() {
    _loadMemos();
  }

  // 모든 메모 로드 또는 특정 폴더의 메모 로드
  Future<void> _loadMemos() async {
    try {
      _memos = await DatabaseHelper.instance.getAllMemos();
      notifyListeners();
    } catch (e) {
      print('메모 로딩 오류: $e');
    }
  }

  // 특정 폴더의 메모 로드
  Future<void> loadMemosByFolder(String folderId) async {
    try {
      if (folderId.isEmpty) {
        // 빈 폴더 ID는 모든 메모 표시
        _memos = await DatabaseHelper.instance.getAllMemos();
      } else {
        // 특정 폴더의 메모만 표시
        _memos = await DatabaseHelper.instance.getMemosByFolder(folderId);
      }
      notifyListeners();
    } catch (e) {
      print('폴더별 메모 로딩 오류: $e');
    }
  }

  Future<void> addMemo(Memo memo) async {
    try {
      await DatabaseHelper.instance.insertMemo(memo);
      _memos.insert(0, memo); // 로컬 상태 바로 업데이트
      notifyListeners();
    } catch (e) {
      print('메모 추가 오류: $e');
    }
  }

  Future<void> updateMemo(Memo memo) async {
    try {
      await DatabaseHelper.instance.updateMemo(memo);
      
      // 메모리 내에서도 업데이트
      final index = _memos.indexWhere((m) => m.id == memo.id);
      if (index != -1) {
        _memos[index] = memo;
      }
      
      notifyListeners();
    } catch (e) {
      print('메모 업데이트 오류: $e');
    }
  }

  Future<void> deleteMemo(String id) async {
    try {
      await DatabaseHelper.instance.deleteMemo(id);
      
      // 메모리 내에서도 삭제
      _memos.removeWhere((memo) => memo.id == id);
      
      notifyListeners();
    } catch (e) {
      print('메모 삭제 오류: $e');
    }
  }

  Future<Memo?> getMemoById(String id) async {
    if (id.isEmpty) return null;
    
    try {
      return await DatabaseHelper.instance.getMemoById(id);
    } catch (e) {
      print('메모 조회 오류: $e');
      return null;
    }
  }

  // 메모를 다른 폴더로 이동
  Future<void> moveMemoToFolder(String memoId, String folderId) async {
    try {
      final memo = await getMemoById(memoId);
      if (memo != null) {
        final updatedMemo = memo.copyWith(folderId: folderId);
        await updateMemo(updatedMemo);
      }
    } catch (e) {
      print('메모 이동 오류: $e');
    }
  }

  Color getColorForMemo(int colorIndex) {
    return memoColors[colorIndex % memoColors.length];
  }
} 