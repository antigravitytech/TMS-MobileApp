# Development workflow

Use Flutter 3.44.8 with Dart 3.12.2. Android builds require Android SDK Platform 37 to compile the notifications and permissions plugins. From a fresh checkout, run these commands from the repository root:

```sh
./tool/bootstrap           # Resolve packages
./tool/check               # Analyze and run tests
flutter devices            # List available emulators and devices
flutter run -d <device-id> # Launch the app
```

Replace `<device-id>` with an ID from `flutter devices`. Format edited Dart files with `dart format <files>`. Run focused widget or unit tests with `flutter test test/path_to_test.dart`. Use `flutter doctor -v` to diagnose SDK and device setup. Use `flutter build apk --debug` for an Android build check and `flutter build ios --simulator` on macOS with Xcode for an iOS build check.

In CI, run `./tool/bootstrap --enforce-lockfile` followed by `./tool/check`. For feature work, give the agent the feature and expected behavior, the sample files to compare, affected workspace roles, and how to verify the result. If working in parallel, assign non-overlapping modules and coordinate shared changes to routing, dependencies, and localization.

| Recommended addition | When to use it |
| --- | --- |
| [Official Flutter agent skills](https://github.com/flutter/agent-plugins) | Start here for widgets, adaptive layouts, navigation, and native platform work. Follow the [Flutter setup instructions](https://docs.flutter.dev/ai/get-started) for Codex or Claude Code. |
| [Official Dart agent skills](https://github.com/dart-lang/skills) | Use for Dart tests, dependency resolution, and analyzer fixes. Check whether the Flutter plugin already includes them before adding both. |
| [Dart and Flutter MCP server](https://docs.flutter.dev/ai/tools#dart-and-flutter-mcp-server) | Add for live diagnostics, test runs, and inspection of a running app. This is tooling for the agent, independent of app dependencies. |
| Project skill for porting web features | Start with the workflow in [mobile architecture](mobile-architecture.md). Once it stabilizes, package it as a `SKILL.md` in [.agents/skills for Codex](https://learn.chatgpt.com/docs/build-skills#where-codex-loads-local-skills) or [.claude/skills for Claude Code](https://code.claude.com/docs/en/skills#choose-where-skills-load). Have it run `./tool/check` after the port. |

The native Flutter screens run with local fixtures and boot without API settings. Use `flutter run -d <device-id>` to check its gestures, keyboard, animations, and back navigation on the connected phone. For screen-level browser previews, open the [mobile design reference](../design/mobile/sabi-pipu-tms.html). When connecting a real backend, agree on the API environment and workspace fixtures before running flows. Keep private sample configuration, tokens, and real user data out of the Flutter project.
