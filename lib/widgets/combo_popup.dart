import 'package:flutter/material.dart';

class ComboPopup extends StatefulWidget {
  const ComboPopup({super.key, required this.text, required this.color});

  final String text;
  final Color color;

  @override
  State<ComboPopup> createState() => _ComboPopupState();
}

class _ComboPopupState extends State<ComboPopup> with TickerProviderStateMixin {
  late AnimationController _mainController;
  late AnimationController _scaleController;

  late Animation<double> _slideAnimation;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();

    _mainController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    );

    _scaleController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );

    _slideAnimation = Tween<double>(begin: 50, end: -100).animate(
      CurvedAnimation(
        parent: _mainController,
        curve: const Interval(0.0, 0.8, curve: Curves.easeOutCubic),
      ),
    );

    _fadeAnimation = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween<double>(
          begin: 0.0,
          end: 1.0,
        ).chain(CurveTween(curve: Curves.easeOut)),
        weight: 20,
      ),
      TweenSequenceItem(tween: Tween<double>(begin: 1.0, end: 1.0), weight: 60),
      TweenSequenceItem(
        tween: Tween<double>(
          begin: 1.0,
          end: 0.0,
        ).chain(CurveTween(curve: Curves.easeIn)),
        weight: 20,
      ),
    ]).animate(_mainController);

    _scaleAnimation = Tween<double>(begin: 0.5, end: 1.2).animate(
      CurvedAnimation(parent: _scaleController, curve: Curves.elasticOut),
    );

    _startAnimations();
  }

  void _startAnimations() {
    _mainController.forward();
    _scaleController.forward();

    _mainController.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        _dispose();
      }
    });
  }

  void _dispose() {
    if (mounted) {}
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: Listenable.merge([_mainController, _scaleController]),
      builder: (context, child) {
        return Positioned(
          left: 0,
          right: 0,
          top: MediaQuery.of(context).size.height * 0.3 + _slideAnimation.value,
          child: Opacity(
            opacity: _fadeAnimation.value,
            child: Transform.scale(
              scale: _scaleAnimation.value,
              child: Center(
                child: Text(
                  widget.text,
                  style: TextStyle(
                    color: widget.color,
                    fontSize: 24,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1,
                    decoration: TextDecoration.none,
                    shadows: [
                      Shadow(
                        offset: const Offset(0, 0),
                        blurRadius: 8,
                        color: widget.color.withValues(alpha: 0.8),
                      ),
                      Shadow(
                        offset: const Offset(1, 1),
                        blurRadius: 2,
                        color: Colors.black.withValues(alpha: 0.5),
                      ),
                    ],
                  ),
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
    super.dispose();
  }
}

class ComboPopupManager extends StatefulWidget {
  const ComboPopupManager({super.key, required this.child});

  final Widget child;

  static ComboPopupManagerState? of(BuildContext context) {
    return context.findAncestorStateOfType<ComboPopupManagerState>();
  }

  @override
  State<ComboPopupManager> createState() => ComboPopupManagerState();
}

class ComboPopupManagerState extends State<ComboPopupManager> {
  final List<Widget> _popups = [];

  void showComboPopup(String text, Color color) {
    final popup = ComboPopup(key: UniqueKey(), text: text, color: color);

    setState(() {
      _popups.add(popup);
    });

    Future.delayed(const Duration(milliseconds: 2000), () {
      if (mounted) {
        setState(() {
          _popups.remove(popup);
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Stack(children: [widget.child, ..._popups]);
  }
}
