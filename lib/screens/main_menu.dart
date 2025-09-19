import 'package:flutter/material.dart';
import 'dart:math' as math;
import 'package:mathgame/screens/game_screen.dart';
import 'package:mathgame/theme.dart';
import 'package:mathgame/game_config.dart';

class MainMenuScreen extends StatefulWidget {
  const MainMenuScreen({super.key});

  @override
  State<MainMenuScreen> createState() => _MainMenuScreenState();
}

class _HeroTitle extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final base =
        Theme.of(context).textTheme.headlineMedium?.copyWith(
          fontSize: 34,
          fontWeight: FontWeight.w900,
        ) ??
        const TextStyle(fontSize: 34, fontWeight: FontWeight.w900);
    return ShaderMask(
      shaderCallback: (rect) => const LinearGradient(
        colors: [AppColors.accent, AppColors.warning],
      ).createShader(rect),
      blendMode: BlendMode.srcIn,
      child: Text('Zeka Kulesi', textAlign: TextAlign.center, style: base),
    );
  }
}

class _MainMenuScreenState extends State<MainMenuScreen>
    with SingleTickerProviderStateMixin {
  GameDifficulty _selected = GameDifficulty.normal;
  late final AnimationController _bgCtrl;

  @override
  void initState() {
    super.initState();
    _bgCtrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 12),
    )..repeat();
  }

  @override
  void dispose() {
    _bgCtrl.dispose();
    super.dispose();
  }

  Widget _difficultyTile({
    required IconData icon,
    required String title,
    required GameDifficulty value,
    required List<_Bullet> bullets,
  }) {
    final isSel = _selected == value;
    final bg = isSel ? AppColors.accent : AppColors.surface;
    final primary = isSel ? Colors.white : AppColors.textPrimary;
    final secondary = isSel
        ? Colors.white.withValues(alpha: 0.9)
        : AppColors.textSecondary;
    return InkWell(
      onTap: () => setState(() => _selected = value),
      borderRadius: BorderRadius.circular(16),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.border),
          boxShadow: isSel
              ? [
                  BoxShadow(
                    color: AppColors.accent.withValues(alpha: 0.4),
                    blurRadius: 16,
                    offset: const Offset(0, 6),
                  ),
                ]
              : null,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: primary),
                const SizedBox(width: 10),
                Text(
                  title,
                  style: TextStyle(
                    fontWeight: FontWeight.w900,
                    fontSize: 16,
                    color: primary,
                  ),
                ),
                const Spacer(),
                Icon(
                  isSel ? Icons.radio_button_checked : Icons.radio_button_off,
                  color: primary,
                ),
              ],
            ),
            AnimatedSize(
              duration: const Duration(milliseconds: 180),
              curve: Curves.easeOutCubic,
              alignment: Alignment.topLeft,
              child: isSel
                  ? Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: bullets
                            .map(
                              (b) => Padding(
                                padding: const EdgeInsets.only(bottom: 6),
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Icon(b.icon, size: 16, color: secondary),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        b.text,
                                        style: TextStyle(
                                          color: secondary,
                                          height: 1.25,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            )
                            .toList(),
                      ),
                    )
                  : const SizedBox.shrink(),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          Positioned.fill(child: _AnimatedMathBackground(controller: _bgCtrl)),
          Positioned.fill(
            child: Container(color: Colors.black.withValues(alpha: 0.12)),
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SizedBox(height: 24),
                  _HeroTitle(),
                  const SizedBox(height: 8),
                  const Text(
                    'Akıl ve hız – zirveye tırman!',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: AppColors.textSecondary),
                  ),
                  const SizedBox(height: 24),
                  _difficultyTile(
                    icon: Icons.spa_rounded,
                    title: 'Kolay',
                    value: GameDifficulty.easy,
                    bullets: const [
                      _Bullet(Icons.timer_rounded, 'Saldırı süresi: 10 saniye'),
                      _Bullet(
                        Icons.trending_up_rounded,
                        'İlerleme: 2 boss → 1 aşama',
                      ),
                      _Bullet(Icons.bolt_rounded, 'Combo etkisi: normal'),
                    ],
                  ),
                  const SizedBox(height: 12),
                  _difficultyTile(
                    icon: Icons.speed_rounded,
                    title: 'Normal',
                    value: GameDifficulty.normal,
                    bullets: const [
                      _Bullet(Icons.timer_rounded, 'Saldırı süresi: 8 saniye'),
                      _Bullet(
                        Icons.trending_up_rounded,
                        'İlerleme: her boss → 1 aşama',
                      ),
                      _Bullet(Icons.bolt_rounded, 'Combo etkisi: normal'),
                    ],
                  ),
                  const SizedBox(height: 12),
                  _difficultyTile(
                    icon: Icons.local_fire_department_rounded,
                    title: 'Zor',
                    value: GameDifficulty.hard,
                    bullets: const [
                      _Bullet(Icons.timer_rounded, 'Saldırı süresi: 5 saniye'),
                      _Bullet(
                        Icons.trending_up_rounded,
                        'İlerleme: her düşman → 1 aşama',
                      ),
                      _Bullet(
                        Icons.flash_on_rounded,
                        'Combo etkisi: x2 (daha yüksek hasar artışı)',
                      ),
                    ],
                  ),
                  const Spacer(),
                  ElevatedButton(
                    onPressed: () {
                      GameConfig.applyDifficulty(_selected);
                      Navigator.of(context).push(
                        MaterialPageRoute(builder: (_) => const GameScreen()),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      textStyle: const TextStyle(fontWeight: FontWeight.w800),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    child: const Text('Oyuna Başla'),
                  ),
                  const SizedBox(height: 12),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _AnimatedMathBackground extends StatefulWidget {
  const _AnimatedMathBackground({required this.controller});
  final AnimationController controller;

  @override
  State<_AnimatedMathBackground> createState() =>
      _AnimatedMathBackgroundState();
}

class _AnimatedMathBackgroundState extends State<_AnimatedMathBackground> {
  late List<_BgSprite> _sprites;

  @override
  void initState() {
    super.initState();
    _sprites = List.generate(22, (i) => _BgSprite.random());
    widget.controller.addListener(_tick);
  }

  @override
  void dispose() {
    widget.controller.removeListener(_tick);
    super.dispose();
  }

  void _tick() {
    setState(() {
      for (final s in _sprites) {
        s.advance();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, c) {
        return Stack(
          children: _sprites
              .map((s) => s.build(c.maxWidth, c.maxHeight))
              .toList(),
        );
      },
    );
  }
}

class _Bullet {
  final IconData icon;
  final String text;
  const _Bullet(this.icon, this.text);
}

class _BgSprite {
  static final _r = math.Random();
  double x = 0;
  double y = 0;
  double speedY = 0.02;
  double drift = 0.0;
  double size = 18;
  double phase = 0.0;
  String char = '+';

  _BgSprite();

  factory _BgSprite.random() {
    final s = _BgSprite();
    s.x = _r.nextDouble();
    s.y = _r.nextDouble();
    s.speedY = 0.002 + _r.nextDouble() * 0.006;
    s.drift = (_r.nextDouble() - 0.5) * 0.004;
    s.size = 16 + _r.nextDouble() * 18;
    s.phase = _r.nextDouble() * math.pi * 2;
    const symbols = [
      '+',
      '−',
      '×',
      '÷',
      '1',
      '2',
      '3',
      '4',
      '5',
      '6',
      '7',
      '8',
      '9',
      '👹',
      '💀',
      '🐉',
    ];
    s.char = symbols[_r.nextInt(symbols.length)];
    return s;
  }

  void advance() {
    y += speedY;
    x += drift + math.sin(phase + y * 6) * 0.0008;
    if (y > 1.1) {
      y = -0.1;
      x = _r.nextDouble();
      size = 16 + _r.nextDouble() * 18;
      drift = (_r.nextDouble() - 0.5) * 0.004;
      speedY = 0.002 + _r.nextDouble() * 0.006;
      phase = _r.nextDouble() * math.pi * 2;
    }
  }

  Widget build(double w, double h) {
    final px = x * w;
    final py = y * h;
    final opacity = (0.35 + (size - 16) / 18 * 0.25).clamp(0.3, 0.6);
    return Positioned(
      left: px,
      top: py,
      child: Opacity(
        opacity: opacity.toDouble(),
        child: Text(
          char,
          style: TextStyle(fontSize: size, color: AppColors.textSecondary),
        ),
      ),
    );
  }
}
