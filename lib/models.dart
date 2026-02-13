class Player {
  final String id;
  final double x;
  final double y;
  final double rot;
  final int fuel;
  final int credits;
  final String username;

  Player({
    required this.id,
    required this.x,
    required this.y,
    required this.rot,
    required this.fuel,
    required this.credits,
    required this.username,
  });

  factory Player.fromJson(Map<String, dynamic> json) {
    return Player(
      id: json['id'] ?? '',
      x: (json['x'] ?? 0).toDouble(),
      y: (json['y'] ?? 0).toDouble(),
      rot: (json['rot'] ?? 0).toDouble(),
      fuel: json['fuel'] ?? 0,
      credits: json['credits'] ?? 0,
      username: json['username'] ?? '',
    );
  }
}

class Planet {
  final String id;
  final double x;
  final double y;
  final double r;
  final String name;
  final String? owner;
  final String? ownerUsername;

  Planet({
    required this.id,
    required this.x,
    required this.y,
    required this.r,
    required this.name,
    this.owner,
    this.ownerUsername,
  });

  factory Planet.fromJson(Map<String, dynamic> json) {
    return Planet(
      id: json['id'] ?? '',
      x: (json['x'] ?? 0).toDouble(),
      y: (json['y'] ?? 0).toDouble(),
      r: (json['r'] ?? 0).toDouble(),
      name: json['name'] ?? '',
      owner: json['owner'],
      ownerUsername: json['ownerUsername'],
    );
  }
}

class LandingPrompt {
  final String planetId;
  final String planetName;
  final bool isOwned;
  final bool isOwner;
  final String? owner;
  final int? rentPaid;
  final int claimCost;
  final int? currentCredits;

  LandingPrompt({
    required this.planetId,
    required this.planetName,
    required this.isOwned,
    required this.isOwner,
    this.owner,
    this.rentPaid,
    required this.claimCost,
    this.currentCredits,
  });

  factory LandingPrompt.fromJson(Map<String, dynamic> json) {
    return LandingPrompt(
      planetId: json['planetId'] ?? '',
      planetName: json['planetName'] ?? '',
      isOwned: json['isOwned'] ?? false,
      isOwner: json['isOwner'] ?? false,
      owner: json['owner'],
      rentPaid: json['rentPaid'],
      claimCost: json['claimCost'] ?? 0,
      currentCredits: json['currentCredits'],
    );
  }
}

class InputState {
  bool thrust;
  int rotate;
  bool brake;

  InputState({
    this.thrust = false,
    this.rotate = 0,
    this.brake = false,
  });

  Map<String, dynamic> toJson() {
    return {
      'thrust': thrust,
      'rotate': rotate,
      'brake': brake,
    };
  }
}