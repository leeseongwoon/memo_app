import 'package:flutter/material.dart';
import '../models/memo.dart';
import '../database/database_helper.dart';

enum MemoSort {
  latest, // 최신순
  oldest, // 오래된순
  nameAscending, // 이름순 (가나다순)
}

class MemoProvider with ChangeNotifier {
  List<Memo> _memos = [];
  MemoSort _sortType = MemoSort.latest; // 기본 정렬: 최신순
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

  List<Memo> get memos {
    final sortedMemos = List<Memo>.from(_memos);
    _sortMemos(sortedMemos);
    return sortedMemos;
  }

  MemoSort get currentSortType => _sortType;

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

  // 여러 메모 한 번에 삭제
  Future<void> deleteMemos(List<String> ids) async {
    try {
      for (final id in ids) {
        await DatabaseHelper.instance.deleteMemo(id);
      }
      
      // 메모리 내에서도 삭제
      _memos.removeWhere((memo) => ids.contains(memo.id));
      
      notifyListeners();
    } catch (e) {
      print('다중 메모 삭제 오류: $e');
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

  // 정렬 방식 변경
  void changeSortType(MemoSort sortType) {
    if (_sortType != sortType) {
      _sortType = sortType;
      notifyListeners();
    }
  }

  // 메모 정렬 적용
  void _sortMemos(List<Memo> memoList) {
    switch (_sortType) {
      case MemoSort.latest:
        memoList.sort((a, b) => b.modifiedAt.compareTo(a.modifiedAt));
        break;
      case MemoSort.oldest:
        memoList.sort((a, b) => a.modifiedAt.compareTo(b.modifiedAt));
        break;
      case MemoSort.nameAscending:
        memoList.sort((a, b) {
          if (a.title.isEmpty && b.title.isEmpty) {
            return a.content.compareTo(b.content);
          } else if (a.title.isEmpty) {
            return a.content.compareTo(b.title);
          } else if (b.title.isEmpty) {
            return a.title.compareTo(b.content);
          } else {
            return a.title.compareTo(b.title);
          }
        });
        break;
    }
  }
} 