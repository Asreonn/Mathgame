# Zeka Kulesi — Math Tower Combat

A fast-paced arithmetic roguelite built with Flutter. Solve procedurally generated math challenges to power up your hero, burst down enemies, and climb an endless tower that adapts to your performance.

## Highlights
- **Three difficulty modes** that tune time pressure, progression pacing, and combo multipliers through a central `GameConfig`.
- **Combo-driven combat loop**: correct streaks boost damage exponentially, while mistakes slash the timer and break your rhythm.
- **Dynamic enemy roster** populated from CSV assets with boss rotation, floor scaling, and fallback logic for resilient loading.
- **Immersive presentation** featuring animated math glyph backgrounds, synchronized UI shuffles, popup feedback, and tactile haptics on critical events.
- **Modular architecture** that separates configuration, state management, themed widgets, and documentation for easy extension.

## Getting Started
### Prerequisites
- Flutter SDK 3.9.0 or newer (`sdk: ^3.9.0` in `pubspec.yaml`).
- A connected device or emulator (Android, iOS, or web) configured per Flutter documentation.

### Installation
```bash
flutter pub get
```

### Launching the Game
```bash
flutter run
```
Select your preferred device when prompted. The app boots into the animated main menu where you can choose a difficulty and start climbing.

### Tooling & Quality Checks
| Task | Command |
| ---- | ------- |
| Static analysis | `flutter analyze` |
| Formatting | `dart format .` |
| Tests | `flutter test` |
| Coverage (optional) | `flutter test --coverage` |

## Gameplay & Systems
- **Difficulty selection**: `MainMenuScreen` applies presets (attack timers, staging cadence, combo scaling) through `GameConfig.applyDifficulty`.
- **Combat engine**: `GameState` orchestrates timers, combo milestones, HP tracking, and floor transitions while notifying the UI.
- **Enemy pipeline**: `EnemyManager` reads `assets/enemies.csv`, filters candidates by floor level/boss flag, and falls back to the full roster if a tier is missing.
- **Feedback layer**: custom widgets (`DamageNumberManager`, `ComboPopupManager`, `DifficultyPopupManager`, etc.) drive HP bar animations, popups, and haptics.

## Project Structure
```
lib/
├─ main.dart                # Entry point wiring theme + routes
├─ theme.dart               # Central colors, typography, and spacing tokens
├─ game_config.dart         # Difficulty + balance knobs exposed as static values
├─ game_state.dart          # Core state machine backing GameScreen
├─ difficulty.dart          # Progressive operation unlock logic
├─ enemy_data.dart          # Enemy models + CSV loader utilities
├─ screens/
│  ├─ main_menu.dart        # Animated landing screen and difficulty tiles
│  └─ game_screen.dart      # Full gameplay experience with managers + widgets
└─ widgets/                 # Reusable UI components (combo counter, HP bars, popups, etc.)

assets/
└─ enemies.csv              # Enemy roster definitions with metadata

docs/
├─ README.md                # Documentation index
└─ architecture/
   └─ enemy_system.md       # Enemy spawning and scaling reference
```

## Configuration & Tuning
Adjust balance quickly via `lib/game_config.dart`. Key levers include:
- Damage scaling factors (`comboLinear`, `comboPower`, `comboPowerCoef`).
- Enemy pacing (`baseAttackTime`, `wrongAnswerPenalty`).
- Floor progression (`enemiesPerFloor`, `difficultyBossesPerStage`).
- Operation caps and weights that govern generated math problems.

To modify enemy data, edit `assets/enemies.csv` and ensure values remain comma-separated with the expected columns. Re-run `flutter pub get` if you add new asset files.

## Documentation
Extended guides live under [`docs/`](docs/README.md). Start with the enemy system deep dive for implementation notes on tiered spawns and bosses.

## Contributing & Maintenance
1. Follow the lint and formatting commands above.
2. Add or update widget/unit tests under `test/` when introducing gameplay or logic changes.
3. Update this README and the relevant files under `docs/` when you expand major systems.

Enjoy the climb, and feel free to iterate on the tower’s challenges to craft your own math-driven adventure.
