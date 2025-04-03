import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/folder.dart';
import '../providers/folder_provider.dart';
import '../providers/memo_provider.dart';

class FolderList extends StatelessWidget {
  final VoidCallback onFolderSelected;

  const FolderList({
    super.key,
    required this.onFolderSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Consumer2<FolderProvider, MemoProvider>(
      builder: (context, folderProvider, memoProvider, child) {
        final folders = folderProvider.folders;
        final currentFolderId = folderProvider.currentFolderId;
        
        return Column(
          children: [
            // 상단 헤더
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 16.0,
                vertical: 12.0,
              ),
              color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '폴더',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ),
                  IconButton(
                    icon: Icon(
                      Icons.add,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                    onPressed: () => _showAddFolderDialog(context),
                    iconSize: 20,
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                ],
              ),
            ),
            
            // 전체 메모 항목 (루트 폴더)
            ListTile(
              leading: const Icon(Icons.folder_outlined, color: Colors.amber),
              title: const Text('전체 메모'),
              selected: currentFolderId.isEmpty,
              selectedTileColor: Theme.of(context).colorScheme.primary.withOpacity(0.1),
              selectedColor: Theme.of(context).colorScheme.primary,
              onTap: () {
                folderProvider.currentFolderId = '';
                memoProvider.loadMemosByFolder('');
                onFolderSelected();
              },
            ),
            
            // 폴더 목록
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: folders.length,
              itemBuilder: (context, index) {
                final folder = folders[index];
                // '전체 메모' 폴더는 이미 위에 표시했으므로 건너뜀
                if (folder.name == '전체 메모') return const SizedBox.shrink();
                
                return ListTile(
                  leading: const Icon(Icons.folder_outlined, color: Colors.amber),
                  title: Text(folder.name),
                  selected: folder.id == currentFolderId,
                  selectedTileColor: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                  selectedColor: Theme.of(context).colorScheme.primary,
                  trailing: IconButton(
                    icon: const Icon(Icons.more_vert, size: 18),
                    onPressed: () => _showFolderOptions(context, folder),
                  ),
                  onTap: () {
                    folderProvider.currentFolderId = folder.id;
                    memoProvider.loadMemosByFolder(folder.id);
                    onFolderSelected();
                  },
                );
              },
            ),
          ],
        );
      },
    );
  }

  // 폴더 추가 다이얼로그
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

  // 폴더 옵션 메뉴
  void _showFolderOptions(BuildContext context, Folder folder) {
    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.edit),
              title: const Text('폴더명 수정'),
              onTap: () {
                Navigator.pop(context);
                _showRenameFolderDialog(context, folder);
              },
            ),
            ListTile(
              leading: const Icon(Icons.delete, color: Colors.red),
              title: const Text('폴더 삭제', style: TextStyle(color: Colors.red)),
              onTap: () {
                Navigator.pop(context);
                _showDeleteFolderDialog(context, folder);
              },
            ),
          ],
        ),
      ),
    );
  }

  // 폴더명 수정 다이얼로그
  void _showRenameFolderDialog(BuildContext context, Folder folder) {
    final textController = TextEditingController(text: folder.name);
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('폴더명 수정'),
        content: TextField(
          controller: textController,
          decoration: const InputDecoration(
            hintText: '새 폴더명 입력',
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
              if (name.isNotEmpty && name != folder.name) {
                final folderProvider = Provider.of<FolderProvider>(context, listen: false);
                folderProvider.updateFolder(folder.copyWith(name: name));
              }
              Navigator.pop(context);
            },
            child: const Text('저장'),
          ),
        ],
      ),
    );
  }

  // 폴더 삭제 확인 다이얼로그
  void _showDeleteFolderDialog(BuildContext context, Folder folder) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('폴더 삭제'),
        content: Text('${folder.name} 폴더를 삭제하시겠습니까?\n폴더 내 메모는 전체 메모로 이동됩니다.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('취소'),
          ),
          TextButton(
            onPressed: () {
              final folderProvider = Provider.of<FolderProvider>(context, listen: false);
              folderProvider.deleteFolder(folder.id);
              Navigator.pop(context);
            },
            child: const Text('삭제', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
} 