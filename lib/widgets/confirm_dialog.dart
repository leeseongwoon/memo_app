import 'package:flutter/material.dart';

/// 확인 다이얼로그 공통 컴포넌트
/// [title] 다이얼로그 제목
/// [content] 다이얼로그 내용
/// [confirmText] 확인 버튼 텍스트
/// [cancelText] 취소 버튼 텍스트
/// [isDangerous] 위험한 작업인지 여부 (삭제 등)
/// [onConfirm] 확인 버튼 콜백
Future<bool?> showConfirmDialog({
  required BuildContext context,
  required String title,
  required String content,
  String confirmText = '확인',
  String cancelText = '취소',
  bool isDangerous = false,
  VoidCallback? onConfirm,
}) {
  return showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      title: Text(title),
      content: Text(content),
      actions: [
        // 취소 버튼
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: Text(cancelText),
        ),
        // 확인 버튼
        TextButton(
          onPressed: () {
            Navigator.of(context).pop(true);
            if (onConfirm != null) {
              onConfirm();
            }
          },
          child: Text(
            confirmText,
            style: TextStyle(
              color: isDangerous ? Colors.red : null,
              fontWeight: isDangerous ? FontWeight.bold : null,
            ),
          ),
        ),
      ],
    ),
  );
} 