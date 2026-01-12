import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

// --- SỬA ĐƯỜNG DẪN IMPORT Ở ĐÂY ---
// Thay vì 'login_screen.dart', phải trỏ vào thư mục screens/auth/
import 'screens/auth/login_screen.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false, // Tắt chữ DEBUG góc phải
      title: 'Game App',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        // Cài font Google đẹp hơn (nếu đã thêm thư viện google_fonts)
        textTheme: GoogleFonts.robotoTextTheme(
          Theme.of(context).textTheme,
        ),
      ),
      home: LoginScreen(), // Gọi màn hình đăng nhập
    );
  }
}