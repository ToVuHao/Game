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
  @override
  _XiangqiScreenState createState() => _XiangqiScreenState();
}

class _XiangqiScreenState extends State<XiangqiScreen> {
  // Kích thước bàn cờ
  final int rows = 10;
  final int cols = 9;

  List<Piece> pieces = [];
  Piece? selectedPiece; // Quân cờ đang được chọn
  bool isRedTurn = true; // Lượt đi

  @override
  void initState() {
    super.initState();
    _initBoard();
  }

  // Khởi tạo bàn cờ tiêu chuẩn
  void _initBoard() {
    pieces.clear();
    // --- QUÂN ĐEN (Ở trên) ---
    Color black = Colors.black;
    _addRow(0, black, ["Xe", "Mã", "Tượng", "Sĩ", "Tướng", "Sĩ", "Tượng", "Mã", "Xe"]);
    _addPiece(2, 1, "Pháo", black); _addPiece(2, 7, "Pháo", black);
    _addPiece(3, 0, "Tốt", black); _addPiece(3, 2, "Tốt", black); _addPiece(3, 4, "Tốt", black); _addPiece(3, 6, "Tốt", black); _addPiece(3, 8, "Tốt", black);

    // --- QUÂN ĐỎ (Ở dưới) ---
    Color red = Colors.red[900]!;
    _addRow(9, red, ["Xe", "Mã", "Tượng", "Sĩ", "Tướng", "Sĩ", "Tượng", "Mã", "Xe"]);
    _addPiece(7, 1, "Pháo", red); _addPiece(7, 7, "Pháo", red);
    _addPiece(6, 0, "Tốt", red); _addPiece(6, 2, "Tốt", red); _addPiece(6, 4, "Tốt", red); _addPiece(6, 6, "Tốt", red); _addPiece(6, 8, "Tốt", red);

    setState(() {
      isRedTurn = true;
      selectedPiece = null;
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

  // Xử lý khi bấm vào ô bàn cờ
  void _onTapCell(int r, int c) {
    // Tìm xem ô đó có quân nào không
    Piece? tappedPiece;
    try {
      tappedPiece = pieces.firstWhere((p) => p.row == r && p.col == c);
    } catch (e) {
      tappedPiece = null;
    }

    setState(() {
      // TRƯỜNG HỢP 1: Chưa chọn quân nào -> Chọn quân
      if (selectedPiece == null) {
        if (tappedPiece != null) {
          // Chỉ được chọn quân đúng lượt (Đỏ hoặc Đen)
          if ((isRedTurn && tappedPiece.color == Colors.red[900]) ||
              (!isRedTurn && tappedPiece.color == Colors.black)) {
            selectedPiece = tappedPiece;
          }
        }
      }
      // TRƯỜNG HỢP 2: Đã chọn quân -> Di chuyển hoặc Ăn quân
      else {
        // Nếu bấm lại chính nó -> Bỏ chọn
        if (tappedPiece == selectedPiece) {
          selectedPiece = null;
          return;
        }

        // Nếu bấm vào quân cùng màu -> Đổi sang chọn quân đó
        if (tappedPiece != null && tappedPiece.color == selectedPiece!.color) {
          selectedPiece = tappedPiece;
          return;
        }

        // --- THỰC HIỆN NƯỚC ĐI (Di chuyển hoặc Ăn) ---
        // Xóa quân bị ăn (nếu có)
        if (tappedPiece != null) {
          pieces.remove(tappedPiece);
        }

        // Cập nhật vị trí mới
        selectedPiece!.row = r;
        selectedPiece!.col = c;

        // Đổi lượt & Bỏ chọn
        isRedTurn = !isRedTurn;
        selectedPiece = null;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    // Tính toán kích thước ô dựa trên màn hình
    double boardWidth = MediaQuery.of(context).size.width - 32; // Padding 16*2
    double cellSize = boardWidth / 9;

    return Scaffold(
      backgroundColor: Colors.amber[100],
      appBar: AppBar(
        title: Text("Cờ Tướng"),
        backgroundColor: Colors.brown,
        actions: [
          IconButton(icon: Icon(Icons.refresh), onPressed: _initBoard)
        ],
      ),
      body: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          children: [
            // Hiển thị lượt đi
            Container(
              padding: EdgeInsets.symmetric(vertical: 10, horizontal: 20),
              decoration: BoxDecoration(
                  color: isRedTurn ? Colors.red[100] : Colors.grey[400],
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: isRedTurn ? Colors.red : Colors.black, width: 2)
              ),
              child: Text(
                isRedTurn ? "Lượt ĐỎ đi" : "Lượt ĐEN đi",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: isRedTurn ? Colors.red[900] : Colors.black),
              ),
            ),
            SizedBox(height: 20),

            // --- BÀN CỜ ---
            Expanded(
              child: Center(
                child: Container(
                  width: boardWidth,
                  height: cellSize * 10,
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.brown, width: 2),
                    color: Colors.orange[50], // Màu nền bàn cờ
                  ),
                  child: Stack(
                    children: [
                      // Lớp 1: Vẽ Lưới Bàn Cờ
                      CustomPaint(
                        size: Size(boardWidth, cellSize * 10),
                        painter: BoardPainter(cellSize: cellSize),
                      ),

                      // Lớp 2: Vẽ các quân cờ
                      ...pieces.map((p) {
                        return Positioned(
                          left: p.col * cellSize,
                          top: p.row * cellSize,
                          width: cellSize,
                          height: cellSize,
                          child: GestureDetector(
                            onTap: () => _onTapCell(p.row, p.col), // Bấm vào quân để chọn
                            child: Container(
                              margin: EdgeInsets.all(2),
                              decoration: BoxDecoration(
                                  color: Colors.orange[100], // Màu nền quân cờ
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                      color: p == selectedPiece ? Colors.blue : p.color, // Viền xanh nếu đang chọn
                                      width: p == selectedPiece ? 3 : 2
                                  ),
                                  boxShadow: [BoxShadow(color: Colors.black26, blurRadius: 2, offset: Offset(1,1))]
                              ),
                              child: Center(
                                child: Text(
                                  p.text,
                                  style: TextStyle(
                                      color: p.color,
                                      fontWeight: FontWeight.bold,
                                      fontSize: cellSize * 0.4 // Chữ to theo ô
                                  ),
                                ),
                              ),
                            ),
                          ),
                        );
                      }).toList(),

                      // Lớp 3: Bắt sự kiện bấm vào ô trống
                      // (Tạo lớp lưới trong suốt đè lên để nhận sự kiện khi bấm vào chỗ không có quân)
                      ...List.generate(90, (index) {
                        int r = index ~/ 9;
                        int c = index % 9;
                        // Chỉ tạo vùng bấm nếu ô đó không có quân (để tránh đè sự kiện của quân cờ)
                        bool hasPiece = pieces.any((p) => p.row == r && p.col == c);
                        if (hasPiece) return SizedBox();

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

// Bộ vẽ lưới bàn cờ (CustomPainter)
class BoardPainter extends CustomPainter {
  final double cellSize;
  BoardPainter({required this.cellSize});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = Colors.brown..strokeWidth = 1.0;
    double width = size.width;
    double height = size.height;
    double halfCell = cellSize / 2;

    // Vẽ các đường ngang (10 đường)
    for (int i = 0; i < 10; i++) {
      double y = i * cellSize + halfCell;
      canvas.drawLine(Offset(halfCell, y), Offset(width - halfCell, y), paint);
    }

    // Vẽ các đường dọc (9 đường)
    for (int i = 0; i < 9; i++) {
      double x = i * cellSize + halfCell;
      // Nửa trên (Bên Đen)
      canvas.drawLine(Offset(x, halfCell), Offset(x, cellSize * 4 + halfCell), paint);
      // Nửa dưới (Bên Đỏ)
      canvas.drawLine(Offset(x, cellSize * 5 + halfCell), Offset(x, height - halfCell), paint);
    }

    // Vẽ khung bao ngoài (để nối liền 2 bên sông)
    canvas.drawLine(Offset(halfCell, halfCell), Offset(halfCell, height - halfCell), paint); // Dọc trái
    canvas.drawLine(Offset(width - halfCell, halfCell), Offset(width - halfCell, height - halfCell), paint); // Dọc phải

    // Vẽ Cửu cung (Chéo ở khu vua) - Bên trên
    canvas.drawLine(Offset(3 * cellSize + halfCell, 0 * cellSize + halfCell), Offset(5 * cellSize + halfCell, 2 * cellSize + halfCell), paint);
    canvas.drawLine(Offset(5 * cellSize + halfCell, 0 * cellSize + halfCell), Offset(3 * cellSize + halfCell, 2 * cellSize + halfCell), paint);

    // Vẽ Cửu cung - Bên dưới
    canvas.drawLine(Offset(3 * cellSize + halfCell, 9 * cellSize + halfCell), Offset(5 * cellSize + halfCell, 7 * cellSize + halfCell), paint);
    canvas.drawLine(Offset(5 * cellSize + halfCell, 9 * cellSize + halfCell), Offset(3 * cellSize + halfCell, 7 * cellSize + halfCell), paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}