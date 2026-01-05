import 'package:flutter/material.dart';
// import 'pages/login.dart';
import 'pages/homePage.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});
   
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark().copyWith(
        scaffoldBackgroundColor: const Color(0xFF080E22),
        primaryColor: const Color(0xFF1E88E5),
      ),
      home: const HomePage(),
    );
  }
}
