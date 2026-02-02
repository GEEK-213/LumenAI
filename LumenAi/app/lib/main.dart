import 'package:app/pages/homePage.dart';
import 'package:app/pages/notes_page.dart';
import 'package:app/pages/splash_page.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'pages/login.dart';
import 'pages/profilePage.dart';
import 'pages/main_page.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Supabase.initialize(
    url: 'https://knonzasojytvmxhkchvg.supabase.co',
    anonKey:
        'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Imtub256YXNvanl0dm14aGtjaHZnIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NjY2NTU4NTIsImV4cCI6MjA4MjIzMTg1Mn0.WnxSictcwfY-1xBH8pHGVczR2BO_ArddpQpR4yCgc-I',
  );
  runApp(const MyApp());
}

final supabase = Supabase.instance.client;

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark().copyWith(
        scaffoldBackgroundColor: const Color(0xFF0C1223),
        primaryColor: const Color(0xFF1E88E5),
        colorScheme: const ColorScheme.dark(secondary: Color(0xFF1E88E5)),
      ),
      // home: const Profilepage(),
      initialRoute: '/',
      routes: {
        '/': (context) => const SplashPage(),
        '/login': (context) => const LoginPage(),
        '/main': (context) => const MainPage(),
        '/account': (context) => const Profilepage(),
      },
    );
  }
}
