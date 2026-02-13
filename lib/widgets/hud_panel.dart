import 'package:flutter/material.dart';

class HudPanel extends StatelessWidget {
  final String playerName;
  final int credits;
  final int fuel;
  final int maxFuel;
  final int playerCount;
  final int ownedPlanetsCount;

  const HudPanel({
    super.key,
    required this.playerName,
    required this.credits,
    required this.fuel,
    required this.maxFuel,
    required this.playerCount,
    required this.ownedPlanetsCount,
  });

  @override
  Widget build(BuildContext context) {
    final fuelPercent = ((fuel / maxFuel) * 1000).floor();
    
    Color fuelBarColor;
    if (fuelPercent > 50) {
      fuelBarColor = const Color(0xFF00FF00);
    } else if (fuelPercent > 25) {
      fuelBarColor = const Color(0xFFFFFF00);
    } else {
      fuelBarColor = const Color(0xFFFF0000);
    }

    return Container(
      width: 200,
      height: 120,
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.8),
        border: Border.all(color: Colors.white, width: 1),
      ),
      padding: const EdgeInsets.all(10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Player name
          Text(
            'Player: $playerName',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 11,
              fontFamily: 'monospace',
            ),
          ),
          const SizedBox(height: 4),
          
          // Credits
          Text(
            'Credits: \$${credits.floor()}',
            style: const TextStyle(
              color: Color(0xFFFFFF00),
              fontSize: 11,
              fontFamily: 'monospace',
            ),
          ),
          const SizedBox(height: 4),
          
          // Fuel with bar
          Row(
            children: [
              Text(
                'Fuel: $fuelPercent%',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 11,
                  fontFamily: 'monospace',
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Stack(
                  children: [
                    // Background
                    Container(
                      height: 8,
                      decoration: BoxDecoration(
                        color: const Color(0xFF333333),
                        border: Border.all(color: Colors.white, width: 1),
                      ),
                    ),
                    // Fuel fill
                    FractionallySizedBox(
                      widthFactor: fuelPercent / 100,
                      child: Container(
                        height: 8,
                        color: fuelBarColor,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          
          // Players count
          Text(
            'Players: $playerCount',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 11,
              fontFamily: 'monospace',
            ),
          ),
          const SizedBox(height: 4),
          
          // Owned planets
          Text(
            'Owned: $ownedPlanetsCount',
            style: TextStyle(
              color: ownedPlanetsCount > 0 
                  ? const Color(0xFF00FF00) 
                  : const Color(0xFF888888),
              fontSize: 11,
              fontFamily: 'monospace',
            ),
          ),
        ],
      ),
    );
  }
}