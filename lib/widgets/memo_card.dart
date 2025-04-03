import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/memo.dart';
import '../models/folder.dart';
import '../providers/memo_provider.dart';
import '../providers/folder_provider.dart';
import '../utils/date_formatter.dart';
import '../screens/memo_detail_screen.dart';

class MemoCard extends StatelessWidget {
  final Memo memo;
  final MemoProvider memoProvider;
  final VoidCallback? onLongPress;

  const MemoCard({
    super.key,
    required this.memo,
    required this.memoProvider,
    this.onLongPress,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => MemoDetailScreen(
              memoId: memo.id,
              folderId: memo.folderId,
            ),
          ),
        );
      },
      onLongPress: onLongPress,
      borderRadius: BorderRadius.circular(15),
      child: Card(
        color: memoProvider.getColorForMemo(memo.colorIndex),
        elevation: 2,
        child: Container(
          padding: const EdgeInsets.all(16.0),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(15),
            border: Border.all(
              color: Colors.grey.withOpacity(0.1),
              width: 0.5,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (memo.title.isNotEmpty)
                Text(
                  memo.title,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    height: 1.4,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              if (memo.title.isNotEmpty) const SizedBox(height: 8),
              Text(
                memo.content,
                style: const TextStyle(
                  fontSize: 16,
                  height: 1.5,
                ),
                maxLines: 6,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // 폴더 정보 (전체 보기에서만 표시)
                  _buildFolderTag(context),
                  
                  // 날짜 정보
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.access_time,
                        size: 14,
                        color: Colors.grey[600],
                      ),
                      const SizedBox(width: 4),
                      Text(
                        DateFormatter.formatDate(memo.modifiedAt),
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
  
  // 폴더 태그 위젯
  Widget _buildFolderTag(BuildContext context) {
    final folderProvider = Provider.of<FolderProvider>(context, listen: false);
    
    // 현재 선택된 폴더가 있거나 메모가 어떤 폴더에도 속하지 않으면 표시하지 않음
    if (folderProvider.currentFolderId.isNotEmpty || memo.folderId.isEmpty) {
      return const SizedBox.shrink();
    }
    
    // 메모가 속한 폴더 찾기
    String folderName = '알 수 없음';
    for (final folder in folderProvider.folders) {
      if (folder.id == memo.folderId) {
        folderName = folder.name;
        break;
      }
    }
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.deepPurple.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.folder_outlined,
            size: 14,
            color: Colors.deepPurple,
          ),
          const SizedBox(width: 4),
          Text(
            folderName,
            style: const TextStyle(
              fontSize: 12,
              color: Colors.deepPurple,
            ),
          ),
        ],
      ),
    );
  }
} 