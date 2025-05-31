// 引入 Flutter 核心套件
import 'package:flutter/material.dart';
// 引入計算記錄模型
import '../models/calculation_record.dart';
// 引入 Hive 資料庫服務
import '../services/hive_database_service.dart';
// 引入自定義頂部導航欄組件
import '../widgets/custom_app_bar.dart';
// 引入 SnackBar 工具類
import '../utils/snackbar_utils.dart';

/// 歷史記錄畫面組件
/// 顯示所有計算歷史記錄，並提供刪除和清空功能
class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

/// 歷史記錄畫面狀態類
/// 管理歷史記錄的載入、顯示和操作
class _HistoryScreenState extends State<HistoryScreen> {
  /// 格式化數字字串，加入千分位分隔符
  /// [number] 要格式化的數字字串
  /// 返回格式化後的字串，包含千分位分隔符
  String _formatNumber(String number) {
    if (number.isEmpty) return '';

    // 檢查是否為小數，分開處理整數和小數部分
    if (number.contains('.')) {
      final parts = number.split('.');
      // 處理整數部分，確保能正確解析
      final integerPart = int.tryParse(parts[0])?.toString() ?? parts[0];
      // 合併格式化後的整數部分和原始小數部分
      return '${_addThousandSeparator(integerPart)}.${parts[1]}';
    }

    // 處理整數
    return _addThousandSeparator(number);
  }

  /// 在數字字串中加入千分位符號
  /// [number] 要處理的數字字串
  /// 返回加入千分位符號後的字串
  String _addThousandSeparator(String number) {
    try {
      // 嘗試將輸入轉換為數字，如果失敗則返回原字串
      final numberValue = double.tryParse(number);
      if (numberValue == null) return number;

      // 分割整數和小數部分
      final parts = number.split('.');
      String integerPart = parts[0];
      final buffer = StringBuffer();

      // 處理負數
      bool isNegative = integerPart.startsWith('-');
      if (isNegative) {
        integerPart = integerPart.substring(1);
      }

      // 從右到左每三位加一個逗號
      int length = integerPart.length;
      for (int i = 0; i < length; i++) {
        buffer.write(integerPart[i]);
        int remaining = length - i - 1;
        if (remaining > 0 && remaining % 3 == 0) {
          buffer.write(',');
        }
      }

      // 處理負數情況
      String result = buffer.toString();
      if (isNegative) {
        result = '-$result';
      }

      // 如果有小數部分，加回去
      if (parts.length > 1) {
        result = '$result.${parts[1]}';
      }

      return result;
    } catch (e) {
      // 如果發生錯誤，返回原始字串
      return number;
    }
  }

  /// 儲存計算記錄的列表
  late List<CalculationRecord> _calculations = [];

  @override
  void initState() {
    super.initState();
    // 初始化組件時載入計算記錄
    _initializeAndLoad();
  }

  /// 初始化並載入計算記錄
  /// 這個方法會先初始化 Hive 資料庫，然後載入所有計算記錄
  Future<void> _initializeAndLoad() async {
    try {
      // 首先初始化 Hive 資料庫
      await HiveDatabaseService.init();
      // 然後載入計算記錄
      await _loadCalculations();
    } catch (e) {
      // 如果組件仍然掛載，顯示錯誤訊息
      if (mounted) {
        SnackBarUtils.showSnackBar(
          context,
          message: '初始化失敗: $e',
          isError: true,
        );
      }
    }
  }

  /// 從資料庫載入計算記錄
  /// 這個方法會從 Hive 資料庫中獲取所有計算記錄並更新狀態
  Future<void> _loadCalculations() async {
    try {
      // 從資料庫獲取計算記錄
      final calculations = await HiveDatabaseService.getCalculations();
      // 如果組件仍然掛載，更新狀態
      if (mounted) {
        setState(() {
          _calculations = calculations;
        });
      }
    } catch (e) {
      // 如果組件仍然掛載，顯示錯誤訊息
      if (mounted) {
        SnackBarUtils.showSnackBar(
          context,
          message: '無法載入歷史記錄: $e',
          isError: true,
        );
      }
    }
  }

  /// 刪除單條計算記錄
  /// [record] 要刪除的計算記錄物件
  Future<void> _deleteRecord(CalculationRecord record) async {
    try {
      // 從資料庫中刪除指定記錄
      await HiveDatabaseService.deleteCalculation(record);
      // 重新載入計算記錄
      await _loadCalculations();
      // 顯示成功訊息
      if (mounted) {
        SnackBarUtils.showSnackBar(context, message: '已刪除記錄');
      }
    } catch (e) {
      // 如果組件仍然掛載，顯示錯誤訊息
      if (mounted) {
        SnackBarUtils.showSnackBar(
          context,
          message: '刪除失敗: ${e.toString().split(':').last.trim()}',
          isError: true,
        );
      }
    }
  }

  /// 顯示確認對話框，詢問用戶是否確定要清除所有記錄
  /// 如果用戶確認，則調用 _clearAll 方法
  Future<void> _confirmClearAll() async {
    // 顯示確認對話框
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('清除所有記錄'),
        content: const Text('確定要清除所有歷史記錄嗎？此操作無法復原。'),
        actions: [
          // 取消按鈕
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('取消'),
          ),
          // 確認按鈕（紅色文字）
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('清除', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    // 如果用戶確認，執行清除操作
    if (confirmed == true) {
      await _clearAll();
    }
  }

  /// 清除所有計算記錄
  /// 這個方法會清空資料庫中的所有記錄，並更新UI
  Future<void> _clearAll() async {
    try {
      // 調用服務層方法清空資料庫
      await HiveDatabaseService.clearAll();
      // 如果組件仍然掛載，更新UI
      if (mounted) {
        setState(() {
          // 清空本地記錄列表
          _calculations = [];
        });
        // 顯示成功訊息
        SnackBarUtils.showSnackBar(context, message: '已清除所有記錄');
      }
    } catch (e) {
      // 如果組件仍然掛載，顯示錯誤訊息
      if (mounted) {
        SnackBarUtils.showSnackBar(context, message: '清除失敗: $e', isError: true);
      }
    }
  }

  /// 計算所有記錄結果的總和
  /// 這個方法會遍歷所有計算記錄，將結果相加
  /// 返回所有記錄結果的總和
  double _calculateTotal() {
    double total = 0;
    // 遍歷所有計算記錄
    for (var record in _calculations) {
      try {
        // 嘗試將結果轉換為數字並累加
        total += double.tryParse(record.result) ?? 0;
      } catch (e) {
        // 如果結果無法轉換為數字，跳過該記錄
      }
    }
    return total;
  }

  /// 構建歷史記錄頁面的主要UI
  /// 根據是否有記錄顯示不同的視圖
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // 使用自定義的頂部導航欄
      appBar: const CustomAppBar(title: '歷史記錄'),
      // 根據是否有記錄顯示不同的視圖
      body: _calculations.isEmpty
          ? _buildEmptyState() // 無記錄時顯示空白狀態
          : _buildHistoryList(), // 有記錄時顯示列表
      // 浮動按鈕用於清除所有記錄
      floatingActionButton: FloatingActionButton(
        onPressed: _confirmClearAll, // 點擊時顯示確認對話框
        child: const Icon(Icons.delete_forever), // 刪除圖標
        tooltip: '清除所有記錄', // 懸停提示文字
      ),
    );
  }

  /// 構建空白狀態視圖
  /// 當沒有歷史記錄時顯示
  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center, // 垂直居中
        children: [
          // 顯示歷史記錄關閉圖標
          Icon(
            Icons.history_toggle_off, // 歷史記錄關閉圖標
            size: 80, // 圖標大小
            color: Theme.of(
              context,
            ).textTheme.bodyLarge?.color?.withOpacity(0.7), // 根據主題設置顏色
          ),
          const SizedBox(height: 16), // 間距
          // 顯示「沒有歷史記錄」文字
          Text(
            '沒有歷史記錄',
            style: TextStyle(
              fontSize: 20, // 字體大小
              color: Theme.of(context).textTheme.bodyLarge?.color, // 文字顏色
            ),
          ),
          const SizedBox(height: 8), // 間距
          // 顯示總和（0）
          Text(
            '總和: ${_formatNumber('0')}',
            style: TextStyle(
              fontSize: 18, // 字體大小
              fontWeight: FontWeight.bold, // 粗體
              color: Theme.of(context).textTheme.bodyLarge?.color, // 文字顏色
            ),
          ),
        ],
      ),
    );
  }

  /// 構建歷史記錄列表視圖
  /// 顯示所有歷史記錄和總和
  Widget _buildHistoryList() {
    // 計算所有記錄的總和
    final total = _calculateTotal();
    return Column(
      children: [
        // 總和顯示區域
        Container(
          width: double.infinity, // 寬度填滿
          padding: const EdgeInsets.symmetric(
            vertical: 16,
            horizontal: 24,
          ), // 內邊距
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surfaceVariant, // 背景色
            border: Border(
              bottom: BorderSide(
                color: Theme.of(context).dividerColor, // 底部邊框顏色
              ),
            ),
          ),
          child: Text(
            '總和: ${_formatNumber(total.toStringAsFixed(2))}', // 格式化總和
            style: TextStyle(
              fontSize: 48, // 大號字體
              fontWeight: FontWeight.bold, // 粗體
              color: Theme.of(context).textTheme.bodyLarge?.color, // 文字顏色
            ),
            textAlign: TextAlign.right, // 文字右對齊
          ),
        ),
        // 記錄列表
        Expanded(
          child: ListView.builder(
            itemCount: _calculations.length, // 列表項數量
            itemBuilder: (context, index) {
              // 構建每個列表項
              final record = _calculations[index];
              return _buildListItem(record);
            },
          ),
        ),
      ],
    );
  }

  /// 構建單個歷史記錄列表項
  /// [record] 要顯示的計算記錄物件
  /// 返回一個列表項
  Widget _buildListItem(CalculationRecord record) {
    return Container(
      // 添加底部邊框
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(color: Colors.grey[300]!, width: 1.0),
        ),
      ),
      child: ListTile(
        // 顯示計算結果（帶千分位格式）
        title: Text(
          _formatNumber(record.result), // 格式化數字
          style: const TextStyle(
            fontSize: 24, // 字體大小
            fontWeight: FontWeight.bold, // 粗體
          ),
          textAlign: TextAlign.right, // 文字右對齊
        ),
        // 顯示記錄創建時間
        subtitle: Text(
          // 格式化日期時間：YYYY/MM/DD HH:MM
          '${record.createdAt.year}/${record.createdAt.month.toString().padLeft(2, '0')}/${record.createdAt.day.toString().padLeft(2, '0')} ${record.createdAt.hour.toString().padLeft(2, '0')}:${record.createdAt.minute.toString().padLeft(2, '0')}',
          textAlign: TextAlign.right, // 文字右對齊
        ),
        // 右側的刪除按鈕
        trailing: IconButton(
          icon: const Icon(Icons.delete, color: Colors.red), // 紅色刪除圖標
          onPressed: () async {
            final shouldDelete = await showDialog<bool>(
              context: context,
              builder: (context) => AlertDialog(
                title: const Text('確認刪除'),
                content: const Text('確定要刪除此筆記錄嗎？'),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(false),
                    child: const Text('取消'),
                  ),
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(true),
                    child: const Text(
                      '刪除',
                      style: TextStyle(color: Colors.red),
                    ),
                  ),
                ],
              ),
            ) ?? false;

            if (shouldDelete && mounted) {
              _deleteRecord(record);
            }
          },
        ),
      ),
    );
  }
}
