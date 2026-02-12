import 'package:equatable/equatable.dart';

enum NeonBlasterStatus { initial, playing, gameOver }

enum BlasterPowerType {
  doubleShot,
  rapidFire,
  slowMotion,
  circularFire,
  shield,
  magnet,
}

enum WavePattern { random, vShape, zigzag, rain, spiral }

class BlasterBullet extends Equatable {
  final double x;
  final double y;
  final double vx;
  final double vy;
  final int damage;

  const BlasterBullet({
    required this.x,
    required this.y,
    required this.vx,
    required this.vy,
    this.damage = 1,
  });

  @override
  List<Object> get props => [x, y, vx, vy, damage];
}

class BlasterEnemy extends Equatable {
  final double x;
  final double y;
  final double radius;
  final int hp;
  final int maxHp;
  final bool isBoss;

  const BlasterEnemy({
    required this.x,
    required this.y,
    required this.radius,
    required this.hp,
    required this.maxHp,
    this.isBoss = false,
  });

  BlasterEnemy copyWith({
    double? x,
    double? y,
    double? radius,
    int? hp,
    int? maxHp,
    bool? isBoss,
  }) {
    return BlasterEnemy(
      x: x ?? this.x,
      y: y ?? this.y,
      radius: radius ?? this.radius,
      hp: hp ?? this.hp,
      maxHp: maxHp ?? this.maxHp,
      isBoss: isBoss ?? this.isBoss,
    );
  }

  @override
  List<Object> get props => [x, y, radius, hp, maxHp, isBoss];
}

class BlasterPowerUp extends Equatable {
  final double x;
  final double y;
  final double radius;
  final BlasterPowerType type;

  const BlasterPowerUp({
    required this.x,
    required this.y,
    required this.radius,
    required this.type,
  });

  BlasterPowerUp copyWith({double? x, double? y, double? radius}) {
    return BlasterPowerUp(
      x: x ?? this.x,
      y: y ?? this.y,
      radius: radius ?? this.radius,
      type: type,
    );
  }

  @override
  List<Object> get props => [x, y, radius, type];
}

class NeonBlasterState extends Equatable {
  final NeonBlasterStatus status;
  final int score;
  final int highScore;
  final int level;
  final int combo;
  final double playerX;
  final List<BlasterBullet> bullets;
  final List<BlasterEnemy> enemies;
  final List<BlasterPowerUp> powerUps;
  final double spawnTimer;
  final double powerSpawnTimer;
  final double shotTimer;
  final double doubleShotTimer;
  final double rapidFireTimer;
  final double slowMotionTimer;
  final double circularFireTimer;
  final double shieldTimer;
  final double magnetTimer;
  final int overdriveCharge;
  final double overdriveTimer;
  final WavePattern currentWavePattern;
  final int waveSpawnCount;
  final double waveDelayTimer;

  const NeonBlasterState({
    this.status = NeonBlasterStatus.initial,
    this.score = 0,
    this.highScore = 0,
    this.level = 1,
    this.combo = 0,
    this.playerX = 0.5,
    this.bullets = const [],
    this.enemies = const [],
    this.powerUps = const [],
    this.spawnTimer = 0,
    this.powerSpawnTimer = 0,
    this.shotTimer = 0,
    this.doubleShotTimer = 0,
    this.rapidFireTimer = 0,
    this.slowMotionTimer = 0,
    this.circularFireTimer = 0,
    this.shieldTimer = 0,
    this.magnetTimer = 0,
    this.overdriveCharge = 0,
    this.overdriveTimer = 0,
    this.currentWavePattern = WavePattern.random,
    this.waveSpawnCount = 0,
    this.waveDelayTimer = 0,
    this.reviveUsed = false,
  });

  NeonBlasterState copyWith({
    NeonBlasterStatus? status,
    int? score,
    int? highScore,
    int? level,
    int? combo,
    double? playerX,
    List<BlasterBullet>? bullets,
    List<BlasterEnemy>? enemies,
    List<BlasterPowerUp>? powerUps,
    double? spawnTimer,
    double? powerSpawnTimer,
    double? shotTimer,
    double? doubleShotTimer,
    double? rapidFireTimer,
    double? slowMotionTimer,
    double? circularFireTimer,
    double? shieldTimer,
    double? magnetTimer,
    int? overdriveCharge,
    double? overdriveTimer,
    WavePattern? currentWavePattern,
    int? waveSpawnCount,
    double? waveDelayTimer,
    bool? reviveUsed,
  }) {
    return NeonBlasterState(
      status: status ?? this.status,
      score: score ?? this.score,
      highScore: highScore ?? this.highScore,
      level: level ?? this.level,
      combo: combo ?? this.combo,
      playerX: playerX ?? this.playerX,
      bullets: bullets ?? this.bullets,
      enemies: enemies ?? this.enemies,
      powerUps: powerUps ?? this.powerUps,
      spawnTimer: spawnTimer ?? this.spawnTimer,
      powerSpawnTimer: powerSpawnTimer ?? this.powerSpawnTimer,
      shotTimer: shotTimer ?? this.shotTimer,
      doubleShotTimer: doubleShotTimer ?? this.doubleShotTimer,
      rapidFireTimer: rapidFireTimer ?? this.rapidFireTimer,
      slowMotionTimer: slowMotionTimer ?? this.slowMotionTimer,
      circularFireTimer: circularFireTimer ?? this.circularFireTimer,
      shieldTimer: shieldTimer ?? this.shieldTimer,
      magnetTimer: magnetTimer ?? this.magnetTimer,
      overdriveCharge: overdriveCharge ?? this.overdriveCharge,
      overdriveTimer: overdriveTimer ?? this.overdriveTimer,
      currentWavePattern: currentWavePattern ?? this.currentWavePattern,
      waveSpawnCount: waveSpawnCount ?? this.waveSpawnCount,
      waveDelayTimer: waveDelayTimer ?? this.waveDelayTimer,
      reviveUsed: reviveUsed ?? this.reviveUsed,
    );
  }

  final bool reviveUsed;

  bool get hasDoubleShot => doubleShotTimer > 0;
  bool get hasRapidFire => rapidFireTimer > 0;
  bool get hasSlowMotion => slowMotionTimer > 0;
  bool get hasCircularFire => circularFireTimer > 0;
  bool get hasShield => shieldTimer > 0;
  bool get hasMagnet => magnetTimer > 0;
  bool get hasOverdrive => overdriveTimer > 0;

  @override
  List<Object> get props => [
    status,
    score,
    highScore,
    level,
    combo,
    playerX,
    bullets,
    enemies,
    powerUps,
    spawnTimer,
    powerSpawnTimer,
    shotTimer,
    doubleShotTimer,
    rapidFireTimer,
    slowMotionTimer,
    circularFireTimer,
    shieldTimer,
    magnetTimer,
    overdriveCharge,
    overdriveTimer,
    currentWavePattern,
    waveSpawnCount,
    waveDelayTimer,
    reviveUsed,
  ];
}
