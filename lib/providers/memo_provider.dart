import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../models/memo.dart';

enum MemoSort {
  latest, // 최신순
  oldest, // 오래된순
  nameAscending, // 이름순 (가나다순)
}

class MemoProvider with ChangeNotifier {
  late Box<Memo> _memoBox;
  List<Memo> _memos = []; // 현재 표시할 메모 목록
  List<Memo> _allMemos = []; // 전체 메모 목록 (개수 계산용)
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

  // 모든 메모를 반환 (개수 계산용)
  List<Memo> get allMemos => _allMemos;

  MemoSort get currentSortType => _sortType;

  MemoProvider() {
    _initHive();
  }

  Future<void> _initHive() async {
    _memoBox = await Hive.openBox<Memo>('memos');
    await _loadAllMemos();
  }

  // 모든 메모 로드
  Future<void> _loadAllMemos() async {
    _allMemos = _memoBox.values.toList();
    _memos = List<Memo>.from(_allMemos); // 초기에는 모든 메모 표시
    notifyListeners();
  }

  // 특정 폴더의 메모 로드
  Future<void> loadMemosByFolder(String folderId) async {
    _allMemos = _memoBox.values.toList();
    
    if (folderId.isEmpty) {
      // 빈 폴더 ID는 모든 메모 표시
      _memos = List<Memo>.from(_allMemos);
    } else {
      // 특정 폴더의 메모만 표시
      _memos = _allMemos.where((memo) => memo.folderId == folderId).toList();
    }
    notifyListeners();
  }

  // 특정 폴더의 메모 개수 반환
  int getMemoCountByFolder(String folderId) {
    if (folderId.isEmpty) {
      return _allMemos.length; // 전체 메모 개수
    }
    return _allMemos.where((memo) => memo.folderId == folderId).length;
  }

  Future<void> addMemo(Memo memo) async {
    await _memoBox.put(memo.id, memo);
    
    // 전체 메모 목록과 현재 표시 목록 모두 업데이트
    _allMemos.insert(0, memo);
    
    // 현재 같은 폴더를 보고 있거나 전체 메모를 보고 있는 경우에만 추가
    if (memo.folderId == '' || _memos.isEmpty || 
        (_memos.isNotEmpty && _memos[0].folderId == memo.folderId) || 
        memo.folderId.isEmpty) {
      _memos.insert(0, memo);
    }
    
    notifyListeners();
  }

  Future<void> updateMemo(Memo memo) async {
    await _memoBox.put(memo.id, memo);
    
    // 전체 메모 목록 업데이트
    final allIndex = _allMemos.indexWhere((m) => m.id == memo.id);
    if (allIndex != -1) {
      _allMemos[allIndex] = memo;
    }
    
    // 현재 표시 목록 업데이트
    final index = _memos.indexWhere((m) => m.id == memo.id);
    if (index != -1) {
      _memos[index] = memo;
    }
    
    notifyListeners();
  }

  Future<void> deleteMemo(String id) async {
    await _memoBox.delete(id);
    
    // 전체 메모 목록에서 삭제
    _allMemos.removeWhere((memo) => memo.id == id);
    
    // 현재 표시 목록에서 삭제
    _memos.removeWhere((memo) => memo.id == id);
    
    notifyListeners();
  }

  // 여러 메모 한 번에 삭제
  Future<void> deleteMemos(List<String> ids) async {
    for (final id in ids) {
      await _memoBox.delete(id);
    }
    
    // 전체 메모 목록에서 삭제
    _allMemos.removeWhere((memo) => ids.contains(memo.id));
    
    // 현재 표시 목록에서 삭제
    _memos.removeWhere((memo) => ids.contains(memo.id));
    
    notifyListeners();
  }

  Future<Memo?> getMemoById(String id) async {
    if (id.isEmpty) return null;
    return _memoBox.get(id);
  }

  // 메모를 다른 폴더로 이동
  Future<void> moveMemoToFolder(String memoId, String folderId) async {
    final memo = await getMemoById(memoId);
    if (memo != null) {
      final updatedMemo = memo.copyWith(folderId: folderId);
      await updateMemo(updatedMemo);
    }
  }

  Color getColorForMemo(int colorIndex) {
    return memoColors[colorIndex % memoColors.length];
  }

  // 메모 ID가 데이터베이스에 존재하는지 확인
  Future<bool> memoExists(String id) async {
    return _memoBox.containsKey(id);
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
        memoList.sort((a, b) => a.title.compareTo(b.title));
        break;
    }
  }
} 