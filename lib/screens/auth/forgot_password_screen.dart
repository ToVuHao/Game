import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class ForgotPasswordScreen extends StatefulWidget {
  @override
  _ForgotPasswordScreenState createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  // Controller nhập liệu
  final TextEditingController _userController = TextEditingController();
  final TextEditingController _otpController = TextEditingController();

  // Trạng thái giao diện
  bool _isLoading = false;
  bool _isOtpSent = false; // False: Nhập Username, True: Nhập OTP

  // Cấu hình API
  final String baseUrl = "http://10.0.2.2:5231/api/auth";

  // --- HÀM 1: GỬI YÊU CẦU OTP ---
  Future<void> _sendOtp() async {
    if (_userController.text.isEmpty) {
      _showMessage("Vui lòng nhập tên tài khoản (Email)", Colors.orange);
      return;
    }

    setState(() => _isLoading = true);

    try {
      final response = await http.post(
        Uri.parse("$baseUrl/forgot-password"),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({"username": _userController.text}),
      );

      if (response.statusCode == 200) {
        _showMessage("Đã gửi mã OTP! Kiểm tra Email của bạn.", Colors.green);
        setState(() => _isOtpSent = true); // Chuyển sang giao diện nhập OTP
      } else {
        _showMessage("Lỗi: ${response.body}", Colors.red);
      }
    } catch (e) {
      _showMessage("Lỗi kết nối Server!", Colors.red);
    } finally {
      setState(() => _isLoading = false);
    }
  }

  // --- HÀM 2: XÁC THỰC OTP ---
  Future<void> _verifyOtp() async {
    if (_otpController.text.isEmpty) {
      _showMessage("Vui lòng nhập mã OTP", Colors.orange);
      return;
    }

    setState(() => _isLoading = true);

    try {
      final response = await http.post(
        Uri.parse("$baseUrl/verify-otp"),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "username": _userController.text,
          "otpCode": _otpController.text
        }),
      );

      if (response.statusCode == 200) {
        // OTP ĐÚNG -> Cho phép đổi mật khẩu (Hiện thông báo thành công)
        showDialog(
          context: context,
          builder: (ctx) => AlertDialog(
            title: Text("Thành công!"),
            content: Text("Mã OTP chính xác. Mật khẩu của bạn đã được xác minh."),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.pop(ctx); // Đóng Dialog
                  Navigator.pop(context); // Quay về màn hình đăng nhập
                },
                child: Text("Về trang Đăng nhập"),
              )
            ],
          ),
        );
      } else {
        _showMessage("Mã OTP không đúng hoặc đã hết hạn!", Colors.red);
      }
    } catch (e) {
      _showMessage("Lỗi kết nối!", Colors.red);
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
    return Scaffold(
      appBar: AppBar(
        title: Text("Quên mật khẩu"),
        backgroundColor: Colors.blueAccent,
      ),
      body: Padding(
        padding: EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.lock_reset, size: 80, color: Colors.blue),
            SizedBox(height: 20),

            // --- GIAO DIỆN THAY ĐỔI DỰA VÀO TRẠNG THÁI _isOtpSent ---
            if (!_isOtpSent) ...[
              // TRẠNG THÁI 1: NHẬP USERNAME
              Text(
                "Nhập tên tài khoản (Email) để nhận mã OTP",
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 16),
              ),
              SizedBox(height: 20),
              TextField(
                controller: _userController,
                decoration: InputDecoration(
                  labelText: "Tên đăng nhập / Email",
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.email),
                ),
              ),
              SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _sendOtp,
                  child: _isLoading
                      ? CircularProgressIndicator(color: Colors.white)
                      : Text("Gửi mã OTP"),
                ),
              ),
            ] else ...[
              // TRẠNG THÁI 2: NHẬP OTP
              Text(
                "Đã gửi mã đến ${_userController.text}.\nVui lòng nhập mã 6 số:",
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 20),
              TextField(
                controller: _otpController,
                keyboardType: TextInputType.number,
                maxLength: 6,
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 24, letterSpacing: 10),
                decoration: InputDecoration(
                  hintText: "______",
                  border: OutlineInputBorder(),
                ),
              ),
              SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _verifyOtp,
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
                  child: _isLoading
                      ? CircularProgressIndicator(color: Colors.white)
                      : Text("Xác nhận OTP"),
                ),
              ),
              TextButton(
                onPressed: () => setState(() => _isOtpSent = false),
                child: Text("Gửi lại mã?"),
              )
            ]
          ],
        ),
      ),
    );
  }
}