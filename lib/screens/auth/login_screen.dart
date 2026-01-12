import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../home/home_screen.dart';
import '../admin/admin_screen.dart';

class LoginScreen extends StatefulWidget {
  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController _userController = TextEditingController();
  final TextEditingController _passController = TextEditingController();
  bool _isLoading = false;
  bool _isLoginMode = true;

  final String baseUrl = "http://10.0.2.2:5231/api/auth";

  Future<void> _submitAuth() async {
    if (_userController.text.isEmpty || _passController.text.isEmpty) {
      _showMessage("Vui lòng nhập tài khoản và mật khẩu", Colors.orange);
      return;
    }

    setState(() => _isLoading = true);

    final endpoint = _isLoginMode ? "/login" : "/register";
    final url = Uri.parse(baseUrl + endpoint);

    try {
      final response = await http.post(
        url,
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "username": _userController.text,
          "password": _passController.text,
          // --- SỬA Ở ĐÂY: Đổi tên mặc định ---
          "fullName": _isLoginMode ? "" : "Tài khoản người chơi"
          // ----------------------------------
        }),
      );

      if (response.statusCode == 200) {
        if (_isLoginMode) {
          final data = jsonDecode(response.body);
          String fullName = data['fullName'] ?? "User";
          String role = data['role'] ?? "user";

          _showMessage("Đăng nhập thành công!", Colors.green);

          if (role == 'admin') {
            Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (context) => AdminScreen())
            );
          } else {
            Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (context) => HomeScreen(userName: fullName))
            );
          }
        } else {
          _showMessage("Đăng ký thành công! Mời đăng nhập.", Colors.green);
          setState(() => _isLoginMode = true);
        }
      } else {
        _showMessage("Thất bại: ${response.body}", Colors.red);
      }
    } catch (e) {
      print("Lỗi kết nối: $e");
      _showMessage("Lỗi kết nối Server!", Colors.red);
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _showMessage(String msg, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), backgroundColor: color),
    );
  }

  @override
  Widget build(BuildContext context) {
    // ... (Giữ nguyên phần giao diện bên dưới của bạn)
    return Scaffold(
      backgroundColor: Colors.blue.shade50,
      body: Center(
        child: SingleChildScrollView(
          padding: EdgeInsets.all(24),
          child: Card(
            elevation: 8,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            child: Padding(
              padding: EdgeInsets.all(30),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.gamepad_rounded, size: 80, color: Colors.blueAccent),
                  SizedBox(height: 10),
                  Text(
                    "GAME APP",
                    style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.blue[900]),
                  ),
                  SizedBox(height: 30),
                  TextField(
                    controller: _userController,
                    decoration: InputDecoration(
                      labelText: "Tên đăng nhập",
                      prefixIcon: Icon(Icons.person),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                  ),
                  SizedBox(height: 15),
                  TextField(
                    controller: _passController,
                    obscureText: true,
                    decoration: InputDecoration(
                      labelText: "Mật khẩu",
                      prefixIcon: Icon(Icons.lock),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                  ),
                  SizedBox(height: 25),
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _submitAuth,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blueAccent,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                      child: _isLoading
                          ? CircularProgressIndicator(color: Colors.white)
                          : Text(
                        _isLoginMode ? "ĐĂNG NHẬP" : "ĐĂNG KÝ",
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
                      ),
                    ),
                  ),
                  SizedBox(height: 15),
                  TextButton(
                    onPressed: () => setState(() => _isLoginMode = !_isLoginMode),
                    child: Text(
                      _isLoginMode ? "Chưa có tài khoản? Đăng ký ngay" : "Đã có tài khoản? Đăng nhập",
                      style: TextStyle(fontSize: 16, color: Colors.blue[800]),
                    ),
                  )
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}