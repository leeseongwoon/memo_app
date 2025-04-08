import 'package:flutter/material.dart';

/// 앱 전체에서 일관된 스타일의 스낵바를 표시하기 위한 유틸리티
class SnackbarUtil {
  /// 정보 메시지 스낵바를 표시합니다.
  static void showInfo(
    BuildContext context, 
    String message, {
    Duration duration = const Duration(seconds: 2),
  }) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        duration: duration,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
  
  /// 성공 메시지 스낵바를 표시합니다.
  static void showSuccess(
    BuildContext context, 
    String message, {
    Duration duration = const Duration(seconds: 2),
  }) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        duration: duration,
        behavior: SnackBarBehavior.floating,
        backgroundColor: Colors.green,
      ),
    );
  }
  
  /// 경고 메시지 스낵바를 표시합니다.
  static void showWarning(
    BuildContext context, 
    String message, {
    Duration duration = const Duration(seconds: 2),
  }) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        duration: duration,
        behavior: SnackBarBehavior.floating,
        backgroundColor: Colors.orange,
      ),
    );
  }
  
  /// 오류 메시지 스낵바를 표시합니다.
  static void showError(
    BuildContext context, 
    String message, {
    Duration duration = const Duration(seconds: 3),
  }) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        duration: duration,
        behavior: SnackBarBehavior.floating,
        backgroundColor: Colors.red,
      ),
    );
  }
} 