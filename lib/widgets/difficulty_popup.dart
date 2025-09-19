import 'package:flutter/material.dart';
import 'package:mathgame/theme.dart';

class DifficultyPopup extends StatefulWidget {
  const DifficultyPopup({super.key});

  @override
  State<DifficultyPopup> createState() => _DifficultyPopupState();
}

class _DifficultyPopupState extends State<DifficultyPopup>
    with TickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _opacity;
  late Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );
    _opacity = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween(
          begin: 0.0,
          end: 1.0,
        ).chain(CurveTween(curve: Curves.easeOutCubic)),
        weight: 20,
      ),
      TweenSequenceItem(tween: ConstantTween(1.0), weight: 60),
      TweenSequenceItem(
        tween: Tween(
          begin: 1.0,
          end: 0.0,
        ).chain(CurveTween(curve: Curves.easeInCubic)),
        weight: 20,
      ),
    ]).animate(_ctrl);
    _scale = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween(
          begin: 0.85,
          end: 1.15,
        ).chain(CurveTween(curve: Curves.easeOutBack)),
        weight: 30,
      ),
      TweenSequenceItem(
        tween: Tween(
          begin: 1.15,
          end: 1.0,
        ).chain(CurveTween(curve: Curves.easeOutCubic)),
        weight: 70,
      ),
    ]).animate(_ctrl);
    _ctrl.forward();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Positioned.fill(
      child: IgnorePointer(
        child: AnimatedBuilder(
          animation: _ctrl,
          builder: (context, child) {
            return Opacity(
              opacity: _opacity.value,
              child: Transform.scale(
                scale: _scale.value,
                child: Center(
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 14,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.surface.withValues(alpha: 0.95),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppColors.border, width: 2),
                      boxShadow: const [
                        BoxShadow(
                          color: Colors.black38,
                          blurRadius: 16,
                          spreadRadius: 2,
                        ),
                      ],
                    ),
                    child: const Text(
                      'Zorluk arttı',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 28,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 0.5,
                        decoration: TextDecoration.none,
                        shadows: [
                          Shadow(blurRadius: 12, color: Colors.black45),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

class DifficultyPopupManager extends StatefulWidget {
  const DifficultyPopupManager({super.key, required this.child});
  final Widget child;

  static DifficultyPopupManagerState? of(BuildContext context) {
    return context.findAncestorStateOfType<DifficultyPopupManagerState>();
  }

  @override
  State<DifficultyPopupManager> createState() => DifficultyPopupManagerState();
}

class DifficultyPopupManagerState extends State<DifficultyPopupManager> {
  final List<Widget> _popups = [];

  void showDifficultyPopup() {
    final popup = DifficultyPopup(key: UniqueKey());
    setState(() {
      _popups.add(popup);
    });
    Future.delayed(const Duration(milliseconds: 1250), () {
      if (!mounted) return;
      setState(() {
        _popups.remove(popup);
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Stack(children: [widget.child, ..._popups]);
  }
}
