# Native feature modules

The Flutter app owns its screens here. `onboarding` holds the splash, welcome and account forms. `workspace` holds the More screen and the preview controller used for fixture changes that cross feature boundaries. Other folders are named for the part of the workspace they implement.

Keep feature UI in `presentation/`. Add `application/` for feature state and `data/` when there is a repository or service to own. Keep reusable visual controls in [shared design](../shared/design/) and register screens in [the router](../router/router_config.dart). The [browser design](../../design/mobile/README.md) is the reference for matching layout and motion.
