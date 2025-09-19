import 'dart:math' as math;

enum Op { add, sub, mul, div }

enum GameDifficulty { easy, normal, hard }

enum StageAdvance { perBoss, perEnemy }

class GameConfig {
  static int maxNumber = 10;
  static Set<Op> operations = {Op.add, Op.sub, Op.mul, Op.div};

  static int baseDamage = 12;
  static double comboLinear = 0.30;
  static double comboPower = 1.20;
  static double comboPowerCoef = 0.06;

  static int maxPlayerHP = 100;
  static int startingPlayerHP = 100;

  static int baseEnemyHP = 50;
  static int enemyDamage = 15;
  static double baseAttackTime = 8.0;
  static double wrongAnswerPenalty = 1.0;

  static int currentFloor = 1;
  static int enemiesPerFloor = 5;

  static int difficultyBossesPerStage = 1;
  static int difficultyNegativeSubtractionStage = 8;
  static const List<int> capsAdd = [5, 10, 20, 50, 100];
  static const List<int> capsSub = [5, 10, 20, 50, 100];
  static const List<int> capsMul = [5, 7, 10, 12, 15, 20];
  static const List<int> capsDiv = [3, 5, 7, 10, 12, 15];
  static const double weightAdd = 1.0;
  static const double weightSub = 0.7;
  static const double weightMul = 0.55;
  static const double weightDiv = 0.45;

  static String symbol(Op op) {
    switch (op) {
      case Op.add:
        return '+';
      case Op.sub:
        return '−';
      case Op.mul:
        return '×';
      case Op.div:
        return '÷';
    }
  }

  static GameDifficulty difficulty = GameDifficulty.normal;
  static StageAdvance stageAdvance = StageAdvance.perBoss;
  static double difficultyComboMultiplierFactor = 1.0;

  static void applyDifficulty(GameDifficulty d) {
    difficulty = d;
    switch (d) {
      case GameDifficulty.easy:
        baseAttackTime = 10.0;
        stageAdvance = StageAdvance.perBoss;
        difficultyBossesPerStage = 2;
        difficultyComboMultiplierFactor = 1.0;
        break;
      case GameDifficulty.normal:
        baseAttackTime = 8.0;
        stageAdvance = StageAdvance.perBoss;
        difficultyBossesPerStage = 1;
        difficultyComboMultiplierFactor = 1.0;
        break;
      case GameDifficulty.hard:
        baseAttackTime = 5.0;
        stageAdvance = StageAdvance.perEnemy;
        difficultyComboMultiplierFactor = 2.0;
        break;
    }
  }

  static int calculateDamage(int combo) {
    final df = difficultyComboMultiplierFactor;
    final lin = comboLinear * df;
    final powCoef = comboPowerCoef * df;
    final c = combo.toDouble().clamp(0.0, 10000.0);
    final multiplier = 1.0 + (lin * c) + (powCoef * math.pow(c, comboPower));
    final dmg = (baseDamage * multiplier).round();
    return dmg;
  }

  static int getEnemyHP() {
    return baseEnemyHP + (currentFloor - 1) * 10;
  }
}
