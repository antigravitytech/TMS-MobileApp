# Sabi Pipu TMS mobile

- Use [the mobile design](design/mobile/sabi-pipu-tms.html) for screen layout, animation, and design copy. Use [the workspace HTML](design/web/tms-app-6.html) for Individual, Family, and Specials workflows. Use the web sample for permissions and backend contracts. Look in `web_sample/web/src/` or `lib/web_sample/web/src/`. Keep sample code and configuration out of the Flutter app.
- Keep feature code in `lib/modules/<feature>/`. Use Riverpod for state, AutoRoute for navigation, and the existing Dio stack for networking. Add layers as the feature needs them.
- Treat the design HTML and its assets as a visual reference. Implement mobile screens and interactions in Dart under their feature modules.
- Check the relevant route, role, request, and response before porting a feature. Use test fixtures for verification. Keep credentials, session tokens, and private data out of source and logs.
- Keep changes focused. Format edited Dart files, run `./tool/check`, and report any checks that could not run. For UI or platform changes, also exercise the affected flow on the relevant device or simulator.

## Presentation, notifiers and services

- Keep screens and widgets in `presentation/` focused on layout, rendering, and UI concerns such as focus, animation, navigation and localized feedback. Have widgets watch Riverpod state and forward user events to a notifier.
- Keep feature state, validation, workflow decisions and asynchronous coordination in Riverpod notifiers under the feature's `application/` directory. Return or expose typed outcomes so the UI can show feedback and navigate.
- Inspect `lib/core/services/` before adding file picking, storage, permissions, notifications or other platform or SDK calls. Reuse or extend the matching service. Add a reusable service there when the capability is missing, and keep non-UI package calls behind that service. Keep feature-specific API calls in the feature's data layer and use the existing Dio stack.
- Apply these boundaries to new code and clean up existing screens as they are worked on.

## File length and widget extraction

- Keep source files at or below 350 lines. When a file exceeds 350 lines, split it at cohesive responsibilities, such as screens, substantial widgets, or related presentation logic, and keep each resulting file within the limit.
- Do not extract widgets solely to shorten a file that is already within the limit. A screen around 250 lines can remain together when its widgets are closely related. Avoid fragmenting a cohesive screen into many small files or extracting trivial, single-use widgets merely to leave a short screen file.
- Apply this rule to files being added or changed. Address existing oversized files as their screens are worked on, and preserve their public entry points and behavior when splitting them.

## Required icon workflow

- Reuse the semantic icons in `lib/shared/design/tms_icons.dart` for app-owned UI. Pick an Iconsax glyph first. Use Lucide if Iconsax has no suitable glyph, and use Material only when neither library has a suitable glyph. Add new choices to the shared registry and prefer outline variants for inactive actions.

## Required localization workflow

- Apply this workflow to every future task that adds or changes Flutter-owned user-facing text. Put the English copy in `assets/translations/en.json` and resolve it through `easy_localization` with `context.tr(key)`. Update the catalog in the same change for navigation, buttons, forms, validation, accessibility labels, dialogs, notifications, toasts, empty states, and errors.
- Use descriptive feature-prefixed keys and reuse a shared key when its meaning and context match. Use named placeholders for dynamic copy, `context.plural` for quantities that change the wording, and the active locale for dates and numbers.
- Keep user-entered text, API codes, and values used for filtering, sorting, and state as data. Translate display labels and typed failures in the presentation layer.
- Keep English as the fallback. When adding a language, follow [the localization guide](docs/localization.md) for catalog and platform registration. Verify that the changed screens resolve their copy and dynamic messages.

Read the relevant reference before changing that area:

- [Architecture and web-to-mobile map](docs/mobile-architecture.md)
- [Localization rules](docs/localization.md)
- [Build commands, checks, and recommended skills](docs/development.md)
