import 'dart:async';
import 'dart:ui';
import 'package:app_links/app_links.dart';
import 'package:app/pages/profile/splash_page.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'config.dart';
import 'pages/profile/login.dart';
import 'pages/main_page.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Global error handlers — catch crashes gracefully
  FlutterError.onError = (details) {
    FlutterError.presentError(details);
    debugPrint('🔴 Flutter Error: ${details.exceptionAsString()}');
  };
  PlatformDispatcher.instance.onError = (error, stack) {
    debugPrint('🔴 Unhandled Error: $error\n$stack');
    return true;
  };

  await dotenv.load(fileName: ".env");

  await Supabase.initialize(
    url: AppConfig.supabaseUrl,
    anonKey: AppConfig.supabaseAnonKey,
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
