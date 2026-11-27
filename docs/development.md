# Development workflow

Use Flutter 3.44.8 with Dart 3.12.2. Android builds require Android SDK Platform 37 to compile the notifications and permissions plugins. From a fresh checkout, run these commands from the repository root:

```sh
./tool/bootstrap           # Resolve packages
./tool/check               # Analyze and run tests
flutter devices            # List available emulators and devices
./tool/run -d <device-id>   # Launch using .env
```

Replace `<device-id>` with an ID from `flutter devices`. Format edited Dart files with `dart format <files>`. Run focused widget or unit tests with `flutter test test/path_to_test.dart`. Use `flutter doctor -v` to diagnose SDK and device setup. Use `flutter build apk --debug` for an Android build check and `flutter build ios --simulator` on macOS with Xcode for an iOS build check.

In CI, run `./tool/bootstrap --enforce-lockfile` followed by `./tool/check`. For feature work, give the agent the feature and expected behavior, the sample files to compare, affected workspace roles, and how to verify the result. If working in parallel, assign non-overlapping modules and coordinate shared changes to routing, dependencies, and localization.

| Recommended addition | When to use it |
| --- | --- |
| [Official Flutter agent skills](https://github.com/flutter/agent-plugins) | Start here for widgets, adaptive layouts, navigation, and native platform work. Follow the [Flutter setup instructions](https://docs.flutter.dev/ai/get-started) for Codex or Claude Code. |
| [Official Dart agent skills](https://github.com/dart-lang/skills) | Use for Dart tests, dependency resolution, and analyzer fixes. Check whether the Flutter plugin already includes them before adding both. |
| [Dart and Flutter MCP server](https://docs.flutter.dev/ai/tools#dart-and-flutter-mcp-server) | Add for live diagnostics, test runs, and inspection of a running app. This is tooling for the agent, independent of app dependencies. |
| Project skill for porting web features | Start with the workflow in [mobile architecture](mobile-architecture.md). Once it stabilizes, package it as a `SKILL.md` in [.agents/skills for Codex](https://learn.chatgpt.com/docs/build-skills#where-codex-loads-local-skills) or [.claude/skills for Claude Code](https://code.claude.com/docs/en/skills#choose-where-skills-load). Have it run `./tool/check` after the port. |

The native Flutter screens run with local fixtures and boot without API settings. Use `./tool/run -d <device-id>` to check its gestures, keyboard, animations, and back navigation on the connected phone. For screen-level browser previews, open the [mobile design reference](../design/mobile/sabi-pipu-tms-prototype.html). When connecting a real backend, agree on the API environment and workspace fixtures before running flows. Keep private sample configuration, tokens, and real user data out of the Flutter project.

## Environment configuration

Run `./tool/run` from the project root. On first run it creates the local
`.env` from `.env.example`. To switch to live mode, edit `.env` in the Flutter
project root.

```dotenv
DATA_SOURCE=live
API_BASE_URL=https://api.example.com
```

Set `DATA_SOURCE=mock` to switch back. Stop and relaunch the app after editing
`.env` so Flutter picks up the build-time values. The local file is ignored by
Git. Use the base URL of the test deployment and fixture accounts. Keep
credentials out of `.env` because its values are compiled into the app.

In VS Code, select **Sabi Pipu (.env)** in Run and Debug. On a fresh checkout,
run `./tool/run` once or copy `.env.example` to `.env` before using the launch
configuration. In Android Studio, set `--dart-define-from-file=.env` once in
the Flutter run configuration's additional run arguments.

Mock mode opens the local workspace previews. Live mode opens Account or resumes
profile setup after sign-in. Account displays supported server workspaces and
polls pending approvals. See [backend coverage](mobile-architecture.md#data-modes-and-backend-coverage)
for the current routing and storage boundaries.

## OAuth and account links

For Google and Microsoft, set `OAUTH_REDIRECT_URI` to the exact HTTPS
`/auth/callback` URL configured in the backend and OAuth providers. Configure the
deployment's Android App Links and iOS Universal Links to deliver that callback
and the reset, verification, and email-change links to the app. OAuth buttons
become available when the redirect is configured. An OAuth attempt must return
to the app instance that opened the provider page so the app can validate state.

## Verifying authentication and workspace data

The loopback auth tests exercise the shared Dio stack using synthetic payloads.
Workspace repository tests exercise local seeding against fixture directories.

```sh
flutter test --no-pub test/modules/authentication
flutter test --no-pub test/modules/workspace
flutter test --no-pub -d <device-id> integration_test/authentication_smoke_test.dart
```

The device smoke test exercises startup, mock sign-in, and profile setup. Use a
configured test deployment and fixture account to verify backend behavior and
OAuth redirects on a device.
