import 'dart:math';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:green_object/games/neon_blaster/bloc/neon_blaster_event.dart';
import 'package:green_object/games/neon_blaster/bloc/neon_blaster_state.dart';
import 'package:green_object/utils/high_score_store.dart';

class NeonBlasterBloc extends Bloc<NeonBlasterEvent, NeonBlasterState> {
  static const double playerY = 0.9;

  static const double _minPlayerX = 0.08;
  static const double _maxPlayerX = 0.92;
  static const double _bulletSpeed = 1.55;
  static const double _enemySpeed = 0.18; // Slower start
  static const double _powerUpSpeed = 0.28;
  static const double _baseFireInterval = 0.16;
  static const double _baseSpawnInterval = 0.95;
  static const double _minSpawnInterval = 0.30;
  static const double _hitRadius = 0.04;
  static const int _overdriveChargeTarget = 25;
  static const double _overdriveDuration = 8.0;

  final Random _random = Random();

  NeonBlasterBloc() : super(const NeonBlasterState()) {
    on<NeonBlasterStarted>(_onStarted);
    on<NeonBlasterTicked>(_onTicked);
    on<NeonBlasterPlayerMoved>(_onPlayerMoved);
    on<NeonBlasterRestarted>(_onRestarted);
    on<NeonBlasterRevived>(_onRevived);
  }

  void _onStarted(NeonBlasterStarted event, Emitter<NeonBlasterState> emit) {
    final highScore = HighScoreStore.getHighScore('neonBlaster_highScore');
    emit(
      state.copyWith(
        status: NeonBlasterStatus.playing,
        score: event.bonusScore,
        highScore: highScore,
        level: 1,
        combo: 0,
        playerX: 0.5,
        bullets: const [],
        enemies: const [],
        powerUps: const [],
        spawnTimer: 0,
        powerSpawnTimer: 0,
        shotTimer: 0,
        doubleShotTimer: 0,
        rapidFireTimer: 0,
        slowMotionTimer: 0,
        circularFireTimer: 0,
        shieldTimer: 0,
        magnetTimer: 0,
        overdriveCharge: 0,
        overdriveTimer: 0,
        currentWavePattern: WavePattern.random,
        waveSpawnCount: 0,
        waveDelayTimer: 0,
      ),
    );
  }

  void _onRestarted(
    NeonBlasterRestarted event,
    Emitter<NeonBlasterState> emit,
  ) {
    add(NeonBlasterStarted(bonusScore: event.bonusScore));
  }

  void _onRevived(NeonBlasterRevived event, Emitter<NeonBlasterState> emit) {
    if (state.status != NeonBlasterStatus.gameOver || state.reviveUsed) return;

    emit(
      state.copyWith(
        status: NeonBlasterStatus.playing,
        bullets: [],
        enemies: [],
        powerUps: [],
        reviveUsed: true,
        shieldTimer: 3.0, // Grant temporary shield
        spawnTimer: 0,
        waveDelayTimer: 2.0, // Brief pause before enemies return
      ),
    );
  }

  void _onPlayerMoved(
    NeonBlasterPlayerMoved event,
    Emitter<NeonBlasterState> emit,
  ) {
    if (state.status != NeonBlasterStatus.playing) return;
    final x = event.normalizedX.clamp(_minPlayerX, _maxPlayerX);
    emit(state.copyWith(playerX: x));
  }

  void _onTicked(NeonBlasterTicked event, Emitter<NeonBlasterState> emit) {
    if (state.status != NeonBlasterStatus.playing) return;

    final dt = event.deltaTime;

    double doubleShotTimer = max(0.0, state.doubleShotTimer - dt);
    double rapidFireTimer = max(0.0, state.rapidFireTimer - dt);
    double slowMotionTimer = max(0.0, state.slowMotionTimer - dt);
    double circularFireTimer = max(0.0, state.circularFireTimer - dt);
    double shieldTimer = max(0.0, state.shieldTimer - dt);
    double magnetTimer = max(0.0, state.magnetTimer - dt);
    double overdriveTimer = max(0.0, state.overdriveTimer - dt);

    // Combo Heat System: 10x -> Double Shot, 25x -> Slow Motion
    if (state.combo >= 25 && !state.hasSlowMotion) {
      slowMotionTimer = 3.0; // 3 seconds slow motion
    } else if (state.combo >= 10) {
      // Passive double shot if not already active from powerup
      if (doubleShotTimer <= 0) doubleShotTimer = 0.1; // Keep it active
    }

    final hasRapid = rapidFireTimer > 0;
    final hasSlow = slowMotionTimer > 0;
    final hasDouble = doubleShotTimer > 0;
    final hasCircle = circularFireTimer > 0;
    final hasMagnet = magnetTimer > 0;
    final hasOverdrive = overdriveTimer > 0;

    final spawnInterval = max(
      _minSpawnInterval,
      _baseSpawnInterval -
          ((state.level - 1) *
              0.025), // Reduced from 0.04 to 0.025 for slower progression
    );
    final fireInterval = max(
      0.08,
      (_baseFireInterval - ((state.level - 1) * 0.005)) *
          (hasRapid ? 0.55 : 1.0) *
          (hasOverdrive ? 0.65 : 1.0),
    );
    final bulletSpeed = _bulletSpeed * (hasOverdrive ? 1.25 : 1.0);
    final enemySpeed =
        (_enemySpeed + state.level * 0.008) * // Reduced from 0.015 to 0.008
        (hasSlow ? 0.58 : 1.0);

    final List<BlasterBullet> bullets = [
      for (final b in state.bullets)
        BlasterBullet(
          x: b.x + (b.vx * bulletSpeed * dt),
          y: b.y + (b.vy * bulletSpeed * dt),
          vx: b.vx,
          vy: b.vy,
          damage: b.damage,
        ),
    ];

    // Enemy movement logic (incorporating Magnet)
    final List<BlasterEnemy> enemies = [];
    for (final e in state.enemies) {
      double newX = e.x;
      if (hasMagnet) {
        // Magnet effect: attract enemies towards player X
        // Only affect X to create "attract toward bullet path" feel
        final dx = state.playerX - e.x;
        // Move towards player with some speed, but clamp to not overshoot instantly
        final attractionSpeed = 0.3 * dt;
        if (dx.abs() > attractionSpeed) {
          newX += dx.sign * attractionSpeed;
        } else {
          newX = state.playerX;
        }
      }
      enemies.add(e.copyWith(x: newX, y: e.y + (enemySpeed * dt)));
    }

    final List<BlasterPowerUp> powerUps = [
      for (final p in state.powerUps) p.copyWith(y: p.y + (_powerUpSpeed * dt)),
    ];

    double nextShotTimer = state.shotTimer + dt;
    while (nextShotTimer >= fireInterval) {
      _spawnPlayerShot(
        bullets,
        playerX: state.playerX,
        hasDouble: hasDouble,
        hasCircular: hasCircle,
        hasOverdrive: hasOverdrive,
      );
      nextShotTimer -= fireInterval;
    }

    // Wave Spawning Logic
    double nextSpawnTimer = state.spawnTimer + dt;
    double nextWaveDelayTimer = max(0.0, state.waveDelayTimer - dt);
    WavePattern currentPattern = state.currentWavePattern;
    int waveSpawnCount = state.waveSpawnCount;

    if (nextWaveDelayTimer <= 0) {
      while (nextSpawnTimer >= spawnInterval) {
        // Determine if we need to switch pattern
        if (waveSpawnCount <= 0) {
          // Pick new pattern
          // Weighted random: 40% Random, 60% Patterned
          if (_random.nextDouble() < 0.4) {
            currentPattern = WavePattern.random;
            waveSpawnCount = 5 + _random.nextInt(5);
          } else {
            final patterns = [
              WavePattern.vShape,
              WavePattern.zigzag,
              WavePattern.rain,
              WavePattern.spiral,
            ];
            currentPattern = patterns[_random.nextInt(patterns.length)];
            waveSpawnCount =
                8 + _random.nextInt(8); // Pattern waves are slightly longer
          }
          // Add a small delay between waves
          nextWaveDelayTimer = 1.0;
          nextSpawnTimer = 0; // Reset spawn timer for the delay
          break; // Wait for delay
        }

        final enemy = _spawnWaveEnemy(
          state.level,
          currentPattern,
          waveSpawnCount,
        );
        enemies.add(enemy);
        waveSpawnCount--;
        nextSpawnTimer -=
            spawnInterval *
            (currentPattern == WavePattern.random
                ? 1.0
                : 0.6); // Patterns spawn faster
      }
    }

    double nextPowerSpawnTimer = state.powerSpawnTimer + dt;
    final powerSpawnInterval = max(4.6, 7.8 - (state.level * 0.2));
    while (nextPowerSpawnTimer >= powerSpawnInterval) {
      powerUps.add(_spawnPowerUp());
      nextPowerSpawnTimer -= powerSpawnInterval;
    }

    final activeBullets = bullets
        .where((b) => b.y > -0.25 && b.y < 1.25 && b.x > -0.25 && b.x < 1.25)
        .toList();
    final activeEnemies = enemies.where((e) => e.y < 1.25 && e.hp > 0).toList();
    final activePowerUps = powerUps.where((p) => p.y < 1.25).toList();

    final Set<int> consumedBullets = <int>{};
    final Set<int> consumedPowerUps = <int>{};
    final List<BlasterEnemy> mutableEnemies = List<BlasterEnemy>.from(
      activeEnemies,
    );

    int kills = 0;
    int destroyedHpTotal = 0;

    for (var bi = 0; bi < activeBullets.length; bi++) {
      if (consumedBullets.contains(bi)) continue;
      final bullet = activeBullets[bi];
      for (var ei = 0; ei < mutableEnemies.length; ei++) {
        final enemy = mutableEnemies[ei];
        final dx = enemy.x - bullet.x;
        final dy = enemy.y - bullet.y;
        final r = enemy.radius + _hitRadius;
        if ((dx * dx) + (dy * dy) > (r * r)) continue;

        consumedBullets.add(bi);
        final nextHp = enemy.hp - bullet.damage;
        if (nextHp <= 0) {
          kills++;
          destroyedHpTotal += enemy.maxHp;
          mutableEnemies[ei] = enemy.copyWith(hp: 0);

          if (_random.nextDouble() < 0.18) {
            activePowerUps.add(_spawnPowerUp(x: enemy.x, y: enemy.y));
          }
        } else {
          mutableEnemies[ei] = enemy.copyWith(hp: nextHp);
        }
        break;
      }
    }

    List<BlasterEnemy> remainingEnemies = [
      for (final e in mutableEnemies)
        if (e.hp > 0) e,
    ];
    final remainingBullets = [
      for (var i = 0; i < activeBullets.length; i++)
        if (!consumedBullets.contains(i)) activeBullets[i],
    ];

    for (var pi = 0; pi < activePowerUps.length; pi++) {
      final p = activePowerUps[pi];
      final dx = p.x - state.playerX;
      final dy = p.y - playerY;
      final r = p.radius + 0.045;
      if ((dx * dx) + (dy * dy) <= (r * r)) {
        consumedPowerUps.add(pi);
        final duration = 10.0 + (_random.nextDouble() * 5.0);
        switch (p.type) {
          case BlasterPowerType.doubleShot:
            doubleShotTimer = max(doubleShotTimer, duration);
            break;
          case BlasterPowerType.rapidFire:
            rapidFireTimer = max(rapidFireTimer, duration);
            break;
          case BlasterPowerType.slowMotion:
            slowMotionTimer = max(slowMotionTimer, duration);
            break;
          case BlasterPowerType.circularFire:
            circularFireTimer = max(circularFireTimer, duration);
            break;
          case BlasterPowerType.shield:
            shieldTimer = max(shieldTimer, duration);
            break;
          case BlasterPowerType.magnet:
            magnetTimer = max(magnetTimer, duration);
            break;
        }
      }
    }

    final remainingPowerUps = [
      for (var i = 0; i < activePowerUps.length; i++)
        if (!consumedPowerUps.contains(i)) activePowerUps[i],
    ];

    // Core Combo Logic: Reset if missed (enemy moved past player or hit bottom)
    // Actually the requirement says "If one rock hits ground → combo reset."
    // We detect hitting ground/player in the GameOver check below.
    // If an enemy passes the player without hitting them (not possible in this game as player is at bottom and they hit player),
    // wait, if enemy hits player = game over.
    // "If one rock hits ground -> combo reset" implies rocks can miss the player and hit the ground?
    // In current logic: `if (enemy.y >= playerY - 0.02) { gameOver = true; ... }`
    // So usually hitting bottom means Game Over.
    // BUT, maybe the user wants a mechanic where rocks can pass by?
    // "Destroy rocks continuously without missing." usually means "don't let any rock pass".
    // If "rock hits ground -> combo reset" but also "hits ground -> game over", then combo reset is redundant on Game Over.
    // However, maybe the user allows rocks to pass if they don't hit the player?
    // Let's assume standard "Game Over" on reach bottom logic stays, but maybe we add a 'miss' mechanic?
    // Or maybe the user implies "If you MISS a shot and it hits the top?" No, "rock hits ground".
    // Let's assume hitting ground = combo reset (and likely game over, unless we change that).
    // Actually, "If one rock hits ground -> combo reset. Destroy rocks continuously without missing."
    // This sounds like "Don't let rocks leave the screen".
    // Since hitting ground causes Game Over currently, maybe I should relax the Game Over condition?
    // Or maybe just stick to: Game Over resets everything anyway.
    // Let's assume the user wants `Combo` to be a "Heat" gauge.
    // If I miss a shot? No "Destroy rocks ... without missing".
    // A strict interpretation: If a rock passes the player line (and doesn't kill them?), reset combo.
    // But currently rock passing line = Death.
    // I will keep Death on rock passing line.

    // BUT! "Destroy rocks continuously without missing" could mean "Accuracy".
    // "without missing" -> "Every bullet hits a rock"?
    // "If one rock hits ground -> combo reset". This aligns with "Don't let them pass".
    // Scaling combo is fine.

    // NEW LOGIC: reset combo to 0 if we haven't killed anything for a while?
    // No, strictly "If one rock hits ground".
    // Let's implement: If enemies escape (if we allow them to escape), reset combo.
    // Currently enemies kill you.
    // I will adhere to: Game Over is the ultimate combo reset.
    // Effectively, combo builds up as long as you play.

    int nextCombo = kills > 0 ? min(state.combo + kills, 50) : state.combo;
    // Requirement: "If one rock hits ground → combo reset."
    // If I interpret this as "If a rock hits the bottom of the screen".
    // I'll check if any enemy reached the bottom.
    // If we want to allow rocks to hit ground WITHOUT dying, I'd need to change Game Over logic.
    // "Neon Blaster" usually implies "Defense".
    // Let's assume "Hits Ground" = "Game Over" stays.
    // Use the `kills > 0` to increase combo.
    // Note: Use `state.combo` not decreasing on time is good for "Heat" feeling.

    int nextOverdriveCharge = state.overdriveCharge;
    if (kills > 0) {
      nextOverdriveCharge += kills * 2 + (destroyedHpTotal ~/ 6);
      nextOverdriveCharge = min(nextOverdriveCharge, _overdriveChargeTarget);
      if (nextOverdriveCharge >= _overdriveChargeTarget) {
        overdriveTimer = max(overdriveTimer, _overdriveDuration);
        nextOverdriveCharge = 0;
      }
    }

    final multiplier = 1 + (nextCombo ~/ 6) + ((overdriveTimer > 0) ? 2 : 0);
    final scoreGain = (kills * 12 + destroyedHpTotal * 3) * multiplier;
    final nextScore = state.score + scoreGain;
    final nextLevel = 1 + (nextScore ~/ 250);

    bool gameOver = false;
    int collidingEnemyIndex = -1;
    for (var i = 0; i < remainingEnemies.length; i++) {
      final enemy = remainingEnemies[i];
      if (enemy.y >= playerY - 0.02) {
        // Rock hit ground/player level
        gameOver = true;
        collidingEnemyIndex = i;
        break;
      }
      final dx = enemy.x - state.playerX;
      final dy = enemy.y - playerY;
      final r = enemy.radius + 0.04;
      if ((dx * dx) + (dy * dy) <= (r * r)) {
        gameOver = true;
        collidingEnemyIndex = i;
        break;
      }
    }

    if (gameOver && shieldTimer > 0 && collidingEnemyIndex >= 0) {
      shieldTimer = 0;
      gameOver = false;
      // Shield saves you, effectively rock is destroyed or pushed back?
      // Let's destroy it.
      remainingEnemies.removeAt(collidingEnemyIndex);
      // Also reset combo on hit? User didn't say. "If one rock hits ground".
      // Shield prevents it from hitting ground/player technically.
      // I'll keep combo.
    }

    // Explicit Loop reset if game over
    if (gameOver) {
      nextCombo =
          0; // Combo reset on game over (implicit, but good to be explicit for heat system state)
    }

    if (gameOver) {
      final nextHighScore = nextScore > state.highScore
          ? nextScore
          : state.highScore;
      if (nextHighScore != state.highScore) {
        _saveHighScore(nextHighScore);
      }
      emit(
        state.copyWith(
          status: NeonBlasterStatus.gameOver,
          score: nextScore,
          highScore: nextHighScore,
          bullets: remainingBullets,
          enemies: remainingEnemies,
          powerUps: remainingPowerUps,
          combo: 0, // Reset combo
          doubleShotTimer: doubleShotTimer,
          rapidFireTimer: rapidFireTimer,
          slowMotionTimer: slowMotionTimer,
          circularFireTimer: circularFireTimer,
          shieldTimer: shieldTimer,
          magnetTimer: magnetTimer,
          overdriveCharge: nextOverdriveCharge,
          overdriveTimer: overdriveTimer,
          currentWavePattern: currentPattern, // Persist current pattern state
          waveSpawnCount: waveSpawnCount,
          waveDelayTimer: nextWaveDelayTimer,
        ),
      );
      return;
    }

    emit(
      state.copyWith(
        score: nextScore,
        level: nextLevel,
        combo: nextCombo,
        bullets: remainingBullets,
        enemies: remainingEnemies,
        powerUps: remainingPowerUps,
        shotTimer: nextShotTimer,
        spawnTimer: nextSpawnTimer,
        powerSpawnTimer: nextPowerSpawnTimer,
        doubleShotTimer: doubleShotTimer,
        rapidFireTimer: rapidFireTimer,
        slowMotionTimer: slowMotionTimer,
        circularFireTimer: circularFireTimer,
        shieldTimer: shieldTimer,
        magnetTimer: magnetTimer,
        overdriveCharge: nextOverdriveCharge,
        overdriveTimer: overdriveTimer,
        currentWavePattern: currentPattern,
        waveSpawnCount: waveSpawnCount,
        waveDelayTimer: nextWaveDelayTimer,
      ),
    );
  }

  void _spawnPlayerShot(
    List<BlasterBullet> bullets, {
    required double playerX,
    required bool hasDouble,
    required bool hasCircular,
    required bool hasOverdrive,
  }) {
    final damage = hasOverdrive ? 2 : 1;
    bullets.add(
      BlasterBullet(
        x: playerX,
        y: playerY - 0.05,
        vx: 0,
        vy: -1,
        damage: damage,
      ),
    );

    if (hasDouble) {
      bullets.add(
        BlasterBullet(
          x: max(_minPlayerX, playerX - 0.03),
          y: playerY - 0.045,
          vx: -0.08,
          vy: -1,
          damage: damage,
        ),
      );
      bullets.add(
        BlasterBullet(
          x: min(_maxPlayerX, playerX + 0.03),
          y: playerY - 0.045,
          vx: 0.08,
          vy: -1,
          damage: damage,
        ),
      );
    }

    if (hasCircular) {
      for (int i = 0; i < 10; i++) {
        final angle = (2 * pi * i) / 10;
        bullets.add(
          BlasterBullet(
            x: playerX,
            y: playerY - 0.03,
            vx: cos(angle),
            vy: sin(angle),
            damage: damage,
          ),
        );
      }
    }
  }

  BlasterEnemy _spawnWaveEnemy(int level, WavePattern pattern, int stepCount) {
    int hp;
    // Base stats
    final pool = <int>[1, 1, 1, 2, 2, 3, 5, 5, 8, 10];
    hp = pool[_random.nextInt(pool.length)] + (level ~/ 8);

    double x = 0.5;
    double y = -0.08;

    switch (pattern) {
      case WavePattern.random:
        x = 0.08 + _random.nextDouble() * 0.84;
        break;
      case WavePattern.vShape:
        // V-Shape: Center first, then move outwards
        // stepCount goes down.
        // e.g. 8, 7, 6, 5...
        // Let's use stepCount to determine position relative to center
        // V shape usually means 1 at center, then 2 slightly up/out, etc.
        // OR spawning sequentially: Center, Left, Right ...
        // Let's do: | \ / |
        // x moves from 0.5 outwards based on step count?
        // Simple V: spawn at x = 0.5 + offset * direction
        final offset = (8 - stepCount).abs() * 0.1;
        final direction = (stepCount % 2 == 0) ? 1.0 : -1.0;
        x = 0.5 + (offset * direction);
        break;
      case WavePattern.zigzag:
        // Zigzag: x moves back and forth
        // Sine wave based on stepCount
        x = 0.5 + 0.4 * sin(stepCount * 0.8);
        break;
      case WavePattern.rain:
        // Rain: Horizontal line or random columns but very frequent
        // "Straight Rain" -> uniform distribution across top
        // Let's act as "Curtain"
        final slots = 8;
        final slot = stepCount % slots;
        x = 0.1 + (slot * 0.11);
        break;
      case WavePattern.spiral:
        // Spiral: Circular pattern of spawn points?
        // x moves in circle?
        // x = 0.5 + 0.4 * cos(theta)
        x = 0.5 + 0.4 * cos(stepCount * 0.5);
        break;
    }

    // Clamp x
    x = x.clamp(0.08, 0.92);

    return BlasterEnemy(
      x: x,
      y: y,
      radius: 0.03 + min(0.02, hp * 0.0012),
      hp: hp,
      maxHp: hp,
      isBoss: false,
    );
  }

  BlasterPowerUp _spawnPowerUp({double? x, double? y}) {
    final types = BlasterPowerType.values;
    return BlasterPowerUp(
      x: (x ?? (0.08 + _random.nextDouble() * 0.84)).clamp(0.08, 0.92),
      y: y ?? -0.08,
      radius: 0.028,
      type: types[_random.nextInt(types.length)],
    );
  }

  Future<void> _saveHighScore(int score) async {
    await HighScoreStore.setHighScore('neonBlaster_highScore', score);
  }
}
