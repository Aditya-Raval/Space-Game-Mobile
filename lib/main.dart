import 'package:flutter/material.dart';
import 'screens/auth_screen.dart';

void main() {
  runApp(const SpaceGameApp());
}

class SpaceGameApp extends StatelessWidget {
  const SpaceGameApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Space Game',
      theme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: Colors.black,
        primaryColor: Colors.white,
        fontFamily: 'monospace',
      ),
      home: const AuthScreen(),
      debugShowCheckedModeBanner: false,
    );
  }
}