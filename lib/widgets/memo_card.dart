import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/memo.dart';
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
              color: Colors.grey.withAlpha(51),
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
                          color: Colors.black87,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    Consumer<DrawingProvider>(
                      builder: (context, drawingProvider, child) {
                        return _DrawingPreview(memoId: memo.id);
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
        color: Colors.deepPurple.withAlpha(26),
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

class _DrawingPreview extends StatelessWidget {
  final String memoId;

  const _DrawingPreview({Key? key, required this.memoId}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // 항상 최신 상태를 반영하도록 listen: true 유지
    final drawingProvider = Provider.of<DrawingProvider>(context, listen: true);
    
    // 마지막 변경 ID에 기반한 고유 키 생성
    final lastChanged = drawingProvider.lastChangedMemoId;
    
    // lastChanged에 현재 memoId가 포함되어 있으면 즉시 갱신 필요
    final needsImmediate = lastChanged.contains(memoId);
    
    // 고유한 키 생성 (lastChangedMemoId가 변경될 때마다 강제 업데이트)
    final uniqueKey = 'drawing_${memoId}_${drawingProvider.lastChangedMemoId}';
    
    print('미리보기 그리기: $memoId, 마지막 변경: $lastChanged, 즉시 갱신 필요: $needsImmediate');
    
    return FutureBuilder<Drawing?>(
      // 고유 키를 사용하여 cache 무시
      key: ValueKey(uniqueKey),
      future: Future(() async {
        if (needsImmediate) {
          // 이 메모의 변경인 경우, 약간 지연 후 다시 확인 (삭제 반영 보장)
          await Future.delayed(const Duration(milliseconds: 50));
        }
        
        // Hive에서 최신 데이터 로드
        return drawingProvider.getDrawingByMemoId(memoId);
      }),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const SizedBox.shrink(); // 로딩 중에는 빈 공간
        }
        
        // 그림이 있고, 내용이 비어있지 않은 경우에만 표시
        if (snapshot.hasData && snapshot.data != null && snapshot.data!.lines.isNotEmpty) {
          return Container(
            width: 40,
            height: 40,
            margin: const EdgeInsets.only(left: 8),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: Colors.grey.withAlpha(51),
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
  }
} 