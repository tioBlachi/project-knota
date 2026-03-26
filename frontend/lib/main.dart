import 'package:flutter/material.dart';
import 'package:frontend/pages/login_page.dart';
import 'package:frontend/pages/home_page.dart';
import 'package:frontend/services/storage_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final bool isLoggedIn = await StorageService.isTokenValid();

  runApp(MyApp(isLoggedIn: isLoggedIn));
}

class MyApp extends StatelessWidget {
  final bool isLoggedIn;
  
  const MyApp({super.key, required this.isLoggedIn});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Knota',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.cyan),
      ),
      home: isLoggedIn ? const HomePage() : const LoginPage(),
    );
  }
}

