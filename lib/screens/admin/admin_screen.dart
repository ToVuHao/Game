import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../auth/login_screen.dart';

class AdminScreen extends StatefulWidget {
  @override
  _AdminScreenState createState() => _AdminScreenState();
}

class _AdminScreenState extends State<AdminScreen> {
  final String apiUrl = "http://10.0.2.2:5231/api/users";
  List<dynamic> users = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    fetchUsers();
  }

  // --- 1. API: LẤY DANH SÁCH ---
  Future<void> fetchUsers() async {
    setState(() => isLoading = true);
    try {
      final response = await http.get(Uri.parse(apiUrl));
      if (response.statusCode == 200) {
        setState(() {
          users = jsonDecode(response.body);
          isLoading = false;
        });
      }
    } catch (e) {
      print("Lỗi: $e");
      setState(() => isLoading = false);
    }
  }

  // --- 2. API: XÓA USER ---
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
      final response = await http.delete(Uri.parse("$apiUrl/$id"));
      if (response.statusCode == 200) {
        fetchUsers();
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Đã xóa thành công!")));
      }
    }
  }

  // --- 3. API: THÊM / SỬA USER ---
  // Nếu user == null nghĩa là Thêm mới, ngược lại là Sửa
  Future<void> showUserDialog({Map<String, dynamic>? user}) async {
    final isEdit = user != null;
    final nameController = TextEditingController(text: isEdit ? user['fullName'] : "");
    final usernameController = TextEditingController(text: isEdit ? user['username'] : "");
    final passController = TextEditingController(text: isEdit ? user['password'] : "");
    String selectedRole = isEdit ? (user['role'] ?? "user") : "user";

    await showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder( // Để cập nhật lại Dropdown trong Dialog
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
                      enabled: !isEdit, // Không cho sửa tên đăng nhập nếu đang edit
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
                    DropdownButtonFormField<String>(
                      value: selectedRole,
                      decoration: InputDecoration(labelText: "Vai trò"),
                      items: [
                        DropdownMenuItem(value: "user", child: Text("Tài khoản người chơi")),
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
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text("Hủy"),
                ),
                ElevatedButton(
                  onPressed: () async {
                    Navigator.pop(context); // Đóng Dialog
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

  // Hàm gọi API Lưu
  Future<void> _saveUser({int? id, required String username, required String pass, required String name, required String role, required bool isEdit}) async {
    try {
      if (username.isEmpty || pass.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Vui lòng nhập đủ thông tin!")));
        return;
      }

      http.Response response;
      Map<String, dynamic> body = {
        "username": username,
        "password": pass,
        "fullName": name,
        "role": role
      };

      if (isEdit) {
        // Gọi API Sửa (PUT)
        body["id"] = id; // Thêm ID vào body cho chắc
        response = await http.put(
            Uri.parse("$apiUrl/$id"),
            headers: {"Content-Type": "application/json"},
            body: jsonEncode(body)
        );
      } else {
        // Gọi API Thêm (POST)
        response = await http.post(
            Uri.parse(apiUrl),
            headers: {"Content-Type": "application/json"},
            body: jsonEncode(body)
        );
      }

      if (response.statusCode == 200 || response.statusCode == 201) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(isEdit ? "Cập nhật thành công!" : "Thêm mới thành công!")));
        fetchUsers(); // Tải lại danh sách
      } else {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Lỗi: ${response.body}")));
      }
    } catch (e) {
      print("Lỗi lưu user: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Quản trị viên"),
        backgroundColor: Colors.redAccent,
        actions: [
          // NÚT THÊM MỚI TRÊN APPBAR
          IconButton(
            icon: Icon(Icons.add_circle, size: 30),
            onPressed: () => showUserDialog(), // Gọi hàm không tham số -> Thêm mới
          ),
          SizedBox(width: 10),
          IconButton(
            icon: Icon(Icons.logout),
            onPressed: () {
              Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => LoginScreen()));
            },
          )
        ],
      ),
      body: isLoading
          ? Center(child: CircularProgressIndicator())
          : users.isEmpty
          ? Center(child: Text("Chưa có người dùng nào"))
          : ListView.builder(
        itemCount: users.length,
        itemBuilder: (context, index) {
          final user = users[index];
          bool isAdmin = user['role'] == 'admin';
          String roleDisplay = isAdmin ? "Quản trị viên" : "Tài khoản người chơi";

          return Card(
            margin: EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            elevation: 3,
            child: ListTile(
              leading: CircleAvatar(
                backgroundColor: isAdmin ? Colors.red : Colors.blue,
                child: Icon(isAdmin ? Icons.admin_panel_settings : Icons.person, color: Colors.white),
              ),
              title: Text(user['fullName'] ?? "No Name", style: TextStyle(fontWeight: FontWeight.bold)),
              subtitle: Text("User: ${user['username']} | Vai trò: $roleDisplay"),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // NÚT SỬA (Màu xanh)
                  IconButton(
                    icon: Icon(Icons.edit, color: Colors.blue),
                    onPressed: () => showUserDialog(user: user), // Truyền user vào -> Chế độ Sửa
                  ),
                  // NÚT XÓA (Màu đỏ)
                  if (!isAdmin) // Không cho xóa admin (tùy chọn)
                    IconButton(
                      icon: Icon(Icons.delete, color: Colors.red),
                      onPressed: () => deleteUser(user['id']),
                    ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}