import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import '../models/memo.dart';
import '../providers/memo_provider.dart';
import '../providers/folder_provider.dart';
import '../widgets/memo_card.dart';
import '../widgets/folder_list.dart';
import 'memo_detail_screen.dart';

class MemoListScreen extends StatefulWidget {
  const MemoListScreen({super.key});

  @override
  State<MemoListScreen> createState() => _MemoListScreenState();
}

class _MemoListScreenState extends State<MemoListScreen> {
  String _searchQuery = '';
  bool _isSearching = false;
  late KoreanTextEditingController _searchController;
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  void initState() {
    super.initState();
    _searchController = KoreanTextEditingController();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<Memo> _getFilteredMemos(List<Memo> memos) {
    if (_searchQuery.isEmpty) return memos;
    
    return memos.where((memo) {
      final titleMatch = memo.title.toLowerCase().contains(_searchQuery.toLowerCase());
      final contentMatch = memo.content.toLowerCase().contains(_searchQuery.toLowerCase());
      return titleMatch || contentMatch;
    }).toList();
  }

  void _startSearch() {
    setState(() {
      _isSearching = true;
    });
  }

  void _stopSearch() {
    setState(() {
      _isSearching = false;
      _searchQuery = '';
      _searchController.clear();
    });
  }

  // 새 메모 생성 및 열기
  void _createNewMemo(BuildContext context) {
    final folderProvider = Provider.of<FolderProvider>(context, listen: false);
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => MemoDetailScreen(
          memoId: '',
          folderId: folderProvider.currentFolderId, // 현재 선택된 폴더에 메모 생성
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final folderProvider = Provider.of<FolderProvider>(context);
    
    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: Colors.grey[50],
      appBar: _isSearching ? _buildSearchAppBar() : _buildNormalAppBar(),
      drawer: Drawer(
        child: FolderList(
          onFolderSelected: () {
            Navigator.pop(context); // 드로어 닫기
          },
        ),
      ),
      body: Consumer<MemoProvider>(
        builder: (context, memoProvider, child) {
          final memos = memoProvider.memos;
          final filteredMemos = _getFilteredMemos(memos);
          
          if (memos.isEmpty) {
            return Container(
              decoration: BoxDecoration(
                color: Colors.white,
              ),
              child: Stack(
                children: [
                  // 배경 아이콘 패턴
                  Positioned.fill(
                    child: CustomPaint(
                      painter: BackgroundIconPainter(),
                    ),
                  ),
                  // 메인 컨텐츠
                  Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          width: 180,
                          height: 180,
                          decoration: BoxDecoration(
                            color: Colors.deepPurple.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(90),
                          ),
                          child: Icon(
                            Icons.edit_note_rounded,
                            size: 100,
                            color: Colors.deepPurple[300],
                          ),
                        ),
                        const SizedBox(height: 24),
                        const Text(
                          '첫 번째 메모를 작성해보세요!',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.deepPurple,
                          ),
                        ),
                        const SizedBox(height: 16),
                        SizedBox(
                          width: 240,
                          child: Text(
                            '오른쪽 하단의 + 버튼을 눌러 새로운 메모를 추가할 수 있습니다.',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey[600],
                              height: 1.5,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          }
          
          if (filteredMemos.isEmpty && _searchQuery.isNotEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.search_off_rounded,
                    size: 80,
                    color: Colors.grey[400],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    '검색 결과가 없습니다',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey[700],
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '"$_searchQuery" 에 대한 검색 결과가 없습니다',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            );
          }

          return Padding(
            padding: const EdgeInsets.all(8.0),
            child: MasonryGridView.count(
              crossAxisCount: 2,
              mainAxisSpacing: 8,
              crossAxisSpacing: 8,
              itemCount: filteredMemos.length,
              itemBuilder: (context, index) {
                return AnimatedContainer(
                  duration: Duration(milliseconds: 300 + (index * 30)),
                  curve: Curves.easeInOut, 
                  transform: Matrix4.translationValues(0, index < 10 ? (1 - index / 10) * 20 : 0, 0),
                  child: MemoCard(
                    memo: filteredMemos[index],
                    memoProvider: memoProvider,
                    onLongPress: () => _showMemoOptions(context, filteredMemos[index]),
                  ),
                );
              },
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _createNewMemo(context),
        child: const Icon(Icons.add_rounded, size: 28),
      ),
    );
  }

  AppBar _buildNormalAppBar() {
    final folderProvider = Provider.of<FolderProvider>(context);
    
    return AppBar(
      title: Text(folderProvider.currentFolderName),
      leading: IconButton(
        icon: const Icon(Icons.menu),
        onPressed: () {
          _scaffoldKey.currentState?.openDrawer();
        },
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.search_rounded),
          onPressed: _startSearch,
        ),
        const SizedBox(width: 8),
      ],
    );
  }

  AppBar _buildSearchAppBar() {
    return AppBar(
      leading: IconButton(
        icon: const Icon(Icons.arrow_back),
        onPressed: _stopSearch,
      ),
      title: TextField(
        controller: _searchController,
        decoration: const InputDecoration(
          hintText: '메모 검색...',
          border: InputBorder.none,
          hintStyle: TextStyle(color: Colors.grey),
        ),
        style: const TextStyle(fontSize: 16),
        autofocus: true,
        onChanged: (value) {
          setState(() {
            _searchQuery = value;
          });
        },
        keyboardType: TextInputType.text,
        enableSuggestions: true,
        textInputAction: TextInputAction.search,
        autocorrect: false,
      ),
      actions: [
        if (_searchQuery.isNotEmpty)
          IconButton(
            icon: const Icon(Icons.clear),
            onPressed: () {
              setState(() {
                _searchQuery = '';
                _searchController.clear();
              });
            },
          ),
      ],
    );
  }

  // 메모 옵션 메뉴 (폴더 이동 등)
  void _showMemoOptions(BuildContext context, Memo memo) {
    final folderProvider = Provider.of<FolderProvider>(context, listen: false);
    final memoProvider = Provider.of<MemoProvider>(context, listen: false);
    
    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.drive_file_move_outlined),
              title: const Text('폴더 이동'),
              onTap: () {
                Navigator.pop(context);
                _showMoveMemoDialog(context, memo);
              },
            ),
            ListTile(
              leading: const Icon(Icons.delete, color: Colors.red),
              title: const Text('메모 삭제', style: TextStyle(color: Colors.red)),
              onTap: () async {
                Navigator.pop(context);
                await memoProvider.deleteMemo(memo.id);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('메모가 삭제되었습니다'),
                    duration: Duration(seconds: 2),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  // 메모 폴더 이동 다이얼로그
  void _showMoveMemoDialog(BuildContext context, Memo memo) {
    final folderProvider = Provider.of<FolderProvider>(context, listen: false);
    final memoProvider = Provider.of<MemoProvider>(context, listen: false);
    final folders = folderProvider.folders;
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('폴더 이동'),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView(
            shrinkWrap: true,
            children: [
              ListTile(
                leading: const Icon(Icons.folder_outlined, color: Colors.amber),
                title: const Text('전체 메모'),
                selected: memo.folderId.isEmpty,
                onTap: () async {
                  await memoProvider.moveMemoToFolder(memo.id, '');
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('메모가 이동되었습니다'),
                      duration: Duration(seconds: 2),
                    ),
                  );
                  // 현재 폴더의 메모 목록 갱신
                  memoProvider.loadMemosByFolder(folderProvider.currentFolderId);
                },
              ),
              ...folders
                  .where((folder) => folder.name != '전체 메모')
                  .map((folder) => ListTile(
                        leading: const Icon(Icons.folder_outlined, color: Colors.amber),
                        title: Text(folder.name),
                        selected: memo.folderId == folder.id,
                        onTap: () async {
                          await memoProvider.moveMemoToFolder(memo.id, folder.id);
                          Navigator.pop(context);
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('메모가 이동되었습니다'),
                              duration: Duration(seconds: 2),
                            ),
                          );
                          // 현재 폴더의 메모 목록 갱신
                          memoProvider.loadMemosByFolder(folderProvider.currentFolderId);
                        },
                      ))
                  .toList(),
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
}

class BackgroundIconPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final icons = [
      Icons.note_outlined,
      Icons.format_list_bulleted,
      Icons.format_color_text,
      Icons.sticky_note_2_outlined,
      Icons.bookmark_border,
      Icons.star_border,
    ];
    
    final colors = [
      Colors.deepPurple[100],
      Colors.amber[200],
      Colors.blue[100],
      Colors.green[100],
      Colors.pink[100],
      Colors.orange[100],
    ];
    
    final random = DateTime.now().millisecondsSinceEpoch;
    final iconSize = 24.0;
    
    // 배경에 아이콘 그리기
    for (var x = 0.0; x < size.width; x += 80) {
      for (var y = 0.0; y < size.height; y += 80) {
        final offset = x % 40 == 0 ? 40.0 : 0.0;
        final iconIndex = ((x.toInt() + y.toInt()) % icons.length).abs();
        
        final textPainter = TextPainter(
          text: TextSpan(
            text: String.fromCharCode(icons[iconIndex].codePoint),
            style: TextStyle(
              fontSize: iconSize,
              fontFamily: icons[iconIndex].fontFamily,
              color: (colors[iconIndex] ?? Colors.grey[200])?.withOpacity(0.2),
            ),
          ),
          textDirection: TextDirection.ltr,
        );
        
        textPainter.layout();
        textPainter.paint(canvas, Offset(x, y + offset));
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
} 