import 'dart:math';
import 'package:flutter/material.dart';

class CaroScreen extends StatefulWidget {
  @override
  _CaroScreenState createState() => _CaroScreenState();
}

class _CaroScreenState extends State<CaroScreen> {
  static const int rows = 15;
  static const int cols = 15;

  // 0: Trống, 1: Người (X), 2: Máy (O)
  List<List<int>> board = List.generate(rows, (i) => List.filled(cols, 0));
  bool isPlayerTurn = true;
  bool isGameOver = false;
  String winner = "";

  // --- LOGIC GAME ---

  void _resetGame() {
    setState(() {
      board = List.generate(rows, (i) => List.filled(cols, 0));
      isPlayerTurn = true;
      isGameOver = false;
      winner = "";
    });
  }

  void _onCellTapped(int row, int col) {
    if (board[row][col] != 0 || isGameOver || !isPlayerTurn) return;

    setState(() {
      board[row][col] = 1; // Người đánh X
      if (_checkWin(row, col, 1)) {
        _endGame("Bạn thắng!");
      } else {
        isPlayerTurn = false;
        // Delay 1 chút để cảm giác máy đang suy nghĩ
        Future.delayed(Duration(milliseconds: 500), () {
          _machineMove();
        });
      }
    });
  }

  void _machineMove() {
    if (isGameOver) return;

    // Thuật toán tìm nước đi tốt nhất
    Point<int> bestMove = _findBestMove();

    setState(() {
      board[bestMove.x][bestMove.y] = 2; // Máy đánh O
      if (_checkWin(bestMove.x, bestMove.y, 2)) {
        _endGame("Máy thắng!");
      } else {
        isPlayerTurn = true;
      }
    });
  }

  // Thuật toán Heuristic đơn giản: Tính điểm tấn công và phòng thủ
  Point<int> _findBestMove() {
    int maxScore = -1;
    Point<int> bestPoint = Point<int>(7, 7); // Mặc định đánh giữa nếu bàn trống

    for (int i = 0; i < rows; i++) {
      for (int j = 0; j < cols; j++) {
        if (board[i][j] == 0) {
          // Tính điểm cho ô trống này
          int attackScore = _evaluate(i, j, 2); // Điểm tấn công (Cho O)
          int defenseScore = _evaluate(i, j, 1); // Điểm phòng thủ (Chặn X)

          // Máy ưu tiên phòng thủ nếu nguy cấp, còn không thì tấn công
          int currentScore = attackScore + defenseScore;

          if (currentScore > maxScore) {
            maxScore = currentScore;
            bestPoint = Point<int>(i, j);
          }
        }
      }
    }
    return bestPoint;
  }

  // Hàm tính điểm dựa trên số quân liên tiếp
  int _evaluate(int row, int col, int player) {
    int score = 0;
    // SỬA LỖI Ở ĐÂY: Dùng List<int> thay vì int[]
    List<int> dx = [1, 0, 1, 1];
    List<int> dy = [0, 1, 1, -1];

    for (int i = 0; i < 4; i++) {
      int count = 0;
      int block = 0;

      // Đếm về 1 phía
      for (int k = 1; k < 5; k++) {
        int r = row + dx[i] * k;
        int c = col + dy[i] * k;
        if (r < 0 || r >= rows || c < 0 || c >= cols) {
          block++;
          break;
        }
        if (board[r][c] == player) {
          count++;
        } else if (board[r][c] != 0) {
          block++;
          break;
        } else {
          break;
        }
      }

      // Đếm về phía ngược lại
      for (int k = 1; k < 5; k++) {
        int r = row - dx[i] * k;
        int c = col - dy[i] * k;
        if (r < 0 || r >= rows || c < 0 || c >= cols) {
          block++;
          break;
        }
        if (board[r][c] == player) {
          count++;
        } else if (board[r][c] != 0) {
          block++;
          break;
        } else {
          break;
        }
      }

      // Quy tắc tính điểm
      if (block == 2) continue; // Bị chặn 2 đầu thì vô dụng
      if (count >= 4) score += 10000; // Sắp thắng (5 con)
      else if (count == 3) score += 1000; // 4 con
      else if (count == 2) score += 100; // 3 con
      else if (count == 1) score += 10;
    }
    return score;
  }

  bool _checkWin(int row, int col, int player) {
    // SỬA LỖI Ở ĐÂY: Dùng List<int>
    List<int> dx = [1, 0, 1, 1];
    List<int> dy = [0, 1, 1, -1];

    for (int i = 0; i < 4; i++) {
      int count = 1;
      // Đếm xuôi
      for (int k = 1; k < 5; k++) {
        int r = row + dx[i] * k;
        int c = col + dy[i] * k;
        if (r >= 0 && r < rows && c >= 0 && c < cols && board[r][c] == player)
          count++;
        else
          break;
      }
      // Đếm ngược
      for (int k = 1; k < 5; k++) {
        int r = row - dx[i] * k;
        int c = col - dy[i] * k;
        if (r >= 0 && r < rows && c >= 0 && c < cols && board[r][c] == player)
          count++;
        else
          break;
      }
      if (count >= 5) return true;
    }
    return false;
  }

  void _endGame(String msg) {
    setState(() {
      isGameOver = true;
      winner = msg;
    });
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        title: Text("KẾT THÚC"),
        content: Text(msg, style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: msg.contains("Bạn") ? Colors.green : Colors.red)),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _resetGame();
            },
            child: Text("Chơi lại"),
          )
        ],
      ),
    );
  }

  // --- GIAO DIỆN ---

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Caro vs Máy"),
        backgroundColor: Colors.redAccent,
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.person, color: Colors.blue),
                Text(" Bạn (X)  vs  ", style: TextStyle(fontWeight: FontWeight.bold)),
                Icon(Icons.computer, color: Colors.red),
                Text(" Máy (O)", style: TextStyle(fontWeight: FontWeight.bold)),
              ],
            ),
          ),
          Expanded(
            child: InteractiveViewer( // Cho phép Zoom in/out
              minScale: 0.5,
              maxScale: 3.0,
              child: Center(
                child: Container(
                  color: Colors.orange[100],
                  padding: EdgeInsets.all(4),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: List.generate(rows, (r) {
                      return Row(
                        mainAxisSize: MainAxisSize.min,
                        children: List.generate(cols, (c) {
                          return GestureDetector(
                            onTap: () => _onCellTapped(r, c),
                            child: Container(
                              width: 30, // Kích thước mỗi ô
                              height: 30,
                              decoration: BoxDecoration(
                                border: Border.all(color: Colors.black45, width: 0.5),
                                color: Colors.transparent,
                              ),
                              child: Center(
                                child: _buildPiece(board[r][c]),
                              ),
                            ),
                          );
                        }),
                      );
                    }),
                  ),
                ),
              ),
            ),
          ),
          Container(
            padding: EdgeInsets.all(16),
            color: Colors.grey[200],
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(isPlayerTurn ? "Lượt của bạn..." : "Máy đang tính...",
                    style: TextStyle(color: Colors.red, fontStyle: FontStyle.italic)),
                ElevatedButton.icon(
                  onPressed: _resetGame,
                  icon: Icon(Icons.refresh),
                  label: Text("Ván mới"),
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
                )
              ],
            ),
          )
        ],
      ),
    );
  }

  Widget _buildPiece(int value) {
    if (value == 1) return Text("X", style: TextStyle(color: Colors.blue, fontWeight: FontWeight.bold, fontSize: 20));
    if (value == 2) return Text("O", style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold, fontSize: 20));
    return SizedBox.shrink();
  }
}