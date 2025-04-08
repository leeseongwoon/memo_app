import 'package:flutter/material.dart';

/// 로딩 스피너 컴포넌트
/// 
/// [size] 로딩 스피너 크기 (기본값: 36)
/// [color] 로딩 스피너 색상 (기본값: 현재 테마의 primary 색상)
/// [strokeWidth] 로딩 스피너 선 두께 (기본값: 4)
/// [backgroundColor] 배경색 (null이면 투명)
/// [isFullScreen] 전체 화면 표시 여부
class LoadingSpinner extends StatelessWidget {
  final double size;
  final Color? color;
  final double strokeWidth;
  final Color? backgroundColor;
  final bool isFullScreen;

  const LoadingSpinner({
    super.key,
    this.size = 36.0,
    this.color,
    this.strokeWidth = 4.0,
    this.backgroundColor,
    this.isFullScreen = false,
  });

  @override
  Widget build(BuildContext context) {
    final themeColor = Theme.of(context).colorScheme.primary;
    final spinnerWidget = SizedBox(
      width: size,
      height: size,
      child: CircularProgressIndicator(
        strokeWidth: strokeWidth,
        valueColor: AlwaysStoppedAnimation<Color>(color ?? themeColor),
        backgroundColor: backgroundColor,
      ),
    );
    
    if (isFullScreen) {
      return Container(
        color: Colors.black12,
        child: Center(child: spinnerWidget),
      );
    } else {
      return spinnerWidget;
    }
  }
}

/// 로딩 상태 스피너 오버레이
/// 
/// [isLoading] 로딩 중 여부
/// [child] 로딩 중이 아닐 때 표시할 위젯
/// [color] 스피너 색상
/// [backgroundColor] 오버레이 배경색
class LoadingOverlay extends StatelessWidget {
  final bool isLoading;
  final Widget child;
  final Color? color;
  final Color backgroundColor;

  const LoadingOverlay({
    super.key,
    required this.isLoading,
    required this.child,
    this.color,
    this.backgroundColor = Colors.black26,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        child,
        if (isLoading)
          Positioned.fill(
            child: Container(
              color: backgroundColor,
              child: Center(
                child: LoadingSpinner(color: color),
              ),
            ),
          ),
      ],
    );
  }
} 