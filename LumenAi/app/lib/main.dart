import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'pages/login.dart';
import 'pages/homePage.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  await Supabase.initialize(
    url: 'https://knonzasojytvmxhkchvg.supabase.co',
    anonKey: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Imtub256YXNvanl0dm14aGtjaHZnIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NjY2NTU4NTIsImV4cCI6MjA4MjIzMTg1Mn0.WnxSictcwfY-1xBH8pHGVczR2BO_ArddpQpR4yCgc-I',
  );
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
      home: const LoginPage(),
    );
  }
}
