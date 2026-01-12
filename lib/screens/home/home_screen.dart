import 'package:flutter/material.dart';

// --- GAME (Nằm trong thư mục games) ---
import '../games/sudoku/sudoku_screen.dart';
import '../games/puzzle/puzzle_screen.dart';
import '../games/caro/caro_screen.dart';
import '../games/xiangqi/xiangqi_screen.dart';

// --- TÍNH NĂNG KHÁC ---
import '../leaderboard/leaderboard_screen.dart';
import '../chat/chat_screen.dart';
import '../social/friend_screen.dart'; // <--- MỚI: Import màn hình bạn bè
import '../auth/login_screen.dart';

class HomeScreen extends StatelessWidget {
  final String userName;
  final int userId; // <--- MỚI: Cần ID để xử lý kết bạn

  // Cập nhật Constructor nhận thêm userId
  HomeScreen({required this.userName, required this.userId});

  // Danh sách tính năng
  final List<Map<String, dynamic>> games = [
    {"name": "Cờ tướng", "icon": Icons.psychology, "color": Colors.brown},
    {"name": "Sudoku", "icon": Icons.grid_4x4, "color": Colors.green},
    {"name": "Xếp hình", "icon": Icons.extension, "color": Colors.purple},
    {"name": "Caro vs Máy", "icon": Icons.close, "color": Colors.red},
    {"name": "Bảng Xếp Hạng", "icon": Icons.emoji_events, "color": Colors.amber},
    {"name": "Chat Room", "icon": Icons.chat, "color": Colors.blue},
    {"name": "Bạn bè", "icon": Icons.people_alt_rounded, "color": Colors.pinkAccent}, // <--- MỚI
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("Xin chào, $userName!", style: TextStyle(fontSize: 18)),
            Text("ID: $userId", style: TextStyle(fontSize: 12, color: Colors.white70)),
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
              child: GridView.builder(
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: 16,
                  mainAxisSpacing: 16,
                  childAspectRatio: 1.2,
                ),
                itemCount: games.length,
                itemBuilder: (context, index) {
                  return InkWell(
                    onTap: () {
                      String gameName = games[index]['name'];

                      // Điều hướng
                      if (gameName == "Sudoku") {
                        Navigator.push(context, MaterialPageRoute(builder: (context) => SudokuScreen()));
                      } else if (gameName == "Xếp hình") {
                        Navigator.push(context, MaterialPageRoute(builder: (context) => PuzzleScreen()));
                      } else if (gameName == "Caro vs Máy") {
                        Navigator.push(context, MaterialPageRoute(builder: (context) => CaroScreen()));
                      } else if (gameName == "Cờ tướng") {
                        Navigator.push(context, MaterialPageRoute(builder: (context) => XiangqiScreen()));
                      } else if (gameName == "Bảng Xếp Hạng") {
                        Navigator.push(context, MaterialPageRoute(builder: (context) => LeaderboardScreen()));
                      } else if (gameName == "Chat Room") {
                        Navigator.push(context, MaterialPageRoute(builder: (context) => ChatScreen(userName: userName)));
                      } else if (gameName == "Bạn bè") {
                        // --- MỚI: Chuyển sang màn hình bạn bè kèm ID ---
                        Navigator.push(context, MaterialPageRoute(builder: (context) => FriendScreen(currentUserId: userId)));
                      } else {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text("Tính năng $gameName đang phát triển!")),
                        );
                      }
                    },
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.grey[100],
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: Colors.blue.withOpacity(0.2)),
                        boxShadow: [
                          BoxShadow(color: Colors.black12, blurRadius: 5, offset: Offset(0, 3))
                        ],
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(games[index]['icon'], size: 40, color: games[index]['color']),
                          SizedBox(height: 10),
                          Padding(
                            padding: EdgeInsets.symmetric(horizontal: 8),
                            child: FittedBox(
                              fit: BoxFit.scaleDown,
                              child: Text(
                                games[index]['name'],
                                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black87),
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