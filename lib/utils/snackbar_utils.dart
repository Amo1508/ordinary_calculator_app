import 'package:flutter/material.dart';

class SnackBarUtils {
  /// 顯示 SnackBar 訊息
  /// 
  /// [context] BuildContext
  /// [message] 要顯示的訊息
  /// [isError] 是否為錯誤訊息（預設為 false）
  /// [duration] 顯示持續時間（預設 2 秒）
  static void showSnackBar(
    BuildContext context, {
    required String message,
    bool isError = false,
    Duration duration = const Duration(seconds: 2),
  }) {
    if (!context.mounted) return;
    
    // 先關閉當前的 SnackBar（如果有的話）
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    
    // 顯示新的 SnackBar
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        behavior: SnackBarBehavior.floating,
        backgroundColor: isError ? Colors.red[700] : null,
        duration: duration,
        margin: EdgeInsets.only(
          bottom: MediaQuery.of(context).size.height - 100, // 調整位置，避免遮擋按鈕
          left: 20,
          right: 20,
        ),
        dismissDirection: DismissDirection.horizontal, // 允許水平滑動關閉
      ),
    );
  }
}
