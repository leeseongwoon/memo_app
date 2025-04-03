import 'package:flutter/material.dart';
import '../models/folder.dart';
import '../database/database_helper.dart';

class FolderProvider with ChangeNotifier {
  List<Folder> _folders = [];
  String _currentFolderId = '';

  List<Folder> get folders => _folders;
  String get currentFolderId => _currentFolderId;
  
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
    _loadFolders();
  }

  Future<void> _loadFolders() async {
    try {
      _folders = await DatabaseHelper.instance.getAllFolders();
      notifyListeners();
    } catch (e) {
      print('폴더 로딩 오류: $e');
    }
  }

  Future<void> addFolder(String name) async {
    try {
      final folder = Folder(name: name);
      await DatabaseHelper.instance.insertFolder(folder);
      await _loadFolders();
    } catch (e) {
      print('폴더 추가 오류: $e');
    }
  }

  Future<void> updateFolder(Folder folder) async {
    try {
      await DatabaseHelper.instance.updateFolder(folder);
      await _loadFolders();
    } catch (e) {
      print('폴더 업데이트 오류: $e');
    }
  }

  Future<void> deleteFolder(String id) async {
    try {
      await DatabaseHelper.instance.deleteFolder(id);
      
      // 현재 선택된 폴더가 삭제되는 경우 기본 폴더로 변경
      if (_currentFolderId == id) {
        _currentFolderId = '';
      }
      
      await _loadFolders();
    } catch (e) {
      print('폴더 삭제 오류: $e');
    }
  }
} 