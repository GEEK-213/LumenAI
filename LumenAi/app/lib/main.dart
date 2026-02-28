import 'dart:async';
import 'package:app_links/app_links.dart';
import 'package:app/pages/profile/splash_page.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'pages/profile/login.dart';
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

final GlobalKey<ScaffoldMessengerState> scaffoldMessengerKey =
    GlobalKey<ScaffoldMessengerState>();

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  late AppLinks _appLinks;
  StreamSubscription<Uri>? _linkSubscription;

  @override
  void initState() {
    super.initState();
    _initDeepLinks();
  }

  void _initDeepLinks() {
    _appLinks = AppLinks();
    _linkSubscription = _appLinks.uriLinkStream.listen((uri) {
      if (uri.scheme == 'lumenai' && uri.host == 'classroom-success') {
        scaffoldMessengerKey.currentState?.showSnackBar(
          const SnackBar(
            content: Text('Successfully connected to Google Classroom! 📚'),
            backgroundColor: Colors.green,
          ),
        );
      }
    });
  }

  @override
  void dispose() {
    _linkSubscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      scaffoldMessengerKey: scaffoldMessengerKey,
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark().copyWith(
        scaffoldBackgroundColor: const Color(0xFF0C1223),
        primaryColor: const Color(0xFF1E88E5),
        colorScheme: const ColorScheme.dark(secondary: Color(0xFF1E88E5)),
      ),
      initialRoute: '/',
      routes: {
        '/': (context) => const SplashPage(),
        '/login': (context) => const LoginPage(),
        '/main': (context) => const MainPage(),
        '/account': (context) => const MainPage(),
      },
    );
  }
}
