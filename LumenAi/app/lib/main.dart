<<<<<<< HEAD
=======
import 'package:app/pages/account_page.dart';
import 'package:app/pages/login.dart';
import 'package:app/pages/splash_page.dart';
>>>>>>> b7afa2d4d215c06b389ab8d0721c0625938e24ee
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
// import 'pages/login.dart';
// import 'pages/register.dart';
import 'pages/homePage.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  await Supabase.initialize(
    url: 'https://yydgvgxczxecfslbrdtj.supabase.co',
    anonKey: 'sb_publishable_dCLTLfWXSK3f-WL2DxpDzA_M4ZlH4cb',
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
        scaffoldBackgroundColor: const Color(0xFF080E22),
        primaryColor: const Color(0xFF1E88E5),
      ),
<<<<<<< HEAD
      home: const HomePage(),
=======
      // home: const LoginPage(),
      initialRoute: '/',
      routes: {
        '/' : (context) => const SplashPage(),
        '/login': (context) => const LoginPage(),
        'account': (context) => const AccountPage(),
      },
>>>>>>> b7afa2d4d215c06b389ab8d0721c0625938e24ee
    );
  }
}
