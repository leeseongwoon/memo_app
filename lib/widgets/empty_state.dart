import 'package:flutter/material.dart';

/// 빈 화면 상태 컴포넌트
/// 
/// [icon] 표시할 아이콘
/// [iconSize] 아이콘 크기
/// [iconColor] 아이콘 색상
/// [title] 제목 텍스트
/// [subtitle] 부제목 텍스트
/// [backgroundColor] 배경색 (기본값: Colors.white)
/// [showBackgroundPattern] 배경 패턴 표시 여부
class EmptyStateView extends StatelessWidget {
  final IconData icon;
  final double iconSize;
  final Color? iconColor;
  final String title;
  final String subtitle;
  final Color? backgroundColor;
  final bool showBackgroundPattern;

  const EmptyStateView({
    super.key,
    required this.icon,
    this.iconSize = 100,
    this.iconColor,
    required this.title,
    required this.subtitle,
    this.backgroundColor = Colors.white,
    this.showBackgroundPattern = true,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final defaultIconColor = theme.colorScheme.primary.withAlpha(179);

    return Container(
      decoration: BoxDecoration(
        color: backgroundColor,
      ),
      child: Stack(
        children: [
          // 배경 아이콘 패턴 (선택적)
          if (showBackgroundPattern)
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
                  width: iconSize * 1.8,
                  height: iconSize * 1.8,
                  decoration: BoxDecoration(
                    color: (iconColor ?? defaultIconColor).withAlpha(26),
                    borderRadius: BorderRadius.circular(iconSize * 0.9),
                  ),
                  child: Icon(
                    icon,
                    size: iconSize,
                    color: iconColor ?? defaultIconColor,
                  ),
                ),
                const SizedBox(height: 24),
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: theme.colorScheme.primary,
                  ),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: 240,
                  child: Text(
                    subtitle,
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
}

/// 배경 아이콘 패턴을 그리는 CustomPainter
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
              color: (colors[iconIndex] ?? Colors.grey[200])?.withAlpha(51),
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