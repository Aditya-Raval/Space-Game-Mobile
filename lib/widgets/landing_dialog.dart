import 'package:flutter/material.dart';
import '../constants.dart';
import '../models.dart';

class LandingDialog extends StatelessWidget {
  final LandingPrompt prompt;
  final int myCredits;
  final Function(String) onClaim;
  final Function(int, bool) onRefuel;
  final Function(String) onRevoke;
  final VoidCallback onClose;

  const LandingDialog({
    super.key,
    required this.prompt,
    required this.myCredits,
    required this.onClaim,
    required this.onRefuel,
    required this.onRevoke,
    required this.onClose,
  });

  @override
  Widget build(BuildContext context) {
    final credits = prompt.currentCredits ?? myCredits;
    final creditsDisplay = '\$${credits.floor()}';
    final canClaim = credits >= prompt.claimCost;

    return Center(
      child: Container(
        constraints: const BoxConstraints(minWidth: 250, maxWidth: 300),
        decoration: BoxDecoration(
          color: Colors.black,
          border: Border.all(color: Colors.white, width: 1),
        ),
        padding: const EdgeInsets.all(15),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Planet name
            Text(
              prompt.planetName,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.bold,
                fontFamily: 'monospace',
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 10),
            
            // Conditional content based on ownership
            if (prompt.isOwned && prompt.isOwner) ...[
              const Text(
                'Your planet - Free refuel available',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontFamily: 'monospace',
                ),
              ),
              const SizedBox(height: 10),
              _buildButton(
                'Refuel Free',
                const Color(0xFF00FF00),
                () => onRefuel(GameConstants.freeRefuelAmount, true),
              ),
              const SizedBox(height: 5),
              _buildButton(
                'Revoke',
                const Color(0xFFFF0000),
                () => onRevoke(prompt.planetId),
              ),
            ] else if (prompt.isOwned && !prompt.isOwner) ...[
              Text(
                'Owned by: ${prompt.owner} | Rent: \$${prompt.rentPaid}',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontFamily: 'monospace',
                ),
              ),
              const SizedBox(height: 10),
              Text(
                'Credits: $creditsDisplay',
                style: const TextStyle(
                  color: Color(0xFFFFFF00),
                  fontSize: 12,
                  fontFamily: 'monospace',
                ),
              ),
              const SizedBox(height: 10),
              _buildButton(
                'Refuel \$${GameConstants.refuelCostPerTank}',
                const Color(0xFFFFFF00),
                () => onRefuel(GameConstants.paidRefuelAmount, false),
              ),
            ] else ...[
              Text(
                'Unclaimed - Claim for \$${prompt.claimCost}',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontFamily: 'monospace',
                ),
              ),
              const SizedBox(height: 10),
              Text(
                'Credits: $creditsDisplay',
                style: const TextStyle(
                  color: Color(0xFFFFFF00),
                  fontSize: 12,
                  fontFamily: 'monospace',
                ),
              ),
              const SizedBox(height: 10),
              if (canClaim) ...[
                _buildButton(
                  'Claim Planet',
                  const Color(0xFF00FF00),
                  () => onClaim(prompt.planetId),
                ),
                const SizedBox(height: 5),
              ] else ...[
                Text(
                  'Need \$${prompt.claimCost - credits.floor()} more',
                  style: const TextStyle(
                    color: Color(0xFFFF0000),
                    fontSize: 12,
                    fontFamily: 'monospace',
                  ),
                ),
                const SizedBox(height: 5),
              ],
              _buildButton(
                'Refuel \$${GameConstants.refuelCostPerTank}',
                const Color(0xFFFFFF00),
                () => onRefuel(GameConstants.paidRefuelAmount, false),
              ),
            ],
            
            const SizedBox(height: 5),
            _buildButton(
              'Close',
              const Color(0xFFAAAAAA),
              onClose,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildButton(String text, Color color, VoidCallback onPressed) {
    return OutlinedButton(
      onPressed: onPressed,
      style: OutlinedButton.styleFrom(
        backgroundColor: Colors.black,
        foregroundColor: color,
        side: BorderSide(color: color, width: 1),
        padding: const EdgeInsets.symmetric(vertical: 8),
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.zero,
        ),
      ),
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 12,
          fontFamily: 'monospace',
        ),
      ),
    );
  }
}