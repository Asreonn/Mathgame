import 'dart:async';
import 'package:flutter/material.dart';
import 'package:mathgame/game_config.dart';
import 'package:mathgame/enemy_data.dart';
import 'package:mathgame/difficulty.dart';

enum GameStatus { playing, gameOver, paused }

class GameState extends ChangeNotifier {
  GameStatus _status = GameStatus.playing;
  GameStatus get status => _status;

  int _playerHP = GameConfig.startingPlayerHP;
  int _previousPlayerHP = GameConfig.startingPlayerHP;
  int get playerHP => _playerHP;
  int get previousPlayerHP => _previousPlayerHP;
  int get maxPlayerHP => GameConfig.maxPlayerHP;
  bool get isPlayerAlive => _playerHP > 0;

  int _enemyHP = GameConfig.getEnemyHP();
  int _previousEnemyHP = GameConfig.getEnemyHP();
  int _enemyMaxHP = GameConfig.getEnemyHP();
  int get enemyHP => _enemyHP;
  int get previousEnemyHP => _previousEnemyHP;
  int get maxEnemyHP => _enemyMaxHP;
  bool get isEnemyAlive => _enemyHP > 0;

  int _combo = 0;
  int get combo => _combo;
  static const List<int> _comboMilestones = [0, 5, 10, 15, 20, 30];
  int _highestMilestoneSinceLastMistake = 0;
  bool _doubleDropActive = false;

  int get lastPlayerDamage => _previousPlayerHP - _playerHP;
  int get lastEnemyDamage => _previousEnemyHP - _enemyHP;

  Timer? _attackTimer;
  double _attackTimeRemaining = GameConfig.baseAttackTime;
  double get attackTimeRemaining => _attackTimeRemaining;
  double get attackProgress =>
      1.0 - (_attackTimeRemaining / GameConfig.baseAttackTime);

  int _currentFloor = 1;
  int _enemyCount = 0;
  int _totalEnemiesKilled = 0;
  int get currentFloor => _currentFloor;
  int get enemyCount => _enemyCount;
  int get totalEnemies => GameConfig.enemiesPerFloor;
  int get totalEnemiesKilled => _totalEnemiesKilled;

  int _difficultyPopupTick = 0;
  int get difficultyPopupTick => _difficultyPopupTick;

  Enemy? _currentEnemy;
  Enemy? get currentEnemy => _currentEnemy;

  GameState() {
    DifficultyController.instance.reset();
    _startAttackTimer();
    _loadEnemyForCurrentPosition();
  }

  Future<void> _loadEnemyForCurrentPosition() async {
    _currentEnemy = await EnemyManager.getEnemyForPosition(
      _currentFloor,
      _totalEnemiesKilled,
    );
    _enemyMaxHP = _currentEnemy!.getHP(_currentFloor);
    _enemyHP = _enemyMaxHP;
    _previousEnemyHP = _enemyHP;
    notifyListeners();
  }

  void _startAttackTimer() {
    _attackTimer?.cancel();
    _attackTimeRemaining = GameConfig.baseAttackTime;

    _attackTimer = Timer.periodic(const Duration(milliseconds: 100), (timer) {
      if (_status != GameStatus.playing) return;

      _attackTimeRemaining -= 0.1;

      if (_attackTimeRemaining <= 0) {
        _executeEnemyAttack();
      }

      notifyListeners();
    });
  }

  void _executeEnemyAttack() {
    _previousPlayerHP = _playerHP;
    _playerHP = (_playerHP - GameConfig.enemyDamage).clamp(
      0,
      GameConfig.maxPlayerHP,
    );

    if (_playerHP <= 0) {
      _status = GameStatus.gameOver;
      _attackTimer?.cancel();
    } else {
      _startAttackTimer();
    }

    notifyListeners();
  }

  void onCorrectAnswer() {
    if (_status != GameStatus.playing) return;

    _combo++;

    final newMilestoneIdx = _milestoneIndexFor(_combo);
    if (newMilestoneIdx > _highestMilestoneSinceLastMistake) {
      _highestMilestoneSinceLastMistake = newMilestoneIdx;
      _doubleDropActive = false;
    }

    final damage = GameConfig.calculateDamage(_combo);
    _previousEnemyHP = _enemyHP;
    _enemyHP = (_enemyHP - damage).clamp(0, maxEnemyHP);

    if (_enemyHP <= 0) {
      _onEnemyDefeated();
    }

    notifyListeners();
  }

  void onWrongAnswer() {
    if (_status != GameStatus.playing) return;

    final currentIdx = _milestoneIndexFor(_combo);
    final dropBy = _doubleDropActive ? 2 : 1;
    final targetIdx = (currentIdx - dropBy).clamp(
      0,
      _comboMilestones.length - 1,
    );
    _combo = _comboMilestones[targetIdx];
    _highestMilestoneSinceLastMistake = targetIdx;
    _doubleDropActive = true;

    _attackTimeRemaining =
        (_attackTimeRemaining - GameConfig.wrongAnswerPenalty).clamp(
          0.1,
          GameConfig.baseAttackTime,
        );

    notifyListeners();
  }

  void _onEnemyDefeated() {
    _enemyCount++;
    _totalEnemiesKilled++;

    _attackTimer?.cancel();

    final isBossKill = _currentEnemy?.isBoss == true;
    if (isBossKill) {
      DifficultyController.instance.onBossDefeated();
    }
    if (GameConfig.stageAdvance == StageAdvance.perEnemy) {
      DifficultyController.instance.onEnemyDefeated();
    }

    final change = DifficultyController.instance.consumeLastChange();
    if (isBossKill || change != null) {
      _difficultyPopupTick++;
      notifyListeners();
    }

    const defeatDelay = Duration(milliseconds: 500);
    Future.delayed(defeatDelay, () {
      if (_enemyCount >= GameConfig.enemiesPerFloor) {
        _nextFloor();
      } else {
        _spawnNewEnemy();
      }
    });
  }

  void _spawnNewEnemy() {
    _loadEnemyForCurrentPosition();
    _startAttackTimer();
  }

  void _nextFloor() {
    _currentFloor++;
    _enemyCount = 0;
    GameConfig.currentFloor = _currentFloor;
    _spawnNewEnemy();
  }

  void pauseGame() {
    _status = GameStatus.paused;
    _attackTimer?.cancel();
    notifyListeners();
  }

  void resumeGame() {
    if (_status == GameStatus.paused && _playerHP > 0) {
      _status = GameStatus.playing;
      _startAttackTimer();
      notifyListeners();
    }
  }

  void resetGame() {
    _status = GameStatus.playing;
    _playerHP = GameConfig.startingPlayerHP;
    _previousPlayerHP = GameConfig.startingPlayerHP;
    _combo = 0;
    _highestMilestoneSinceLastMistake = 0;
    _doubleDropActive = false;
    _currentFloor = 1;
    _enemyCount = 0;
    _totalEnemiesKilled = 0;
    GameConfig.currentFloor = 1;
    _attackTimer?.cancel();
    DifficultyController.instance.reset();
    _loadEnemyForCurrentPosition();
    _startAttackTimer();
    notifyListeners();
  }

  int _milestoneIndexFor(int c) {
    int idx = 0;
    for (int i = 0; i < _comboMilestones.length; i++) {
      if (c >= _comboMilestones[i]) {
        idx = i;
      } else {
        break;
      }
    }
    return idx;
  }

  String getEnemyName() {
    return _currentEnemy?.name ?? 'Bilinmeyen Düşman';
  }

  String getEnemyEmoji() {
    return _currentEnemy?.emoji ?? '👾';
  }

  @override
  void dispose() {
    _attackTimer?.cancel();
    super.dispose();
  }
}
