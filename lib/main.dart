import 'package:flutter/material.dart';
import 'package:jawda_sales/screens/home_screen.dart';
import 'package:jawda_sales/screens/login_screen.dart';
import 'package:jawda_sales/core/services/auth_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final token = await AuthService.getToken();
  final isLoggedIn = token != null && token.isNotEmpty;

  runApp(MyApp(isLoggedIn: isLoggedIn));
}

class MyApp extends StatelessWidget {
  final bool isLoggedIn;
  const MyApp({super.key, required this.isLoggedIn});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: isLoggedIn ? const HomeScreen() : const LoginScreen(),
    );
  }
}
