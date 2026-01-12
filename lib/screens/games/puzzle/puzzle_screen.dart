import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';

class PuzzleScreen extends StatefulWidget {
  @override
  _PuzzleScreenState createState() => _PuzzleScreenState();
}

class _PuzzleScreenState extends State<PuzzleScreen> {
  // 0 đại diện cho ô trống
  List<int> numbers = [1, 2, 3, 4, 5, 6, 7, 8, 0];
  int moves = 0; // Đếm số bước đi
  int seconds = 0; // Đếm thời gian
  Timer? timer;
  bool isPlaying = false;

  @override
  void initState() {
    super.initState();
    _startNewGame();
  }

  @override
  void dispose() {
    timer?.cancel();
    super.dispose();
  }

  // --- LOGIC GAME ---

  void _startNewGame() {
    setState(() {
      numbers = [1, 2, 3, 4, 5, 6, 7, 8, 0];
      moves = 0;
      seconds = 0;
      isPlaying = true;
    });
    _shuffleBoard();
    _startTimer();
  }

  void _startTimer() {
    timer?.cancel();
    timer = Timer.periodic(Duration(seconds: 1), (timer) {
      if (mounted) {
        setState(() {
          seconds++;
        });
      }
    });
  }

  // Thuật toán trộn: Thực hiện 100 nước đi ngẫu nhiên hợp lệ từ trạng thái thắng
  // Cách này đảm bảo bài toán LUÔN LUÔN giải được (Tránh trường hợp không giải được)
  void _shuffleBoard() {
    Random rng = Random();
    for (int i = 0; i < 100; i++) {
      int emptyIndex = numbers.indexOf(0);
      List<int> validMoves = [];

      // Kiểm tra các ô có thể di chuyển vào ô trống (Lên, Xuống, Trái, Phải)
      int row = emptyIndex ~/ 3;
      int col = emptyIndex % 3;

      if (row > 0) validMoves.add(emptyIndex - 3); // Ô ở trên
      if (row < 2) validMoves.add(emptyIndex + 3); // Ô ở dưới
      if (col > 0) validMoves.add(emptyIndex - 1); // Ô bên trái
      if (col < 2) validMoves.add(emptyIndex + 1); // Ô bên phải

      // Chọn ngẫu nhiên 1 nước đi
      int moveIndex = validMoves[rng.nextInt(validMoves.length)];

      // Hoán đổi
      int temp = numbers[moveIndex];
      numbers[moveIndex] = numbers[emptyIndex];
      numbers[emptyIndex] = temp;
    }
  }

  void _moveTile(int index) {
    if (!isPlaying) return;

    int emptyIndex = numbers.indexOf(0);

    // Kiểm tra xem ô vừa bấm có nằm cạnh ô trống không
    // Logic: Cùng hàng (khoảng cách là 1) hoặc cùng cột (khoảng cách là 3)
    bool isAdjacent = false;
    int rowUser = index ~/ 3;
    int colUser = index % 3;
    int rowEmpty = emptyIndex ~/ 3;
    int colEmpty = emptyIndex % 3;

    // Kề nhau theo chiều dọc hoặc ngang
    if ((rowUser == rowEmpty && (colUser - colEmpty).abs() == 1) ||
        (colUser == colEmpty && (rowUser - rowEmpty).abs() == 1)) {
      isAdjacent = true;
    }

    if (isAdjacent) {
      setState(() {
        // Hoán đổi vị trí
        numbers[emptyIndex] = numbers[index];
        numbers[index] = 0;
        moves++;
      });
      _checkWin();
    }
  }

  void _checkWin() {
    List<int> target = [1, 2, 3, 4, 5, 6, 7, 8, 0];
    bool isWin = true;
    for (int i = 0; i < numbers.length; i++) {
      if (numbers[i] != target[i]) {
        isWin = false;
        break;
      }
    }

    if (isWin) {
      timer?.cancel();
      setState(() => isPlaying = false);
      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          title: Text("CHIẾN THẮNG!"),
          content: Text("Bạn đã hoàn thành trong:\n⏱ $seconds giây\n👣 $moves bước đi"),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                _startNewGame();
              },
              child: Text("Chơi lại"),
            )
          ],
        ),
      );
    }
  }

  // --- GIAO DIỆN ---

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.blue[50],
      appBar: AppBar(
        title: Text("Xếp Hình (Sliding Puzzle)"),
        backgroundColor: Colors.blueAccent,
      ),
      body: Column(
        children: [
          // Phần hiển thị thông tin điểm số
          Padding(
            padding: EdgeInsets.all(20),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildInfoCard(Icons.timer, "$seconds s", Colors.orange),
                _buildInfoCard(Icons.directions_walk, "$moves", Colors.green),
              ],
            ),
          ),

          // Bàn cờ 3x3
          Expanded(
            child: Center(
              child: Container(
                width: 300,
                height: 300,
                padding: EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: Colors.blue[900],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: GridView.builder(
                  physics: NeverScrollableScrollPhysics(), // Không cho cuộn
                  itemCount: 9,
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 3,
                    crossAxisSpacing: 4,
                    mainAxisSpacing: 4,
                  ),
                  itemBuilder: (context, index) {
                    if (numbers[index] == 0) {
                      return Container(color: Colors.white.withOpacity(0.1)); // Ô trống
                    }
                    return GestureDetector(
                      onTap: () => _moveTile(index),
                      child: Container(
                        decoration: BoxDecoration(
                            color: Colors.blueAccent,
                            borderRadius: BorderRadius.circular(8),
                            boxShadow: [
                              BoxShadow(color: Colors.black26, blurRadius: 2, offset: Offset(2,2))
                            ]
                        ),
                        child: Center(
                          child: Text(
                            "${numbers[index]}",
                            style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: Colors.white),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
          ),

          // Nút chơi lại
          Padding(
            padding: EdgeInsets.only(bottom: 40),
            child: ElevatedButton.icon(
              onPressed: _startNewGame,
              icon: Icon(Icons.refresh),
              label: Text("Trộn lại / Chơi mới"),
              style: ElevatedButton.styleFrom(
                padding: EdgeInsets.symmetric(horizontal: 30, vertical: 15),
              ),
            ),
          )
        ],
      ),
    );
  }

  Widget _buildInfoCard(IconData icon, String text, Color color) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 4)]
      ),
      child: Row(
        children: [
          Icon(icon, color: color),
          SizedBox(width: 8),
          Text(text, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}