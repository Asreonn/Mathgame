# Zeka Kulesi

A Flutter-based arithmetic roguelite where players climb a procedurally scaling tower by answering rapid-fire math challenges. Correct streaks trigger combo-driven combat bonuses, while mistakes accelerate enemy attacks and jeopardise survival. The project targets mobile form factors first, with responsive layouts for tablets and the web.

## Feature Overview
- **Adaptive difficulty system** driven by `GameConfig` and `DifficultyController`, unlocking new operations and number ranges as floors are cleared.
- **Combo-centric combat loop** with exponential damage scaling, milestone-based combo retention, and time penalties on mistakes.
- **Data-driven enemy roster** sourced from `assets/enemies.csv`, supporting tiered difficulty, unique bosses, and resilient fallbacks when data is incomplete.
- **Rich feedback layer** combining haptics, animated widgets (`DamageNumberManager`, `ComboPopupManager`, `DifficultyPopupManager`), and themed UI to convey state changes.
- **Lean state management** through a single `GameState` `ChangeNotifier`, keeping logic predictable and testable without external state libraries.

## Architecture
```
lib/
├─ main.dart                 # Entry point binding theme + initial route
├─ theme.dart                # Color, typography, spacing tokens
├─ game_config.dart          # Static knobs for balance & difficulty presets
├─ game_state.dart           # Central gameplay state machine & timers
├─ difficulty.dart           # Progressive operation unlock logic
├─ enemy_data.dart           # Enemy models + CSV loading utilities
├─ screens/
│  ├─ main_menu.dart         # Animated landing screen with difficulty tiles
│  └─ game_screen.dart       # Core gameplay, orchestrating managers & widgets
└─ widgets/                  # Reusable UI components (combo counter, HP bars, popups, death screen)

assets/
└─ enemies.csv               # Enemy catalogue consumed by EnemyManager
```

Key design principles:
- **Configuration-first:** all tunables (damage, timers, floor pacing) live in `game_config.dart` to simplify balancing.
- **Documented flow:** `GameState` owns timers and combo transitions, while UI widgets stay presentational and subscribe via listeners.
- **Asset resilience:** enemy loading is tolerant of malformed CSV rows, ensuring the game still boots with defaults.
- **Animation encapsulation:** each widget manages its own controllers to avoid cross-component coupling.

## Environment Setup
- Flutter SDK: `>= 3.9.0`
- Dart SDK: installed via Flutter toolchain
- Recommended tooling: Android Studio or VS Code with Flutter extension

```bash
# verify toolchain
dart --version
flutter --version

# fetch dependencies
flutter pub get
```

## Running & Debugging
```bash
# run on connected device/emulator
flutter run

# specify platform explicitly
flutter run -d chrome      # web
flutter run -d emulator-5554  # android emulator example
```
Enable performance overlays via Flutter DevTools when tuning animations. `GameState` emits granular events, so attach a debugger or log listeners for deeper inspection.

## Quality Gates
| Task | Command | Notes |
| ---- | ------- | ----- |
| Static analysis | `flutter analyze` | Enforces `flutter_lints` from `analysis_options.yaml` |
| Formatting | `dart format .` | Run before committing to maintain 2-space indentation |
| Tests | `flutter test` | Add widget/unit coverage for gameplay logic |
| Coverage (optional) | `flutter test --coverage` | Generates `coverage/lcov.info` |

## Configuration Matrix
`lib/game_config.dart` centralises all balance levers:
- `baseAttackTime`, `wrongAnswerPenalty` – pacing for enemy strikes.
- `comboLinear`, `comboPower`, `comboPowerCoef` – governs damage multiplier growth.
- `difficultyBossesPerStage`, `difficultyNegativeSubtractionStage` – stage progression cadence.
- Operation caps (`capsAdd`, `capsSub`, `capsMul`, `capsDiv`) and weights to shape generated equations.

Difficulty presets map to these values via `GameConfig.applyDifficulty`, updating timers, stage behaviour, and combo multipliers when the player selects Easy/Normal/Hard.

## Enemy Data Contract
`assets/enemies.csv` columns:
1. `id`
2. `name`
3. `emoji`
4. `baseHP`
5. `baseDamageMultiplier`
6. `difficultyLevel`
7. `type` (`normal` | `boss`)
8. `specialAbilityId`
9. `specialAbilityDescription`

`EnemyManager` filters by floor level and boss flag. Missing tiers fall back to the full list, so ensure each level has at least one normal enemy and a boss for best pacing.

## Build & Release Targets
```bash
# Android release APK
flutter build apk --release

# iOS (requires macOS tooling)
flutter build ios --release

# Web (for quick demos)
flutter build web
```
Package-specific configuration (icons, bundle IDs, signing) resides under `android/` and `ios/`. Update those platforms before distributing.

## Maintenance Checklist
- Keep `pubspec.yaml` dependency versions current (`flutter pub outdated`).
- Audit `assets/enemies.csv` for balance tweaks and emoji/ability consistency.
- Monitor animation performance on lower-end hardware; adjust controller durations or particle counts if necessary.
- Extend test coverage as new gameplay systems are added.

## Troubleshooting
| Symptom | Resolution |
| ------- | ---------- |
| Flutter commands request engine updates | Run with `--no-version-check` or update Flutter; ensure write permissions to `flutter/bin/cache`. |
| CSV parsing exceptions | Validate delimiter and column count; ensure there’s no trailing comma on lines. |
| Animations feel choppy | Profile with `flutter run --profile`; inspect widget rebuild counts and animation controllers. |
| Combo multiplier feels unbalanced | Tweak `comboLinear`/`comboPowerCoef` and re-run tests for damage expectations. |

## Roadmap Ideas
- Progress persistence across sessions (save floor + stats).
- Additional enemy abilities with active player counters.
- Daily challenges with constrained operation sets.
- Multiplayer leaderboards sharing max combo / floor reached.

Feel free to fork, experiment with new mechanics, and open pull requests via the provided templates. Happy hacking!
