# Contributing

Thank you for your interest in improving **Zeka Kulesi**!

## Workflow
1. Fork the repository and create a feature branch based on `main`.
2. Run `flutter pub get`, then make your changes.
3. Keep code formatted (`dart format .`) and lint-free (`flutter analyze`).
4. Add or update tests inside `test/` and run `flutter test`.
5. Update documentation (README, docs/) if behaviour changes.
6. Commit with concise, imperative messages (e.g. `feat: add ice mage enemy`).
7. Open a pull request describing what changed and how to verify it.

## Coding Standards
- Follow the defaults from `analysis_options.yaml` (`flutter_lints`).
- Keep widgets focused; place private helpers (`_MyWidget`) in the same file.
- Reuse theme tokens from `lib/theme.dart` to maintain visual consistency.

## Reporting Issues
When filing an issue, include:
- Flutter version (`flutter --version`).
- Platform/device.
- Steps to reproduce and expected vs actual behaviour.
- Logs or screenshots if applicable.

We appreciate every contribution—thanks for helping the tower grow stronger!
