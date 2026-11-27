# Sabi Pipu TMS mobile

- Use [the mobile prototype](design/mobile/sabi-pipu-tms-prototype.html) for layout, motion, and copy. Use the web workspace prototype at `design/web/tms-app-6.html` when supplied for Individual, Family, and Specials workflows. Use the [backend docs](design/backend/docs/) as the source for API contracts. Consult the local web sample in `web_sample/web/src/` or `lib/web_sample/web/src/` when workflow or permission details need clarification. Keep sample code and configuration out of the Flutter app.
- Keep feature code in `lib/modules/<feature>/`. Use Riverpod for state, AutoRoute for navigation, and the existing Dio stack for networking. Add layers as the feature needs them.
- Treat the design HTML and its assets as a visual reference. Implement mobile screens and interactions in Dart under their feature modules.
- Treat the prototype’s status and navigation bar space as device chrome. Use Flutter safe-area insets for system bars and add only content spacing. Avoid fixed top or bottom padding that imitates the system bars.
- Check the relevant route, role, request, and response before porting a feature. Use test fixtures for verification. Keep credentials, session tokens, and private data out of source and logs.
- Keep changes focused. Format edited Dart files, run `./tool/check`, and report any checks that could not run. For UI or platform changes, also exercise the affected flow on the relevant device or simulator.

## Configuration and data modes

- Run the app with [`./tool/run`](tool/run) or the **Sabi Pipu (.env)** VS Code configuration. The launcher creates the ignored root `.env` from [`.env.example`](.env.example). Use `DATA_SOURCE=mock` for local previews and `DATA_SOURCE=live` with `API_BASE_URL` for the backend. Relaunch after editing `.env`. These values are compiled into the app, so keep credentials and tokens out of the file.
- Select implementations through Riverpod using `environmentProvider`. Keep shared repository contracts and providers in the owning feature, with mock and live implementations in separate files. Reuse `networkCallsRepositoryProvider` for backend calls and `TokenUtils` for secure session storage.
- Live routes cover authentication, account, workspace enrollment for Business, Individual, and Family, and profile setup. Keep the live route guard aligned with the backend coverage. The Company, Individual, Family, and Specials dashboards and tools run as local previews in mock mode. A backend failure should surface as a typed failure.
- `workspaceRepositoryProvider` controls local workspace seeding. Mock mode fills eligible non-Business workspaces with reference records. The live implementation passes stored records through. Server workspace listing and creation currently belong to the authenticated account flow. Preserve workspace IDs, active selection, user-created records, and legacy fixture migration behavior when editing local storage.

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
- [Environment setup, build commands, and checks](docs/development.md)
