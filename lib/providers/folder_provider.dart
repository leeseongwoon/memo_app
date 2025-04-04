import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../models/folder.dart';

enum FolderSort {
  latest, // 최신순
  oldest, // 오래된순
  nameAscending, // 이름순 (가나다순)
}

class FolderProvider with ChangeNotifier {
  late Box<Folder> _folderBox;
  List<Folder> _folders = [];
  String _currentFolderId = '';
  FolderSort _sortType = FolderSort.nameAscending; // 기본 정렬: 이름순

  List<Folder> get folders {
    final sortedFolders = List<Folder>.from(_folders);
    _sortFolders(sortedFolders);
    return sortedFolders;
  }
  
  String get currentFolderId => _currentFolderId;
  
  FolderSort get currentSortType => _sortType;
  
  // 정렬 방식 변경
  void changeSortType(FolderSort sortType) {
    if (_sortType != sortType) {
      _sortType = sortType;
      notifyListeners();
    }
  }
  
  // 폴더 정렬 적용
  void _sortFolders(List<Folder> folderList) {
    switch (_sortType) {
      case FolderSort.latest:
        folderList.sort((a, b) => b.createdAt.compareTo(a.createdAt));
        break;
      case FolderSort.oldest:
        folderList.sort((a, b) => a.createdAt.compareTo(b.createdAt));
        break;
      case FolderSort.nameAscending:
        folderList.sort((a, b) => a.name.compareTo(b.name));
        break;
    }
    
    // '전체 메모' 폴더는 항상 맨 위에 표시
    final allMemosIndex = folderList.indexWhere((folder) => folder.name == '전체 메모');
    if (allMemosIndex > 0) {
      final allMemos = folderList.removeAt(allMemosIndex);
      folderList.insert(0, allMemos);
    }
  }

  // 현재 선택된 폴더를 변경
  set currentFolderId(String id) {
    _currentFolderId = id;
    notifyListeners();
  }

  // 현재 선택된 폴더 이름 얻기
  String get currentFolderName {
    if (_currentFolderId.isEmpty) return '전체 메모';
    final folder = _folders.firstWhere(
      (folder) => folder.id == _currentFolderId,
      orElse: () => Folder(name: '전체 메모'),
    );
    return folder.name;
  }

  FolderProvider() {
    _initHive();
  }

  Future<void> _initHive() async {
    _folderBox = await Hive.openBox<Folder>('folders');
    await _loadFolders();
  }

  Future<void> _loadFolders() async {
    _folders = _folderBox.values.toList();
    notifyListeners();
  }

  Future<void> addFolder(String name) async {
    final folder = Folder(name: name);
    await _folderBox.put(folder.id, folder);
    await _loadFolders();
  }

  Future<void> updateFolder(Folder folder) async {
    await _folderBox.put(folder.id, folder);
    await _loadFolders();
  }

  Future<void> deleteFolder(String id) async {
    await _folderBox.delete(id);
    
    // 현재 선택된 폴더가 삭제되는 경우 기본 폴더로 변경
    if (_currentFolderId == id) {
      _currentFolderId = '';
    }
    
    await _loadFolders();
  }
} 