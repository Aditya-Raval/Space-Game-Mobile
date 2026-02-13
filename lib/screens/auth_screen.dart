import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../constants.dart';
import 'game_screen.dart';

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  String _message = '';
  bool _isLoading = false;

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _doAuth(String action) async {
    final username = _usernameController.text.trim();
    final password = _passwordController.text;

    if (username.isEmpty || password.isEmpty) {
      setState(() {
        _message = 'Please enter username and password';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _message = '';
    });

    try {
      final url = Uri.parse('${GameConstants.httpBaseUrl}/$action');
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'username': username,
          'password': password,
        }),
      );

      final data = jsonDecode(response.body);

      if (!response.statusCode.toString().startsWith('2')) {
        setState(() {
          _message = data['error'] ?? 'Auth failed';
          _isLoading = false;
        });
        return;
      }

      // Success - navigate to game screen
      if (!mounted) return;
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (context) => GameScreen(
            playerId: data['playerId'],
            username: data['username'] ?? username,
          ),
        ),
      );
    } catch (e) {
      setState(() {
        _message = 'Auth failed: ${e.toString()}';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Container(
          constraints: const BoxConstraints(maxWidth: 300),
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.black,
            border: Border.all(color: Colors.white, width: 1),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                'SPACE GAME',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 15),
              TextField(
                controller: _usernameController,
                decoration: InputDecoration(
                  hintText: 'Username',
                  hintStyle: TextStyle(color: Colors.grey[600]),
                  filled: true,
                  fillColor: Colors.black,
                  border: const OutlineInputBorder(
                    borderSide: BorderSide(color: Colors.white),
                  ),
                  enabledBorder: const OutlineInputBorder(
                    borderSide: BorderSide(color: Colors.white),
                  ),
                  focusedBorder: const OutlineInputBorder(
                    borderSide: BorderSide(color: Colors.white),
                  ),
                ),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontFamily: 'monospace',
                ),
                autocorrect: false,
              ),
              const SizedBox(height: 10),
              TextField(
                controller: _passwordController,
                obscureText: true,
                decoration: InputDecoration(
                  hintText: 'Password',
                  hintStyle: TextStyle(color: Colors.grey[600]),
                  filled: true,
                  fillColor: Colors.black,
                  border: const OutlineInputBorder(
                    borderSide: BorderSide(color: Colors.white),
                  ),
                  enabledBorder: const OutlineInputBorder(
                    borderSide: BorderSide(color: Colors.white),
                  ),
                  focusedBorder: const OutlineInputBorder(
                    borderSide: BorderSide(color: Colors.white),
                  ),
                ),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontFamily: 'monospace',
                ),
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : () => _doAuth('login'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: Colors.black,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.zero,
                          side: const BorderSide(color: Colors.white),
                        ),
                      ),
                      child: const Text(
                        'Login',
                        style: TextStyle(
                          fontSize: 14,
                          fontFamily: 'monospace',
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : () => _doAuth('register'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: Colors.black,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.zero,
                          side: const BorderSide(color: Colors.white),
                        ),
                      ),
                      child: const Text(
                        'Register',
                        style: TextStyle(
                          fontSize: 14,
                          fontFamily: 'monospace',
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              SizedBox(
                height: 16,
                child: _isLoading
                    ? const Center(
                        child: SizedBox(
                          width: 12,
                          height: 12,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        ),
                      )
                    : Text(
                        _message,
                        style: const TextStyle(
                          color: Colors.red,
                          fontSize: 12,
                        ),
                        textAlign: TextAlign.center,
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}