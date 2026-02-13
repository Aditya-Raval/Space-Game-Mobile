// Game constants matching the original JavaScript constants
class GameConstants {
  // Fuel constants
  static const int maxFuel = 1000;
  static const int freeRefuelAmount = 1000;
  static const int paidRefuelAmount = 500;
  static const int refuelCostPerTank = 100;
  
  // Planet constants
  static const int planetClaimCost = 500;
  
  // Network constants
  static const String httpBaseUrl = 'http://localhost:3000';
  static const String wsUrl = 'ws://localhost:8080';
}

// Message types matching the shared messageTypes
class MessageTypes {
  static const String msgInput = 'input';
  static const String msgState = 'state';
  static const String msgClaimPlanet = 'claim_planet';
  static const String msgClaimResponse = 'claim_response';
  static const String msgRefuel = 'refuel';
  static const String msgRefuelResponse = 'refuel_response';
  static const String msgRevokePlanet = 'revoke_planet';
  static const String msgLandingPrompt = 'landing_prompt';
}
