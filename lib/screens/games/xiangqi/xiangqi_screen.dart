import 'package:flutter/material.dart';

// Định nghĩa quân cờ
class Piece {
  String text; // Tên quân (Tướng, Sĩ, Tượng...)
  Color color; // Màu (Đỏ/Đen)
  int row;
  int col;

  Piece({required this.text, required this.color, required this.row, required this.col});
}

class XiangqiScreen extends StatefulWidget {
  const XiangqiScreen({super.key});

  @override
  State<XiangqiScreen> createState() => _XiangqiScreenState();
}

class _XiangqiScreenState extends State<XiangqiScreen> {
  final int rows = 10;
  final int cols = 9;

  List<Piece> pieces = [];
  Piece? selectedPiece;
  bool isRedTurn = true;
  bool isGameOver = false;

  @override
  void initState() {
    super.initState();
    _initBoard();
  }

  void _initBoard() {
    pieces.clear();
    Color black = Colors.black;
    _addRow(0, black, ["Xe", "Mã", "Tượng", "Sĩ", "Tướng", "Sĩ", "Tượng", "Mã", "Xe"]);
    _addPiece(2, 1, "Pháo", black); _addPiece(2, 7, "Pháo", black);
    _addPiece(3, 0, "Tốt", black); _addPiece(3, 2, "Tốt", black); _addPiece(3, 4, "Tốt", black); _addPiece(3, 6, "Tốt", black); _addPiece(3, 8, "Tốt", black);

    Color red = Colors.red[900]!;
    _addRow(9, red, ["Xe", "Mã", "Tượng", "Sĩ", "Tướng", "Sĩ", "Tượng", "Mã", "Xe"]);
    _addPiece(7, 1, "Pháo", red); _addPiece(7, 7, "Pháo", red);
    _addPiece(6, 0, "Tốt", red); _addPiece(6, 2, "Tốt", red); _addPiece(6, 4, "Tốt", red); _addPiece(6, 6, "Tốt", red); _addPiece(6, 8, "Tốt", red);

    setState(() {
      isRedTurn = true;
      selectedPiece = null;
      isGameOver = false;
    });
  }

  void _addRow(int r, Color c, List<String> names) {
    for (int i = 0; i < 9; i++) {
      pieces.add(Piece(text: names[i], color: c, row: r, col: i));
    }
  }

  void _addPiece(int r, int c, String text, Color color) {
    pieces.add(Piece(text: text, color: color, row: r, col: c));
  }

  // --- KIỂM TRA LUẬT DI CHUYỂN ---
  bool _isValidMove(Piece piece, int targetRow, int targetCol) {
    int dr = (targetRow - piece.row).abs();
    int dc = (targetCol - piece.col).abs();
    bool isRed = piece.color == Colors.red[900];

    // Kiểm tra xem ô mục tiêu có quân cùng màu không
    Piece? targetPiece = _getPieceAt(targetRow, targetCol);
    if (targetPiece != null && targetPiece.color == piece.color) return false;

    switch (piece.text) {
      case "Tướng":
      // Trong cung: Red (7-9, 3-5), Black (0-2, 3-5)
        if (targetCol < 3 || targetCol > 5) return false;
        if (isRed && (targetRow < 7 || targetRow > 9)) return false;
        if (!isRed && (targetRow < 0 || targetRow > 2)) return false;
        return (dr + dc == 1); // Đi 1 ô ngang hoặc dọc

      case "Sĩ":
      // Trong cung, đi chéo 1 ô
        if (targetCol < 3 || targetCol > 5) return false;
        if (isRed && (targetRow < 7 || targetRow > 9)) return false;
        if (!isRed && (targetRow < 0 || targetRow > 2)) return false;
        return (dr == 1 && dc == 1);

      case "Tượng":
// Đi chéo đúng 2 ô, không qua sông, không bị cản (mắt tượng)
        if (dr != 2 || dc != 2) return false;
        if (isRed && targetRow < 5) return false;
        if (!isRed && targetRow > 4) return false;
        // Kiểm tra cản (mắt tượng)
        if (_getPieceAt((piece.row + targetRow) ~/ 2, (piece.col + targetCol) ~/ 2) != null) return false;
        return true;

      case "Mã":
      // Đi hình chữ L (2-1), kiểm tra cản (chân mã)
        if (!((dr == 2 && dc == 1) || (dr == 1 && dc == 2))) return false;
        if (dr == 2) {
          if (_getPieceAt((piece.row + targetRow) ~/ 2, piece.col) != null) return false;
        } else {
          if (_getPieceAt(piece.row, (piece.col + targetCol) ~/ 2) != null) return false;
        }
        return true;

      case "Xe":
      // Đi ngang/dọc, không có quân cản
        if (dr != 0 && dc != 0) return false;
        return _countPiecesBetween(piece.row, piece.col, targetRow, targetCol) == 0;

      case "Pháo":
        if (dr != 0 && dc != 0) return false;
        int count = _countPiecesBetween(piece.row, piece.col, targetRow, targetCol);
        if (targetPiece == null) return count == 0; // Di chuyển: không có quân cản
        return count == 1; // Ăn quân: phải nhảy qua đúng 1 quân

      case "Tốt":
        if (isRed) {
          if (targetRow > piece.row) return false; // Không đi lùi
          if (piece.row >= 5) return dr == 1 && dc == 0; // Chưa qua sông: chỉ tiến
          return (dr + dc == 1) && targetRow <= piece.row; // Qua sông: tiến/ngang
        } else {
          if (targetRow < piece.row) return false;
          if (piece.row <= 4) return dr == 1 && dc == 0;
          return (dr + dc == 1) && targetRow >= piece.row;
        }
    }
    return false;
  }

  Piece? _getPieceAt(int r, int c) {
    try { return pieces.firstWhere((p) => p.row == r && p.col == c); } catch (_) { return null; }
  }

  int _countPiecesBetween(int r1, int c1, int r2, int c2) {
    int count = 0;
    if (r1 == r2) {
      int start = c1 < c2 ? c1 : c2;
      int end = c1 < c2 ? c2 : c1;
      for (int i = start + 1; i < end; i++) {
        if (_getPieceAt(r1, i) != null) count++;
      }
    } else {
      int start = r1 < r2 ? r1 : r2;
      int end = r1 < r2 ? r2 : r1;
      for (int i = start + 1; i < end; i++) {
        if (_getPieceAt(i, c1) != null) count++;
      }
    }
    return count;
  }

  void _onTapCell(int r, int c) {
    if (isGameOver) return; // Nếu game kết thúc thì không cho bấm nữa

    Piece? tappedPiece = _getPieceAt(r, c);

    setState(() {
      if (selectedPiece == null) {
        if (tappedPiece != null) {
          if ((isRedTurn && tappedPiece.color == Colors.red[900]) ||
              (!isRedTurn && tappedPiece.color == Colors.black)) {
            selectedPiece = tappedPiece;
          }
        }
      } else {
        if (tappedPiece == selectedPiece) {
          selectedPiece = null;
          return;
        }
        if (tappedPiece != null && tappedPiece.color == selectedPiece!.color) {
          selectedPiece = tappedPiece;
          return;
        }

        // KIỂM TRA LUẬT TẠI ĐÂY
        if (_isValidMove(selectedPiece!, r, c)) {
          bool kingEaten = false;
          String winnerText = "";

          if (tappedPiece != null) {
            if (tappedPiece.text == "Tướng") {
              kingEaten = true;
              winnerText = tappedPiece.color == Colors.black ? "ĐỎ THẮNG!" : "ĐEN THẮNG!";
            }
            pieces.remove(tappedPiece);
          }

          selectedPiece!.row = r;
          selectedPiece!.col = c;

          if (kingEaten) {
            isGameOver = true;
            _showEndDialog(winnerText);
          } else {
            isRedTurn = !isRedTurn;
          }
          selectedPiece = null;
        }
      }
    });
  }

  void _showEndDialog(String title) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 24, color: Colors.brown)),
        content: const Text("Ván cờ đã kết thúc. Bạn có muốn chơi ván mới không?"),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _initBoard();
            },
            child: const Text("Chơi lại", style: TextStyle(fontSize: 18)),
          )
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    double boardWidth = MediaQuery.of(context).size.width - 32;
    double cellSize = boardWidth / 9;

    return Scaffold(
      backgroundColor: Colors.amber[100],
      appBar: AppBar(
        title: const Text("Cờ Tướng"),
        backgroundColor: Colors.brown,
        actions: [IconButton(icon: const Icon(Icons.refresh), onPressed: _initBoard)],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 20),
              decoration: BoxDecoration(
                  color: isRedTurn ? Colors.red[100] : Colors.grey[400],
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: isRedTurn ? Colors.red! : Colors.black, width: 2)
              ),
              child: Text(
                isRedTurn ? "Lượt ĐỎ đi" : "Lượt ĐEN đi",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: isRedTurn ? Colors.red[900] : Colors.black),
              ),
            ),
            const SizedBox(height: 20),
            Expanded(
              child: Center(
                child: Container(
                  width: boardWidth,
                  height: cellSize * 10,
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.brown, width: 2),
                    color: Colors.orange[50],
                  ),
                  child: Stack(
                    children: [
                      CustomPaint(
                        size: Size(boardWidth, cellSize * 10),
                        painter: BoardPainter(cellSize: cellSize),
                      ),
                      for (var p in pieces)
                        Positioned(
                          left: p.col * cellSize,
                          top: p.row * cellSize,
                          width: cellSize,
                          height: cellSize,
                          child: GestureDetector(
                            onTap: () => _onTapCell(p.row, p.col),
                            child: Container(
                              margin: const EdgeInsets.all(2),
                              decoration: BoxDecoration(
                                  color: Colors.orange[100],
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                      color: p == selectedPiece ? Colors.blue : p.color,
                                      width: p == selectedPiece ? 3 : 2
                                  ),
                                  boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 2, offset: Offset(1,1))]
                              ),
                              child: Center(
                                child: Text(
                                  p.text,
                                  style: TextStyle(
                                      color: p.color,
                                      fontWeight: FontWeight.bold,
                                      fontSize: cellSize * 0.4
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ...List.generate(90, (index) {
                        int r = index ~/ 9;
                        int c = index % 9;
                        if (pieces.any((p) => p.row == r && p.col == c)) return const SizedBox();
                        return Positioned(
                          left: c * cellSize,
                          top: r * cellSize,
                          width: cellSize,
                          height: cellSize,
                          child: GestureDetector(
                            onTap: () => _onTapCell(r, c),
                            child: Container(color: Colors.transparent),
                          ),
                        );
                      }),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class BoardPainter extends CustomPainter {
  final double cellSize;
  BoardPainter({required this.cellSize});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = Colors.brown..strokeWidth = 1.0;
    double width = size.width;
    double height = size.height;
    double halfCell = cellSize / 2;

    for (int i = 0; i < 10; i++) {
      double y = i * cellSize + halfCell;
      canvas.drawLine(Offset(halfCell, y), Offset(width - halfCell, y), paint);
    }
    for (int i = 0; i < 9; i++) {
      double x = i * cellSize + halfCell;
      canvas.drawLine(Offset(x, halfCell), Offset(x, cellSize * 4 + halfCell), paint);
      canvas.drawLine(Offset(x, cellSize * 5 + halfCell), Offset(x, height - halfCell), paint);
    }
    canvas.drawLine(Offset(halfCell, halfCell), Offset(halfCell, height - halfCell), paint);
    canvas.drawLine(Offset(width - halfCell, halfCell), Offset(width - halfCell, height - halfCell), paint);

    // Cửu cung
    canvas.drawLine(Offset(3 * cellSize + halfCell, 0 * cellSize + halfCell), Offset(5 * cellSize + halfCell, 2 * cellSize + halfCell), paint);
    canvas.drawLine(Offset(5 * cellSize + halfCell, 0 * cellSize + halfCell), Offset(3 * cellSize + halfCell, 2 * cellSize + halfCell), paint);
    canvas.drawLine(Offset(3 * cellSize + halfCell, 9 * cellSize + halfCell), Offset(5 * cellSize + halfCell, 7 * cellSize + halfCell), paint);
    canvas.drawLine(Offset(5 * cellSize + halfCell, 9 * cellSize + halfCell), Offset(3 * cellSize + halfCell, 7 * cellSize + halfCell), paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}