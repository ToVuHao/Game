import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class FriendScreen extends StatefulWidget {
  final int currentUserId; // ID người đang đăng nhập

  FriendScreen({required this.currentUserId});

  @override
  _FriendScreenState createState() => _FriendScreenState();
}

class _FriendScreenState extends State<FriendScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final String baseUrl = "http://10.0.2.2:5231/api/friends"; // Sửa port nếu khác

  List<dynamic> myFriends = [];
  List<dynamic> pendingRequests = [];
  List<dynamic> strangers = []; // Danh sách người lạ để kết bạn

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadAllData();
  }

  void _loadAllData() {
    fetchFriends();
    fetchRequests();
    fetchStrangers();
  }

  // --- API CALLS ---
  Future<void> fetchFriends() async {
    final res = await http.get(Uri.parse("$baseUrl/list/${widget.currentUserId}"));
    if (res.statusCode == 200) setState(() => myFriends = jsonDecode(res.body));
  }

  Future<void> fetchRequests() async {
    final res = await http.get(Uri.parse("$baseUrl/requests/${widget.currentUserId}"));
    if (res.statusCode == 200) setState(() => pendingRequests = jsonDecode(res.body));
  }

  Future<void> fetchStrangers() async {
    final res = await http.get(Uri.parse("$baseUrl/find/${widget.currentUserId}"));
    if (res.statusCode == 200) setState(() => strangers = jsonDecode(res.body));
  }

  Future<void> sendRequest(int receiverId) async {
    final res = await http.post(
      Uri.parse("$baseUrl/send"),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({"senderId": widget.currentUserId, "receiverId": receiverId}),
    );
    if (res.statusCode == 200) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Đã gửi lời mời!")));
      fetchStrangers(); // Load lại để ẩn nút hoặc cập nhật UI
    }
  }

  Future<void> acceptRequest(int friendshipId) async {
    final res = await http.post(Uri.parse("$baseUrl/accept/$friendshipId"));
    if (res.statusCode == 200) {
      fetchRequests();
      fetchFriends();
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Đã chấp nhận kết bạn!"), backgroundColor: Colors.green));
    }
  }

  Future<void> deleteFriendship(int friendshipId) async {
    final res = await http.delete(Uri.parse("$baseUrl/$friendshipId"));
    if (res.statusCode == 200) {
      _loadAllData();
    }
  }

  // --- UI ---
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Bạn Bè"),
        bottom: TabBar(
          controller: _tabController,
          tabs: [
            Tab(text: "Bạn bè", icon: Icon(Icons.people)),
            Tab(text: "Lời mời", icon: Icon(Icons.notifications)),
            Tab(text: "Tìm bạn", icon: Icon(Icons.person_add)),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          // TAB 1: DANH SÁCH BẠN BÈ
          myFriends.isEmpty
              ? Center(child: Text("Chưa có bạn bè nào"))
              : ListView.builder(
            itemCount: myFriends.length,
            itemBuilder: (ctx, i) {
              final f = myFriends[i];
              return Card(
                child: ListTile(
                  leading: CircleAvatar(child: Text(f['friendName'][0])),
                  title: Text(f['friendName']),
                  subtitle: Text("@${f['friendUsername']}"),
                  trailing: IconButton(
                    icon: Icon(Icons.person_remove, color: Colors.red),
                    onPressed: () => deleteFriendship(f['friendshipId']),
                  ),
                ),
              );
            },
          ),

          // TAB 2: LỜI MỜI KẾT BẠN
          pendingRequests.isEmpty
              ? Center(child: Text("Không có lời mời nào"))
              : ListView.builder(
            itemCount: pendingRequests.length,
            itemBuilder: (ctx, i) {
              final req = pendingRequests[i];
              return Card(
                child: ListTile(
                  leading: Icon(Icons.waving_hand, color: Colors.orange),
                  title: Text("${req['senderName']} muốn kết bạn"),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: Icon(Icons.check_circle, color: Colors.green, size: 30),
                        onPressed: () => acceptRequest(req['friendshipId']),
                      ),
                      IconButton(
                        icon: Icon(Icons.cancel, color: Colors.red),
                        onPressed: () => deleteFriendship(req['friendshipId']),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),

          // TAB 3: TÌM BẠN (GỬI LỜI MỜI)
          strangers.isEmpty
              ? Center(child: Text("Không tìm thấy ai"))
              : ListView.builder(
            itemCount: strangers.length,
            itemBuilder: (ctx, i) {
              final u = strangers[i];
              // Kiểm tra xem đã là bạn chưa (Logic đơn giản ở Frontend, tốt nhất nên check ở Backend)
              bool isFriend = myFriends.any((f) => f['friendId'] == u['id']);

              if (isFriend) return SizedBox(); // Ẩn nếu đã là bạn

              return Card(
                child: ListTile(
                  leading: CircleAvatar(backgroundColor: Colors.blue[100], child: Icon(Icons.person)),
                  title: Text(u['fullName']),
                  subtitle: Text("@${u['username']}"),
                  trailing: ElevatedButton.icon(
                    onPressed: () => sendRequest(u['id']),
                    icon: Icon(Icons.add, size: 18),
                    label: Text("Kết bạn"),
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.blueAccent, foregroundColor: Colors.white),
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}