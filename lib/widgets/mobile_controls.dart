import 'package:flutter/material.dart';

/// Mobile on-screen controls for devices without keyboard
/// Add this to game_screen.dart for mobile support
class MobileControls extends StatelessWidget {
  final Function(String) onControlPressed;
  final Function(String) onControlReleased;

  const MobileControls({
    super.key,
    required this.onControlPressed,
    required this.onControlReleased,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // Left side - Rotation controls
        Positioned(
          left: 20,
          bottom: 20,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildControlButton(
                icon: Icons.arrow_upward,
                label: 'W',
                onPressed: () => onControlPressed('w'),
                onReleased: () => onControlReleased('w'),
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  _buildControlButton(
                    icon: Icons.arrow_back,
                    label: 'A',
                    onPressed: () => onControlPressed('a'),
                    onReleased: () => onControlReleased('a'),
                  ),
                  const SizedBox(width: 10),
                  _buildControlButton(
                    icon: Icons.arrow_forward,
                    label: 'D',
                    onPressed: () => onControlPressed('d'),
                    onReleased: () => onControlReleased('d'),
                  ),
                ],
              ),
            ],
          ),
        ),
        
        // Right side - Brake
        Positioned(
          right: 20,
          bottom: 20,
          child: _buildControlButton(
            icon: Icons.arrow_downward,
            label: 'S',
            onPressed: () => onControlPressed('s'),
            onReleased: () => onControlReleased('s'),
            size: 70,
          ),
        ),
      ],
    );
  }

  Widget _buildControlButton({
    required IconData icon,
    required String label,
    required VoidCallback onPressed,
    required VoidCallback onReleased,
    double size = 60,
  }) {
    return GestureDetector(
      onTapDown: (_) => onPressed(),
      onTapUp: (_) => onReleased(),
      onTapCancel: onReleased,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: Colors.black.withOpacity(0.6),
          border: Border.all(color: Colors.white, width: 2),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: Colors.white, size: size * 0.4),
            Text(
              label,
              style: TextStyle(
                color: Colors.white,
                fontSize: size * 0.2,
                fontFamily: 'monospace',
              ),
            ),
          ],
        ),
      ),
    );
  }
}