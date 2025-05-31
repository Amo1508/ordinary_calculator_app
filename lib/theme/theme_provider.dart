import 'package:flutter/material.dart';

/// 主題提供者類別，用於管理應用的深色/淺色主題切換
/// 使用 ChangeNotifier 來通知監聽者主題變更
class ThemeProvider with ChangeNotifier {
  // 目前使用的主題模式
  late ThemeMode _themeMode;
  // 當前是否為深色模式
  late bool _isDarkMode;

  /// 建構函式，初始化主題提供者
  ThemeProvider() {
    // 同步初始化主題設定
    // 獲取系統當前的亮度設定
    final isSystemDark =
        WidgetsBinding.instance.window.platformBrightness == Brightness.dark;
    // 預設使用系統主題
    _themeMode = isSystemDark == true ? ThemeMode.dark : ThemeMode.light;
    // 根據系統設定初始化深色模式狀態
    _isDarkMode = isSystemDark;

    // 在框架繪製完成後執行非同步初始化
    // 這樣可以確保在 UI 準備好之後再進行可能的主題變更
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initTheme();
    });
  }

  /// 初始化主題設定（非同步）
  /// 可以在這裡載入使用者儲存的主題偏好設定
  Future<void> _initTheme() async {
    // 這裡可以加入從本地儲存載入主題設定的邏輯
    // 目前直接使用系統亮度設定
    final isSystemDark =
        WidgetsBinding.instance.window.platformBrightness == Brightness.dark;
    _isDarkMode = isSystemDark;
    // 通知監聽者主題已初始化
    notifyListeners();
  }

  /// 獲取當前主題模式
  ThemeMode get themeMode => _themeMode;

  /// 檢查當前是否為深色模式
  bool get isDarkMode => _isDarkMode;

  /// 檢查主題是否已初始化
  /// 由於我們改為同步初始化，這裡總是返回 true
  bool get isInitialized => true;

  /// 切換深色/淺色主題
  void toggleTheme() {
    // 在淺色和深色模式之間切換
    _themeMode = _themeMode == ThemeMode.dark
        ? ThemeMode.light
        : ThemeMode.dark;
    // 更新深色模式狀態
    // 如果主題模式是系統模式，則根據系統亮度決定是否使用深色模式
    _isDarkMode =
        _themeMode == ThemeMode.dark ||
        (_themeMode == ThemeMode.system &&
            WidgetsBinding.instance.window.platformBrightness ==
                Brightness.dark);
    // 通知所有監聽者主題已變更
    notifyListeners();
  }

  /// 更新主題模式（內部方法）
  /// [mode] 要設定的主題模式
  void _updateThemeMode(ThemeMode mode) {
    _themeMode = mode;
    // 更新深色模式狀態
    _isDarkMode =
        _themeMode == ThemeMode.dark ||
        (_themeMode == ThemeMode.system &&
            WidgetsBinding.instance.window.platformBrightness ==
                Brightness.dark);
    // 通知所有監聽者主題已變更
    notifyListeners();
  }
}
