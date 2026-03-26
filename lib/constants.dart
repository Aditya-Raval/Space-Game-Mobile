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
  static const String httpBaseUrl = 'http://172.180.13.73:3000';
  static const String wsUrl = 'ws://172.180.13.73:8080';
}

// Message types matching the shared messageTypes
class MessageTypes {
  // Core
  static const String msgInput = 'input';
  static const String msgState = 'state';

  // Planets
  static const String msgClaimPlanet = 'claim_planet';
  static const String msgClaimResponse = 'claim_response';
  static const String msgRevokePlanet = 'revoke_planet';

  // Refuel
  static const String msgRefuel = 'refuel';
  static const String msgRefuelResponse = 'refuel_response';

  // Landing
  static const String msgLandingPrompt = 'landing_prompt';

  // Chat
  static const String msgChat = 'chat';
  static const String msgChatBroadcast = 'chat_broadcast';
  static const String msgChatError = 'chat_error';

  // Missile
  static const String msgFireMissile = 'fire_missile';
  static const String msgMissileUpdate = 'missile_update';
  static const String msgMissileHit = 'missile_hit';
}
