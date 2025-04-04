import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/memo.dart';
import '../models/folder.dart';
import '../models/drawing.dart';
import '../providers/memo_provider.dart';
import '../providers/folder_provider.dart';
import '../providers/drawing_provider.dart';
import '../utils/date_formatter.dart';
import '../screens/memo_detail_screen.dart';
import '../painters/drawing_preview_painter.dart';

class MemoCard extends StatelessWidget {
  final Memo memo;
  final MemoProvider memoProvider;
  final VoidCallback? onLongPress;
  final VoidCallback? onTap;

  const MemoCard({
    super.key,
    required this.memo,
    required this.memoProvider,
    this.onLongPress,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap ?? () {
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
          height: 120,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(15),
            border: Border.all(
              color: Colors.grey.withOpacity(0.1),
              width: 0.5,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
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
              if (memo.title.isNotEmpty) const SizedBox(height: 4),
              Expanded(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Text(
                        memo.content,
                        style: const TextStyle(
                          fontSize: 16,
                          height: 1.5,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    Consumer<DrawingProvider>(
                      builder: (context, drawingProvider, child) {
                        return FutureBuilder<Drawing?>(
                          future: drawingProvider.getDrawingByMemoId(memo.id),
                          builder: (context, snapshot) {
                            if (snapshot.hasData && snapshot.data != null && snapshot.data!.lines.isNotEmpty) {
                              return Container(
                                width: 40,
                                height: 40,
                                margin: const EdgeInsets.only(left: 8),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(
                                    color: Colors.grey.withOpacity(0.2),
                                    width: 1,
                                  ),
                                ),
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(8),
                                  child: CustomPaint(
                                    painter: DrawingPreviewPainter(snapshot.data!.lines),
                                    size: const Size(40, 40),
                                  ),
                                ),
                              );
                            }
                            return const SizedBox.shrink();
                          },
                        );
                      },
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // 폴더 정보 (전체 보기에서만 표시)
                  _buildFolderTag(context),
                  
                  const SizedBox(width: 8), // 폴더 태그와 날짜 사이 간격 추가
                  
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
    
    // 현재 선택된 폴더가 있거나 메모가 어떤 폴더에도 속하지 않으면 빈 공간 반환
    if (folderProvider.currentFolderId.isNotEmpty || memo.folderId.isEmpty) {
      return const SizedBox(height: 22, width: 0);
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
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
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
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 80),
            child: Text(
              folderName,
              style: const TextStyle(
                fontSize: 12,
                color: Colors.deepPurple,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
} 