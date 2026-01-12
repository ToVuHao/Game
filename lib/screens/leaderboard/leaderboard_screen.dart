import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class LeaderboardScreen extends StatefulWidget {
  @override
  _LeaderboardScreenState createState() => _LeaderboardScreenState();
}

class _LeaderboardScreenState extends State<LeaderboardScreen> {
  // Danh sách các game có trong hệ thống
  final List<String> gameList = ["Sudoku", "Cờ tướng", "Xếp hình", "Caro vs Máy"];

  String selectedGame = "Sudoku"; // Game mặc định được chọn
  List<dynamic> rankings = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    fetchRankings();
  }

  // Gọi API lấy dữ liệu
  Future<void> fetchRankings() async {
    setState(() => isLoading = true);

    // Cổng 5231
    final String url = "http://10.0.2.2:5231/api/leaderboard?gameName=$selectedGame";

    try {
      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        setState(() {
          rankings = jsonDecode(response.body);
          isLoading = false;
        });
      }
    } catch (e) {
      print("Lỗi: $e");
      setState(() => isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Bảng Xếp Hạng"),
        backgroundColor: Colors.amber[700],
      ),
      body: Column(
        children: [
          // --- PHẦN 1: MENU CHỌN GAME ---
          Container(
            padding: EdgeInsets.all(16),
            color: Colors.amber[50],
            child: Row(
              children: [
                Icon(Icons.emoji_events, color: Colors.amber[800], size: 30),
                SizedBox(width: 15),
                Expanded(
                  child: Container(
                    padding: EdgeInsets.symmetric(horizontal: 12),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.amber),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        value: selectedGame,
                        isExpanded: true,
                        items: gameList.map((String game) {
                          return DropdownMenuItem<String>(
                            value: game,
                            child: Text(game, style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                          );
                        }).toList(),
                        onChanged: (String? newValue) {
                          if (newValue != null) {
                            setState(() {
                              selectedGame = newValue;
                            });
                            fetchRankings(); // Tải lại dữ liệu khi đổi game
                          }
                        },
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // --- PHẦN 2: DANH SÁCH XẾP HẠNG ---
          Expanded(
            child: isLoading
                ? Center(child: CircularProgressIndicator())
                : ListView.builder(
              itemCount: rankings.length,
              itemBuilder: (context, index) {
                final item = rankings[index];
                // Màu cho Top 3
                Color? rankColor;
                if (item['rank'] == 1) rankColor = Colors.yellow[700]; // Vàng
                else if (item['rank'] == 2) rankColor = Colors.grey[400]; // Bạc
                else if (item['rank'] == 3) rankColor = Colors.brown[300]; // Đồng
                else rankColor = Colors.white;

                return Card(
                  margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  elevation: 4,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: rankColor,
                      child: Text(
                        "#${item['rank']}",
                        style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
                      ),
                    ),
                    title: Text(
                      item['playerName'],
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                    ),
                    subtitle: Text("Ngày: ${item['date']}"),
                    trailing: Container(
                      padding: EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                          color: Colors.blue[50],
                          borderRadius: BorderRadius.circular(10)
                      ),
                      child: Text(
                        item['score'],
                        style: TextStyle(color: Colors.blue[800], fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}