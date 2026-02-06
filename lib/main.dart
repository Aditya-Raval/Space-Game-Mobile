import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:http/http.dart' as http;

// Constants
const int MAX_FUEL = 100;
const String MSG_INPUT = 'input';
const String MSG_STATE = 'state';

void main() {
  runApp(const SpaceGameApp());
}

class SpaceGameApp extends StatelessWidget {
  const SpaceGameApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Space Game',
      theme: ThemeData.dark(),
      home: const GameScreen(),
    );
  }
}

class GameScreen extends StatefulWidget {
  const GameScreen({Key? key}) : super(key: key);

  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen> {
  // Auth state
  bool isAuthenticated = false;
  final TextEditingController usernameController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  String authMessage = '';

  // Game state
  String? myId;
  String? myName;
  double myFuel = MAX_FUEL.toDouble();
  int myCredits = 0;
  List<dynamic> players = [];
  List<dynamic> planets = [];

  // Input state
  bool thrust = false;
  int rotate = 0;

  // WebSocket
  WebSocketChannel? channel;
  Timer? inputTimer;
  StreamSubscription? wsSubscription;

  // Focus node for keyboard input
  final FocusNode gameFocusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      gameFocusNode.requestFocus();
    });
  }

  @override
  void dispose() {
    usernameController.dispose();
    passwordController.dispose();
    inputTimer?.cancel();
    wsSubscription?.cancel();
    channel?.sink.close();
    gameFocusNode.dispose();
    super.dispose();
  }

  Future<void> doAuth(String action) async {
    final username = usernameController.text.trim();
    final password = passwordController.text;

    if (username.isEmpty || password.isEmpty) {
      setState(() {
        authMessage = 'Please enter username and password';
      });
      return;
    }

    try {
      final response = await http.post(
        Uri.parse('http://localhost:3000/$action'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'username': username, 'password': password}),
      );

      final data = jsonDecode(response.body);

      if (response.statusCode != 200) {
        setState(() {
          authMessage = data['error'] ?? 'Auth failed';
        });
        return;
      }

      // Success
      setState(() {
        myName = data['username'] ?? username;
        authMessage = 'Authenticated, connecting...';
      });

      connectSocket(data['playerId']);
    } catch (err) {
      setState(() {
        authMessage = 'Auth server unreachable';
      });
      print('Auth error: $err');
    }
  }

  void connectSocket(String playerId) {
    try {
      channel = WebSocketChannel.connect(
        Uri.parse('ws://localhost:8080'),
      );

      // Send auth message
      channel!.sink.add(jsonEncode({
        'type': 'auth',
        'payload': {'playerId': playerId}
      }));

      // Start input timer (send every 50ms)
      inputTimer = Timer.periodic(const Duration(milliseconds: 50), (timer) {
        if (channel != null) {
          channel!.sink.add(jsonEncode({
            'type': MSG_INPUT,
            'payload': {'thrust': thrust, 'rotate': rotate}
          }));
        }
      });

      // Listen to messages
      wsSubscription = channel!.stream.listen(
        (message) {
          handleMessage(message);
        },
        onError: (error) {
          print('WebSocket error: $error');
        },
        onDone: () {
          print('WebSocket closed');
        },
      );
    } catch (err) {
      print('WebSocket connection error: $err');
    }
  }

  void handleMessage(dynamic message) {
    final msg = jsonDecode(message);

    if (msg['type'] == 'init') {
      setState(() {
        myId = msg['id'];
        myName = msg['username'] ?? myId;
        isAuthenticated = true;
      });
      print('MY ID: $myId');
    }

    if (msg['type'] == MSG_STATE) {
      setState(() {
        players = msg['payload']['players'] ?? [];
        planets = msg['payload']['planets'] ?? [];

        // Update my fuel and credits
        final myPlayer = players.firstWhere(
          (p) => p['id'] == myId,
          orElse: () => null,
        );

        if (myPlayer != null) {
          myFuel = (myPlayer['fuel'] ?? MAX_FUEL).toDouble();
          myCredits = myPlayer['credits'] ?? 0;
          myName = myPlayer['username'] ?? myName;
        }
      });
    }
  }

  void handleKeyEvent(RawKeyEvent event) {
    if (event is RawKeyDownEvent) {
      if (event.logicalKey == LogicalKeyboardKey.keyW) {
        setState(() => thrust = true);
      } else if (event.logicalKey == LogicalKeyboardKey.keyA) {
        setState(() => rotate = -1);
      } else if (event.logicalKey == LogicalKeyboardKey.keyD) {
        setState(() => rotate = 1);
      }
    } else if (event is RawKeyUpEvent) {
      if (event.logicalKey == LogicalKeyboardKey.keyW) {
        setState(() => thrust = false);
      } else if (event.logicalKey == LogicalKeyboardKey.keyA ||
          event.logicalKey == LogicalKeyboardKey.keyD) {
        setState(() => rotate = 0);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!isAuthenticated) {
      return Scaffold(
        body: Center(
          child: Container(
            padding: const EdgeInsets.all(32),
            constraints: const BoxConstraints(maxWidth: 400),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text(
                  'SPACE GAME',
                  style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 40),
                TextField(
                  controller: usernameController,
                  decoration: const InputDecoration(
                    labelText: 'Username',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: passwordController,
                  obscureText: true,
                  decoration: const InputDecoration(
                    labelText: 'Password',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 24),
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () => doAuth('login'),
                        child: const Text('LOGIN'),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () => doAuth('register'),
                        child: const Text('REGISTER'),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Text(
                  authMessage,
                  style: const TextStyle(color: Colors.red),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      );
    }

    return RawKeyboardListener(
      focusNode: gameFocusNode,
      onKey: handleKeyEvent,
      autofocus: true,
      child: Scaffold(
        body: CustomPaint(
          painter: GamePainter(
            myId: myId,
            myName: myName,
            myFuel: myFuel,
            myCredits: myCredits,
            players: players,
            planets: planets,
          ),
          child: Container(),
        ),
      ),
    );
  }
}

class GamePainter extends CustomPainter {
  final String? myId;
  final String? myName;
  final double myFuel;
  final int myCredits;
  final List<dynamic> players;
  final List<dynamic> planets;

  GamePainter({
    required this.myId,
    required this.myName,
    required this.myFuel,
    required this.myCredits,
    required this.players,
    required this.planets,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint();

    // Draw UI (screen space)
    final textStyle = const TextStyle(
      color: Colors.white,
      fontSize: 18,
      fontFamily: 'monospace',
    );

    final textPainter = TextPainter(
      textDirection: TextDirection.ltr,
    );

    // Draw player count
    textPainter.text = TextSpan(text: 'PLAYERS: ${players.length}', style: textStyle);
    textPainter.layout();
    textPainter.paint(canvas, const Offset(20, 30));

    // Draw ID
    textPainter.text = TextSpan(text: 'MY ID: ${myId ?? "null"}', style: textStyle);
    textPainter.layout();
    textPainter.paint(canvas, const Offset(20, 55));

    // Draw fuel text
    textPainter.text = TextSpan(text: 'FUEL: ${myFuel.toStringAsFixed(1)}/$MAX_FUEL', style: textStyle);
    textPainter.layout();
    textPainter.paint(canvas, const Offset(20, 80));

    // Draw fuel bar
    final fuelPercentage = (myFuel / MAX_FUEL) * 100;
    paint.style = PaintingStyle.stroke;
    paint.color = Colors.green;
    paint.strokeWidth = 2;
    canvas.drawRect(const Rect.fromLTWH(20, 90, 200, 20), paint);

    paint.style = PaintingStyle.fill;
    paint.color = fuelPercentage > 25 ? Colors.green : Colors.red;
    canvas.drawRect(Rect.fromLTWH(20, 90, (fuelPercentage / 100) * 200, 20), paint);

    // Draw username
    textPainter.text = TextSpan(text: 'USER: ${myName ?? "guest"}', style: textStyle);
    textPainter.layout();
    textPainter.paint(canvas, const Offset(20, 100));

    // Draw credits
    textPainter.text = TextSpan(
      text: 'CREDITS: \$${myCredits}',
      style: textStyle.copyWith(color: Colors.green),
    );
    textPainter.layout();
    textPainter.paint(canvas, const Offset(20, 125));

    if (players.isEmpty) return;

    // Get camera target
    final camTarget = players.firstWhere(
      (p) => p['id'] == myId,
      orElse: () => players[0],
    );

    final camX = (camTarget['x'] ?? 0).toDouble();
    final camY = (camTarget['y'] ?? 0).toDouble();

    // World space transform
    canvas.save();
    canvas.translate(size.width / 2 - camX, size.height / 2 - camY);

    // Draw planets
    for (final planet in planets) {
      drawPlanet(canvas, paint, planet);
    }

    // Draw ships
    for (final player in players) {
      drawShip(canvas, paint, player);
    }

    canvas.restore();
  }

  void drawShip(Canvas canvas, Paint paint, dynamic player) {
    final x = (player['x'] ?? 0).toDouble();
    final y = (player['y'] ?? 0).toDouble();
    final rot = (player['rot'] ?? 0).toDouble();

    canvas.save();
    canvas.translate(x, y);
    canvas.rotate(rot);

    final path = Path();
    path.moveTo(15, 0);
    path.lineTo(-10, 8);
    path.lineTo(-10, -8);
    path.close();

    paint.style = PaintingStyle.stroke;
    paint.color = player['id'] == myId ? Colors.cyan : Colors.white;
    paint.strokeWidth = 2;
    canvas.drawPath(path, paint);

    canvas.restore();
  }

  void drawPlanet(Canvas canvas, Paint paint, dynamic planet) {
    final x = (planet['x'] ?? 0).toDouble();
    final y = (planet['y'] ?? 0).toDouble();
    final r = (planet['r'] ?? 0).toDouble();

    paint.style = PaintingStyle.stroke;
    paint.color = const Color(0xFF44AAFF);
    paint.strokeWidth = 3;
    canvas.drawCircle(Offset(x, y), r, paint);
  }

  @override
  bool shouldRepaint(GamePainter oldDelegate) => true;
}