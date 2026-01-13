import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class ForgotPasswordScreen extends StatefulWidget {
  @override
  _ForgotPasswordScreenState createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  // Controller
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _otpController = TextEditingController();
  final TextEditingController _newPassController = TextEditingController(); // Nhập pass mới

  int _step = 1; // 1: Nhập Email, 2: Nhập OTP, 3: Nhập Pass Mới
  bool _isLoading = false;
  bool _obscureText = true; // Ẩn hiện pass

  final String baseUrl = "http://10.0.2.2:5231/api/auth";

  // --- BƯỚC 1: GỬI OTP (Đã sửa key thành 'username') ---
  Future<void> _sendOtp() async {
    if (_emailController.text.isEmpty) {
      _showMessage("Vui lòng nhập Email!", Colors.orange);
      return;
    }
    setState(() => _isLoading = true);
    try {
      final res = await http.post(
        Uri.parse("$baseUrl/forgot-password"),
        headers: {"Content-Type": "application/json"},
        // SỬA: Dùng "username" thay vì "email" để khớp với Backend DTO
        body: jsonEncode({"username": _emailController.text}),
      );

      if (res.statusCode == 200) {
        _showMessage("Đã gửi OTP qua Email!", Colors.green);
        setState(() => _step = 2); // Chuyển sang bước nhập OTP
      } else {
        _showMessage("Lỗi: ${res.body}", Colors.red);
      }
    } catch (e) {
      _showMessage("Lỗi kết nối!", Colors.red);
    } finally {
      setState(() => _isLoading = false);
    }
  }

  // --- BƯỚC 2: XÁC THỰC OTP (Đã sửa key thành 'username') ---
  Future<void> _verifyOtp() async {
    if (_otpController.text.isEmpty) return;
    setState(() => _isLoading = true);
    try {
      final res = await http.post(
        Uri.parse("$baseUrl/verify-otp"),
        headers: {"Content-Type": "application/json"},
        // SỬA: Dùng "username" thay vì "email"
        body: jsonEncode({
          "username": _emailController.text,
          "otpCode": _otpController.text
        }),
      );

      if (res.statusCode == 200) {
        _showMessage("OTP Chính xác! Mời nhập mật khẩu mới.", Colors.green);
        setState(() => _step = 3); // Chuyển sang bước Đổi mật khẩu
      } else {
        _showMessage("Mã OTP sai hoặc hết hạn!", Colors.red);
      }
    } catch (e) {
      _showMessage("Lỗi kết nối!", Colors.red);
    } finally {
      setState(() => _isLoading = false);
    }
  }

  // --- BƯỚC 3: ĐỔI MẬT KHẨU MỚI (Giữ nguyên 'email') ---
  Future<void> _resetPassword() async {
    if (_newPassController.text.isEmpty) {
      _showMessage("Vui lòng nhập mật khẩu mới!", Colors.orange);
      return;
    }

    setState(() => _isLoading = true);
    try {
      final res = await http.post(
        Uri.parse("$baseUrl/reset-password"),
        headers: {"Content-Type": "application/json"},
        // Lưu ý: Backend API reset-password dùng "email" nên chỗ này giữ nguyên
        body: jsonEncode({
          "email": _emailController.text,
          "newPassword": _newPassController.text
        }),
      );

      if (res.statusCode == 200) {
        _showMessage("Đổi mật khẩu thành công! Hãy đăng nhập lại.", Colors.green);
        Navigator.pop(context); // Quay về màn hình Login
      } else {
        _showMessage("Lỗi: ${res.body}", Colors.red);
      }
    } catch (e) {
      _showMessage("Lỗi kết nối!", Colors.red);
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _showMessage(String msg, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg), backgroundColor: color));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Quên mật khẩu"),
        backgroundColor: Colors.blue.shade900,
        foregroundColor: Colors.white,
      ),
      body: Container(
        padding: EdgeInsets.all(25),
        width: double.infinity,
        height: double.infinity,
        decoration: BoxDecoration(
            gradient: LinearGradient(
                colors: [Colors.blue.shade900, Colors.blue.shade400],
                begin: Alignment.topCenter, end: Alignment.bottomCenter
            )
        ),
        child: Column(
          children: [
            Icon(Icons.lock_reset, size: 80, color: Colors.white),
            SizedBox(height: 20),

            // Card chứa nội dung thay đổi theo từng bước
            Container(
              padding: EdgeInsets.all(20),
              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20)),
              child: Column(
                children: [
                  if (_step == 1) ...[
                    Text("Bước 1: Nhập Email", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    SizedBox(height: 15),
                    TextField(
                      controller: _emailController,
                      decoration: InputDecoration(labelText: "Email đăng ký", prefixIcon: Icon(Icons.email), border: OutlineInputBorder(borderRadius: BorderRadius.circular(10))),
                    ),
                    SizedBox(height: 20),
                    SizedBox(width: double.infinity, child: ElevatedButton(onPressed: _isLoading ? null : _sendOtp, child: _isLoading ? CircularProgressIndicator() : Text("Gửi mã OTP"))),

                  ] else if (_step == 2) ...[
                    Text("Bước 2: Nhập OTP", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    SizedBox(height: 10),
                    Text("Mã đã gửi đến: ${_emailController.text}", style: TextStyle(color: Colors.grey)),
                    SizedBox(height: 15),
                    TextField(
                      controller: _otpController,
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(labelText: "Mã OTP (6 số)", prefixIcon: Icon(Icons.security), border: OutlineInputBorder(borderRadius: BorderRadius.circular(10))),
                    ),
                    SizedBox(height: 20),
                    SizedBox(width: double.infinity, child: ElevatedButton(onPressed: _isLoading ? null : _verifyOtp, child: _isLoading ? CircularProgressIndicator() : Text("Xác thực OTP"))),

                  ] else ...[
                    // --- BƯỚC 3: GIAO DIỆN ĐỔI MẬT KHẨU MỚI ---
                    Text("Bước 3: Mật khẩu mới", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    SizedBox(height: 15),
                    TextField(
                      controller: _newPassController,
                      obscureText: _obscureText,
                      decoration: InputDecoration(
                          labelText: "Nhập mật khẩu mới",
                          prefixIcon: Icon(Icons.lock),
                          suffixIcon: IconButton(icon: Icon(_obscureText ? Icons.visibility : Icons.visibility_off), onPressed: () => setState(() => _obscureText = !_obscureText)),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10))
                      ),
                    ),
                    SizedBox(height: 20),
                    SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                            onPressed: _isLoading ? null : _resetPassword,
                            style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
                            child: _isLoading ? CircularProgressIndicator() : Text("Lưu Mật Khẩu Mới", style: TextStyle(color: Colors.white))
                        )
                    ),
                  ]
                ],
              ),
            )
          ],
        ),
      ),
    );
  }
}