import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class SudokuScreen extends StatefulWidget {
  @override
  _SudokuScreenState createState() => _SudokuScreenState();
}

class _SudokuScreenState extends State<SudokuScreen> {
  // URL API (Giữ nguyên cấu hình emulator của bạn)
  final String apiUrl = "http://10.0.2.2:5231/api/sudoku/new-game";

  List<int> puzzle = [];
  List<int> solution = [];
  List<int> currentBoard = []; // Bảng hiện tại hiển thị lên màn hình
  List<bool> isFixed = []; // Đánh dấu các ô đề bài (không được sửa)

  bool isLoading = true;
  bool isGameOver = false; // Trạng thái game
  int mistakes = 0;
  final int maxMistakes = 3; // Giới hạn lỗi
  int selectedIndex = -1; // Ô đang chọn

  @override
  void initState() {
    super.initState();
    fetchGame();
  }

  // Hàm lấy đề mới từ Server
  Future<void> fetchGame() async {
    setState(() {
      isLoading = true;
      isGameOver = false;
      mistakes = 0;
      selectedIndex = -1;
    });

    try {
      print("Calling API: $apiUrl");
      final response = await http.get(Uri.parse(apiUrl));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        setState(() {
          puzzle = List<int>.from(data['puzzle']);
          solution = List<int>.from(data['solution']);
          // Clone puzzle sang currentBoard để người chơi điền
          currentBoard = List.from(puzzle);
          // Đánh dấu các ô có số sẵn là Fixed
          isFixed = puzzle.map((e) => e != 0).toList();
        });
      } else {
        print("Error: ${response.statusCode}");
        _showErrorSnackBar("Lỗi server: ${response.statusCode}");
      }
    } catch (e) {
      print("Connection error: $e");
      _showErrorSnackBar("Không kết nối được Server!");
    } finally {
      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }
    }
  }

  void _showErrorSnackBar(String msg) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(msg), backgroundColor: Colors.red),
      );
    }
  }

  // Xử lý khi bấm số trên bàn phím
  void onNumberSelected(int number) {
    // Nếu chưa chọn ô, hoặc ô đó là ô đề bài, hoặc game đã kết thúc -> Bỏ qua
    if (selectedIndex == -1 || isFixed[selectedIndex] || isGameOver) return;

    setState(() {
      // Logic kiểm tra đúng sai ngay lập tức
      if (number != solution[selectedIndex]) {
        mistakes++;
        if (mistakes >= maxMistakes) {
          isGameOver = true;
          _showGameOverDialog();
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text("Sai rồi! Cẩn thận nhé."),
              backgroundColor: Colors.orange,
              duration: Duration(milliseconds: 500),
            ),
          );
        }
      } else {
        // Điền đúng
        currentBoard[selectedIndex] = number;
        // Kiểm tra chiến thắng (không còn số 0 nào trong bảng)
        if (!currentBoard.contains(0)) {
          isGameOver = true;
          _showWinDialog();
        }
      }
    });
  }

  // Xử lý nút xóa (Clear ô đang chọn)
  void onClear() {
    if (selectedIndex == -1 || isFixed[selectedIndex] || isGameOver) return;
    setState(() {
      currentBoard[selectedIndex] = 0;
    });
  }

  void _showWinDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        title: Text("🎉 CHIẾN THẮNG!", style: TextStyle(color: Colors.green)),
        content: Text("Chúc mừng bạn đã giải thành công!"),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              fetchGame(); // Chơi ván mới
            },
            child: Text("Chơi lại"),
          )
        ],
      ),
    );
  }

  void _showGameOverDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        title: Text("GAME OVER", style: TextStyle(color: Colors.red)),
        content: Text("Bạn đã sai quá 3 lần. Thử lại nhé!"),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              fetchGame(); // Reset game
            },
            child: Text("Thử lại"),
          )
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Sudoku Game"),
        backgroundColor: Colors.green[700],
        actions: [
          // Hiển thị số lỗi
          Center(
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: 10),
              child: Text(
                "Lỗi: $mistakes/$maxMistakes",
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  color: mistakes >= 2 ? Colors.redAccent : Colors.white,
                ),
              ),
            ),
          ),
          // Nút Game Mới
          IconButton(
            icon: Icon(Icons.refresh),
            tooltip: "Game mới",
            onPressed: fetchGame,
          )
        ],
      ),
      body: isLoading
          ? Center(child: CircularProgressIndicator())
          : puzzle.isEmpty
          ? Center(
        child: ElevatedButton(
          onPressed: fetchGame,
          child: Text("Tải lại dữ liệu"),
        ),
      )
          : Column(
        children: [
          Expanded(child: _buildSudokuGrid()),
          _buildNumberPad(),
        ],
      ),
    );
  }

  // Widget hiển thị bàn cờ
  Widget _buildSudokuGrid() {
    return Container(
      padding: EdgeInsets.all(10),
      alignment: Alignment.center,
      child: AspectRatio(
        aspectRatio: 1.0, // Giữ hình vuông
        child: Container(
          decoration: BoxDecoration(
            border: Border.all(color: Colors.black, width: 2), // Viền ngoài cùng
          ),
          child: GridView.builder(
            physics: NeverScrollableScrollPhysics(), // Tắt cuộn
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 9,
            ),
            itemCount: 81,
            itemBuilder: (context, index) {
              int row = index ~/ 9;
              int col = index % 9;

              // Logic vẽ viền đậm chia khối 3x3
              bool borderRight = (col + 1) % 3 == 0 && col != 8;
              bool borderBottom = (row + 1) % 3 == 0 && row != 8;

              bool isSelected = index == selectedIndex;
              bool isOriginal = isFixed[index];
              int value = currentBoard[index];

              return GestureDetector(
                onTap: () {
                  if (!isGameOver) {
                    setState(() => selectedIndex = index);
                  }
                },
                child: Container(
                  decoration: BoxDecoration(
                    color: isSelected
                        ? Colors.green[200] // Màu ô đang chọn
                        : (isOriginal ? Colors.grey[300] : Colors.white),
                    border: Border(
                      right: BorderSide(
                        width: borderRight ? 2.0 : 0.5,
                        color: borderRight ? Colors.black : Colors.grey,
                      ),
                      bottom: BorderSide(
                        width: borderBottom ? 2.0 : 0.5,
                        color: borderBottom ? Colors.black : Colors.grey,
                      ),
                    ),
                  ),
                  child: Center(
                    child: Text(
                      value == 0 ? "" : value.toString(),
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: isOriginal ? FontWeight.bold : FontWeight.w500,
                        color: isOriginal ? Colors.black : Colors.blue[800],
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  // Widget bàn phím số
  Widget _buildNumberPad() {
    return Container(
      padding: EdgeInsets.symmetric(vertical: 20, horizontal: 10),
      color: Colors.green[50],
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: List.generate(9, (index) {
              return _buildKeyButton(index + 1);
            }),
          ),
          SizedBox(height: 10),
          // Nút Xóa riêng biệt
          ElevatedButton.icon(
            onPressed: onClear,
            icon: Icon(Icons.backspace_outlined),
            label: Text("Xóa ô"),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.redAccent,
              foregroundColor: Colors.white,
            ),
          )
        ],
      ),
    );
  }

  // Nút số tròn
  Widget _buildKeyButton(int number) {
    return SizedBox(
      width: 35,
      height: 35, // Giảm kích thước xíu để vừa màn hình nhỏ
      child: ElevatedButton(
        onPressed: () => onNumberSelected(number),
        style: ElevatedButton.styleFrom(
          padding: EdgeInsets.zero,
          shape: CircleBorder(),
          backgroundColor: Colors.green[700],
        ),
        child: Text(
          "$number",
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }
}