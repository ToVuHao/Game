import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class SudokuScreen extends StatefulWidget {
  @override
  _SudokuScreenState createState() => _SudokuScreenState();
}

class _SudokuScreenState extends State<SudokuScreen> {
  // Thay PORT bằng port backend của bạn (đang là 5231)
  final String apiUrl = "http://10.0.2.2:5231/api/sudoku/new-game";

  List<int> puzzle = [];
  List<int> solution = [];
  List<int> currentBoard = [];
  List<bool> isFixed = [];

  bool isLoading = true;
  int mistakes = 0;
  int selectedIndex = -1;

  @override
  void initState() {
    super.initState();
    fetchGame();
  }

  Future<void> fetchGame() async {
    try {
      print("Bắt đầu gọi API: $apiUrl"); // In log để kiểm tra

      // Gọi thẳng API
      final response = await http.get(Uri.parse(apiUrl));

      print("Server trả về Code: ${response.statusCode}"); // In mã lỗi (200 là ok)

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        setState(() {
          puzzle = List<int>.from(data['puzzle']);
          solution = List<int>.from(data['solution']);
          currentBoard = List.from(puzzle);
          isFixed = puzzle.map((e) => e != 0).toList();
        });
      } else {
        print("Lỗi Server: ${response.body}"); // In nội dung lỗi nếu có
      }
    } catch (e) {
      print("Lỗi KẾT NỐI: $e"); // In lỗi nếu không kết nối được
      // Nếu lỗi kết nối thì hiện thông báo nhỏ
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Lỗi kết nối Server! Xem log để biết thêm."), backgroundColor: Colors.red),
        );
      }
    } finally {
      // QUAN TRỌNG NHẤT: Dù thành công hay thất bại cũng phải tắt Loading
      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }
    }
  }

  void onNumberSelected(int number) {
    if (selectedIndex == -1 || isFixed[selectedIndex]) return;

    setState(() {
      if (number != solution[selectedIndex]) {
        mistakes++;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Sai rồi!"), backgroundColor: Colors.red, duration: Duration(milliseconds: 500)),
        );
      } else {
        currentBoard[selectedIndex] = number;
        if (!currentBoard.contains(0)) {
          _showWinDialog();
        }
      }
    });
  }

  void _showWinDialog() {
    showDialog(
        context: context,
        builder: (_) => AlertDialog(
          title: Text("CHIẾN THẮNG!"),
          content: Text("Bạn quá đỉnh!"),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: Text("Đóng"))
          ],
        )
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Sudoku"),
        backgroundColor: Colors.green,
        actions: [
          Center(child: Padding(
            padding: EdgeInsets.only(right: 16),
            child: Text("Lỗi: $mistakes/3", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          ))
        ],
      ),
      body: isLoading
          ? Center(child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(),
          SizedBox(height: 10),
          Text("Đang tải đề bài..."),
        ],
      ))
          : puzzle.isEmpty // Nếu tải xong mà không có dữ liệu (do lỗi)
          ? Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error, color: Colors.red, size: 50),
            Text("Không tải được dữ liệu!", style: TextStyle(fontSize: 18)),
            ElevatedButton(onPressed: fetchGame, child: Text("Thử lại"))
          ],
        ),
      )
          : Column( // Nếu có dữ liệu thì hiện bàn cờ
        children: [
          Expanded(
            child: Padding(
              padding: EdgeInsets.all(8.0),
              child: GridView.builder(
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 9,
                  childAspectRatio: 1.0,
                ),
                itemCount: 81,
                itemBuilder: (context, index) {
                  int row = index ~/ 9;
                  int col = index % 9;
                  bool rightBorder = (col + 1) % 3 == 0 && col != 8;
                  bool bottomBorder = (row + 1) % 3 == 0 && row != 8;

                  return GestureDetector(
                    onTap: () {
                      if (!isFixed[index]) setState(() => selectedIndex = index);
                    },
                    child: Container(
                      decoration: BoxDecoration(
                        border: Border(
                          right: BorderSide(width: rightBorder ? 2 : 0.5),
                          bottom: BorderSide(width: bottomBorder ? 2 : 0.5),
                          left: BorderSide(width: 0.5),
                          top: BorderSide(width: 0.5),
                        ),
                        color: selectedIndex == index
                            ? Colors.green[100]
                            : (isFixed[index] ? Colors.grey[300] : Colors.white),
                      ),
                      child: Center(
                        child: Text(
                          currentBoard[index] == 0 ? "" : currentBoard[index].toString(),
                          style: TextStyle(
                              fontSize: 18,
                              fontWeight: isFixed[index] ? FontWeight.bold : FontWeight.normal,
                              color: isFixed[index] ? Colors.black : Colors.green
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
          // Bàn phím số
          Container(
            padding: EdgeInsets.all(10),
            color: Colors.green[50],
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: List.generate(9, (index) {
                int num = index + 1;
                return ElevatedButton(
                  onPressed: () => onNumberSelected(num),
                  style: ElevatedButton.styleFrom(
                      shape: CircleBorder(),
                      padding: EdgeInsets.all(12),
                      backgroundColor: Colors.green
                  ),
                  child: Text("$num", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                );
              }),
            ),
          ),
          SizedBox(height: 20),
        ],
      ),
    );
  }
}