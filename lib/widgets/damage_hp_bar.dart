import 'package:flutter/material.dart';
import 'package:mathgame/theme.dart';
import 'dart:math' as math;

class DamageHpBar extends StatefulWidget {
  const DamageHpBar({
    super.key,
    required this.current,
    required this.max,
    required this.previousValue,
    this.color,
    this.isPlayer = false,
  });

  final int current;
  final int max;
  final int previousValue;
  final Color? color;
  final bool isPlayer;

  @override
  State<DamageHpBar> createState() => _DamageHpBarState();
}

class _DamageHpBarState extends State<DamageHpBar>
    with TickerProviderStateMixin {
  late AnimationController _damageFlashController;
  late AnimationController _damageReduceController;
  late AnimationController _impactController;

  late Animation<double> _damageFlashAnimation;
  late Animation<double> _damageReduceAnimation;
  late Animation<double> _impactScaleAnimation;

  int _displayValue = 0;

  @override
  void initState() {
    super.initState();

    _displayValue = widget.current;

    _damageFlashController = AnimationController(
      duration: Duration(milliseconds: widget.isPlayer ? 250 : 150),
      vsync: this,
    );

    _damageReduceController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _impactController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    _damageFlashAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _damageFlashController, curve: Curves.easeInOut),
    );

    _damageReduceAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _damageReduceController, curve: Curves.easeOut),
    );

    _impactScaleAnimation =
        Tween<double>(begin: 1.0, end: widget.isPlayer ? 1.1 : 1.05).animate(
          CurvedAnimation(parent: _impactController, curve: Curves.elasticOut),
        );
  }

  @override
  void didUpdateWidget(DamageHpBar oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (oldWidget.current != widget.current &&
        widget.current < oldWidget.current) {
      if (widget.isPlayer) {
        _damageReduceController.duration = Duration(
          milliseconds: widget.current <= 0 ? 1200 : 800,
        );
      } else {
        _damageReduceController.duration = Duration(
          milliseconds: widget.current <= 0 ? 700 : 450,
        );
      }
      _triggerDamageEffect();
    } else if (oldWidget.current != widget.current) {
      _displayValue = widget.current;
    }
  }

  void _triggerDamageEffect() async {
    _impactController.forward().then((_) {
      _impactController.reverse();
    });

    _damageFlashController
      ..reset()
      ..forward().then((_) => _damageFlashController.reverse());

    await _damageReduceController.forward();

    setState(() {
      _displayValue = widget.current;
    });

    _damageReduceController.reset();
  }

  @override
  Widget build(BuildContext context) {
    final currentRatio = (_displayValue / widget.max).clamp(0.0, 1.0);
    final previousRatio = (widget.previousValue / widget.max).clamp(0.0, 1.0);
    final targetRatio = (widget.current / widget.max).clamp(0.0, 1.0);

    final barColor =
        widget.color ??
        (currentRatio > 0.5
            ? AppColors.accent
            : (currentRatio > 0.25 ? AppColors.warning : AppColors.danger));

    return AnimatedBuilder(
      animation: Listenable.merge([
        _damageFlashController,
        _damageReduceController,
        _impactController,
      ]),
      builder: (context, child) {
        final flashIntensity = _damageFlashAnimation.value;
        final damageProgress = _damageReduceAnimation.value;
        final scale = _impactScaleAnimation.value;

        return Transform.scale(
          scale: scale,
          child: LayoutBuilder(
            builder: (context, constraints) {
              final barWidth = constraints.maxWidth;

              return Stack(
                children: [
                  Container(
                    height: 14,
                    decoration: BoxDecoration(
                      color: AppColors.track,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Stack(
                        children: [
                          Container(
                            width: double.infinity,
                            height: 14,
                            color: barColor.withValues(alpha: 0.2),
                          ),
                          Align(
                            alignment: Alignment.centerLeft,
                            child: SizedBox(
                              width: barWidth * targetRatio,
                              height: 14,
                              child: ColoredBox(color: barColor),
                            ),
                          ),
                          if (flashIntensity > 0)
                            ColoredBox(
                              color: (widget.isPlayer
                                  ? Colors.red.withValues(
                                      alpha: flashIntensity * 0.4,
                                    )
                                  : Colors.white.withValues(
                                      alpha: flashIntensity * 0.3,
                                    )),
                            ),
                          if (_damageReduceController.isAnimating &&
                              previousRatio > targetRatio)
                            Positioned(
                              left: targetRatio * barWidth,
                              child: SizedBox(
                                width:
                                    (previousRatio - targetRatio) *
                                    (1.0 - damageProgress) *
                                    barWidth,
                                height: 14,
                                child: const ColoredBox(color: Colors.white),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),

                  if (widget.isPlayer)
                    CustomPaint(
                      size: const Size(double.infinity, 14),
                      painter: _SlashEffectPainter(
                        progress: _impactController.value,
                        isReversed: false,
                      ),
                    )
                  else
                    CustomPaint(
                      size: const Size(double.infinity, 14),
                      painter: _SlashEffectPainter(
                        progress: _impactController.value,
                        isReversed: true,
                      ),
                    ),
                ],
              );
            },
          ),
        );
      },
    );
  }

  @override
  void dispose() {
    _damageFlashController.dispose();
    _damageReduceController.dispose();
    _impactController.dispose();
    super.dispose();
  }
}

class _SlashEffectPainter extends CustomPainter {
  final double progress;
  final bool isReversed;

  _SlashEffectPainter({required this.progress, required this.isReversed});

  @override
  void paint(Canvas canvas, Size size) {
    if (progress <= 0) return;

    final paint = Paint()
      ..color = Colors.white.withValues(alpha: progress * 0.4)
      ..strokeWidth = 1.0
      ..style = PaintingStyle.stroke;

    final center = Offset(size.width / 2, size.height / 2);
    final slashLength = size.width * 0.3 * progress;

    final angle = isReversed ? -math.pi / 6 : math.pi / 6;
    final startX = center.dx - (slashLength / 2) * math.cos(angle);
    final startY = center.dy - (slashLength / 2) * math.sin(angle);
    final endX = center.dx + (slashLength / 2) * math.cos(angle);
    final endY = center.dy + (slashLength / 2) * math.sin(angle);

    canvas.drawLine(Offset(startX, startY), Offset(endX, endY), paint);
  }

  @override
  bool shouldRepaint(_SlashEffectPainter oldDelegate) =>
      oldDelegate.progress != progress;
}
