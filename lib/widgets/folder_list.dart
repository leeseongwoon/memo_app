import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/folder.dart';
import '../models/memo.dart';
import '../providers/folder_provider.dart';
import '../providers/memo_provider.dart';
import '../screens/memo_detail_screen.dart';

class FolderList extends StatefulWidget {
  final VoidCallback onFolderSelected;

  const FolderList({
    super.key,
    required this.onFolderSelected,
  });

  @override
  State<FolderList> createState() => _FolderListState();
}

class _FolderListState extends State<FolderList> {
  // 확장된 폴더 ID 저장
  Set<String> _expandedFolders = {};
  
  @override
  void initState() {
    super.initState();
    // 현재 선택된 폴더가 있으면 초기에 확장 상태로 설정
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final folderProvider = Provider.of<FolderProvider>(context, listen: false);
      if (folderProvider.currentFolderId.isNotEmpty) {
        setState(() {
          _expandedFolders.add(folderProvider.currentFolderId);
        });
      } else {
        // 처음에는 전체 메모 폴더 확장
        setState(() {
          _expandedFolders.add('');
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Consumer2<FolderProvider, MemoProvider>(
      builder: (context, folderProvider, memoProvider, child) {
        final folders = folderProvider.folders;
        final currentFolderId = folderProvider.currentFolderId;
        final memos = memoProvider.allMemos;
        
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
                  Row(
                    children: [
                      IconButton(
                        icon: Icon(
                          Icons.sort,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                        onPressed: () => _showFolderSortOptions(context, folderProvider),
                        iconSize: 20,
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                      ),
                      const SizedBox(width: 8),
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
                ],
              ),
            ),
            
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    // 전체 메모 항목 (루트 폴더)
                    Container(
                      color: currentFolderId.isEmpty 
                        ? Theme.of(context).colorScheme.primary.withOpacity(0.1)
                        : null,
                      child: Column(
                        children: [
                          ListTile(
                            leading: const Icon(Icons.folder_outlined, color: Colors.amber),
                            title: Row(
                              children: [
                                const Expanded(child: Text('전체 메모')),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: Theme.of(context).colorScheme.primary.withOpacity(0.2),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Text(
                                    '${memoProvider.getMemoCountByFolder("")}',
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.bold,
                                      color: Theme.of(context).colorScheme.primary,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            trailing: SizedBox(
                              width: 24,
                              child: InkWell(
                                child: Icon(
                                  _expandedFolders.contains('') 
                                    ? Icons.keyboard_arrow_up 
                                    : Icons.keyboard_arrow_down,
                                  color: currentFolderId.isEmpty 
                                    ? Theme.of(context).colorScheme.primary
                                    : null,
                                  size: 20,
                                ),
                                onTap: () {
                                  setState(() {
                                    if (_expandedFolders.contains('')) {
                                      _expandedFolders.remove('');
                                    } else {
                                      _expandedFolders.clear();
                                      _expandedFolders.add('');
                                    }
                                  });
                                },
                              ),
                            ),
                            contentPadding: const EdgeInsets.only(left: 16.0, right: 8.0),
                            onTap: () {
                              folderProvider.currentFolderId = '';
                              memoProvider.loadMemosByFolder('');
                              widget.onFolderSelected();
                            },
                          ),
                          if (_expandedFolders.contains(''))
                            Column(children: _buildMemoList(memos, '')),
                        ],
                      ),
                    ),
                    
                    // 폴더 목록
                    ...folders.where((folder) => folder.name != '전체 메모').map((folder) {
                      // 폴더의 메모들 필터링
                      final folderMemos = memos.where((memo) => memo.folderId == folder.id).toList();
                      
                      return Container(
                        color: currentFolderId == folder.id 
                          ? Theme.of(context).colorScheme.primary.withOpacity(0.1)
                          : null,
                        child: Column(
                          children: [
                            ListTile(
                              leading: const Icon(Icons.folder_outlined, color: Colors.amber),
                              title: Row(
                                children: [
                                  Expanded(child: Text(folder.name)),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: Theme.of(context).colorScheme.primary.withOpacity(0.2),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Text(
                                      '${memoProvider.getMemoCountByFolder(folder.id)}',
                                      style: TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.bold,
                                        color: Theme.of(context).colorScheme.primary,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  InkWell(
                                    onTap: () => _showFolderOptions(context, folder),
                                    child: const Icon(Icons.more_vert, size: 18),
                                  ),
                                ],
                              ),
                              trailing: SizedBox(
                                width: 24,
                                child: InkWell(
                                  child: Icon(
                                    _expandedFolders.contains(folder.id) 
                                      ? Icons.keyboard_arrow_up 
                                      : Icons.keyboard_arrow_down,
                                    color: currentFolderId == folder.id 
                                      ? Theme.of(context).colorScheme.primary
                                      : null,
                                    size: 20,
                                  ),
                                  onTap: () {
                                    setState(() {
                                      if (_expandedFolders.contains(folder.id)) {
                                        _expandedFolders.remove(folder.id);
                                      } else {
                                        _expandedFolders.clear();
                                        _expandedFolders.add(folder.id);
                                      }
                                    });
                                  },
                                ),
                              ),
                              contentPadding: const EdgeInsets.only(left: 16.0, right: 8.0),
                              onTap: () {
                                folderProvider.currentFolderId = folder.id;
                                memoProvider.loadMemosByFolder(folder.id);
                                widget.onFolderSelected();
                              },
                            ),
                            if (_expandedFolders.contains(folder.id))
                              Column(children: _buildMemoList(folderMemos, folder.id)),
                          ],
                        ),
                      );
                    }).toList(),
                  ],
                ),
              ),
            ),
          ],
        );
      },
    );
  }
  
  // 메모 리스트 생성
  List<Widget> _buildMemoList(List<Memo> memos, String folderId) {
    final memoProvider = Provider.of<MemoProvider>(context, listen: false);
    // 해당 폴더의 메모 필터링
    final filteredMemos = folderId.isEmpty 
        ? memoProvider.allMemos 
        : memoProvider.allMemos.where((memo) => memo.folderId == folderId).toList();
    
    if (filteredMemos.isEmpty) {
      return [
        ListTile(
          contentPadding: const EdgeInsets.symmetric(horizontal: 40),
          title: Text(
            '메모가 없습니다',
            style: TextStyle(
              fontSize: 14,
              fontStyle: FontStyle.italic,
              color: Colors.grey[500],
            ),
          ),
        ),
      ];
    }
    
    return filteredMemos.map((memo) {
      return ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 40),
        title: Text(
          memo.title.isNotEmpty ? memo.title : '(제목 없음)',
          style: const TextStyle(fontSize: 14),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => MemoDetailScreen(
                memoId: memo.id,
                folderId: folderId,
              ),
            ),
          );
        },
      );
    }).toList();
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
        content: Text('${folder.name} 폴더를 삭제하시겠습니까?\n폴더 내 모든 메모도 함께 삭제됩니다.'),
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

  // 폴더 정렬 옵션 다이얼로그
  void _showFolderSortOptions(BuildContext context, FolderProvider folderProvider) {
    final currentFolderSort = folderProvider.currentSortType;
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('폴더 정렬'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            RadioListTile<FolderSort>(
              title: const Text('최신순'),
              value: FolderSort.latest,
              groupValue: currentFolderSort,
              onChanged: (value) {
                Navigator.pop(context);
                if (value != null) {
                  folderProvider.changeSortType(value);
                }
              },
            ),
            RadioListTile<FolderSort>(
              title: const Text('오래된순'),
              value: FolderSort.oldest,
              groupValue: currentFolderSort,
              onChanged: (value) {
                Navigator.pop(context);
                if (value != null) {
                  folderProvider.changeSortType(value);
                }
              },
            ),
            RadioListTile<FolderSort>(
              title: const Text('이름순'),
              value: FolderSort.nameAscending,
              groupValue: currentFolderSort,
              onChanged: (value) {
                Navigator.pop(context);
                if (value != null) {
                  folderProvider.changeSortType(value);
                }
              },
            ),
          ],
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
} 