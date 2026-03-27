import 'dart:math';
import 'package:flutter/material.dart';

/// Mobile on-screen controls with a virtual joystick for rotation
/// and dedicated Thrust / Brake buttons.
///
/// Joystick outputs:
///   - Tilt left  → onControlPressed('a') / onControlReleased('a')
///   - Tilt right → onControlPressed('d') / onControlReleased('d')
///
/// Buttons:
///   - Thrust (top-right) → onControlPressed('w') / onControlReleased('w')
///   - Brake  (bot-right) → onControlPressed('s') / onControlReleased('s')
class MobileControls extends StatefulWidget {
  final Function(String) onControlPressed;
  final Function(String) onControlReleased;

  const MobileControls({
    super.key,
    required this.onControlPressed,
    required this.onControlReleased,
  });

  @override
  State<MobileControls> createState() => _MobileControlsState();
}

class _MobileControlsState extends State<MobileControls> {
  // ── Joystick state ───────────────────────────────────────────────────────
  Offset _stickOffset = Offset.zero; // current knob position (relative to base centre)
  bool _joystickActive = false;
  Offset _joystickOrigin = Offset.zero; // base centre in global coordinates

  static const double _baseRadius = 55.0;
  static const double _knobRadius = 24.0;
  static const double _deadZone = 0.25; // fraction of baseRadius

  // Which directions are currently "held"
  String? _currentHorizontal; // 'a' | 'd' | null

  // ── Action button state ──────────────────────────────────────────────────
  bool _thrustActive = false;
  bool _brakeActive = false;
  bool _fireActive = false;

  // ── Joystick gesture handlers ────────────────────────────────────────────

  void _onJoystickStart(DragStartDetails d) {
    setState(() {
      _joystickActive = true;
      _joystickOrigin = d.globalPosition;
      _stickOffset = Offset.zero;
    });
  }

  void _onJoystickUpdate(DragUpdateDetails d) {
    final raw = d.globalPosition - _joystickOrigin;
    final dist = raw.distance;
    final clamped = dist <= _baseRadius
        ? raw
        : raw / dist * _baseRadius;

    setState(() => _stickOffset = clamped);

    final nx = clamped.dx / _baseRadius; // normalised –1 … +1

    if (nx < -_deadZone) {
      _setHorizontal('a');
    } else if (nx > _deadZone) {
      _setHorizontal('d');
    } else {
      _clearHorizontal();
    }
  }

  void _onJoystickEnd(DragEndDetails _) => _releaseJoystick();
  void _onJoystickCancel() => _releaseJoystick();

  void _releaseJoystick() {
    _clearHorizontal();
    setState(() {
      _joystickActive = false;
      _stickOffset = Offset.zero;
    });
  }

  void _setHorizontal(String dir) {
    if (_currentHorizontal == dir) return;
    if (_currentHorizontal != null) {
      widget.onControlReleased(_currentHorizontal!);
    }
    _currentHorizontal = dir;
    widget.onControlPressed(dir);
  }

  void _clearHorizontal() {
    if (_currentHorizontal != null) {
      widget.onControlReleased(_currentHorizontal!);
      _currentHorizontal = null;
    }
  }

  // ── Build ────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // ── LEFT: Virtual joystick ─────────────────────────────────────────
        Positioned(
          left: 24,
          bottom: 24,
          child: _buildJoystick(),
        ),

        // ── RIGHT: Thrust + Brake ──────────────────────────────────────────
        Positioned(
          right: 24,
          bottom: 24,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildActionButton(
                label: 'THRUST',
                icon: Icons.arrow_upward_rounded,
                active: _thrustActive,
                color: const Color(0xFF00E5FF),
                onDown: () {
                  setState(() => _thrustActive = true);
                  widget.onControlPressed('w');
                },
                onUp: () {
                  setState(() => _thrustActive = false);
                  widget.onControlReleased('w');
                },
              ),
              const SizedBox(height: 16),
              _buildActionButton(
                label: 'FIRE',
                icon: Icons.gps_fixed_rounded,
                active: _fireActive,
                color: const Color(0xFFFFAA00),
                onDown: () {
                  setState(() => _fireActive = true);
                  widget.onControlPressed('f');
                },
                onUp: () {
                  setState(() => _fireActive = false);
                  widget.onControlReleased('f');
                },
              ),
              const SizedBox(height: 16),
              _buildActionButton(
                label: 'BRAKE',
                icon: Icons.arrow_downward_rounded,
                active: _brakeActive,
                color: const Color(0xFFFF3D57),
                onDown: () {
                  setState(() => _brakeActive = true);
                  widget.onControlPressed('s');
                },
                onUp: () {
                  setState(() => _brakeActive = false);
                  widget.onControlReleased('s');
                },
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ── Joystick widget ──────────────────────────────────────────────────────

  Widget _buildJoystick() {
    // The touch area is slightly larger than the visible base so it's easy to grab.
    const touchSize = (_baseRadius + 20) * 2;

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onPanStart: _onJoystickStart,
      onPanUpdate: _onJoystickUpdate,
      onPanEnd: _onJoystickEnd,
      onPanCancel: _onJoystickCancel,
      child: SizedBox(
        width: touchSize,
        height: touchSize,
        child: Stack(
          alignment: Alignment.center,
          children: [
            // Outer ring / base
            Container(
              width: _baseRadius * 2,
              height: _baseRadius * 2,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.black.withOpacity(0.45),
                border: Border.all(
                  color: Colors.white.withOpacity(0.35),
                  width: 2,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.white.withOpacity(0.08),
                    blurRadius: 12,
                    spreadRadius: 2,
                  ),
                ],
              ),
              child: CustomPaint(
                painter: _JoystickGuidePainter(),
              ),
            ),

            // Knob
            Transform.translate(
              offset: _stickOffset,
              child: AnimatedContainer(
                duration: _joystickActive
                    ? Duration.zero
                    : const Duration(milliseconds: 180),
                curve: Curves.easeOut,
                width: _knobRadius * 2,
                height: _knobRadius * 2,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      Colors.white.withOpacity(0.95),
                      Colors.white.withOpacity(0.55),
                    ],
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.white.withOpacity(0.4),
                      blurRadius: 10,
                      spreadRadius: 1,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Action button widget ─────────────────────────────────────────────────

  Widget _buildActionButton({
    required String label,
    required IconData icon,
    required bool active,
    required Color color,
    required VoidCallback onDown,
    required VoidCallback onUp,
  }) {
    const size = 72.0;
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTapDown: (_) => onDown(),
      onTapUp: (_) => onUp(),
      onTapCancel: onUp,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 80),
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: active
              ? color.withOpacity(0.85)
              : Colors.black.withOpacity(0.50),
          border: Border.all(
            color: active ? color : color.withOpacity(0.45),
            width: 2.5,
          ),
          boxShadow: active
              ? [
                  BoxShadow(
                    color: color.withOpacity(0.55),
                    blurRadius: 18,
                    spreadRadius: 3,
                  ),
                ]
              : [],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              color: active ? Colors.black : color,
              size: 26,
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: TextStyle(
                color: active ? Colors.black : color,
                fontSize: 9,
                fontWeight: FontWeight.w800,
                letterSpacing: 1.2,
                fontFamily: 'monospace',
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Guide lines painted inside the joystick base ─────────────────────────────

class _JoystickGuidePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withOpacity(0.12)
      ..strokeWidth = 1.0
      ..style = PaintingStyle.stroke;

    final cx = size.width / 2;
    final cy = size.height / 2;
    final r = cx;

    // Cross-hair lines
    canvas.drawLine(Offset(cx - r * 0.65, cy), Offset(cx + r * 0.65, cy), paint);
    canvas.drawLine(Offset(cx, cy - r * 0.65), Offset(cx, cy + r * 0.65), paint);

    // Inner dashed circle (dead-zone indicator)
    const segments = 20;
    final dzR = r * 0.28;
    for (int i = 0; i < segments; i++) {
      if (i.isOdd) continue;
      final a1 = 2 * pi * i / segments;
      final a2 = 2 * pi * (i + 1) / segments;
      canvas.drawArc(
        Rect.fromCircle(center: Offset(cx, cy), radius: dzR),
        a1,
        a2 - a1,
        false,
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(_JoystickGuidePainter old) => false;
}