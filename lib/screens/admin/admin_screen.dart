import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../auth/login_screen.dart';

class AdminScreen extends StatefulWidget {
  @override
  _AdminScreenState createState() => _AdminScreenState();
}

class _AdminScreenState extends State<AdminScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  // --- BIẾN CHO TAB QUẢN LÝ USER ---
  final String userApiUrl = "http://10.0.2.2:5231/api/users";
  List<dynamic> users = [];
  bool isLoadingUsers = true;

  // --- BIẾN CHO TAB QUẢN LÝ GAME ---
  final String gameApiUrl = "http://10.0.2.2:5231/api/games";
  List<dynamic> games = [];
  bool isLoadingGames = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    fetchUsers();
    fetchGames();
  }

  // ==========================================
  // PHẦN 1: QUẢN LÝ USER
  // ==========================================

  Future<void> fetchUsers() async {
    setState(() => isLoadingUsers = true);
    try {
      final response = await http.get(Uri.parse(userApiUrl));
      if (response.statusCode == 200) {
        setState(() {
          users = jsonDecode(response.body);
          isLoadingUsers = false;
        });
      }
    } catch (e) {
      print("Lỗi user: $e");
      setState(() => isLoadingUsers = false);
    }
  }

  Future<void> deleteUser(int id) async {
    bool confirm = await showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          title: Text("Xác nhận"),
          content: Text("Bạn có chắc muốn xóa người dùng này?"),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text("Hủy")),
            TextButton(onPressed: () => Navigator.pop(ctx, true), child: Text("Xóa", style: TextStyle(color: Colors.red))),
          ],
        )
    ) ?? false;

    if (confirm) {
      final response = await http.delete(Uri.parse("$userApiUrl/$id"));
      if (response.statusCode == 200) {
        fetchUsers();
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Đã xóa thành công!")));
      }
    }
  }

  // --- HÀM SHOW DIALOG (ĐÃ SỬA LỖI DROPDOWN) ---
  Future<void> showUserDialog({Map<String, dynamic>? user}) async {
    final isEdit = user != null;
    final nameController = TextEditingController(text: isEdit ? user['fullName'] : "");
    final usernameController = TextEditingController(text: isEdit ? user['username'] : "");
    final passController = TextEditingController(text: isEdit ? user['password'] : "");

    // --- KHẮC PHỤC LỖI CRASH ---
    // Lấy role gốc từ DB
    String rawRole = isEdit ? (user['role'] ?? "user") : "user";
    // Chuẩn hóa về chữ thường và cắt khoảng trắng.
    // Nếu không phải "admin" thì gán mặc định là "user" để khớp với Dropdown.
    String selectedRole = (rawRole.toLowerCase().trim() == "admin") ? "admin" : "user";
    // ----------------------------

    await showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setStateDialog) {
            return AlertDialog(
              title: Text(isEdit ? "Sửa thông tin" : "Thêm tài khoản mới"),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: usernameController,
                      decoration: InputDecoration(labelText: "Tên đăng nhập"),
                      enabled: !isEdit, // Không cho sửa username
                    ),
                    TextField(
                      controller: passController,
                      decoration: InputDecoration(labelText: "Mật khẩu"),
                    ),
                    TextField(
                      controller: nameController,
                      decoration: InputDecoration(labelText: "Tên hiển thị (Full Name)"),
                    ),
                    SizedBox(height: 15),

                    // Dropdown chọn quyền
                    DropdownButtonFormField<String>(
                      value: selectedRole, // Biến này giờ đã an toàn
                      decoration: InputDecoration(labelText: "Vai trò"),
                      items: [
                        DropdownMenuItem(value: "user", child: Text("Người chơi")),
                        DropdownMenuItem(value: "admin", child: Text("Quản trị viên")),
                      ],
                      onChanged: (val) {
                        setStateDialog(() => selectedRole = val!);
                      },
                    )
                  ],
                ),
              ),
              actions: [
                TextButton(onPressed: () => Navigator.pop(context), child: Text("Hủy")),
                ElevatedButton(
                  onPressed: () async {
                    Navigator.pop(context);
                    await _saveUser(
                        id: isEdit ? user['id'] : null,
                        username: usernameController.text,
                        pass: passController.text,
                        name: nameController.text,
                        role: selectedRole,
                        isEdit: isEdit
                    );
                  },
                  child: Text("Lưu"),
                )
              ],
            );
          },
        );
      },
    );
  }

  Future<void> _saveUser({int? id, required String username, required String pass, required String name, required String role, required bool isEdit}) async {
    try {
      if (username.isEmpty || pass.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Vui lòng nhập đủ thông tin!")));
        return;
      }
      Map<String, dynamic> body = {"username": username, "password": pass, "fullName": name, "role": role};
      http.Response response;

      if (isEdit) {
        body["id"] = id;
        response = await http.put(Uri.parse("$userApiUrl/$id"), headers: {"Content-Type": "application/json"}, body: jsonEncode(body));
      } else {
        response = await http.post(Uri.parse(userApiUrl), headers: {"Content-Type": "application/json"}, body: jsonEncode(body));
      }

      if (response.statusCode == 200 || response.statusCode == 201) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(isEdit ? "Cập nhật thành công!" : "Thêm mới thành công!")));
        fetchUsers();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Lỗi: ${response.body}")));
      }
    } catch (e) {
      print("Lỗi lưu user: $e");
    }
  }

  // ==========================================
  // PHẦN 2: QUẢN LÝ GAME
  // ==========================================

  Future<void> fetchGames() async {
    setState(() => isLoadingGames = true);
    try {
      final res = await http.get(Uri.parse(gameApiUrl));
      if (res.statusCode == 200) {
        setState(() {
          games = jsonDecode(res.body);
          isLoadingGames = false;
        });
      }
    } catch (e) {
      print("Lỗi tải game: $e");
      setState(() => isLoadingGames = false);
    }
  }

  Future<void> toggleGame(int id, bool currentValue) async {
    try {
      final res = await http.put(
        Uri.parse("$gameApiUrl/$id"),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode(!currentValue),
      );

      if (res.statusCode == 200) {
        fetchGames();
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Đã cập nhật trạng thái game!")));
      }
    } catch (e) {
      print("Lỗi cập nhật game: $e");
    }
  }

  // ==========================================
  // PHẦN 3: GIAO DIỆN CHÍNH
  // ==========================================
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Admin Panel"),
        backgroundColor: Colors.redAccent,
        bottom: TabBar(
          controller: _tabController,
          tabs: [
            Tab(icon: Icon(Icons.people), text: "Người dùng"),
            Tab(icon: Icon(Icons.videogame_asset), text: "Trò chơi"),
          ],
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.logout),
            onPressed: () => Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => LoginScreen())),
          )
        ],
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          // TAB 1: DANH SÁCH USER
          _buildUserTab(),

          // TAB 2: DANH SÁCH GAME
          _buildGameTab(),
        ],
      ),
      floatingActionButton: _tabController.index == 0
          ? FloatingActionButton(
        child: Icon(Icons.add),
        backgroundColor: Colors.redAccent,
        onPressed: () => showUserDialog(),
      )
          : null,
    );
  }

  Widget _buildUserTab() {
    if (isLoadingUsers) return Center(child: CircularProgressIndicator());
    if (users.isEmpty) return Center(child: Text("Chưa có người dùng nào"));

    return ListView.builder(
      itemCount: users.length,
      itemBuilder: (context, index) {
        final user = users[index];
        bool isAdmin = (user['role'] ?? "").toString().toLowerCase() == 'admin';
        return Card(
          margin: EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: isAdmin ? Colors.red : Colors.blue,
              child: Icon(isAdmin ? Icons.admin_panel_settings : Icons.person, color: Colors.white),
            ),
            title: Text(user['fullName'] ?? "No Name", style: TextStyle(fontWeight: FontWeight.bold)),
            subtitle: Text("User: ${user['username']} | Role: ${isAdmin ? 'Admin' : 'User'}"),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(icon: Icon(Icons.edit, color: Colors.blue), onPressed: () => showUserDialog(user: user)),
                if (!isAdmin)
                  IconButton(icon: Icon(Icons.delete, color: Colors.red), onPressed: () => deleteUser(user['id'])),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildGameTab() {
    if (isLoadingGames) return Center(child: CircularProgressIndicator());
    if (games.isEmpty) return Center(child: Text("Chưa có dữ liệu game"));

    return ListView.builder(
      padding: EdgeInsets.all(10),
      itemCount: games.length,
      itemBuilder: (context, index) {
        final game = games[index];
        return Card(
          color: game['isActive'] ? Colors.white : Colors.grey[200],
          child: SwitchListTile(
            title: Text(
              game['name'],
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: game['isActive'] ? Colors.black : Colors.red,
                decoration: game['isActive'] ? null : TextDecoration.lineThrough,
              ),
            ),
            subtitle: Text(game['isActive'] ? "Đang hoạt động" : "Đang bảo trì"),
            value: game['isActive'],
            activeColor: Colors.green,
            inactiveThumbColor: Colors.red,
            onChanged: (val) => toggleGame(game['id'], game['isActive']),
          ),
        );
      },
    );
  }
}