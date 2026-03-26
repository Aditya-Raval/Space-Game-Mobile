import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:convert';
import 'dart:async';
import 'dart:io' show Platform;
import 'dart:math';
import 'dart:ui' as ui;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:web_socket_channel/web_socket_channel.dart';
import '../constants.dart';
import '../models.dart';
import '../widgets/hud_panel.dart';
import '../widgets/landing_dialog.dart';
import '../widgets/notification_overlay.dart';
import '../widgets/mobile_controls.dart';

class Star {
  final double x;
  final double y;
  final double radius;
  final double opacity;
  final double parallax;

  const Star({
    required this.x,
    required this.y,
    required this.radius,
    required this.opacity,
    required this.parallax,
  });
}

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
  List<Missile> _missiles = [];

  final InputState _input = InputState();
  Timer? _inputTimer;

  final GlobalKey<NotificationOverlayState> _notificationKey =
      GlobalKey<NotificationOverlayState>();

  // Ship images
  ui.Image? _shipIdleImage;
  ui.Image? _shipThrustImage;
  ui.Image? _otherShipImage;

  // Planet images
  Map<String, ui.Image?> _planetImages = {};

  // Stars
  List<Star> _stars = [];

  List<ChatMessage> _chatMessages = [];
  bool _showChatInput = false;
  final TextEditingController _chatController = TextEditingController();
  List<String> _profanityList = [];
  @override
  void initState() {
    super.initState();
    _myName = widget.username;
    _generateStars();
    _loadImages();
    _connectWebSocket();
    _loadProfanity();

    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 16),
    )..repeat();

    _animationController.addListener(() {
      setState(() {});
    });
  }

  Future<void> _loadProfanity() async {
      try {
        final data = await rootBundle.loadString('assets/en.txt');
        _profanityList = data
            .split('\n')
            .map((e) => e.trim().toLowerCase())
            .where((e) => e.isNotEmpty)
            .toList();
      } catch (e) {
        debugPrint('Failed to load profanity list');
      }
  }

  void _generateStars() {
    final rng = Random(42); // fixed seed = consistent starfield
    const int count = 300;
    const double worldSize = 6000.0;

    _stars = List.generate(count, (_) {
      final layer = rng.nextInt(3); // 0=far, 1=mid, 2=near
      return Star(
        x: rng.nextDouble() * worldSize - worldSize / 2,
        y: rng.nextDouble() * worldSize - worldSize / 2,
        radius: layer == 0 ? 0.8 : layer == 1 ? 1.2 : 1.8,
        opacity: 0.3 + rng.nextDouble() * 0.7,
        parallax: layer == 0 ? 0.15 : layer == 1 ? 0.4 : 0.75,
      );
    });
  }

  Future<ui.Image> _loadImage(String assetPath) async {
    final data = await rootBundle.load(assetPath);
    final codec = await ui.instantiateImageCodec(data.buffer.asUint8List());
    final frame = await codec.getNextFrame();
    return frame.image;
  }

  Future<void> _loadImages() async {
    try {
      final idle = await _loadImage('assets/ships/player_ship_idle.png');
      final thrust = await _loadImage('assets/ships/player_ship.png');
      final other = await _loadImage('assets/ships/other_ship_idle.png');

      // Load planet images
     final planetImages = <String, ui.Image?>{
        'p1': await _loadImage('assets/planets/sphereplanet.png'),     // Terra (big)
        'p2': await _loadImage('assets/planets/dryhotplanet.png'),
        'p3': await _loadImage('assets/planets/neptunlikeplanet.png'),
        'p4': await _loadImage('assets/planets/dryvenuslikeplanet.png'),
        'p5': await _loadImage('assets/planets/moon.png'),
        'p6': await _loadImage('assets/planets/neptunlikeplanet.png'),
        'p7': await _loadImage('assets/planets/iceplanet.png'),
        'p8': await _loadImage('assets/planets/iceplanet_2.png'),
        'p9': await _loadImage('assets/planets/shattered_planet.png'),
        'p10': await _loadImage('assets/planets/exoplanet.png'),
        'p11': await _loadImage('assets/planets/sphereplanet.png'),
        'p12': await _loadImage('assets/planets/sun.png'),

        // reuse textures for remaining (same as typical JS reuse)
        'p13': await _loadImage('assets/planets/dryhotplanet.png'),
        'p14': await _loadImage('assets/planets/neptunlikeplanet.png'),
        'p15': await _loadImage('assets/planets/moon.png'),
        'p16': await _loadImage('assets/planets/iceplanet.png'),
        'p17': await _loadImage('assets/planets/shattered_planet.png'),
        'p18': await _loadImage('assets/planets/lava_planet.png'),
        'p19': await _loadImage('assets/planets/iceplanet_2.png'),
        'p20': await _loadImage('assets/planets/exoplanet.png'),
        'p21': await _loadImage('assets/planets/moon.png'),
        'p22': await _loadImage('assets/planets/sphereplanet.png'),
        'p23': await _loadImage('assets/planets/dryvenuslikeplanet.png'),
        'p24': await _loadImage('assets/planets/neptunlikeplanet.png'),
        'p25': await _loadImage('assets/planets/iceplanet.png'),
        'p26': await _loadImage('assets/planets/lava_planet.png'),
        'p27': await _loadImage('assets/planets/moon.png'),
        'p28': await _loadImage('assets/planets/exoplanet.png'),
      };


      debugPrint('Images loaded successfully. Planet images count: ${planetImages.length}');
      if (mounted) {
        setState(() {
          _shipIdleImage = idle;
          _shipThrustImage = thrust;
          _otherShipImage = other;
          _planetImages = planetImages;
        });
      }
    } catch (e) {
      debugPrint('Error loading ship images: $e');
    }
  }

  void _connectWebSocket() {
    try {
      debugPrint('=== WEBSOCKET CONNECTION ===');
      debugPrint('Connecting to: ${GameConstants.wsUrl}');
      debugPrint('Player ID: ${widget.playerId}');
      debugPrint('Username: ${widget.username}');

      _channel = WebSocketChannel.connect(
        Uri.parse(GameConstants.wsUrl),
      );

      final authMessage = jsonEncode({
        'type': 'auth',
        'payload': {'playerId': widget.playerId},
      });

      debugPrint('Sending auth message: $authMessage');
      _channel.sink.add(authMessage);

      _inputTimer = Timer.periodic(const Duration(milliseconds: 50), (timer) {
        if (_channel.closeCode == null) {
          _channel.sink.add(jsonEncode({
            'type': MessageTypes.msgInput,
            'payload': _input.toJson(),
          }));

          // FIRE MISSILE
          if (_input.missile) {
            _channel.sink.add(jsonEncode({
              'type': MessageTypes.msgFireMissile,
            }));
            _input.missile = false;
          }
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
    } catch (e, stackTrace) {
      debugPrint('WebSocket connection error: $e');
      debugPrint('Stack trace: $stackTrace');
    }
  }

  void _handleMessage(dynamic message) {
  try {
    final data = jsonDecode(message);
    final type = data['type'];

    if (type == 'init') {
      setState(() {
        _myId = data['id'];
        _myName = data['username'] ?? _myId ?? widget.username;
      });
    }

    else if (type == MessageTypes.msgState) {
      final payload = data['payload'];

      final playersList = payload['players'] as List?;
      final planetsList = payload['planets'] as List?;

      setState(() {
        _players = (playersList ?? [])
            .map((p) => Player.fromJson(p as Map<String, dynamic>))
            .toList();

        _planets = (planetsList ?? [])
            .map((p) => Planet.fromJson(p as Map<String, dynamic>))
            .toList();

        _missiles = (payload['missiles'] ?? [])
            .map<Missile>((m) => Missile.fromJson(m))
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
    }

    else if (type == MessageTypes.msgChatBroadcast) {
      final payload = data['payload'];
      final msg = ChatMessage.fromJson(payload);

      setState(() {
        _chatMessages.add(msg);
        if (_chatMessages.length > 50) {
          _chatMessages.removeAt(0);
        }
      });
    }

    else if (type == MessageTypes.msgLandingPrompt) {
      setState(() {
        _landingPrompt = LandingPrompt.fromJson(data);
      });
    }

    else if (type == MessageTypes.msgClaimResponse) {
      if (data['success'] == true) {
        _showNotification(data['message'] ?? 'Success', Colors.green);
        setState(() => _landingPrompt = null);
      } else {
        _showNotification(data['error'] ?? 'Failed', Colors.red);
      }
    }

    else if (type == MessageTypes.msgRefuelResponse) {
      if (data['success'] == true) {
        setState(() {
          _myFuel = data['newFuel'];
        });

        final cost = data['costDeducted'] ?? 0;
        _showNotification(
          'Refueled +${data['fuelAmount']} | Cost: \$${cost}',
          cost > 0 ? Colors.yellow : Colors.green,
        );
      } else {
        _showNotification(data['error'] ?? 'Failed', Colors.red);
      }
    }
    
    else if (type == MessageTypes.msgMissileUpdate) {
      final payload = data['payload'];

      setState(() {
        _missiles = (payload ?? [])
            .map<Missile>((m) => Missile.fromJson(m))
            .toList();
      });
    }

    else if (type == MessageTypes.msgMissileHit) {
      final payload = data['payload'];

      final hitId = payload['id'];

      setState(() {
        _missiles.removeWhere((m) => m.id == hitId);
      });

      _showNotification('💥 Hit!', Colors.red);
    }

  } catch (e) {
    debugPrint('Error handling message: $e');
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
  void _sendChatMessage(String text) {
    if (text.trim().isEmpty) return;

    final lower = text.toLowerCase();

    final hasProfanity = _profanityList.any((word) {
      return RegExp(r'\b' + word + r'\b', caseSensitive: false)
          .hasMatch(lower);
    });

    if (hasProfanity) {
      _showNotification('Profanity blocked', Colors.red);
      return;
    }

    _sendMessage(MessageTypes.msgChat, {'text': text});
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
        } else if (event.logicalKey == LogicalKeyboardKey.keyF) {
           _input.missile = true;
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
        } else if (event.logicalKey == LogicalKeyboardKey.keyF) {
           _input.missile = false;
        }
      });
    }
  }

  bool get isMobile {
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
      } else if (key == 'f') {
        _input.missile = isPressed;
      }
    });
  }

  @override
  void dispose() {
    _inputTimer?.cancel();
    _animationController.dispose();
    _channel.sink.close();
    _chatController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return KeyboardListener(
      focusNode: FocusNode(),
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
                thrustInput: _input.thrust,
                shipIdleImage: _shipIdleImage,
                shipThrustImage: _shipThrustImage,
                otherShipImage: _otherShipImage,
                stars: _stars,
                planetImages: _planetImages,
                missiles: _missiles
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
                    const Text(
                      'Debug Info',
                      style: TextStyle(
                        color: Colors.yellow,
                        fontSize: 10,
                        fontFamily: 'monospace',
                      ),
                    ),
                    Text(
                      'Players: ${_players.length}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 9,
                        fontFamily: 'monospace',
                      ),
                    ),
                    Text(
                      'Planets: ${_planets.length}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 9,
                        fontFamily: 'monospace',
                      ),
                    ),
                    Text(
                      'My ID: ${_myId ?? "null"}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 9,
                        fontFamily: 'monospace',
                      ),
                    ),
                    Text(
                      'WS: ${_channel.closeCode == null ? "Connected" : "Closed"}',
                      style: TextStyle(
                        color: _channel.closeCode == null
                            ? Colors.green
                            : Colors.red,
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
                  _sendMessage(
                      MessageTypes.msgClaimPlanet, {'planetId': planetId});
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
                  _sendMessage(
                      MessageTypes.msgRevokePlanet, {'planetId': planetId});
                  setState(() => _landingPrompt = null);
                },
                onClose: () {
                  setState(() => _landingPrompt = null);
                },
              ),
            Positioned(
              right: 15,
              top: 15,
              child: GestureDetector(
                       onTap: () {
                  setState(() {
                    _showChatInput = !_showChatInput;
                  });
                },
                child: FocusScope(
                  child: Container(
                    width: 280,
                    constraints: const BoxConstraints(maxHeight: 420),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.7),
                      border: Border.all(color: Colors.grey),
                    ),
                    child: Column(
                      children: [
                        const Padding(
                          padding: EdgeInsets.all(8),
                          child: Text(
                            'Chat (hover to type)',
                            style: TextStyle(
                              fontSize: 12,
                              fontFamily: 'monospace',
                            ),
                          ),
                        ),

                        // Messages
                        SizedBox(
                          height: 270,
                          child: ListView.builder(
                            itemCount: _chatMessages.length,
                            itemBuilder: (_, i) {
                              final msg = _chatMessages[i];
                              final time = TimeOfDay.fromDateTime(
                                DateTime.fromMillisecondsSinceEpoch(msg.timestamp),
                              ).format(context);

                              return Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                child: Text(
                                  '[$time] ${msg.from}: ${msg.text}',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontFamily: 'monospace',
                                    color: msg.system ? Colors.orange : Colors.white,
                                  ),
                                ),
                              );
                            },
                          ),
                        ),

                        // Input
                        if (_showChatInput)
                          Padding(
                            padding: const EdgeInsets.all(8),
                            child: TextField(
                              controller: _chatController,
                              autofocus: true,
                              style: const TextStyle(
                                color: Colors.white,
                                fontFamily: 'monospace',
                              ),
                              decoration: const InputDecoration(
                                hintText: 'Type message...',
                                hintStyle: TextStyle(color: Colors.grey),
                                border: OutlineInputBorder(),
                              ),
                              onSubmitted: (text) {
                                _sendChatMessage(text);
                                _chatController.clear();
                              },
                            ),
                          ),
                      ],
                    ),
                  )
                  ),
              ),
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
  final bool thrustInput;
  final ui.Image? shipIdleImage;
  final ui.Image? shipThrustImage;
  final ui.Image? otherShipImage;
  final List<Star> stars;
  final Map<String, ui.Image?> planetImages;
  final List<Missile> missiles;

  GamePainter({
    required this.players,
    required this.planets,
    this.myId,
    required this.thrustInput,
    this.shipIdleImage,
    this.shipThrustImage,
    this.otherShipImage,
    required this.stars,
    required this.planetImages,
    required this.missiles,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // Clear background
    canvas.drawRect(
      Rect.fromLTWH(0, 0, size.width, size.height),
      Paint()..color = Colors.black,
    );

    if (players.isEmpty) return;

    final camTarget = players.firstWhere(
      (p) => p.id == myId,
      orElse: () => players.first,
    );

    final double camX = size.width / 2 - camTarget.x;
    final double camY = size.height / 2 - camTarget.y;
   // debugPrint('Camera: myId=$myId, players count=${players.length}, camTarget=${camTarget.id} at (${camTarget.x.toInt()}, ${camTarget.y.toInt()})');

    // Draw stars with parallax (screen space, before camera transform)
    final starPaint = Paint()..style = PaintingStyle.fill;
    for (final star in stars) {
      final double sx = star.x + camX * star.parallax;
      final double sy = star.y + camY * star.parallax;

      // Wrap stars to always fill the viewport
      final double wx = sx % size.width + (sx < 0 ? size.width : 0);
      final double wy = sy % size.height + (sy < 0 ? size.height : 0);

      starPaint.color = Colors.white.withOpacity(star.opacity);
      canvas.drawCircle(Offset(wx, wy), star.radius, starPaint);
    }

    // Apply camera transform for world objects
    canvas.save();
    canvas.translate(camX, camY);
    
    // Draw planets
    for (final planet in planets) {
      final planetImage = planetImages[planet.id];
      _drawPlanet(canvas, planet, planetImage);
    }

    // Draw ships
    for (final player in players) {
      _drawShip(canvas, player);
    }

    for (final m in missiles) {
      _drawMissile(canvas, m);
    }

    canvas.restore();
  }


  void _drawShip(Canvas canvas, Player player) {
    final isMe = player.id == myId;

    final ui.Image? image;
    if (isMe) {
      image = thrustInput ? shipThrustImage : shipIdleImage;
    } else {
      image = otherShipImage;
    }

    canvas.save();
    canvas.translate(player.x, player.y);
    canvas.rotate(player.rot + pi / 2);

    if (image != null) {
      const double size = 80;
      canvas.drawImageRect(
        image,
        Rect.fromLTWH(0, 0, image.width.toDouble(), image.height.toDouble()),
        Rect.fromLTWH(-size / 2, -size / 2, size, size),
        Paint(),
      );
    } else {
      final path = Path()
        ..moveTo(15, 0)
        ..lineTo(-10, 8)
        ..lineTo(-10, -8)
        ..close();

      canvas.drawPath(
        path,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2
          ..color = isMe ? Colors.cyan : Colors.white,
      );
    }

    canvas.restore();
  }
  void _drawPlanet(Canvas canvas, Planet planet, ui.Image? planetImage) {
    if (planetImage != null) {
      // Draw planet image scaled by radius
      final size = (planet.id == 'p1' || planet.id == 'p22')
      ? planet.r * 4 + 3
      : planet.r * 2 + 3; // diameter = 2 * radius
      canvas.drawImageRect(
        planetImage,
        Rect.fromLTWH(0, 0, planetImage.width.toDouble(), planetImage.height.toDouble()),
        Rect.fromLTWH(planet.x - size / 2, planet.y - size / 2, size, size),
        Paint(),
      );
    } else {
      // Fallback: draw circle if image not available
      final paint = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3;

      if (planet.owner != null) {
        paint.color =
            planet.owner == myId ? const Color(0xFF00FF00) : const Color(0xFFFF00FF);
      } else {
        paint.color = const Color(0xFF44AAFF);
      }

      canvas.drawCircle(
        Offset(planet.x, planet.y),
        planet.r,
        paint,
      );
    }

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

    if (planet.owner != null) {
      final ownerColor =
          planet.owner == myId ? const Color(0xFF00FF00) : const Color(0xFFFF00FF);
      _drawText(
        canvas,
        '[${planet.ownerUsername ?? "?"}]',
        Offset(planet.x, planet.y - planet.r - 3),
        ownerColor,
        10,
      );
    }
  }

  void _drawMissile(Canvas canvas, Missile m) {
      canvas.save();
      canvas.translate(m.x, m.y);

      final angle = atan2(m.vy, m.vx); 
      canvas.rotate(angle);

      final paint = Paint()
        ..color = Colors.orange
        ..strokeWidth = 2;

      canvas.drawLine(
        const Offset(-5, 0),
        const Offset(5, 0),
        paint,
      );

      canvas.restore();
    }

  void _drawText(Canvas canvas, String text, Offset position, Color color,
      double fontSize) {
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