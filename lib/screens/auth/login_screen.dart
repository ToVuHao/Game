import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../home/home_screen.dart';
import '../admin/admin_screen.dart';
import 'forgot_password_screen.dart';

class LoginScreen extends StatefulWidget {
  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController _userController = TextEditingController();
  final TextEditingController _passController = TextEditingController();
  bool _isLoading = false;
  bool _isLoginMode = true;
  bool _obscureText = true;

  // Cấu hình Server
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
          "fullName": _isLoginMode ? "" : "Tài khoản người chơi"
        }),
      );

      if (response.statusCode == 200) {
        if (_isLoginMode) {
          final data = jsonDecode(response.body);

          // --- CẬP NHẬT QUAN TRỌNG: LẤY userId ---
          String fullName = data['fullName'] ?? "User";
          String role = data['role'] ?? "user";
          int userId = data['userId'] ?? 0; // Lấy ID từ server trả về

          _showMessage("Đăng nhập thành công!", Colors.green);

          if (role == 'admin') {
            Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (context) => AdminScreen())
            );
          } else {
            // Truyền userId sang Home để dùng cho tính năng Kết bạn/Chat
            Navigator.pushReplacement(
                context,
                MaterialPageRoute(
                    builder: (context) => HomeScreen(userName: fullName, userId: userId)
                )
            );
          }
          // ----------------------------------------

        } else {
          _showMessage("Đăng ký thành công! Mời đăng nhập.", Colors.green);
          setState(() => _isLoginMode = true);
        }
      } else {
        _showMessage("Thất bại: ${response.body}", Colors.redAccent);
      }
    } catch (e) {
      print("Login Error: $e");
      _showMessage("Lỗi kết nối Server!", Colors.redAccent);
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _showMessage(String msg, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Colors.blue.shade900, Colors.blue.shade400, Colors.blue.shade200],
          ),
        ),
        child: Center(
          child: SingleChildScrollView(
            padding: EdgeInsets.symmetric(horizontal: 30),
            child: Column(
              children: [
                Container(
                  padding: EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(Icons.gamepad_rounded, size: 80, color: Colors.white),
                ),
                SizedBox(height: 20),
                Text(
                  _isLoginMode ? "WELCOME BACK" : "CREATE ACCOUNT",
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    letterSpacing: 1.5,
                  ),
                ),
                SizedBox(height: 40),

                Container(
                  padding: EdgeInsets.all(25),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(30),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black26,
                        blurRadius: 15,
                        offset: Offset(0, 10),
                      )
                    ],
                  ),
                  child: Column(
                    children: [
                      _buildTextField(
                        controller: _userController,
                        label: "Tên đăng nhập / Email",
                        icon: Icons.person_outline,
                      ),
                      SizedBox(height: 20),
                      _buildTextField(
                        controller: _passController,
                        label: "Mật khẩu",
                        icon: Icons.lock_outline,
                        isPassword: true,
                      ),

                      if (_isLoginMode)
                        Align(
                          alignment: Alignment.centerRight,
                          child: TextButton(
                            onPressed: () {
                              Navigator.push(
                                  context,
                                  MaterialPageRoute(builder: (context) => ForgotPasswordScreen())
                              );
                            },
                            child: Text(
                                "Quên mật khẩu?",
                                style: TextStyle(color: Colors.blue.shade700, fontWeight: FontWeight.bold)
                            ),
                          ),
                        ),

                      SizedBox(height: _isLoginMode ? 10 : 30),

                      SizedBox(
                        width: double.infinity,
                        height: 55,
                        child: ElevatedButton(
                          onPressed: _isLoading ? null : _submitAuth,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.blue.shade700,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(15),
                            ),
                            elevation: 5,
                          ),
                          child: _isLoading
                              ? CircularProgressIndicator(color: Colors.white)
                              : Text(
                            _isLoginMode ? "ĐĂNG NHẬP" : "ĐĂNG KÝ",
                            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                SizedBox(height: 20),
                TextButton(
                  onPressed: () => setState(() => _isLoginMode = !_isLoginMode),
                  child: Text(
                    _isLoginMode ? "Chưa có tài khoản? Đăng ký ngay" : "Đã có tài khoản? Đăng nhập",
                    style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w500),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    bool isPassword = false,
  }) {
    return TextFormField(
      controller: controller,
      obscureText: isPassword ? _obscureText : false,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: Colors.blue.shade700),
        suffixIcon: isPassword
            ? IconButton(
          icon: Icon(_obscureText ? Icons.visibility : Icons.visibility_off),
          onPressed: () => setState(() => _obscureText = !_obscureText),
        )
            : null,
        filled: true,
        fillColor: Colors.grey.shade100,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15),
          borderSide: BorderSide(color: Colors.transparent),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15),
          borderSide: BorderSide(color: Colors.blue.shade700, width: 2),
        ),
      ),
    );
  }
}