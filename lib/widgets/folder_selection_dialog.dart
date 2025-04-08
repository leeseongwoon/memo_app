import 'package:flutter/material.dart';
import '../models/folder.dart';
import '../providers/folder_provider.dart';
import 'package:provider/provider.dart';

/// 폴더 선택 다이얼로그
/// 
/// [title] 다이얼로그 제목
/// [folders] 선택 가능한 폴더 목록
/// [selectedFolderId] 현재 선택된 폴더 ID
/// [onFolderSelected] 폴더 선택 시 콜백
Future<void> showFolderSelectionDialog({
  required BuildContext context,
  required String title,
  required List<Folder> folders,
  required String selectedFolderId,
  required Function(String) onFolderSelected,
}) {
  return showDialog(
    context: context,
    builder: (context) => AlertDialog(
      title: Text(title),
      content: SizedBox(
        width: double.maxFinite,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // 폴더 추가 버튼
            InkWell(
              onTap: () => _showAddFolderDialog(context),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 8.0),
                decoration: BoxDecoration(
                  border: Border(
                    bottom: BorderSide(color: Colors.grey.withAlpha(77)),
                  ),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.create_new_folder, color: Colors.deepPurple),
                    const SizedBox(width: 16),
                    Text(
                      '새 폴더 만들기',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.deepPurple,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 8),
            
            // 폴더 목록
            Flexible(
              child: ListView(
                shrinkWrap: true,
                children: [
                  // 전체 메모 항목
                  ListTile(
                    leading: const Icon(Icons.folder_outlined, color: Colors.amber),
                    title: const Text('전체 메모'),
                    selected: selectedFolderId.isEmpty,
                    onTap: () {
                      Navigator.pop(context);
                      onFolderSelected('');
                    },
                  ),
                  // 나머지 폴더 목록
                  ...folders
                      .where((folder) => folder.name != '전체 메모')
                      .map((folder) => ListTile(
                            leading: const Icon(Icons.folder_outlined, color: Colors.amber),
                            title: Text(folder.name),
                            selected: selectedFolderId == folder.id,
                            onTap: () {
                              Navigator.pop(context);
                              onFolderSelected(folder.id);
                            },
                          ))
                      .toList(),
                ],
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('취소'),
        ),
      ],
    ),
  );
}

/// 새 폴더 추가 다이얼로그
void _showAddFolderDialog(BuildContext context) {
  final textController = TextEditingController();
  
  showDialog(
    context: context,
    builder: (context) => AlertDialog(
      title: const Text('새 폴더 추가'),
      content: TextField(
        controller: textController,
        decoration: const InputDecoration(
          hintText: '폴더명 입력',
        ),
        autofocus: true,
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('취소'),
        ),
        TextButton(
          onPressed: () {
            final name = textController.text.trim();
            if (name.isNotEmpty) {
              final folderProvider = Provider.of<FolderProvider>(context, listen: false);
              folderProvider.addFolder(name);
            }
            Navigator.pop(context);
          },
          child: const Text('추가'),
        ),
      ],
    ),
  );
} 