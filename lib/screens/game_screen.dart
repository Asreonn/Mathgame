import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:mathgame/theme.dart';
import 'package:mathgame/screens/main_menu.dart';
import 'package:mathgame/game_config.dart';
import 'package:mathgame/widgets/combo_counter_advanced.dart';
import 'package:mathgame/widgets/combo_popup.dart';
import 'package:mathgame/widgets/death_screen.dart';
import 'package:mathgame/widgets/damage_hp_bar.dart';
import 'package:mathgame/widgets/damage_number.dart';
import 'package:mathgame/game_state.dart';
import 'package:flutter/services.dart';
import 'package:mathgame/enemy_data.dart';
import 'package:mathgame/widgets/difficulty_popup.dart';
import 'package:mathgame/difficulty.dart';

class GameScreen extends StatefulWidget {
  const GameScreen({super.key});

  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen> {
  late GameState gameState;
  final ValueNotifier<int> enemyShuffleTick = ValueNotifier<int>(0);
  final ValueNotifier<int> questionShuffleTick = ValueNotifier<int>(0);
  Enemy? _lastEnemy;
  bool _didInitEnemy = false;
  int _lastDifficultyTick = 0;

  @override
  void initState() {
    super.initState();
    gameState = GameState();
    gameState.addListener(_onGameStateChanged);
    _lastDifficultyTick = gameState.difficultyPopupTick;
  }

  void _onGameStateChanged() {
    if (gameState.status == GameStatus.gameOver) {
      _showDeathScreen();
    }

    if (gameState.lastPlayerDamage > 0) {
      _showPlayerDamageNumber();
    }

    final currentEnemy = gameState.currentEnemy;
    if (!_didInitEnemy && currentEnemy != null) {
      _didInitEnemy = true;
      _lastEnemy = currentEnemy;
    } else if (currentEnemy != null && !identical(_lastEnemy, currentEnemy)) {
      _lastEnemy = currentEnemy;
      enemyShuffleTick.value++;
      questionShuffleTick.value++;
    }

    if (gameState.difficultyPopupTick != _lastDifficultyTick) {
      _lastDifficultyTick = gameState.difficultyPopupTick;
      final mgr = DifficultyPopupManager.of(context);
      mgr?.showDifficultyPopup();
    }
  }

  void _showPlayerDamageNumber() {
    final damageManager = DamageNumberManager.of(context);
    if (damageManager == null) return;

    final damage = gameState.lastPlayerDamage;
    if (damage > 0) {
      HapticFeedback.heavyImpact();

      final screenSize = MediaQuery.of(context).size;
      final position = Offset(screenSize.width * 0.2, screenSize.height * 0.8);

      damageManager.showDamage(
        damage: damage,
        position: position,
        isPlayer: true,
      );
    }
  }

  void _showDeathScreen() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => DeathScreen(
        finalScore: gameState.combo * 100,
        maxCombo: gameState.combo,
        floor: gameState.currentFloor,
        enemiesDefeated: gameState.enemyCount,
        onRestart: () {
          Navigator.of(context).pop();
          gameState.resetGame();
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return DamageNumberManager(
      child: DifficultyPopupManager(
        child: ComboPopupManager(
          child: Scaffold(
            body: SafeArea(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final isTablet = constraints.maxWidth >= 600;
                  final children = <Widget>[
                    _TopBar(gameState: gameState),
                    const SizedBox(height: Spacing.lg),
                  ];

                  if (isTablet) {
                    children.add(
                      Expanded(
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              flex: 3,
                              child: _EnemyAndFloor(
                                gameState: gameState,
                                enemyShuffleTick: enemyShuffleTick,
                              ),
                            ),
                            const SizedBox(width: Spacing.lg),
                            Expanded(
                              flex: 4,
                              child: _QuestionAndInput(
                                gameState: gameState,
                                enemyShuffleTick: enemyShuffleTick,
                                questionShuffleTick: questionShuffleTick,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  } else {
                    children.addAll([
                      _EnemyAndFloor(
                        gameState: gameState,
                        enemyShuffleTick: enemyShuffleTick,
                      ),
                      const SizedBox(height: Spacing.lg),
                      Expanded(
                        child: _QuestionAndInput(
                          gameState: gameState,
                          enemyShuffleTick: enemyShuffleTick,
                          questionShuffleTick: questionShuffleTick,
                        ),
                      ),
                    ]);
                  }

                  return Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: children,
                    ),
                  );
                },
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    gameState.removeListener(_onGameStateChanged);
    gameState.dispose();
    super.dispose();
  }
}

class _TopBar extends StatelessWidget {
  const _TopBar({required this.gameState});

  final GameState gameState;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        IconButton(
          onPressed: () {
            gameState.pauseGame();
            showDialog(
              context: context,
              barrierDismissible: true,
              barrierColor: Colors.black54,
              builder: (_) => _PauseDialog(gameState: gameState),
            );
          },
          icon: const Icon(Icons.pause_rounded, size: 28),
          tooltip: 'Duraklat',
        ),
        const SizedBox(width: 12),
        const Expanded(child: SizedBox()),
      ],
    );
  }
}

class _PauseDialog extends StatelessWidget {
  const _PauseDialog({required this.gameState});

  final GameState gameState;

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: AppColors.surface,
      insetPadding: const EdgeInsets.symmetric(horizontal: 24),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: TweenAnimationBuilder<double>(
        tween: Tween(begin: 0.9, end: 1.0),
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOutBack,
        builder: (context, scale, child) =>
            Transform.scale(scale: scale, child: child),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: AppColors.surfaceAlt,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.pause_rounded,
                  size: 32,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 12),
              const Text(
                'Durduruldu',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 6),
              const Text(
                'Kısa bir nefes alın.',
                style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: _InfoChip(
                      label: 'Kat',
                      value: '${gameState.currentFloor}',
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _InfoChip(
                      label: 'Düşman',
                      value:
                          '${gameState.enemyCount + 1}/${gameState.totalEnemies}',
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.of(context).pop();
                        gameState.resumeGame();
                      },
                      child: const Text('Devam Et'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.danger,
                        foregroundColor: Colors.white,
                      ),
                      onPressed: () {
                        Navigator.of(context).pop();
                        Navigator.of(context).pushAndRemoveUntil(
                          MaterialPageRoute(
                            builder: (_) => const MainMenuScreen(),
                          ),
                          (_) => false,
                        );
                      },
                      child: const Text('Çıkış'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _InfoChip extends StatelessWidget {
  const _InfoChip({required this.label, required this.value});
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.surfaceAlt,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 12,
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _EnemyAndFloor extends StatelessWidget {
  const _EnemyAndFloor({
    required this.gameState,
    required this.enemyShuffleTick,
  });

  final GameState gameState;
  final ValueNotifier<int> enemyShuffleTick;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _EnemyCard(gameState: gameState, enemyShuffleTick: enemyShuffleTick),
        const SizedBox(height: Spacing.md),
        _FloorNavigator(gameState: gameState),
      ],
    );
  }
}

class _EnemyCard extends StatefulWidget {
  const _EnemyCard({required this.gameState, required this.enemyShuffleTick});

  final GameState gameState;
  final ValueNotifier<int> enemyShuffleTick;

  @override
  State<_EnemyCard> createState() => _EnemyCardState();
}

class _EnemyCardState extends State<_EnemyCard> {
  bool _isShuffling = false;
  String _shuffleName = '';
  String _shuffleEmoji = '';
  Timer? _timer;
  int _lastTick = 0;

  @override
  void initState() {
    super.initState();
    _lastTick = widget.enemyShuffleTick.value;
    widget.enemyShuffleTick.addListener(_onTick);
  }

  @override
  void didUpdateWidget(covariant _EnemyCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.enemyShuffleTick != widget.enemyShuffleTick) {
      oldWidget.enemyShuffleTick.removeListener(_onTick);
      _lastTick = widget.enemyShuffleTick.value;
      widget.enemyShuffleTick.addListener(_onTick);
    }
  }

  void _onTick() {
    final t = widget.enemyShuffleTick.value;
    if (t != _lastTick) {
      _lastTick = t;
      _startEnemyShuffle();
    }
  }

  Future<void> _startEnemyShuffle() async {
    _cancelShuffle();
    final target = widget.gameState.currentEnemy;
    List<Enemy> candidates = [];
    try {
      if (target != null) {
        candidates = await EnemyManager.getEnemiesByLevel(
          target.difficultyLevel,
          target.isBoss,
        );
      } else {
        candidates = await EnemyManager.loadEnemies();
      }
    } catch (_) {
      candidates = await EnemyManager.loadEnemies();
    }
    if (candidates.isEmpty) {
      candidates = await EnemyManager.loadEnemies();
    }

    final rnd = math.Random();
    const maxShuffles = 20;
    const shuffleSpeedMs = 10;
    var count = 0;

    setState(() {
      _isShuffling = true;
      final pick = candidates[rnd.nextInt(candidates.length)];
      _shuffleName = pick.name;
      _shuffleEmoji = pick.emoji;
    });

    void tick() {
      if (!mounted) return;
      if (count >= maxShuffles) {
        setState(() {
          _isShuffling = false;
          _shuffleName = widget.gameState.getEnemyName();
          _shuffleEmoji = widget.gameState.getEnemyEmoji();
        });
        return;
      }
      count++;
      final pick = candidates[rnd.nextInt(candidates.length)];
      setState(() {
        _shuffleName = pick.name;
        _shuffleEmoji = pick.emoji;
      });
      _timer = Timer(const Duration(milliseconds: shuffleSpeedMs), tick);
    }

    _timer = Timer(const Duration(milliseconds: shuffleSpeedMs), tick);
  }

  void _cancelShuffle() {
    _timer?.cancel();
    _timer = null;
    _isShuffling = false;
  }

  @override
  void dispose() {
    widget.enemyShuffleTick.removeListener(_onTick);
    _cancelShuffle();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: widget.gameState,
      builder: (context, child) {
        return Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppColors.surface,
            border: Border.all(color: AppColors.border),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Row(
            children: [
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  color: AppColors.surfaceAlt,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.border),
                ),
                alignment: Alignment.center,
                child: Text(
                  _isShuffling
                      ? _shuffleEmoji
                      : widget.gameState.getEnemyEmoji(),
                  style: const TextStyle(fontSize: 32),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            _isShuffling
                                ? _shuffleName
                                : widget.gameState.getEnemyName(),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontWeight: FontWeight.w700,
                              fontSize: 16,
                              color: AppColors.textPrimary,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Lv. ${widget.gameState.currentFloor}',
                          style: const TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    DamageHpBar(
                      current: widget.gameState.enemyHP,
                      max: widget.gameState.maxEnemyHP,
                      previousValue: widget.gameState.previousEnemyHP,
                      color: AppColors.hpEnemy,
                      isPlayer: false,
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            'Saldırı: ${widget.gameState.attackTimeRemaining.toStringAsFixed(1)}s',
                            style: const TextStyle(
                              color: AppColors.textSecondary,
                              fontSize: 12,
                            ),
                          ),
                        ),
                        _AttackRing(progress: widget.gameState.attackProgress),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _AttackRing extends StatelessWidget {
  const _AttackRing({required this.progress});
  final double progress;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 28,
      height: 28,
      child: CustomPaint(painter: _RingPainter(progress)),
    );
  }
}

class _RingPainter extends CustomPainter {
  _RingPainter(this.progress);
  final double progress;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = math.min(size.width, size.height) / 2 - 1;

    final track = Paint()
      ..color = AppColors.border
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3;

    final progColor = progress < 0.33
        ? AppColors.accent
        : (progress < 0.66 ? AppColors.warning : AppColors.danger);

    final fill = Paint()
      ..color = progColor
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeWidth = 3.5;

    canvas.drawCircle(center, radius, track);

    final startAngle = -math.pi / 2;
    final sweepAngle = 2 * math.pi * progress;
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      startAngle,
      sweepAngle,
      false,
      fill,
    );
  }

  @override
  bool shouldRepaint(covariant _RingPainter oldDelegate) =>
      oldDelegate.progress != progress;
}

class _FloorNavigator extends StatefulWidget {
  const _FloorNavigator({required this.gameState});

  final GameState gameState;

  @override
  State<_FloorNavigator> createState() => _FloorNavigatorState();
}

class _FloorNavigatorState extends State<_FloorNavigator>
    with TickerProviderStateMixin {
  late AnimationController _progressCtrl;
  late AnimationController _shimmerCtrl;
  late AnimationController _headPulseCtrl;
  late AnimationController _burstCtrl;
  double _progress = 0;
  VoidCallback? _progressTick;

  int get _total => widget.gameState.totalEnemies;

  double _targetProgress() {
    return widget.gameState.enemyCount.clamp(0, _total).toDouble();
  }

  void _animateToTarget() {
    final start = _progress;
    final end = _targetProgress();
    if ((end - start).abs() < 1e-3) return;
    final startStep = start.floor();
    final endStep = end.floor();
    _progressCtrl
      ..stop()
      ..reset();
    if (_progressTick != null) {
      _progressCtrl.removeListener(_progressTick!);
    }
    final tween = Tween<double>(
      begin: start,
      end: end,
    ).chain(CurveTween(curve: Curves.easeOutCubic));
    _progressTick = () {
      setState(() {
        _progress = tween.evaluate(_progressCtrl);
      });
    };
    _progressCtrl.addListener(_progressTick!);
    _progressCtrl.forward();
    if (endStep > startStep) {
      _burstCtrl.forward(from: 0);
    }
  }

  void _onGameStateChanged() {
    _animateToTarget();
  }

  @override
  void initState() {
    super.initState();
    _progress = _targetProgress();
    _progressCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 350),
    );
    _shimmerCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat();
    _headPulseCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat();
    _burstCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    widget.gameState.addListener(_onGameStateChanged);
  }

  @override
  void didUpdateWidget(covariant _FloorNavigator oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.gameState != widget.gameState) {
      oldWidget.gameState.removeListener(_onGameStateChanged);
      widget.gameState.addListener(_onGameStateChanged);
    }
    _animateToTarget();
  }

  @override
  void dispose() {
    widget.gameState.removeListener(_onGameStateChanged);
    _progressCtrl.dispose();
    _shimmerCtrl.dispose();
    _headPulseCtrl.dispose();
    _burstCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final floor = widget.gameState.currentFloor;
    final total = _total;
    final enemyIndex = widget.gameState.enemyCount;
    final isBossFight = enemyIndex >= total - 1;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(
            height: 20,
            child: LayoutBuilder(
              builder: (context, constraints) {
                final fullWidth = constraints.maxWidth;
                final segmentGap = 6.0;
                final segmentCount = total;
                final segmentWidth =
                    (fullWidth - segmentGap * (segmentCount - 1)) /
                    segmentCount;

                final p = math.min(_progress, total.toDouble());
                final baseIndex = p.floor();
                final safeIndex = (p >= total) ? (segmentCount - 1) : baseIndex;
                final fract = (p >= total) ? 1.0 : (p - baseIndex);
                final headX =
                    safeIndex * (segmentWidth + segmentGap) +
                    fract * segmentWidth;

                final barHeight = 20.0;
                final segHeight = 10.0;
                final segTop = (barHeight - segHeight) / 2;

                return Stack(
                  clipBehavior: Clip.none,
                  children: [
                    Positioned(
                      top: segTop,
                      left: 0,
                      right: 0,
                      child: Row(
                        children: List.generate(segmentCount, (i) {
                          final isBoss = i == segmentCount - 1;
                          final fill = (_progress - i).clamp(0.0, 1.0);
                          final baseColor = isBoss
                              ? AppColors.warning
                              : AppColors.accent;
                          return Container(
                            width: segmentWidth,
                            height: segHeight,
                            margin: EdgeInsets.only(
                              right: i == segmentCount - 1 ? 0 : segmentGap,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.track,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: AppColors.border),
                            ),
                            child: Stack(
                              children: [
                                FractionallySizedBox(
                                  widthFactor: fill,
                                  alignment: Alignment.centerLeft,
                                  child: Container(
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(8),
                                      gradient: LinearGradient(
                                        colors: [
                                          baseColor.withValues(alpha: 0.85),
                                          baseColor,
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                                if (fill > 0 && fill < 1)
                                  FractionallySizedBox(
                                    widthFactor: fill,
                                    alignment: Alignment.centerLeft,
                                    child: AnimatedBuilder(
                                      animation: _shimmerCtrl,
                                      builder: (_, __) {
                                        final t = _shimmerCtrl.value;
                                        return Container(
                                          decoration: BoxDecoration(
                                            borderRadius: BorderRadius.circular(
                                              8,
                                            ),
                                            gradient: LinearGradient(
                                              begin: Alignment(-1 + 2 * t, 0),
                                              end: Alignment(0 + 2 * t, 0),
                                              colors: [
                                                Colors.white.withValues(
                                                  alpha: 0.0,
                                                ),
                                                Colors.white.withValues(
                                                  alpha: 0.25,
                                                ),
                                                Colors.white.withValues(
                                                  alpha: 0.0,
                                                ),
                                              ],
                                            ),
                                          ),
                                        );
                                      },
                                    ),
                                  ),
                                if (isBoss && isBossFight)
                                  Positioned.fill(
                                    child: AnimatedBuilder(
                                      animation: _shimmerCtrl,
                                      builder: (_, __) {
                                        final pulse =
                                            (math.sin(
                                                  _shimmerCtrl.value *
                                                      2 *
                                                      math.pi,
                                                ) +
                                                1) /
                                            2;
                                        return Container(
                                          decoration: BoxDecoration(
                                            borderRadius: BorderRadius.circular(
                                              8,
                                            ),
                                            boxShadow: [
                                              BoxShadow(
                                                color: AppColors.warning
                                                    .withValues(
                                                      alpha: 0.25 * pulse,
                                                    ),
                                                blurRadius: 10 + 10 * pulse,
                                                spreadRadius: 0,
                                              ),
                                            ],
                                          ),
                                        );
                                      },
                                    ),
                                  ),
                              ],
                            ),
                          );
                        }),
                      ),
                    ),
                    Positioned(
                      left: math.max(0, math.min(headX - 28, fullWidth - 28)),
                      top: segTop,
                      child: SizedBox(
                        width: 28,
                        height: segHeight,
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(8),
                            gradient: LinearGradient(
                              begin: Alignment.centerLeft,
                              end: Alignment.centerRight,
                              colors: [
                                Colors.white.withValues(alpha: 0.0),
                                Colors.white.withValues(alpha: 0.18),
                                Colors.white.withValues(alpha: 0.0),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                    Positioned(
                      left: math.max(0, math.min(headX - 9, fullWidth - 18)),
                      top: (barHeight - 18) / 2,
                      child: AnimatedBuilder(
                        animation: Listenable.merge([
                          _headPulseCtrl,
                          _burstCtrl,
                        ]),
                        builder: (_, __) {
                          final nearBoss = enemyIndex >= total - 2;
                          final baseColor = nearBoss
                              ? AppColors.warning
                              : AppColors.accent;
                          final pulse =
                              (math.sin(_headPulseCtrl.value * 2 * math.pi) *
                                  0.15) +
                              1.0;
                          final burstT = _burstCtrl.value;
                          final burstOpacity = (1 - burstT) * 0.35;

                          return SizedBox(
                            width: 18,
                            height: 18,
                            child: Stack(
                              alignment: Alignment.center,
                              children: [
                                if (burstT > 0)
                                  Opacity(
                                    opacity: burstOpacity,
                                    child: Transform.scale(
                                      scale: 1.0 + 0.8 * burstT,
                                      child: Container(
                                        decoration: BoxDecoration(
                                          shape: BoxShape.circle,
                                          border: Border.all(
                                            color: Colors.white,
                                            width: 2,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                Container(
                                  width: 18 * pulse,
                                  height: 18 * pulse,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: baseColor,
                                    boxShadow: [
                                      BoxShadow(
                                        color: baseColor.withValues(alpha: 0.5),
                                        blurRadius: 14,
                                        spreadRadius: 1,
                                      ),
                                    ],
                                  ),
                                ),
                                Container(
                                  width: 7,
                                  height: 7,
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    shape: BoxShape.circle,
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.white.withValues(
                                          alpha: 0.6,
                                        ),
                                        blurRadius: 6,
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 260),
                  transitionBuilder: (child, anim) {
                    final slide =
                        Tween<Offset>(
                              begin: const Offset(0, 0.2),
                              end: Offset.zero,
                            )
                            .chain(CurveTween(curve: Curves.easeOutCubic))
                            .animate(anim);
                    return FadeTransition(
                      opacity: anim,
                      child: SlideTransition(position: slide, child: child),
                    );
                  },
                  child: _StatusLine(
                    key: ValueKey('f$floor-e${widget.gameState.enemyCount}'),
                    floor: floor,
                    current: widget.gameState.enemyCount + 1,
                    total: widget.gameState.totalEnemies,
                    isBoss: isBossFight,
                  ),
                ),
              ),
              AnimatedBuilder(
                animation: _shimmerCtrl,
                builder: (_, __) {
                  final pulse =
                      (math.sin(_shimmerCtrl.value * 2 * math.pi) * 0.08) + 1.0;
                  return Container(
                    decoration: isBossFight
                        ? BoxDecoration(
                            boxShadow: [
                              BoxShadow(
                                color: AppColors.warning.withValues(
                                  alpha: 0.35,
                                ),
                                blurRadius: 10,
                              ),
                            ],
                          )
                        : null,
                    child: Transform.scale(
                      scale: isBossFight ? pulse : 1.0,
                      child: Icon(
                        Icons.workspace_premium_rounded,
                        size: 20,
                        color: AppColors.warning,
                      ),
                    ),
                  );
                },
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _StatusLine extends StatelessWidget {
  const _StatusLine({
    super.key,
    required this.floor,
    required this.current,
    required this.total,
    required this.isBoss,
  });
  final int floor;
  final int current;
  final int total;
  final bool isBoss;

  TextSpan _span(
    String text,
    Color color, {
    FontWeight weight = FontWeight.w600,
  }) => TextSpan(
    text: text,
    style: TextStyle(color: color, fontWeight: weight),
  );

  @override
  Widget build(BuildContext context) {
    final primary = AppColors.textPrimary;
    final secondary = AppColors.textSecondary;
    return Row(
      children: [
        Expanded(
          child: RichText(
            text: TextSpan(
              children: [
                _span('Kat ', secondary, weight: FontWeight.w500),
                _span('$floor', primary),
                _span('  •  ', secondary, weight: FontWeight.w500),
                _span('Düşman ', secondary, weight: FontWeight.w500),
                _span('$current', primary),
                _span('/', secondary, weight: FontWeight.w500),
                _span('$total', primary),
              ],
            ),
          ),
        ),
        if (isBoss)
          AnimatedContainer(
            duration: const Duration(milliseconds: 280),
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: AppColors.warning.withValues(alpha: 0.18),
              borderRadius: BorderRadius.circular(999),
              border: Border.all(color: AppColors.warning),
            ),
            child: const Text(
              'BOSS',
              style: TextStyle(
                color: AppColors.warning,
                fontWeight: FontWeight.w800,
                letterSpacing: 1.1,
                fontSize: 11,
              ),
            ),
          ),
      ],
    );
  }
}

class _QuestionAndInput extends StatefulWidget {
  const _QuestionAndInput({
    required this.gameState,
    required this.enemyShuffleTick,
    required this.questionShuffleTick,
  });

  final GameState gameState;
  final ValueNotifier<int> enemyShuffleTick;
  final ValueNotifier<int> questionShuffleTick;

  @override
  State<_QuestionAndInput> createState() => _QuestionAndInputState();
}

enum _FeedbackType { correct, wrong }

class _QuestionAndInputState extends State<_QuestionAndInput>
    with SingleTickerProviderStateMixin {
  String input = '';
  late int _a;
  late int _b;
  late Op _op;
  late int _answer;
  int? _nextA;
  int? _nextB;
  Op? _nextOp;
  int? _nextAnswer;
  _FeedbackType? _feedback;
  late final AnimationController _fxCtrl;
  bool _isComboIncrementing = false;
  bool _isComboResetting = false;
  bool _isShuffling = false;
  String _currentShuffleA = '';
  String _currentShuffleB = '';
  String _currentShuffleOp = '';
  Timer? _shuffleTimer;
  int _lastQuestionTick = 0;

  @override
  void initState() {
    super.initState();
    _fxCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 550),
    );
    _nextQuestion();
    _lastQuestionTick = widget.questionShuffleTick.value;
    widget.questionShuffleTick.addListener(_onQuestionTick);
  }

  bool get _hasDigits => input.replaceAll('-', '').isNotEmpty;

  void _onDigit(String d) {
    setState(() => input = input + d);
  }

  void _onMinus() {
    if (_hasDigits) {
      setState(() => input = '');
    } else {
      setState(() => input.startsWith('-') ? input = '' : input = '-');
    }
  }

  void _onEquals() {
    if (_isShuffling) {
      HapticFeedback.selectionClick();
      return;
    }
    final parsed = int.tryParse(input);
    if (parsed != null && parsed == _answer) {
      HapticFeedback.heavyImpact();
      final oldCombo = widget.gameState.combo;
      widget.gameState.onCorrectAnswer();
      _showDamageNumber();
      _incrementCombo(oldCombo);
      _playFeedback(_FeedbackType.correct);
      final wasKill = widget.gameState.enemyHP <= 0;
      if (!wasKill) {
        const delayMs = 450;
        Future.delayed(const Duration(milliseconds: delayMs), () async {
          if (!mounted) return;
          widget.questionShuffleTick.value++;
        });
      }
    } else {
      HapticFeedback.lightImpact();
      widget.gameState.onWrongAnswer();
      _resetCombo();
      _playFeedback(_FeedbackType.wrong);
      setState(() => input = '');
    }
  }

  void _nextQuestion() {
    _prepareNextQuestion();
    _applyPendingQuestion();
  }

  void _prepareNextQuestion() {
    final dc = DifficultyController.instance;
    _nextOp = dc.pickOp();
    late int na;
    late int nb;
    late int ans;
    switch (_nextOp!) {
      case Op.add:
        {
          final cap = dc.currentCap(Op.add);
          na = _rand(0, cap);
          nb = _rand(0, cap);
          ans = na + nb;
          break;
        }
      case Op.sub:
        {
          final cap = dc.currentCap(Op.sub);
          if (!dc.isSubtractionNegativeAllowed) {
            na = _rand(0, cap);
            nb = _rand(0, cap);
            if (nb > na) {
              final t = na;
              na = nb;
              nb = t;
            }
            ans = na - nb;
          } else {
            na = _rand(0, cap);
            nb = _rand(0, cap);
            if (_rand(0, 1) == 1) {
              final t = na;
              na = nb;
              nb = t;
            }
            ans = na - nb;
          }
          break;
        }
      case Op.mul:
        {
          final cap = dc.currentCap(Op.mul);
          na = _rand(0, cap);
          nb = _rand(0, cap);
          ans = na * nb;
          break;
        }
      case Op.div:
        {
          final cap = dc.currentCap(Op.div);
          final b = _rand(1, math.max(1, cap));
          final q = _rand(0, cap);
          na = b * q;
          nb = b;
          ans = q;
          break;
        }
    }
    _nextA = na;
    _nextB = nb;
    _nextAnswer = ans;
  }

  void _applyPendingQuestion() {
    if (_nextA == null ||
        _nextB == null ||
        _nextOp == null ||
        _nextAnswer == null) {
      return;
    }
    setState(() {
      _a = _nextA!;
      _b = _nextB!;
      _op = _nextOp!;
      _answer = _nextAnswer!;
      input = '';
    });
    _nextA = null;
    _nextB = null;
    _nextOp = null;
    _nextAnswer = null;
  }

  int _rand(int min, int max) {
    return (min + (math.Random().nextInt((max - min) + 1)));
  }

  void _incrementCombo(int oldCombo) {
    setState(() {
      _isComboIncrementing = true;
    });

    _showComboPopupIfNeeded(oldCombo, widget.gameState.combo);

    Future.delayed(const Duration(milliseconds: 100), () {
      if (mounted) {
        setState(() {
          _isComboIncrementing = false;
        });
      }
    });
  }

  void _showDamageNumber() {
    final damageManager = DamageNumberManager.of(context);
    if (damageManager == null) return;

    final damage = widget.gameState.lastEnemyDamage;
    if (damage > 0) {
      final renderBox = context.findRenderObject() as RenderBox?;
      if (renderBox != null) {
        final size = renderBox.size;
        final position = Offset(size.width * 0.8, size.height * 0.3);

        damageManager.showDamage(
          damage: damage,
          position: position,
          isPlayer: false,
        );
      }
    }
  }

  void _showComboPopupIfNeeded(int oldCombo, int newCombo) {
    final popupManager = ComboPopupManager.of(context);
    if (popupManager == null) return;

    String? text;
    Color? color;

    if (newCombo >= 30 && oldCombo < 30) {
      text = "GODLIKE!";
      color = const Color(0xFFFF00FF);
    } else if (newCombo >= 20 && oldCombo < 20) {
      text = "LEGENDARY!";
      color = const Color(0xFF00FFFF);
    } else if (newCombo >= 15 && oldCombo < 15) {
      text = "EPIC!";
      color = const Color(0xFFFFD700);
    } else if (newCombo >= 10 && oldCombo < 10) {
      text = "MASTER!";
      color = const Color(0xFFFFD700);
    } else if (newCombo >= 5 && oldCombo < 5) {
      text = "GOOD!";
      color = AppColors.warning;
    }

    if (text != null && color != null) {
      popupManager.showComboPopup(text, color);
    }
  }

  void _resetCombo() {
    if (widget.gameState.combo > 0) {
      setState(() {
        _isComboResetting = true;
      });
      Future.delayed(const Duration(milliseconds: 200), () {
        if (mounted) {
          setState(() {
            _isComboResetting = false;
          });
        }
      });
    }
  }

  void _playFeedback(_FeedbackType type) {
    _fxCtrl
      ..stop()
      ..reset();
    setState(() => _feedback = type);
    _fxCtrl.forward().whenComplete(() {
      if (mounted) setState(() => _feedback = null);
    });
  }

  void _startShuffle() {
    if (_isShuffling) return;
    _cancelShuffle();
    _prepareNextQuestion();
    final random = math.Random();
    const symbols = ['+', '−', '×', '÷'];
    int shuffleCount = 0;
    const maxShuffles = 20;
    const shuffleSpeed = 10;

    setState(() {
      _isShuffling = true;
      _currentShuffleA = random.nextInt(99).toString();
      _currentShuffleB = random.nextInt(99).toString();
      _currentShuffleOp = symbols[random.nextInt(symbols.length)];
    });

    void performShuffle() {
      if (!mounted || shuffleCount >= maxShuffles) {
        if (mounted) {
          setState(() => _isShuffling = false);
          _applyPendingQuestion();
        }
        return;
      }

      shuffleCount++;

      if (mounted) {
        final newA = random.nextInt(99).toString();
        final newB = random.nextInt(99).toString();
        final newOp = symbols[random.nextInt(symbols.length)];

        setState(() {
          _currentShuffleA = newA;
          _currentShuffleB = newB;
          _currentShuffleOp = newOp;
        });
      }

      _shuffleTimer = Timer(
        Duration(milliseconds: shuffleSpeed),
        performShuffle,
      );
    }

    _shuffleTimer = Timer(const Duration(milliseconds: 10), performShuffle);
  }

  void _cancelShuffle() {
    _shuffleTimer?.cancel();
    _shuffleTimer = null;
    _isShuffling = false;
  }

  void _onQuestionTick() {
    final t = widget.questionShuffleTick.value;
    if (t != _lastQuestionTick) {
      _lastQuestionTick = t;
      _startShuffle();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        AnimatedBuilder(
          animation: _fxCtrl,
          builder: (context, _) {
            final t = Curves.easeOutCubic.transform(
              _fxCtrl.value.clamp(0.0, 1.0),
            );
            final isWrong = _feedback == _FeedbackType.wrong && t > 0;
            final isCorrect = _feedback == _FeedbackType.correct && t > 0;
            return Expanded(
              child: Stack(
                fit: StackFit.expand,
                children: [
                  _QuestionArea(
                    a: _a,
                    b: _b,
                    opSymbol: GameConfig.symbol(_op),
                    input: input,
                    feedback: _feedback,
                    progress: _fxCtrl.value,
                    isShuffling: _isShuffling,
                    shuffleA: _currentShuffleA.isEmpty
                        ? null
                        : _currentShuffleA,
                    shuffleB: _currentShuffleB.isEmpty
                        ? null
                        : _currentShuffleB,
                    shuffleOp: _currentShuffleOp.isEmpty
                        ? null
                        : _currentShuffleOp,
                  ),
                  if (isWrong || isCorrect)
                    Positioned.fill(
                      child: _EdgePulseOverlay(
                        color: isWrong ? AppColors.danger : AppColors.success,
                        t: t,
                      ),
                    ),
                  if (isCorrect)
                    Positioned.fill(
                      child: IgnorePointer(
                        child: CustomPaint(
                          painter: _SuccessBurstPainter(progress: t),
                        ),
                      ),
                    ),
                ],
              ),
            );
          },
        ),
        const SizedBox(height: Spacing.lg),
        _PlayerHpBar(
          gameState: widget.gameState,
          isComboIncrementing: _isComboIncrementing,
          isComboResetting: _isComboResetting,
        ),
        const SizedBox(height: Spacing.md),
        _Numpad(
          onDigit: _onDigit,
          onMinus: _onMinus,
          onEquals: _onEquals,
          hasDigits: _hasDigits,
        ),
      ],
    );
  }

  @override
  void dispose() {
    _fxCtrl.dispose();
    _cancelShuffle();
    widget.questionShuffleTick.removeListener(_onQuestionTick);
    super.dispose();
  }
}

class _QuestionArea extends StatelessWidget {
  const _QuestionArea({
    required this.a,
    required this.b,
    required this.opSymbol,
    required this.input,
    required this.feedback,
    required this.progress,
    required this.isShuffling,
    this.shuffleA,
    this.shuffleB,
    this.shuffleOp,
  });
  final int a;
  final int b;
  final String opSymbol;
  final String input;
  final _FeedbackType? feedback;
  final double progress;
  final bool isShuffling;
  final String? shuffleA;
  final String? shuffleB;
  final String? shuffleOp;

  @override
  Widget build(BuildContext context) {
    final hasDigits = input.replaceAll('-', '').isNotEmpty;
    final answerDisplay = hasDigits || input == '-' ? input : '?';
    final t = Curves.easeOutCubic.transform(progress.clamp(0.0, 1.0));
    final isWrong = feedback == _FeedbackType.wrong && t > 0;
    final isCorrect = feedback == _FeedbackType.correct && t > 0;
    final dx = isWrong ? math.sin(t * 16 * math.pi) * (1 - t) * 9.0 : 0.0;
    final scale = isCorrect ? 1.0 + (1 - t) * 0.10 : 1.0;

    final displayA = isShuffling ? (shuffleA ?? a.toString()) : a.toString();
    final displayB = isShuffling ? (shuffleB ?? b.toString()) : b.toString();
    final displayOp = isShuffling ? (shuffleOp ?? opSymbol) : opSymbol;

    return Transform.translate(
      offset: Offset(dx, 0),
      child: Transform.scale(
        scale: scale,
        child: Container(
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.border),
          ),
          child: RichText(
            textAlign: TextAlign.center,
            text: TextSpan(
              style: Theme.of(
                context,
              ).textTheme.headlineMedium?.copyWith(fontSize: 32),
              children: [
                TextSpan(
                  text: '$displayA ',
                  style: TextStyle(
                    color: isShuffling
                        ? AppColors.textSecondary
                        : AppColors.textPrimary,
                  ),
                ),
                TextSpan(
                  text: displayOp,
                  style: TextStyle(
                    color: isShuffling
                        ? AppColors.textSecondary
                        : AppColors.warning,
                  ),
                ),
                TextSpan(
                  text: ' $displayB = ',
                  style: TextStyle(
                    color: isShuffling
                        ? AppColors.textSecondary
                        : AppColors.textPrimary,
                  ),
                ),
                TextSpan(
                  text: answerDisplay,
                  style: TextStyle(
                    color: answerDisplay == '?'
                        ? AppColors.textSecondary
                        : AppColors.accent,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _EdgePulseOverlay extends StatelessWidget {
  const _EdgePulseOverlay({required this.color, required this.t});
  final Color color;
  final double t;

  @override
  Widget build(BuildContext context) {
    final opacity = (1 - t) * 0.28;
    if (opacity <= 0.01) return const SizedBox.shrink();
    return IgnorePointer(
      child: ColoredBox(color: color.withValues(alpha: opacity)),
    );
  }
}

class _SuccessBurstPainter extends CustomPainter {
  final double progress;
  _SuccessBurstPainter({required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    if (progress <= 0) return;
    final center = Offset(size.width / 2, size.height / 2);
    final maxR = (size.shortestSide) * 0.65;
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;

    for (int i = 0; i < 3; i++) {
      final p = (progress - i * 0.15).clamp(0.0, 1.0);
      if (p <= 0) continue;
      final r = p * maxR;
      final alpha = (1 - p) * (i == 0 ? 0.35 : (i == 1 ? 0.25 : 0.18));
      paint.color = AppColors.success.withValues(alpha: alpha);
      canvas.drawCircle(center, r, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _SuccessBurstPainter oldDelegate) =>
      oldDelegate.progress != progress;
}

class _PlayerHpBar extends StatelessWidget {
  const _PlayerHpBar({
    required this.gameState,
    required this.isComboIncrementing,
    required this.isComboResetting,
  });

  final GameState gameState;
  final bool isComboIncrementing;
  final bool isComboResetting;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: gameState,
      builder: (context, child) {
        return Row(
          children: [
            const Icon(
              Icons.favorite_rounded,
              color: AppColors.success,
              size: 18,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: DamageHpBar(
                current: gameState.playerHP,
                max: gameState.maxPlayerHP,
                previousValue: gameState.previousPlayerHP,
                color: AppColors.hpPlayer,
                isPlayer: true,
              ),
            ),
            const SizedBox(width: 8),
            ComboCounterAdvanced(
              combo: gameState.combo,
              isIncrementing: isComboIncrementing,
              isResetting: isComboResetting,
            ),
          ],
        );
      },
    );
  }
}

class _Numpad extends StatefulWidget {
  const _Numpad({
    required this.onDigit,
    required this.onMinus,
    required this.onEquals,
    required this.hasDigits,
  });

  final void Function(String) onDigit;
  final VoidCallback onMinus;
  final VoidCallback onEquals;
  final bool hasDigits;

  @override
  State<_Numpad> createState() => _NumpadState();
}

class _NumpadState extends State<_Numpad> {
  String _pressedId = '';

  void _pulse(String id, VoidCallback action) {
    setState(() => _pressedId = id);
    action();
    Future.delayed(const Duration(milliseconds: 120), () {
      if (mounted && _pressedId == id) setState(() => _pressedId = '');
    });
  }

  @override
  Widget build(BuildContext context) {
    ButtonStyle keyStyle({bool accent = false, Color? bg, Color? fg}) {
      final shape = RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      );
      final usedBg = bg ?? (accent ? AppColors.accent : AppColors.surface);
      final usedFg = fg ?? (accent ? Colors.black : AppColors.textPrimary);
      final filled = accent || bg != null;
      return ButtonStyle(
        backgroundColor: WidgetStatePropertyAll(usedBg),
        foregroundColor: WidgetStatePropertyAll(usedFg),
        overlayColor: const WidgetStatePropertyAll(Colors.transparent),
        shape: WidgetStatePropertyAll(shape),
        side: WidgetStatePropertyAll(
          BorderSide(color: filled ? Colors.transparent : AppColors.border),
        ),
        padding: const WidgetStatePropertyAll(
          EdgeInsets.symmetric(vertical: 18),
        ),
      );
    }

    Widget key(
      String id,
      String label,
      VoidCallback onTap, {
      bool accent = false,
      Color? bg,
      Color? fg,
    }) {
      final baseStyle = Theme.of(
        context,
      ).textTheme.titleLarge?.copyWith(fontSize: 20);
      return Expanded(
        child: Padding(
          padding: const EdgeInsets.all(6),
          child: AnimatedScale(
            scale: _pressedId == id ? 0.94 : 1.0,
            duration: const Duration(milliseconds: 180),
            curve: Curves.easeOutBack,
            child: ElevatedButton(
              onPressed: () => _pulse(id, onTap),
              style: keyStyle(accent: accent, bg: bg, fg: fg),
              child: Text(label, style: baseStyle),
            ),
          ),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            key('1', '1', () => widget.onDigit('1')),
            key('2', '2', () => widget.onDigit('2')),
            key('3', '3', () => widget.onDigit('3')),
          ],
        ),
        Row(
          children: [
            key('4', '4', () => widget.onDigit('4')),
            key('5', '5', () => widget.onDigit('5')),
            key('6', '6', () => widget.onDigit('6')),
          ],
        ),
        Row(
          children: [
            key('7', '7', () => widget.onDigit('7')),
            key('8', '8', () => widget.onDigit('8')),
            key('9', '9', () => widget.onDigit('9')),
          ],
        ),
        Row(
          children: [
            key(
              'minus',
              widget.hasDigits ? 'C' : '−',
              widget.onMinus,
              bg: widget.hasDigits ? AppColors.danger : AppColors.accent,
              fg: Colors.white,
            ),
            key('0', '0', () => widget.onDigit('0')),
            key('eq', '=', widget.onEquals, accent: true),
          ],
        ),
      ],
    );
  }
}
