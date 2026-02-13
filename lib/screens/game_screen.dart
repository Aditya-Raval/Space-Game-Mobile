import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:convert';
import 'dart:async';
import 'dart:io' show Platform;
import 'dart:ui' as ui;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:web_socket_channel/web_socket_channel.dart';
import '../constants.dart';
import '../models.dart';
import '../widgets/hud_panel.dart';
import '../widgets/landing_dialog.dart';
import '../widgets/notification_overlay.dart';
import '../widgets/mobile_controls.dart';

class GameScreen extends StatefulWidget {
  final String playerId;
  final String username;

  const GameScreen({
    super.key,
    required this.playerId,
    required this.username,
  });

  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen> with TickerProviderStateMixin {
  late WebSocketChannel _channel;
  late AnimationController _animationController;
  
  List<Player> _players = [];
  List<Planet> _planets = [];
  String? _myId;
  String _myName = '';
  int _myFuel = GameConstants.maxFuel;
  int _myCredits = 0;
  LandingPrompt? _landingPrompt;
  List<String> _ownedPlanets = [];
  
  final InputState _input = InputState();
  Timer? _inputTimer;
  
  final GlobalKey<NotificationOverlayState> _notificationKey = 
      GlobalKey<NotificationOverlayState>();

  @override
  void initState() {
    super.initState();
    _myName = widget.username;
    _connectWebSocket();
    
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 16),
    )..repeat();
    
    _animationController.addListener(() {
      setState(() {});
    });
  }

  void _connectWebSocket() {
    try {
      _channel = WebSocketChannel.connect(
        Uri.parse(GameConstants.wsUrl),
      );

      // Send auth message
      _channel.sink.add(jsonEncode({
        'type': 'auth',
        'payload': {'playerId': widget.playerId},
      }));

      // Start input timer
      _inputTimer = Timer.periodic(const Duration(milliseconds: 50), (timer) {
        if (_channel.closeCode == null) {
          _channel.sink.add(jsonEncode({
            'type': MessageTypes.msgInput,
            'payload': _input.toJson(),
          }));
        }
      });

      _channel.stream.listen(
        _handleMessage,
        onError: (error) {
          debugPrint('WebSocket error: $error');
        },
        onDone: () {
          debugPrint('WebSocket closed');
        },
      );
    } catch (e) {
      debugPrint('WebSocket connection error: $e');
    }
  }

  void _handleMessage(dynamic message) {
    try {
      final data = jsonDecode(message);
      final type = data['type'];
      
      debugPrint('Received message type: $type');

      if (type == 'init') {
        setState(() {
          _myId = data['id'];
          _myName = data['username'] ?? _myId ?? widget.username;
        });
        debugPrint('Initialized with ID: $_myId, Name: $_myName');
      } else if (type == MessageTypes.msgState) {
        final payload = data['payload'];
        
        try {
          final playersList = payload['players'] as List?;
          final planetsList = payload['planets'] as List?;
          
          debugPrint('Players count: ${playersList?.length ?? 0}, Planets count: ${planetsList?.length ?? 0}');
          
          setState(() {
            _players = (playersList ?? [])
                .map((p) => Player.fromJson(p as Map<String, dynamic>))
                .toList();
            _planets = (planetsList ?? [])
                .map((p) => Planet.fromJson(p as Map<String, dynamic>))
                .toList();

            final myPlayer = _players.firstWhere(
              (p) => p.id == _myId,
              orElse: () => Player(
                id: '',
                x: 0,
                y: 0,
                rot: 0,
                fuel: _myFuel,
                credits: _myCredits,
                username: _myName,
              ),
            );

            if (myPlayer.id.isNotEmpty) {
              _myFuel = myPlayer.fuel;
              _myCredits = myPlayer.credits;
              _myName = myPlayer.username;
            }
          });
        } catch (e) {
          debugPrint('Error parsing state: $e');
          debugPrint('Payload: $payload');
        }
      } else if (type == MessageTypes.msgLandingPrompt) {
        setState(() {
          _landingPrompt = LandingPrompt.fromJson(data);
        });
      } else if (type == MessageTypes.msgClaimResponse) {
        if (data['success'] == true) {
          if (data['planetId'] != null) {
            setState(() {
              _ownedPlanets.add(data['planetId']);
            });
          }
          _showNotification(data['message'] ?? 'Success!', Colors.green);
          setState(() {
            _landingPrompt = null;
          });
        } else {
          _showNotification(data['error'] ?? 'Failed', Colors.red);
        }
      } else if (type == MessageTypes.msgRefuelResponse) {
        if (data['success'] == true) {
          setState(() {
            _myFuel = data['newFuel'];
          });
          final cost = data['costDeducted'] ?? 0;
          _showNotification(
            'Refueled +${data['fuelAmount']}. Cost: \$${cost.toStringAsFixed(2)}',
            cost > 0 ? Colors.yellow : Colors.green,
          );
        } else {
          _showNotification(data['error'] ?? 'Failed', Colors.red);
        }
      }
    } catch (e, stackTrace) {
      debugPrint('Error handling message: $e');
      debugPrint('Stack trace: $stackTrace');
      debugPrint('Message: $message');
    }
  }

  void _showNotification(String text, Color color) {
    _notificationKey.currentState?.showNotification(text, color);
  }

  void _sendMessage(String type, Map<String, dynamic> payload) {
    if (_channel.closeCode == null) {
      _channel.sink.add(jsonEncode({
        'type': type,
        'payload': payload,
      }));
    }
  }

  void _handleKeyEvent(KeyEvent event) {
    if (event is KeyDownEvent) {
      setState(() {
        if (event.logicalKey == LogicalKeyboardKey.keyW) {
          _input.thrust = true;
        } else if (event.logicalKey == LogicalKeyboardKey.keyA) {
          _input.rotate = -1;
        } else if (event.logicalKey == LogicalKeyboardKey.keyD) {
          _input.rotate = 1;
        } else if (event.logicalKey == LogicalKeyboardKey.keyS) {
          _input.brake = true;
        }
      });
    } else if (event is KeyUpEvent) {
      setState(() {
        if (event.logicalKey == LogicalKeyboardKey.keyW) {
          _input.thrust = false;
        } else if (event.logicalKey == LogicalKeyboardKey.keyA ||
            event.logicalKey == LogicalKeyboardKey.keyD) {
          _input.rotate = 0;
        } else if (event.logicalKey == LogicalKeyboardKey.keyS) {
          _input.brake = false;
        }
      });
    }
  }

  bool get isMobile {
    // Check if running on mobile platform
    try {
      return !kIsWeb && (Platform.isAndroid || Platform.isIOS);
    } catch (e) {
      return false;
    }
  }

  void _handleMobileControl(String key, bool isPressed) {
    setState(() {
      if (key == 'w') {
        _input.thrust = isPressed;
      } else if (key == 'a') {
        _input.rotate = isPressed ? -1 : 0;
      } else if (key == 'd') {
        _input.rotate = isPressed ? 1 : 0;
      } else if (key == 's') {
        _input.brake = isPressed;
      }
    });
  }

  @override
  void dispose() {
    _inputTimer?.cancel();
    _animationController.dispose();
    _channel.sink.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return KeyboardListener(
      focusNode: FocusNode()..requestFocus(),
      onKeyEvent: _handleKeyEvent,
      child: Scaffold(
        body: Stack(
          children: [
            // Game canvas
            CustomPaint(
              painter: GamePainter(
                players: _players,
                planets: _planets,
                myId: _myId,
              ),
              size: Size.infinite,
            ),
            
            // Debug info (top right)
            Positioned(
              top: 10,
              right: 10,
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.7),
                  border: Border.all(color: Colors.yellow, width: 1),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Debug Info',
                      style: TextStyle(
                        color: Colors.yellow,
                        fontSize: 10,
                        fontFamily: 'monospace',
                      ),
                    ),
                    Text(
                      'Players: ${_players.length}',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 9,
                        fontFamily: 'monospace',
                      ),
                    ),
                    Text(
                      'Planets: ${_planets.length}',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 9,
                        fontFamily: 'monospace',
                      ),
                    ),
                    Text(
                      'My ID: ${_myId ?? "null"}',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 9,
                        fontFamily: 'monospace',
                      ),
                    ),
                    Text(
                      'WS: ${_channel.closeCode == null ? "Connected" : "Closed"}',
                      style: TextStyle(
                        color: _channel.closeCode == null ? Colors.green : Colors.red,
                        fontSize: 9,
                        fontFamily: 'monospace',
                      ),
                    ),
                  ],
                ),
              ),
            ),
            
            // HUD Panel
            Positioned(
              left: 10,
              top: 10,
              child: HudPanel(
                playerName: _myName,
                credits: _myCredits,
                fuel: _myFuel,
                maxFuel: GameConstants.maxFuel,
                playerCount: _players.length,
                ownedPlanetsCount: _ownedPlanets.length,
              ),
            ),
            
            // Mobile Controls (only show on mobile)
            if (isMobile)
              MobileControls(
                onControlPressed: (key) => _handleMobileControl(key, true),
                onControlReleased: (key) => _handleMobileControl(key, false),
              ),
            
            // Landing Dialog
            if (_landingPrompt != null)
              LandingDialog(
                prompt: _landingPrompt!,
                myCredits: _myCredits,
                onClaim: (planetId) {
                  _sendMessage(MessageTypes.msgClaimPlanet, {'planetId': planetId});
                  setState(() => _landingPrompt = null);
                },
                onRefuel: (amount, isOwned) {
                  _sendMessage(MessageTypes.msgRefuel, {
                    'amount': amount,
                    'isOwned': isOwned,
                  });
                  setState(() => _landingPrompt = null);
                },
                onRevoke: (planetId) {
                  _sendMessage(MessageTypes.msgRevokePlanet, {'planetId': planetId});
                  setState(() => _landingPrompt = null);
                },
                onClose: () {
                  setState(() => _landingPrompt = null);
                },
              ),
            
            // Notification overlay
            NotificationOverlay(key: _notificationKey),
          ],
        ),
      ),
    );
  }
}

class GamePainter extends CustomPainter {
  final List<Player> players;
  final List<Planet> planets;
  final String? myId;

  GamePainter({
    required this.players,
    required this.planets,
    this.myId,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // Clear background
    canvas.drawRect(
      Rect.fromLTWH(0, 0, size.width, size.height),
      Paint()..color = Colors.black,
    );

    if (players.isEmpty) return;

    // Find camera target
    final camTarget = players.firstWhere(
      (p) => p.id == myId,
      orElse: () => players.first,
    );

    // Apply camera transform
    canvas.save();
    canvas.translate(
      size.width / 2 - camTarget.x,
      size.height / 2 - camTarget.y,
    );

    // Draw planets
    for (final planet in planets) {
      _drawPlanet(canvas, planet);
    }

    // Draw ships
    for (final player in players) {
      _drawShip(canvas, player);
    }

    canvas.restore();
  }

  void _drawPlanet(Canvas canvas, Planet planet) {
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3;

    if (planet.owner != null) {
      paint.color = planet.owner == myId ? const Color(0xFF00FF00) : const Color(0xFFFF00FF);
    } else {
      paint.color = const Color(0xFF44AAFF);
    }

    canvas.drawCircle(
      Offset(planet.x, planet.y),
      planet.r,
      paint,
    );

    // Draw planet name
    final textColor = planet.owner == myId
        ? const Color(0xFF00FF00)
        : planet.owner != null
            ? const Color(0xFFFF00FF)
            : const Color(0xFF44AAFF);

    _drawText(
      canvas,
      planet.name,
      Offset(planet.x, planet.y - planet.r - 15),
      textColor,
      12,
    );

    // Draw owner name
    if (planet.owner != null) {
      final ownerColor = planet.owner == myId ? const Color(0xFF00FF00) : const Color(0xFFFF00FF);
      _drawText(
        canvas,
        '[${planet.ownerUsername ?? "?"}]',
        Offset(planet.x, planet.y - planet.r - 3),
        ownerColor,
        10,
      );
    }
  }

  void _drawShip(Canvas canvas, Player player) {
    canvas.save();
    canvas.translate(player.x, player.y);
    canvas.rotate(player.rot);

    final path = Path()
      ..moveTo(15, 0)
      ..lineTo(-10, 8)
      ..lineTo(-10, -8)
      ..close();

    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2
      ..color = player.id == myId ? Colors.cyan : Colors.white;

    canvas.drawPath(path, paint);
    canvas.restore();
  }

  void _drawText(Canvas canvas, String text, Offset position, Color color, double fontSize) {
    final textPainter = TextPainter(
      text: TextSpan(
        text: text,
        style: TextStyle(
          color: color,
          fontSize: fontSize,
          fontFamily: 'monospace',
        ),
      ),
      textAlign: TextAlign.center,
      textDirection: ui.TextDirection.ltr,
    );

    textPainter.layout();
    textPainter.paint(
      canvas,
      Offset(position.dx - textPainter.width / 2, position.dy),
    );
  }

  @override
  bool shouldRepaint(GamePainter oldDelegate) => true;
}