// 引入 Flutter 核心套件
import 'package:flutter/material.dart';
// 引入 Provider 狀態管理套件
import 'package:provider/provider.dart';
// 引入 Hive 資料庫套件
import 'package:hive_flutter/hive_flutter.dart';
// 引入服務
import 'package:flutter/services.dart';

// 引入自定義模型、頁面和服務
import 'models/calculation_record.dart';
import 'screens/history_screen.dart';
import 'services/hive_database_service.dart';
import 'package:simple_calculator/utils/snackbar_utils.dart';
import 'theme/theme_provider.dart';
import 'widgets/custom_app_bar.dart';

/// 應用程式進入點
/// 負責初始化應用程式並設置主題提供者
void main() async {
  // 確保 Flutter 綁定已初始化
  WidgetsFlutterBinding.ensureInitialized();

  // 鎖定應用程式為直向顯示
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  // 確保狀態欄和導航欄的樣式一致
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
    ),
  );

  try {
    // 初始化 Hive 資料庫
    await HiveDatabaseService.init();

    // 啟動應用程式，並包裝在 ChangeNotifierProvider 中用於主題管理
    runApp(
      ChangeNotifierProvider(
        create: (_) => ThemeProvider(),
        child: const MyApp(),
      ),
    );
  } catch (e) {
    // 如果初始化失敗，顯示錯誤界面
    runApp(
      MaterialApp(
        home: Scaffold(body: Center(child: Text('資料庫初始化失敗: $e'))),
      ),
    );
  }
}

/// 應用程式根組件
/// 負責設置主題和導航

/// 應用程式根組件
/// 負責設置主題和導航
class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    // 使用 Consumer 監聽主題變化
    return Consumer<ThemeProvider>(
      builder: (context, themeProvider, child) {
        return MaterialApp(
          title: '平凡計算機',
          // 淺色主題設置
          theme: ThemeData(
            colorScheme: ColorScheme.fromSeed(
              seedColor: Colors.blue, // 主色調
              brightness: Brightness.light, // 亮色模式
            ),
            useMaterial3: true, // 啟用 Material 3 設計
          ),
          // 深色主題設置
          darkTheme: ThemeData(
            colorScheme: ColorScheme.fromSeed(
              seedColor: Colors.blueGrey, // 深色模式主色調
              brightness: Brightness.dark, // 深色模式
            ),
            useMaterial3: true, // 啟用 Material 3 設計
          ),
          themeMode: themeProvider.themeMode, // 當前主題模式
          home: const MainScreen(), // 主頁面
          debugShowCheckedModeBanner: false, // 移除 debug 標籤
        );
      },
    );
  }
}

/// 主畫面組件
/// 包含底部導航欄和頁面切換功能
class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

/// 主畫面狀態類
/// 管理底部導航欄的狀態和頁面切換邏輯
class _MainScreenState extends State<MainScreen> {
  int _selectedIndex = 0; // 當前選中的頁面索引
  // 頁面列表：計算機頁面和歷史記錄頁面
  final List<Widget> _screens = [Calculator(), const HistoryScreen()];

  /// 處理底部導航欄點擊事件
  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index; // 更新選中的頁面索引
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // 顯示當前選中的頁面
      body: _screens.elementAt(_selectedIndex),
      // 底部導航欄
      bottomNavigationBar: BottomNavigationBar(
        items: const <BottomNavigationBarItem>[
          // 計算機按鈕
          BottomNavigationBarItem(icon: Icon(Icons.calculate), label: '計算機'),
          // 歷史記錄按鈕
          BottomNavigationBarItem(icon: Icon(Icons.history), label: '歷史記錄'),
        ],
        currentIndex: _selectedIndex, // 當前選中的索引
        selectedItemColor: Colors.blue, // 選中項目的顏色
        onTap: _onItemTapped, // 點擊事件處理
      ),
    );
  }
}

/// 計算機組件
/// 負責顯示計算機界面和處理計算邏輯
class Calculator extends StatefulWidget {
  @override
  _CalculatorState createState() => _CalculatorState();
}

/// 計算機狀態類
/// 管理計算機的狀態和業務邏輯
class _CalculatorState extends State<Calculator> {
  /// 格式化數字顯示，加入千分位
  /// [number] 要格式化的數字字串
  /// 返回格式化後的字串
  String _formatNumber(String number) {
    if (number.isEmpty) return '';

    // 檢查是否為小數
    if (number.contains('.')) {
      final parts = number.split('.');
      // 處理整數部分，確保能正確解析
      final integerPart = int.tryParse(parts[0])?.toString() ?? parts[0];
      return '${_addThousandSeparator(integerPart)}.${parts[1]}';
    }

    return _addThousandSeparator(number);
  }

  /// 加入千分位符號
  /// [number] 要處理的數字字串
  /// 返回加入千分位後的字串
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

  // 當前顯示的數值
  String display = "0";
  // 上一個運算數值
  String previousValue = "";
  // 當前運算符號 (+, -, ×, ÷)
  String operation = "";
  // 是否等待輸入下一個運算數
  bool waitingForOperand = false;
  // 完整的計算表達式
  String calculation = "";

  /// 處理數字按鈕點擊事件
  /// [number] 點擊的數字按鈕值
  void inputNumber(String number) {
    setState(() {
      if (waitingForOperand) {
        // 如果正在等待輸入運算數，則重置顯示
        display = number;
        // 更新計算表達式
        calculation = calculation.endsWith(" ") ? calculation + number : number;
        waitingForOperand = false;
      } else {
        // 否則將數字追加到當前顯示的數字後面
        display = display == "0" ? number : display + number;
        // 更新計算表達式
        calculation = calculation.endsWith(" ") ? number : calculation + number;
      }
    });
  }

  /// 處理運算符按鈕點擊事件
  /// [nextOperation] 點擊的運算符 (+, -, ×, ÷)
  void inputOperation(String nextOperation) {
    // 將當前顯示的數字轉換為數值
    double inputValue = double.parse(display);

    if (previousValue.isEmpty) {
      // 如果沒有上一個運算數，將當前顯示的數字設為上一個運算數
      previousValue = display;
      // 更新計算表達式
      calculation = display + " " + nextOperation + " ";
    } else if (operation.isNotEmpty) {
      // 如果已經有運算符，則執行計算
      double prevValue = double.parse(previousValue);
      // 計算結果
      double result = calculate(prevValue, inputValue, operation);

      setState(() {
        // 更新顯示結果
        display = result.toString();
        // 將結果設為下一個運算的上一個運算數
        previousValue = display;
        // 更新計算表達式
        calculation = display + " " + nextOperation + " ";
      });
    }

    setState(() {
      // 設置為等待輸入下一個運算數
      waitingForOperand = true;
      // 更新當前運算符
      operation = nextOperation;
    });
  }

  /// 執行基本算術運算
  /// [firstValue] 第一個運算數
  /// [secondValue] 第二個運算數
  /// [operation] 運算符 (+, -, ×, ÷)
  /// 返回計算結果
  double calculate(double firstValue, double secondValue, String operation) {
    switch (operation) {
      case "+":
        return firstValue + secondValue;
      case "-":
        return firstValue - secondValue;
      case "×":
        return firstValue * secondValue;
      case "÷":
        // 處理除以零的情況
        if (secondValue == 0) throw Exception('除數不能為零');
        return firstValue / secondValue;
      default:
        return secondValue; // 預設返回第二個運算數
    }
  }

  /// 執行計算並更新顯示
  /// 當用戶點擊等號時調用此方法
  void performCalculation() {
    try {
      // 將當前顯示的數字轉換為數值
      double inputValue = double.parse(display);

      // 確保有足夠的運算數和運算符來執行計算
      if (previousValue.isNotEmpty && operation.isNotEmpty) {
        double prevValue = double.parse(previousValue);
        // 執行計算
        double result = calculate(prevValue, inputValue, operation);

        setState(() {
          // 將完整精度的結果存儲在 display 中
          display = result.toString();

          // 格式化結果以顯示
          String displayValue = formatResult(result);

          // 如果格式化後的顯示過長，使用科學記號表示
          if (displayValue.length > 15) {
            displayValue = result.toStringAsExponential(4);
          }

          // 使用格式化後的值更新顯示
          display = displayValue;

          // 使用格式化後的結果更新計算字串
          calculation = displayValue;

          // 重置狀態
          previousValue = "";
          operation = "";
          waitingForOperand = true;
        });
      }
    } catch (e) {
      // 處理計算錯誤（如除以零）
      setState(() {
        display = "Error";
        calculation = "";
        previousValue = "";
        operation = "";
        waitingForOperand = true;
      });
    }
  }

  String formatResult(double result) {
    // For display purposes, format the number to avoid scientific notation
    // and limit decimal places to 10 for display
    if (result == result.truncateToDouble()) {
      return result.truncate().toString();
    } else {
      // Convert to string and remove trailing zeros after decimal
      String resultStr = result.toString();
      // If the number is in scientific notation, convert it to regular decimal
      if (resultStr.contains('e') || resultStr.contains('E')) {
        // Convert scientific notation to decimal string
        resultStr = result
            .toStringAsFixed(10)
            .replaceAll(RegExp(r'\.?0*$'), '');
        // If we removed all decimal places, remove the decimal point too
        if (resultStr.endsWith('.')) {
          resultStr = resultStr.substring(0, resultStr.length - 1);
        }
      }
      return resultStr;
    }
  }

  void clear() {
    setState(() {
      display = "0";
      previousValue = "";
      operation = "";
      calculation = "";
      waitingForOperand = false;
    });
  }

  void backspace() {
    if (display.length > 1) {
      setState(() {
        display = display.substring(0, display.length - 1);
        // 如果刪除後字符串為空，設置為 "0"
        if (display.isEmpty) {
          display = "0";
        }
        // 更新計算式
        if (calculation.isNotEmpty) {
          calculation = calculation.substring(0, calculation.length - 1);
          if (calculation.endsWith(" ")) {
            calculation = calculation.substring(0, calculation.length - 1);
          }
          if (calculation.isEmpty) {
            calculation = "";
          }
        }
      });
    } else {
      // 如果只有一個字符，直接重置為 0
      setState(() {
        display = "0";
        calculation = "";
      });
    }
  }

  void percentage() {
    setState(() {
      double value = double.parse(display);
      display = (value / 100).toString();
    });
  }

  void toggleSign() {
    setState(() {
      if (display != "0") {
        if (display.startsWith("-")) {
          display = display.substring(1);
        } else {
          display = "-" + display;
        }
      }
    });
  }

  void addDecimal() {
    setState(() {
      if (!display.contains(".")) {
        display = display + ".";
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const CustomAppBar(title: '計算機'),
      body: Column(
        children: [
          // 顯示區域
          Expanded(
            flex: 4,
            child: Container(
              padding: const EdgeInsets.all(16.0),
              alignment: Alignment.bottomRight,
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                reverse: true,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.end,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      calculation.isNotEmpty ? _formatNumber(calculation) : ' ',
                      style: const TextStyle(fontSize: 24, color: Colors.grey),
                      textAlign: TextAlign.right,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _formatNumber(display),
                      style: const TextStyle(
                        fontSize: 48,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.right,
                    ),
                  ],
                ),
              ),
            ),
          ),
          // 按鈕區域
          Expanded(
            flex: 6,
            child: Container(
              padding: const EdgeInsets.all(8),
              child: Column(
                children: [
                  // 刪除和儲存按鈕行
                  Expanded(
                    child: Row(
                      children: [
                        Expanded(
                          flex: 1,
                          child: Padding(
                            padding: const EdgeInsets.all(4),
                            child: _buildButton(
                              '⌫',
                              _getButtonColor('⌫'),
                              backspace,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          flex: 1,
                          child: Padding(
                            padding: const EdgeInsets.all(4),
                            child: _buildButton(
                              '儲存',
                              Colors.green,
                              _saveCalculation,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  // 第一排按鈕
                  Expanded(
                    child: Row(
                      children: [
                        _buildButtonWithFlex(
                          "AC",
                          _getButtonColor("AC"),
                          clear,
                        ),
                        _buildButtonWithFlex(
                          "⁺∕₋",
                          _getButtonColor("⁺∕₋"),
                          toggleSign,
                        ),
                        _buildButtonWithFlex(
                          "%",
                          _getButtonColor("%"),
                          percentage,
                        ),
                        _buildButtonWithFlex(
                          "÷",
                          _getButtonColor("÷"),
                          () => inputOperation("÷"),
                        ),
                      ],
                    ),
                  ),
                  // 第二排按鈕
                  Expanded(
                    child: Row(
                      children: [
                        _buildButtonWithFlex(
                          "7",
                          _getButtonColor("7"),
                          () => inputNumber("7"),
                        ),
                        _buildButtonWithFlex(
                          "8",
                          _getButtonColor("8"),
                          () => inputNumber("8"),
                        ),
                        _buildButtonWithFlex(
                          "9",
                          _getButtonColor("9"),
                          () => inputNumber("9"),
                        ),
                        _buildButtonWithFlex(
                          "×",
                          _getButtonColor("×"),
                          () => inputOperation("×"),
                        ),
                      ],
                    ),
                  ),
                  // 第三排按鈕
                  Expanded(
                    child: Row(
                      children: [
                        _buildButtonWithFlex(
                          "4",
                          _getButtonColor("4"),
                          () => inputNumber("4"),
                        ),
                        _buildButtonWithFlex(
                          "5",
                          _getButtonColor("5"),
                          () => inputNumber("5"),
                        ),
                        _buildButtonWithFlex(
                          "6",
                          _getButtonColor("6"),
                          () => inputNumber("6"),
                        ),
                        _buildButtonWithFlex(
                          "-",
                          _getButtonColor("-"),
                          () => inputOperation("-"),
                        ),
                      ],
                    ),
                  ),
                  // 第四排按鈕
                  Expanded(
                    child: Row(
                      children: [
                        _buildButtonWithFlex(
                          "1",
                          _getButtonColor("1"),
                          () => inputNumber("1"),
                        ),
                        _buildButtonWithFlex(
                          "2",
                          _getButtonColor("2"),
                          () => inputNumber("2"),
                        ),
                        _buildButtonWithFlex(
                          "3",
                          _getButtonColor("3"),
                          () => inputNumber("3"),
                        ),
                        _buildButtonWithFlex(
                          "+",
                          _getButtonColor("+"),
                          () => inputOperation("+"),
                        ),
                      ],
                    ),
                  ),
                  // 第五排按鈕
                  Expanded(
                    child: Row(
                      children: [
                        Expanded(
                          flex: 2,
                          child: Padding(
                            padding: const EdgeInsets.all(4),
                            child: _buildButton(
                              "0",
                              _getButtonColor("0"),
                              () => inputNumber("0"),
                            ),
                          ),
                        ),
                        Expanded(
                          flex: 1,
                          child: Padding(
                            padding: const EdgeInsets.all(4),
                            child: _buildButton(
                              ".",
                              _getButtonColor("."),
                              addDecimal,
                            ),
                          ),
                        ),
                        Expanded(
                          flex: 1,
                          child: Padding(
                            padding: const EdgeInsets.all(4),
                            child: _buildButton(
                              "=",
                              Colors.blue,
                              performCalculation,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Color _getButtonColor(String buttonText) {
    if (["AC", "⁺∕₋", "%"].contains(buttonText)) {
      return Colors.grey.shade400;
    } else if (["+", "-", "×", "÷", "="].contains(buttonText)) {
      return buttonText == "=" ? Colors.green : Colors.orange;
    } else if (buttonText == "儲存") {
      return Colors.green;
    } else {
      return Colors.grey.shade700;
    }
  }

  Color _getTextColor(String buttonText) {
    if (["AC", "⁺∕₋", "%"].contains(buttonText)) {
      return Colors.black;
    } else {
      return Colors.white;
    }
  }

  // 使用共用的 SnackBar 工具類
  void _showSnackBar(String message, {bool isError = false}) {
    SnackBarUtils.showSnackBar(context, message: message, isError: isError);
  }

  Future<void> _saveCalculation() async {
    try {
      // 1. 檢查是否有運算符號需要計算
      if (previousValue.isNotEmpty && operation.isNotEmpty) {
        // 執行計算
        performCalculation();
        // 等待狀態更新
        await Future.delayed(Duration.zero);
      }

      // 2. 檢查顯示是否為空或錯誤
      if (display.isEmpty || display == "Error") {
        if (mounted) {
          _showSnackBar('沒有可儲存的計算結果');
        }
        return;
      }

      // 3. 儲存顯示的數字
      final record = CalculationRecord.create(
        expression: display,
        result: display,
      );

      await HiveDatabaseService.saveCalculation(record);
      
      if (mounted) {
        _showSnackBar('已儲存計算結果');
      }
    } catch (e) {
      if (mounted) {
        _showSnackBar('儲存失敗: ${e.toString()}', isError: true);
      }
    }
  }

  /// 構建計算機按鈕
  /// [buttonText] 按鈕顯示的文字
  /// [buttonColor] 按鈕背景顏色
  /// [onPressed] 按鈕點擊回調
  /// 構建帶有 flex 屬性的按鈕
  /// [buttonText] 按鈕顯示的文字
  /// [buttonColor] 按鈕背景顏色
  /// [onPressed] 按鈕點擊回調
  Widget _buildButtonWithFlex(
    String buttonText,
    Color buttonColor,
    VoidCallback onPressed, {
    int flex = 1,
  }) {
    return Expanded(
      flex: flex,
      child: Padding(
        padding: const EdgeInsets.all(4),
        child: _buildButton(buttonText, buttonColor, onPressed),
      ),
    );
  }

  /// 構建計算機按鈕
  /// [buttonText] 按鈕顯示的文字
  /// [buttonColor] 按鈕背景顏色
  /// [onPressed] 按鈕點擊回調
  Widget _buildButton(
    String buttonText,
    Color buttonColor,
    VoidCallback onPressed,
  ) {
    return Container(
      margin: const EdgeInsets.all(4),
      constraints: const BoxConstraints(
        minHeight: 60, // 設置按鈕最小高度
      ),
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: buttonColor,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          minimumSize: const Size(60, 60), // 設置按鈕最小尺寸
          padding: const EdgeInsets.all(8),
          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        ),
        child: Container(
          constraints: const BoxConstraints.expand(),
          child: Center(
            child: FittedBox(
              fit: BoxFit.contain,
              child: Text(
                buttonText,
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w400,
                  color: _getTextColor(buttonText),
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildWideButton(
    String buttonText,
    Color buttonColor,
    VoidCallback onPressed,
  ) {
    return LayoutBuilder(
      builder: (context, constraints) {
        // 計算按鈕的高度，用於文字大小
        final buttonHeight = constraints.maxHeight;

        return Container(
          margin: const EdgeInsets.all(4),
          child: ConstrainedBox(
            constraints: const BoxConstraints(
              minWidth: 0,
              minHeight: 0,
              maxWidth: double.infinity,
              maxHeight: double.infinity,
            ),
            child: ElevatedButton(
              onPressed: onPressed,
              style: ElevatedButton.styleFrom(
                backgroundColor: buttonColor,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              child: FittedBox(
                fit: BoxFit.contain,
                child: Text(
                  buttonText,
                  style: TextStyle(
                    fontSize: buttonHeight * 0.3, // 根據按鈕高度動態調整字體大小
                    fontWeight: FontWeight.w400,
                    color: _getTextColor(buttonText),
                    height: 1.2, // 調整行高以確保垂直居中
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
