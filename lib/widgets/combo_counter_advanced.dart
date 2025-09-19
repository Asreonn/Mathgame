import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:mathgame/theme.dart';

class ComboCounterAdvanced extends StatefulWidget {
  const ComboCounterAdvanced({
    super.key,
    required this.combo,
    required this.isIncrementing,
    required this.isResetting,
  });

  final int combo;
  final bool isIncrementing;
  final bool isResetting;

  @override
  State<ComboCounterAdvanced> createState() => _ComboCounterAdvancedState();
}

class _ComboCounterAdvancedState extends State<ComboCounterAdvanced>
    with TickerProviderStateMixin {
  late AnimationController _pulseController;
  late AnimationController _flameController;
  late AnimationController _lightController;
  late AnimationController _hitController;
  late AnimationController _resetController;

  @override
  void initState() {
    super.initState();

    _hitController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );

    _resetController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _flameController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );

    _lightController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    _updateAnimations();
  }

  @override
  void didUpdateWidget(ComboCounterAdvanced oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (widget.isIncrementing && !oldWidget.isIncrementing) {
      _onComboIncrease();
    }

    if (widget.isResetting && !oldWidget.isResetting) {
      _onComboReset();
    }

    _updateAnimations();
  }

  void _updateAnimations() {
    if (widget.combo >= 10) {
      if (!_pulseController.isAnimating) {
        _pulseController.repeat(reverse: true);
      }
    } else {
      _pulseController.stop();
      _pulseController.reset();
    }

    if (widget.combo >= 15) {
      if (!_flameController.isAnimating) {
        _flameController.repeat();
      }
    } else {
      _flameController.stop();
      _flameController.reset();
    }

    if (widget.combo >= 5) {
      if (!_lightController.isAnimating) {
        _lightController.repeat(reverse: true);
      }
    } else {
      _lightController.stop();
      _lightController.reset();
    }
  }

  void _onComboIncrease() {
    _hitController.forward().then((_) {
      _hitController.reverse();
    });
  }

  void _onComboReset() {
    _pulseController.stop();
    _flameController.stop();
    _lightController.stop();
    _resetController.forward().then((_) {
      _resetController.reverse();
    });
  }

  Color _getComboColor() {
    if (widget.combo >= 30) return const Color(0xFFFF00FF);
    if (widget.combo >= 20) return const Color(0xFF00FFFF);
    if (widget.combo >= 10) return const Color(0xFFFFD700);
    if (widget.combo >= 5) return AppColors.warning;
    return AppColors.combo;
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: Listenable.merge([
        _pulseController,
        _flameController,
        _lightController,
        _hitController,
        _resetController,
      ]),
      builder: (context, child) {
        final color = _getComboColor();

        final hitScale = 1.0 + (_hitController.value * 0.15);

        final pulseScale = 1.0 + ((_pulseController.value - 0.5) * 0.08);

        final resetScale = 1.0 - (_resetController.value * 0.2);

        final finalScale = hitScale * pulseScale * resetScale;

        return SizedBox(
          width: 60,
          height: 40,
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              if (widget.combo >= 5)
                Positioned.fill(
                  child: CustomPaint(
                    painter: _FlickeringLightPainter(
                      progress: _lightController.value,
                      color: color,
                      intensity: widget.combo >= 20 ? 1.0 : 0.6,
                    ),
                  ),
                ),

              if (widget.combo >= 15)
                Positioned.fill(
                  child: CustomPaint(
                    painter: _FlamePainter(
                      progress: _flameController.value,
                      color: color,
                      intensity: (widget.combo - 15) / 15,
                    ),
                  ),
                ),

              Center(
                child: Transform.scale(
                  scale: finalScale,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: color,
                      borderRadius: BorderRadius.circular(8),
                      border: widget.combo >= 10
                          ? Border.all(color: Colors.white, width: 1.5)
                          : null,
                    ),
                    child: Text(
                      '${widget.combo}x',
                      style: TextStyle(
                        color: Colors.black,
                        fontWeight: FontWeight.w800,
                        fontSize: widget.combo >= 100 ? 10 : 12,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _flameController.dispose();
    _lightController.dispose();
    _hitController.dispose();
    _resetController.dispose();
    super.dispose();
  }
}

class _FlickeringLightPainter extends CustomPainter {
  final double progress;
  final Color color;
  final double intensity;

  _FlickeringLightPainter({
    required this.progress,
    required this.color,
    required this.intensity,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);

    for (int i = 0; i < 3; i++) {
      final radius = (10 + i * 5) * intensity;
      final alpha = (math.sin(progress * math.pi * 2 + i) + 1) / 2;
      final flickerAlpha = alpha * 0.3 * intensity;

      final paint = Paint()
        ..color = color.withValues(alpha: flickerAlpha)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8);

      canvas.drawCircle(center, radius, paint);
    }
  }

  @override
  bool shouldRepaint(_FlickeringLightPainter oldDelegate) =>
      oldDelegate.progress != progress;
}

class _FlamePainter extends CustomPainter {
  final double progress;
  final Color color;
  final double intensity;

  _FlamePainter({
    required this.progress,
    required this.color,
    required this.intensity,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);

    for (int i = 0; i < (8 * intensity).round(); i++) {
      final angle = (i / (8 * intensity)) * math.pi * 2;
      final flameProgress = (progress + i * 0.1) % 1.0;

      final distance = 15 + math.sin(flameProgress * math.pi * 3) * 8;
      final x = center.dx + math.cos(angle) * distance;
      final y = center.dy + math.sin(angle) * distance - flameProgress * 10;

      final size = (3 + math.sin(flameProgress * math.pi * 2) * 2) * intensity;
      final alpha = (1 - flameProgress) * 0.6;

      final flameColor = Color.lerp(
        Colors.red,
        Colors.orange,
        math.sin(flameProgress * math.pi),
      )!;

      final paint = Paint()
        ..color = flameColor.withValues(alpha: alpha)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3);

      canvas.drawCircle(Offset(x, y), size, paint);
    }
  }

  @override
  bool shouldRepaint(_FlamePainter oldDelegate) =>
      oldDelegate.progress != progress;
}

class ComboMinimal extends StatelessWidget {
  const ComboMinimal({super.key, required this.multiplier});
  final int multiplier;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.combo,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        '${multiplier}x',
        style: const TextStyle(
          color: Colors.black,
          fontWeight: FontWeight.w800,
          fontSize: 12,
        ),
      ),
    );
  }
}
