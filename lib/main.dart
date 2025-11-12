
import 'package:intl/intl.dart';
import 'package:flutter/material.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Xalculator',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
      ),
      home: const CalculatorPage(title: 'Xalculator'),
    );
  }
}


// --- 計算ロジック・履歴管理 ---
class CalculatorLogic {
  static double calculate(String expr) {
    expr = expr.replaceAll(' ', '');
    List<String> mulDiv = expr.split(RegExp(r'(?=[+-])'));
    double total = evalTerm(mulDiv[0]);
    for (int i = 1; i < mulDiv.length; i++) {
      String part = mulDiv[i];
      if (part.startsWith('+')) {
        total += evalTerm(part.substring(1));
      } else if (part.startsWith('-')) {
        total -= evalTerm(part.substring(1));
      }
    }
    return total;
  }

  static double evalTerm(String term) {
    List<String> nums = term.split(RegExp(r'([*/])'));
    double val = double.parse(nums[0]);
    int idx = nums[0].length;
    while (idx < term.length) {
      String op = term[idx];
      int nextIdx = idx + 1;
      while (nextIdx < term.length && '0123456789.'.contains(term[nextIdx])) {
        nextIdx++;
      }
      double num = double.parse(term.substring(idx + 1, nextIdx));
      if (op == '*') {
        val *= num;
      } else if (op == '/') {
        val /= num;
      }
      idx = nextIdx;
    }
    return val;
  }

  static double totalSum(List<String> history) {
    double sum = 0;
    for (final entry in history) {
      final match = RegExp(r'=\s*(-?\d+(?:\.\d+)?)').firstMatch(entry);
      if (match != null) {
        sum += double.tryParse(match.group(1) ?? '0') ?? 0;
      }
    }
    return sum;
  }
}

// --- メインページ ---
class CalculatorPage extends StatefulWidget {
  const CalculatorPage({super.key, required this.title});
  final String title;

  @override
  State<CalculatorPage> createState() => _CalculatorPageState();
}

class _CalculatorPageState extends State<CalculatorPage> {


  final NumberFormat _numberFormat = NumberFormat('#,##0.##');
  final ScrollController _scrollController = ScrollController();
  final GlobalKey<AnimatedListState> _listKey = GlobalKey<AnimatedListState>();
  String _display = '0';
  List<String> _history = [];
  final List<List<String>> _buttons = [
    ['7', '8', '9', '÷'],
    ['4', '5', '6', '×'],
    ['1', '2', '3', '-'],
    ['0', '.', '⏏', '+'],
  ];

  void _removeAllHistory() {
    if (_history.isEmpty) return;
    final len = _history.length;
    for (int i = len - 1; i >= 0; i--) {
      final item = _history[i];
      _listKey.currentState?.removeItem(
        i,
        (context, animation) => SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(-1, 0),
            end: Offset.zero,
          ).animate(animation),
          child: FadeTransition(
            opacity: animation,
            child: HistoryCard(
              item: item,
              numberFormat: _numberFormat,
            ),
          ),
        ),
        duration: const Duration(milliseconds: 350),
      );
    }
    setState(() {
      _history.clear();
    });
  }

  void _removeAllAndCopyToDisplay() {
    final sum = CalculatorLogic.totalSum(_history);
    _display = sum == 0 ? '' : sum.toString();
    if (_history.isNotEmpty) {
      final len = _history.length;
      for (int i = len - 1; i >= 0; i--) {
        final item = _history[i];
        _listKey.currentState?.removeItem(
          i,
          (context, animation) => SlideTransition(
            position: Tween<Offset>(
              begin: const Offset(-1, 0),
              end: Offset.zero,
            ).animate(animation),
            child: FadeTransition(
              opacity: animation,
              child: HistoryCard(
                item: item,
                numberFormat: _numberFormat,
              ),
            ),
          ),
          duration: const Duration(milliseconds: 350),
        );
      }
    }
    setState(() {
      _history.clear();
    });
  }

  void _onButtonPressed(String value) {
    setState(() {
      if (_display == 'Error') {
        if (value == '×') value = '*';
        if (value == '÷') value = '/';
        if (value == '⏏' || value == '=') {
          _display = '';
          return;
        }
        _display = (RegExp(r'[0-9.]').hasMatch(value)) ? value : '';
        return;
      }
      if (value == '⏏' || value == '=') {
        try {
          String expression = _display.replaceAll('×', '*').replaceAll('÷', '/');
          if (RegExp(r'[\+\-\*/]$').hasMatch(expression)) {
            expression = expression.substring(0, expression.length - 1);
          }
          if (RegExp(r'[\+\-\*/]{2,}').hasMatch(expression)) {
            _display = 'Error';
            return;
          }
          double result = CalculatorLogic.calculate(expression);
          String resultStr = result.toString().replaceAll(RegExp(r'\.0+\u0000?$'), '');
          _history.add('$_display = $resultStr');
          if (_listKey.currentState != null) {
            const animDuration = Duration(milliseconds: 120);
            _listKey.currentState!.insertItem(_history.length - 1, duration: animDuration);
            Future.delayed(animDuration, () {
              if (_scrollController.hasClients) {
                _scrollController.animateTo(
                  _scrollController.position.maxScrollExtent,
                  duration: const Duration(milliseconds: 180),
                  curve: Curves.easeOut,
                );
              }
            });
          }
          _display = '';
        } catch (e) {
          _display = 'Error';
        }
      } else {
        String inputValue = value;
        if (value == '×') inputValue = '*';
        if (value == '÷') inputValue = '/';
        if ('+-*/'.contains(inputValue)) {
          if (_display.endsWith('+') || _display.endsWith('-') || _display.endsWith('*') || _display.endsWith('/')) {
            _display = _display.substring(0, _display.length - 1) + inputValue;
            return;
          }
        }
        if (value == '.') {
          if (_display.isEmpty || '+-*/'.contains(_display.characters.last)) {
            _display += '0.';
            return;
          }
          final lastNum = _display.split(RegExp(r'[\+\-\*/]')).last;
          if (lastNum.contains('.')) {
            return;
          }
        }
        if (_display == '0' && RegExp(r'[0-9]').hasMatch(value)) {
          _display = value;
        } else if (_display == '0' && value != '.' && !RegExp(r'[0-9]').hasMatch(value)) {
          _display = inputValue;
        } else {
          _display += inputValue;
        }
      }
    });
  }

  void _removeHistoryItem(int index) {
    if (index < 0 || index >= _history.length) return;
    _history.removeAt(index);
    _listKey.currentState?.removeItem(
      index,
      (context, animation) => const SizedBox.shrink(),
      duration: const Duration(milliseconds: 300),
    );
  }

  @override
  Widget build(BuildContext context) {
    final sum = CalculatorLogic.totalSum(_history);
    final sumStr = _numberFormat.format(sum);
    return Scaffold(
  backgroundColor: Colors.grey[600],
      appBar: AppBar(
        backgroundColor: Colors.white,
        title: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            GestureDetector(
              onTap: _removeAllHistory,
              child: SizedBox(
                height: kToolbarHeight,
                child: AspectRatio(
                  aspectRatio: 1.0,
                  child: Image.asset(
                    'assets/img/xalculator.png',
                    fit: BoxFit.contain,
                  ),
                ),
              ),
            ),
            PopupMenuButton<int>(
              tooltip: 'メニュー',
              offset: const Offset(0, 40),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              color: Colors.white,
              elevation: 12,
              onSelected: (selected) {
                if (selected == 1) {
                  _removeAllHistory();
                } else if (selected == 2) {
                  _removeAllAndCopyToDisplay();
                }
              },
              itemBuilder: (context) => [
                PopupMenuItem<int>(
                  value: 1,
                  child: Row(
                    children: [
                      Icon(Icons.delete_sweep, color: Colors.redAccent),
                      const SizedBox(width: 12),
                      const Text('Flush', style: TextStyle(fontWeight: FontWeight.bold)),
                    ],
                  ),
                ),
                PopupMenuItem<int>(
                  value: 2,
                  child: Row(
                    children: [
                      Icon(Icons.undo, color: Colors.blueAccent),
                      const SizedBox(width: 12),
                      const Text('Return', style: TextStyle(fontWeight: FontWeight.bold)),
                    ],
                  ),
                ),
              ],
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.blueGrey.shade50,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.08),
                      blurRadius: 6,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                constraints: const BoxConstraints(minHeight: 0, maxHeight: kToolbarHeight - 8),
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerRight,
                  child: Text(
                    sumStr,
                    style: const TextStyle(fontSize: 44, fontWeight: FontWeight.bold, color: Colors.black87),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
      body: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          Expanded(
            child: HistoryList(
              history: _history,
              listKey: _listKey,
              scrollController: _scrollController,
              numberFormat: _numberFormat,
              onRemove: (index) => setState(() => _removeHistoryItem(index)),
            ),
          ),
          DisplayPanel(
            display: _display,
            onClear: () => setState(() => _display = ''),
          ),
          ButtonPad(
            buttons: _buttons,
            onPressed: _onButtonPressed,
          ),
        ],
      ),
    );
  }
}

// --- ディスプレイWidget ---
class DisplayPanel extends StatelessWidget {
  final String display;
  final VoidCallback onClear;
  const DisplayPanel({super.key, required this.display, required this.onClear});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF222222), Color(0xFF444444)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.4),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
        borderRadius: BorderRadius.circular(12),
      ),
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      child: Row(
        children: [
          Padding(
            padding: const EdgeInsets.all(6.0),
            child: Container(
              width: 40,
              height: 40,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                color: Color(0xFF444444),
              ),
              child: IconButton(
                icon: const Icon(Icons.close, color: Colors.white),
                onPressed: onClear,
                iconSize: 24,
                splashRadius: 22,
              ),
            ),
          ),
          Expanded(
            child: Container(
              alignment: Alignment.centerRight,
              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
              child: Text(
                display.isEmpty
                    ? ''
                    : display.replaceAll('*', '×').replaceAll('/', '÷'),
                style: const TextStyle(fontSize: 48, fontWeight: FontWeight.bold, color: Colors.white),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// --- ボタンパッドWidget ---
class ButtonPad extends StatelessWidget {
  final List<List<String>> buttons;
  final void Function(String) onPressed;
  const ButtonPad({super.key, required this.buttons, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: buttons.map((row) =>
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: row.map((buttonText) {
            return Expanded(
              child: Padding(
                padding: const EdgeInsets.all(4.0),
                child: AnimatedButton(
                  buttonText: buttonText,
                  onPressed: onPressed,
                ),
              ),
            );
          }).toList(),
        )
      ).toList(),
    );
  }
}

class AnimatedButton extends StatefulWidget {
  final String buttonText;
  final void Function(String) onPressed;
  const AnimatedButton({super.key, required this.buttonText, required this.onPressed});

  @override
  State<AnimatedButton> createState() => _AnimatedButtonState();
}

class _AnimatedButtonState extends State<AnimatedButton> {
  bool _pressed = false;

  void _onTapDown(TapDownDetails details) {
    setState(() => _pressed = true);
  }

  void _onTapUp(TapUpDetails details) {
    setState(() => _pressed = false);
  }

  void _onTapCancel() {
    setState(() => _pressed = false);
  }

  @override
  Widget build(BuildContext context) {
    final isPop = widget.buttonText == '⏏';
    return GestureDetector(
      onTap: () => widget.onPressed(widget.buttonText),
      onTapDown: _onTapDown,
      onTapUp: _onTapUp,
      onTapCancel: _onTapCancel,
      child: AnimatedScale(
        scale: _pressed ? 0.92 : 1.0,
        duration: const Duration(milliseconds: 80),
        curve: Curves.easeOut,
        child: Container(
          decoration: BoxDecoration(
            gradient: isPop
                ? const LinearGradient(
                    colors: [Color(0xFFFFA726), Color(0xFFFF9800)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  )
                : '+-×÷'.contains(widget.buttonText)
                    ? const LinearGradient(
                        colors: [Color(0xFFB3E5FC), Color(0xFF81D4FA)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      )
                    : const LinearGradient(
                        colors: [Color(0xFFF5F5F5), Color(0xFFE0E0E0)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.25),
                blurRadius: isPop ? 12 : 8,
                offset: const Offset(0, 4),
              ),
            ],
            borderRadius: BorderRadius.circular(8),
          ),
          height: 56,
          padding: const EdgeInsets.symmetric(vertical: 0),
          child: Center(
            child: isPop
                ? Icon(Icons.eject, size: 32, color: Colors.white)
                : Text(
                    widget.buttonText,
                    style: TextStyle(
                      fontSize: 32,
                      fontWeight: '+-×÷'.contains(widget.buttonText)
                          ? FontWeight.bold
                          : FontWeight.normal,
                      color: '+-×÷'.contains(widget.buttonText)
                          ? Colors.blue.shade900
                          : Colors.black,
                    ),
                  ),
          ),
        ),
      ),
    );
  }
}

// --- 履歴リストWidget ---
class HistoryList extends StatelessWidget {
  final List<String> history;
  final GlobalKey<AnimatedListState> listKey;
  final ScrollController scrollController;
  final NumberFormat numberFormat;
  final void Function(int) onRemove;
  const HistoryList({
    super.key,
    required this.history,
    required this.listKey,
    required this.scrollController,
    required this.numberFormat,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedList(
      key: listKey,
      controller: scrollController,
      initialItemCount: history.length,
      itemBuilder: (context, index, animation) {
        final item = history[index];
        return SizeTransition(
          sizeFactor: animation,
          axisAlignment: 0.0,
          child: FadeTransition(
            opacity: animation,
            child: SlideTransition(
              position: Tween<Offset>(
                begin: const Offset(0, 1), // 下から上へ
                end: Offset.zero,
              ).animate(animation),
              child: Dismissible(
                key: Key(item + index.toString()),
                direction: DismissDirection.endToStart,
                background: Container(
                  color: Colors.red,
                  alignment: Alignment.centerRight,
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: const Icon(Icons.delete, color: Colors.white),
                ),
                onDismissed: (direction) => onRemove(index),
                child: HistoryCard(
                  item: item,
                  numberFormat: numberFormat,
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

// --- 履歴カードWidget ---
class HistoryCard extends StatelessWidget {
  final String item;
  final NumberFormat numberFormat;
  const HistoryCard({super.key, required this.item, required this.numberFormat});

  @override
  Widget build(BuildContext context) {
    final match = RegExp(r'^(.*)=\s*(-?\d+(?:\.\d+)?)').firstMatch(item);
    final expr = match != null ? match.group(1)?.trim() ?? '' : item;
    final subtotal = match != null ? match.group(2) ?? '' : '';
    final subtotalStr = subtotal.isEmpty ? '' : numberFormat.format(double.tryParse(subtotal) ?? 0);
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 0),
      child: Card(
        color: Colors.grey[100],
        margin: const EdgeInsets.symmetric(horizontal: 12),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
          child: Row(
            children: [
              Expanded(
                child: Tooltip(
                  message: expr,
                  waitDuration: Duration.zero,
                  showDuration: const Duration(seconds: 2),
                  child: Text(
                    expr.replaceAll('*', '×').replaceAll('/', '÷'),
                    style: const TextStyle(fontSize: 14, color: Colors.grey),
                    textAlign: TextAlign.left,
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1,
                  ),
                ),
              ),
              Text(
                subtotalStr,
                style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.black),
                textAlign: TextAlign.right,
              ),
            ],
          ),
        ),
      ),
    );
  }
}