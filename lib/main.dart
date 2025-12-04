import 'package:flutter/material.dart';
import 'package:jawda_sales/screens/dashboard_screen.dart';
import 'package:jawda_sales/screens/home_screen.dart';
import 'package:jawda_sales/screens/login_screen.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      
      home: HomeScreen(),
    );
      
      
     
}}
