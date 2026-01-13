import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

// --- GAME (Nằm trong thư mục games) ---
import '../games/sudoku/sudoku_screen.dart';
import '../games/puzzle/puzzle_screen.dart';
import '../games/caro/caro_screen.dart';
import '../games/xiangqi/xiangqi_screen.dart';

// --- TÍNH NĂNG KHÁC ---
import '../leaderboard/leaderboard_screen.dart';
import '../chat/chat_screen.dart';
import '../social/friend_screen.dart';
import '../auth/login_screen.dart';

class HomeScreen extends StatefulWidget {
  final String userName;
  final int userId;

  HomeScreen({required this.userName, required this.userId});

  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  // Biến lưu trạng thái game lấy từ Server
  List<dynamic> serverGamesStatus = [];

  // URL API kiểm tra trạng thái game
  final String gameApiUrl = "http://10.0.2.2:5231/api/games";

  // Danh sách Game hiển thị trên UI
  final List<Map<String, dynamic>> uiGames = [
    {"name": "Cờ tướng", "icon": Icons.psychology, "color": Colors.brown},
    {"name": "Sudoku", "icon": Icons.grid_4x4, "color": Colors.green},
    {"name": "Xếp hình", "icon": Icons.extension, "color": Colors.purple},
    {"name": "Caro vs Máy", "icon": Icons.close, "color": Colors.red},
    {"name": "Bảng Xếp Hạng", "icon": Icons.emoji_events, "color": Colors.amber},
    {"name": "Chat Room", "icon": Icons.chat, "color": Colors.blue},
    {"name": "Bạn bè", "icon": Icons.people_alt_rounded, "color": Colors.pinkAccent},
  ];

  @override
  void initState() {
    super.initState();
    _fetchGameStatus(); // Gọi API ngay khi mở màn hình
  }

  // --- 1. GỌI API LẤY TRẠNG THÁI ---
  Future<void> _fetchGameStatus() async {
    try {
      final res = await http.get(Uri.parse(gameApiUrl));
      if (res.statusCode == 200) {
        setState(() {
          serverGamesStatus = jsonDecode(res.body);
        });
      }
    } catch (e) {
      print("Lỗi lấy trạng thái game: $e");
    }
  }

  // --- 2. HÀM CHECK BẢO TRÌ ---
  bool _isMaintenance(String gameName) {
    // Những tính năng này không bị ảnh hưởng bởi bảo trì game
    if (gameName == "Bảng Xếp Hạng" ||
        gameName == "Chat Room" ||
        gameName == "Bạn bè") return false;

    // Tìm game trong danh sách server trả về
    var game = serverGamesStatus.firstWhere(
            (g) => g['name'] == gameName,
        orElse: () => null
    );

    // Nếu tìm thấy và isActive = false => Đang bảo trì
    if (game != null && game['isActive'] == false) return true;

    return false; // Mặc định là Hoạt động
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("Xin chào, ${widget.userName}!", style: TextStyle(fontSize: 18)),
            Text("ID: ${widget.userId}", style: TextStyle(fontSize: 12, color: Colors.white70)),
          ],
        ),
        backgroundColor: Colors.blueAccent,
        elevation: 0,
        automaticallyImplyLeading: false,
      ),
      body: Padding(
        padding: EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Menu chính",
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.black87),
            ),
            SizedBox(height: 20),

            // --- KHU VỰC DANH SÁCH GAME ---
            Expanded(
              child: RefreshIndicator(
                onRefresh: _fetchGameStatus, // Kéo xuống để cập nhật lại trạng thái
                child: GridView.builder(
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    crossAxisSpacing: 16,
                    mainAxisSpacing: 16,
                    childAspectRatio: 1.2,
                  ),
                  itemCount: uiGames.length,
                  itemBuilder: (context, index) {
                    String name = uiGames[index]['name'];
                    // Kiểm tra xem game này có đang bảo trì không
                    bool isMaintenance = _isMaintenance(name);

                    return InkWell(
                      onTap: () {
                        // Nếu đang bảo trì thì chặn lại
                        if (isMaintenance) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text("Game $name đang bảo trì! Vui lòng quay lại sau."),
                              backgroundColor: Colors.orange,
                              behavior: SnackBarBehavior.floating,
                            ),
                          );
                          return;
                        }

                        // Điều hướng bình thường
                        if (name == "Sudoku") Navigator.push(context, MaterialPageRoute(builder: (context) => SudokuScreen()));
                        else if (name == "Xếp hình") Navigator.push(context, MaterialPageRoute(builder: (context) => PuzzleScreen()));
                        else if (name == "Caro vs Máy") Navigator.push(context, MaterialPageRoute(builder: (context) => CaroScreen()));
                        else if (name == "Cờ tướng") Navigator.push(context, MaterialPageRoute(builder: (context) => XiangqiScreen()));
                        else if (name == "Bảng Xếp Hạng") Navigator.push(context, MaterialPageRoute(builder: (context) => LeaderboardScreen()));
                        else if (name == "Chat Room") Navigator.push(context, MaterialPageRoute(builder: (context) => ChatScreen(userName: widget.userName)));
                        else if (name == "Bạn bè") Navigator.push(context, MaterialPageRoute(builder: (context) => FriendScreen(currentUserId: widget.userId)));
                        else {
                          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Tính năng đang phát triển!")));
                        }
                      },
                      child: Container(
                        decoration: BoxDecoration(
                          // Nếu bảo trì thì nền xám, ngược lại nền trắng xám nhẹ
                          color: isMaintenance ? Colors.grey[300] : Colors.grey[100],
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: isMaintenance ? Colors.grey : Colors.blue.withOpacity(0.2)),
                          boxShadow: [
                            BoxShadow(color: Colors.black12, blurRadius: 5, offset: Offset(0, 3))
                          ],
                        ),
                        child: Stack(
                          children: [
                            // Nội dung Icon và Tên
                            Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                      uiGames[index]['icon'],
                                      size: 40,
                                      // Nếu bảo trì thì Icon màu xám
                                      color: isMaintenance ? Colors.grey : uiGames[index]['color']
                                  ),
                                  SizedBox(height: 10),
                                  Padding(
                                    padding: EdgeInsets.symmetric(horizontal: 8),
                                    child: FittedBox(
                                      fit: BoxFit.scaleDown,
                                      child: Text(
                                        name,
                                        style: TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.bold,
                                            color: isMaintenance ? Colors.grey[600] : Colors.black87
                                        ),
                                      ),
                                    ),
                                  )
                                ],
                              ),
                            ),

                            // Nhãn "BẢO TRÌ" đè lên trên góc
                            if (isMaintenance)
                              Positioned(
                                top: 10,
                                right: 10,
                                child: Container(
                                  padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                                      color: Colors.red,
                                      borderRadius: BorderRadius.circular(10)
                                  ),
                                  child: Text(
                                      "BẢO TRÌ",
                                      style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)
                                  ),
                                ),
                              )
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),

            // --- NÚT ĐĂNG XUẤT ---
            SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton.icon(
                onPressed: () {
                  showDialog(
                    context: context,
                    builder: (ctx) => AlertDialog(
                      title: Text("Đăng xuất"),
                      content: Text("Bạn có chắc chắn muốn đăng xuất không?"),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(ctx),
                          child: Text("Hủy"),
                        ),
                        TextButton(
                          onPressed: () {
                            Navigator.pop(ctx);
                            Navigator.pushReplacement(
                                context,
                                MaterialPageRoute(builder: (context) => LoginScreen())
                            );
                          },
                          child: Text("Đồng ý", style: TextStyle(color: Colors.red)),
                        ),
                      ],
                    ),
                  );
                },
                icon: Icon(Icons.logout, color: Colors.white),
                label: Text("Đăng xuất tài khoản", style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.redAccent,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
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