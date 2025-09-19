import 'dart:math' as math;
import 'package:flutter/foundation.dart';
import 'package:mathgame/game_config.dart';

class DifficultyController extends ChangeNotifier {
  static final DifficultyController instance = DifficultyController._();
  DifficultyController._();

  int _stage = 0;
  int _bossesSinceStage = 0;
  DifficultyChange? _lastChange;

  final Map<Op, int> _capIndex = {
    Op.add: 0,
    Op.sub: -1,
    Op.mul: -1,
    Op.div: -1,
  };

  int get stage => _stage;

  void reset() {
    _stage = 0;
    _bossesSinceStage = 0;
    _capIndex[Op.add] = 0;
    _capIndex[Op.sub] = -1;
    _capIndex[Op.mul] = -1;
    _capIndex[Op.div] = -1;
    notifyListeners();
  }

  static const List<Op> _progression = [
    Op.add,
    Op.sub,
    Op.add,
    Op.mul,
    Op.sub,
    Op.add,
    Op.div,
    Op.mul,
    Op.sub,
    Op.add,
    Op.div,
    Op.mul,
    Op.sub,
    Op.div,
    Op.mul,
    Op.sub,
    Op.div,
  ];

  void onBossDefeated() {
    _bossesSinceStage++;
    if (_bossesSinceStage >= GameConfig.difficultyBossesPerStage) {
      _bossesSinceStage = 0;
      _advanceStage();
    }
  }

  void onEnemyDefeated() {
    if (GameConfig.stageAdvance == StageAdvance.perEnemy) {
      _advanceStage();
    }
  }

  void _advanceStage() {
    _stage++;
    final idx = (_stage - 1) % _progression.length;
    final op = _progression[idx];
    final nextIndex = (_capIndex[op] ?? -1) + 1;
    final maxIndex = _capsFor(op).length - 1;
    final prev = _capIndex[op] ?? -1;
    final updated = math.min(nextIndex, maxIndex);
    _capIndex[op] = updated;
    _lastChange = DifficultyChange(
      op: op,
      cap: currentCap(op),
      unlocked: prev < 0,
      stage: _stage,
    );
    notifyListeners();
  }

  List<int> _capsFor(Op op) {
    switch (op) {
      case Op.add:
        return GameConfig.capsAdd;
      case Op.sub:
        return GameConfig.capsSub;
      case Op.mul:
        return GameConfig.capsMul;
      case Op.div:
        return GameConfig.capsDiv;
    }
  }

  bool get isSubtractionNegativeAllowed =>
      _stage >= GameConfig.difficultyNegativeSubtractionStage;

  bool isUnlocked(Op op) => (_capIndex[op] ?? -1) >= 0;

  int currentCap(Op op) {
    final idx = _capIndex[op] ?? -1;
    if (idx < 0) return 0;
    final caps = _capsFor(op);
    return caps[math.min(idx, caps.length - 1)];
  }

  Op pickOp() {
    final entries = <_Entry>[];
    void add(Op op, double weight) {
      if (isUnlocked(op) && weight > 0) entries.add(_Entry(op, weight));
    }

    add(Op.add, GameConfig.weightAdd);
    add(Op.sub, GameConfig.weightSub);
    add(Op.mul, GameConfig.weightMul);
    add(Op.div, GameConfig.weightDiv);

    final total = entries.fold<double>(0, (s, e) => s + e.weight);
    if (total <= 0) return Op.add;
    final r = math.Random().nextDouble() * total;
    double acc = 0;
    for (final e in entries) {
      acc += e.weight;
      if (r <= acc) return e.op;
    }
    return entries.last.op;
  }

  DifficultyChange? consumeLastChange() {
    final c = _lastChange;
    _lastChange = null;
    return c;
  }
}

class DifficultyChange {
  final Op op;
  final int cap;
  final bool unlocked;
  final int stage;
  const DifficultyChange({
    required this.op,
    required this.cap,
    required this.unlocked,
    required this.stage,
  });
}

class _Entry {
  final Op op;
  final double weight;
  const _Entry(this.op, this.weight);
}
