import 'package:flutter/services.dart';
import 'dart:math' as math;

class Enemy {
  final int id;
  final String name;
  final String emoji;
  final int baseHP;
  final double baseDamageMultiplier;
  final int difficultyLevel;
  final String type;
  final String? specialAbilityId;
  final String? specialAbilityDescription;

  const Enemy({
    required this.id,
    required this.name,
    required this.emoji,
    required this.baseHP,
    required this.baseDamageMultiplier,
    required this.difficultyLevel,
    required this.type,
    this.specialAbilityId,
    this.specialAbilityDescription,
  });

  bool get isBoss => type == 'boss';

  int getHP(int floor) {
    final floorMultiplier = 1.0 + (floor - 1) * 0.15;
    return (baseHP * floorMultiplier).round();
  }

  double getDamageMultiplier(int floor) {
    final floorMultiplier = 1.0 + (floor - 1) * 0.1;
    return baseDamageMultiplier * floorMultiplier;
  }

  factory Enemy.fromCsv(List<String> row) {
    return Enemy(
      id: int.parse(row[0]),
      name: row[1],
      emoji: row[2],
      baseHP: int.parse(row[3]),
      baseDamageMultiplier: double.parse(row[4]),
      difficultyLevel: int.parse(row[5]),
      type: row[6],
      specialAbilityId: row[7].isEmpty ? null : row[7],
      specialAbilityDescription: row[8].isEmpty ? null : row[8],
    );
  }
}

class EnemyManager {
  static List<Enemy>? _enemies;
  static final _random = math.Random();

  static Future<List<Enemy>> loadEnemies() async {
    if (_enemies != null) return _enemies!;

    try {
      final csvString = await rootBundle.loadString('assets/enemies.csv');
      final lines = csvString.split('\n');

      _enemies = <Enemy>[];

      for (int i = 1; i < lines.length; i++) {
        final line = lines[i].trim();
        if (line.isEmpty) continue;

        final row = line.split(',');
        if (row.length >= 9) {
          _enemies!.add(Enemy.fromCsv(row));
        }
      }

      return _enemies!;
    } catch (e) {
      _enemies = _getDefaultEnemies();
      return _enemies!;
    }
  }

  static List<Enemy> _getDefaultEnemies() {
    return [
      const Enemy(
        id: 1,
        name: 'Yılan Savaşçısı',
        emoji: '🐍',
        baseHP: 60,
        baseDamageMultiplier: 0.8,
        difficultyLevel: 1,
        type: 'normal',
      ),
      const Enemy(
        id: 2,
        name: 'Karanlık Yarasa',
        emoji: '🦇',
        baseHP: 70,
        baseDamageMultiplier: 0.9,
        difficultyLevel: 1,
        type: 'normal',
      ),
      const Enemy(
        id: 3,
        name: 'Buzul Kurdı',
        emoji: '🐺',
        baseHP: 65,
        baseDamageMultiplier: 0.85,
        difficultyLevel: 1,
        type: 'normal',
      ),
      const Enemy(
        id: 4,
        name: 'Zehirli Akrep',
        emoji: '🦂',
        baseHP: 75,
        baseDamageMultiplier: 0.95,
        difficultyLevel: 1,
        type: 'normal',
      ),
      const Enemy(
        id: 5,
        name: 'Ateş Ejderi',
        emoji: '🔥',
        baseHP: 90,
        baseDamageMultiplier: 1.1,
        difficultyLevel: 2,
        type: 'normal',
      ),
      const Enemy(
        id: 6,
        name: 'Gölge Katili',
        emoji: '🥷',
        baseHP: 100,
        baseDamageMultiplier: 1.2,
        difficultyLevel: 2,
        type: 'normal',
      ),
      const Enemy(
        id: 7,
        name: 'Ruh Avcısı',
        emoji: '👻',
        baseHP: 95,
        baseDamageMultiplier: 1.15,
        difficultyLevel: 2,
        type: 'normal',
      ),
      const Enemy(
        id: 8,
        name: 'Fırtına Şamanı',
        emoji: '⚡',
        baseHP: 110,
        baseDamageMultiplier: 1.25,
        difficultyLevel: 2,
        type: 'normal',
      ),
      const Enemy(
        id: 9,
        name: 'Taş Devi',
        emoji: '⛰️',
        baseHP: 200,
        baseDamageMultiplier: 1.6,
        difficultyLevel: 3,
        type: 'boss',
        specialAbilityId: 'earth_shield',
        specialAbilityDescription: 'Aldığı hasarı %25 azaltır',
      ),
      const Enemy(
        id: 9,
        name: 'Kristal Golem',
        emoji: '💎',
        baseHP: 130,
        baseDamageMultiplier: 1.4,
        difficultyLevel: 3,
        type: 'normal',
      ),
      const Enemy(
        id: 10,
        name: 'Cehennem Köpeği',
        emoji: '🔥',
        baseHP: 140,
        baseDamageMultiplier: 1.5,
        difficultyLevel: 3,
        type: 'normal',
      ),
      const Enemy(
        id: 11,
        name: 'Buz Sihirbazı',
        emoji: '❄️',
        baseHP: 125,
        baseDamageMultiplier: 1.35,
        difficultyLevel: 3,
        type: 'normal',
      ),
      const Enemy(
        id: 12,
        name: 'Hayalet Şövalye',
        emoji: '⚔️',
        baseHP: 135,
        baseDamageMultiplier: 1.45,
        difficultyLevel: 3,
        type: 'normal',
      ),
      const Enemy(
        id: 13,
        name: 'Taş Devi',
        emoji: '⛰️',
        baseHP: 200,
        baseDamageMultiplier: 1.6,
        difficultyLevel: 3,
        type: 'boss',
        specialAbilityId: 'earth_shield',
        specialAbilityDescription: 'Aldığı hasarı %25 azaltır',
      ),
      const Enemy(
        id: 14,
        name: 'Karanlık Efendi',
        emoji: '👹',
        baseHP: 280,
        baseDamageMultiplier: 2.2,
        difficultyLevel: 4,
        type: 'boss',
        specialAbilityId: 'dark_magic',
        specialAbilityDescription:
            'Her saldırısında oyuncunun combo\'sunu sıfırlar',
      ),
      const Enemy(
        id: 15,
        name: 'Ejder Kralı',
        emoji: '🐉',
        baseHP: 400,
        baseDamageMultiplier: 3.0,
        difficultyLevel: 5,
        type: 'boss',
        specialAbilityId: 'dragon_fury',
        specialAbilityDescription:
            'Canı %50\'nin altına düştüğünde saldırı hızı ikiye katlanır',
      ),
    ];
  }

  /// Her 5. düşman boss olur (5, 10, 15, 20...)
  static bool shouldSpawnBoss(int totalEnemiesKilled) {
    return (totalEnemiesKilled + 1) % 5 == 0;
  }

  /// Kat numarasına göre düşman seviyesi hesaplar
  /// Normal düşmanlar = kat seviyesi, Boss = kat seviyesi + 2
  static int getEnemyLevelForFloor(int floor, bool isBoss) {
    if (isBoss) {
      return math.min(floor + 2, 5);
    } else {
      return math.min(floor, 3);
    }
  }

  /// Belirtilen seviyedeki düşmanları döner
  static Future<List<Enemy>> getEnemiesByLevel(int level, bool bossOnly) async {
    final enemies = await loadEnemies();
    return enemies
        .where((e) => e.difficultyLevel == level && e.isBoss == bossOnly)
        .toList();
  }

  /// Kat ve düşman sırası bilgisine göre uygun düşmanı döner
  static Future<Enemy> getEnemyForPosition(
    int floor,
    int totalEnemiesKilled,
  ) async {
    final isBoss = shouldSpawnBoss(totalEnemiesKilled);
    final level = getEnemyLevelForFloor(floor, isBoss);

    final availableEnemies = await getEnemiesByLevel(level, isBoss);

    if (availableEnemies.isEmpty) {
      final allEnemies = await loadEnemies();
      return allEnemies[_random.nextInt(allEnemies.length)];
    }

    return availableEnemies[_random.nextInt(availableEnemies.length)];
  }

  static Future<Enemy> getRandomEnemy() async {
    final enemies = await loadEnemies();
    return enemies[_random.nextInt(enemies.length)];
  }

  static Future<Enemy> getBoss() async {
    final enemies = await loadEnemies();
    final bosses = enemies.where((e) => e.isBoss).toList();
    return bosses[_random.nextInt(bosses.length)];
  }

  static Future<Enemy> getNormalEnemy() async {
    final enemies = await loadEnemies();
    final normalEnemies = enemies.where((e) => !e.isBoss).toList();
    return normalEnemies[_random.nextInt(normalEnemies.length)];
  }
}
