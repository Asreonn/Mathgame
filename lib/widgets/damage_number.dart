import 'package:flutter/material.dart';
import 'package:mathgame/theme.dart';
import 'dart:math' as math;

class DamageNumber extends StatefulWidget {
  const DamageNumber({
    super.key,
    required this.damage,
    required this.position,
    required this.onComplete,
    this.isPlayer = false,
  });

  final int damage;
  final Offset position;
  final VoidCallback onComplete;
  final bool isPlayer;

  @override
  State<DamageNumber> createState() => _DamageNumberState();
}

class _DamageNumberState extends State<DamageNumber>
    with TickerProviderStateMixin {
  late AnimationController _mainController;
  late AnimationController _scaleController;
  late AnimationController _bounceController;

  late Animation<double> _slideAnimation;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;
  late Animation<double> _bounceAnimation;

  @override
  void initState() {
    super.initState();

    _mainController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );

    _scaleController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );

    _bounceController = AnimationController(
      duration: const Duration(milliseconds: 100),
      vsync: this,
    );

    _slideAnimation = Tween<double>(begin: 0.0, end: -40.0).animate(
      CurvedAnimation(parent: _mainController, curve: Curves.easeOutCubic),
    );

    _fadeAnimation = TweenSequence<double>([
      TweenSequenceItem(tween: Tween<double>(begin: 0.0, end: 1.0), weight: 15),
      TweenSequenceItem(tween: Tween<double>(begin: 1.0, end: 1.0), weight: 50),
      TweenSequenceItem(tween: Tween<double>(begin: 1.0, end: 0.0), weight: 35),
    ]).animate(_mainController);

    _scaleAnimation = Tween<double>(begin: 0.6, end: 1.0).animate(
      CurvedAnimation(parent: _scaleController, curve: Curves.easeOutBack),
    );

    _bounceAnimation = Tween<double>(begin: 1.0, end: 1.2).animate(
      CurvedAnimation(parent: _bounceController, curve: Curves.easeOut),
    );

    _startAnimation();
  }

  void _startAnimation() async {
    _scaleController.forward();

    if (widget.damage >= 50) {
      await _bounceController.forward();
      _bounceController.reverse();
    }

    await _mainController.forward();
    widget.onComplete();
  }

  @override
  Widget build(BuildContext context) {
    final isLargeDamage = widget.damage >= 50;
    final isMediumDamage = widget.damage >= 25;

    Color damageColor;
    if (widget.isPlayer) {
      damageColor = AppColors.danger;
    } else if (isLargeDamage) {
      damageColor = AppColors.accent;
    } else if (isMediumDamage) {
      damageColor = AppColors.warning;
    } else {
      damageColor = Colors.white;
    }

    return AnimatedBuilder(
      animation: Listenable.merge([
        _mainController,
        _scaleController,
        _bounceController,
      ]),
      builder: (context, child) {
        final slideOffset = _slideAnimation.value;
        final horizontalOffset = math.sin(_mainController.value * math.pi) * 15;

        return Positioned(
          left: widget.position.dx + horizontalOffset,
          top: widget.position.dy + slideOffset,
          child: Transform.scale(
            scale: _scaleAnimation.value * _bounceAnimation.value,
            child: Opacity(
              opacity: _fadeAnimation.value,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: damageColor.withValues(alpha: 0.9),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.8),
                    width: 1.5,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.5),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (!widget.isPlayer) ...[
                      Icon(
                        Icons.whatshot,
                        size: isLargeDamage ? 18 : 16,
                        color: Colors.white,
                      ),
                      const SizedBox(width: 4),
                    ] else ...[
                      Icon(
                        Icons.favorite_border,
                        size: 16,
                        color: Colors.white,
                      ),
                      const SizedBox(width: 4),
                    ],
                    Text(
                      widget.isPlayer
                          ? '-${widget.damage}'
                          : '${widget.damage}',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w900,
                        fontSize: isLargeDamage
                            ? 18
                            : (isMediumDamage ? 16 : 14),
                        shadows: [
                          Shadow(
                            color: Colors.black.withValues(alpha: 0.8),
                            offset: const Offset(1, 1),
                            blurRadius: 2,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  @override
  void dispose() {
    _mainController.dispose();
    _scaleController.dispose();
    _bounceController.dispose();
    super.dispose();
  }
}

class DamageNumberManager extends StatefulWidget {
  const DamageNumberManager({super.key, required this.child});

  final Widget child;

  static DamageNumberManagerState? of(BuildContext context) {
    return context.findAncestorStateOfType<DamageNumberManagerState>();
  }

  @override
  State<DamageNumberManager> createState() => DamageNumberManagerState();
}

class DamageNumberManagerState extends State<DamageNumberManager> {
  final List<Widget> _damageNumbers = [];

  void showDamage({
    required int damage,
    required Offset position,
    bool isPlayer = false,
  }) {
    final damageWidget = DamageNumber(
      damage: damage,
      position: position,
      isPlayer: isPlayer,
      onComplete: () {
        setState(() {
          _damageNumbers.removeWhere((widget) {
            if (widget is DamageNumber) {
              return widget.damage == damage &&
                  widget.position == position &&
                  widget.isPlayer == isPlayer;
            }
            return false;
          });
        });
      },
    );

    setState(() {
      _damageNumbers.add(damageWidget);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Stack(children: [widget.child, ..._damageNumbers]);
  }
}
