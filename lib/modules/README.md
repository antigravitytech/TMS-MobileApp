# Native feature modules

The Flutter app owns its screens here. Each folder is one feature with the same layout:

- `presentation/` — screens, with feature widgets in `presentation/widgets/`.
- `application/` — Riverpod notifiers and providers: state, validation and workflow.
- `data/` — repositories (a shared contract with `live_` and `mock_` implementations, as in `authentication`) and mock fixtures.
- `domain/` — models and rules shared beyond one screen, when the feature has them.

Where things live:

- `authentication` owns splash, welcome, sign-in and the session. `onboarding` owns workspace and profile setup.
- `workspace` owns the workspace directory and its storage (`LocalWorkspaces`, `WorkspaceRepository`), the record model, Home and Plan routing (`workspace_home.dart`, `section_screens.dart`), More, and the generic record list and sheets used by sections that have no design screen of their own.
- Each role has its own module: `individual`, `family` (home, household, kid view, family tasks) with `bills`, `chores`, `rewards`, `school`, `shopping` and `family_plans`, and the Specials roles `church`, `alumni`, `estate`, `event`, `committee` and `club`. `specials` holds what those roles share (home shell, notices, polls, collections, stage lists, meetings).
- Company tabs (`home`, `tasks`, `approvals`, `chat`, `notifications`, `reports` and the other business tools) keep their own folders.

Keep reusable visual controls in [shared design](../shared/design/) and the cross-role widget kit (`Kit*` cards, chips, tabs, inputs, payment sheet) in [shared kit](../shared/kit/). Register screens in [the router](../router/router_config.dart). The [browser design](../../design/mobile/README.md) is the reference for matching layout and motion.
