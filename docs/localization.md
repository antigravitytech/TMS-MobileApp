# Localization

Native Flutter screens use `easy_localization`. Edit `assets/translations/en.json` for English copy. The app initializes localization before the first frame and declares its supported locales in `lib/app/tms_app.dart`. English is the initial locale and fallback.

- Use descriptive dotted keys by feature, such as `tasks.no_tasks_match_this_filter`. Reuse shared keys when the meaning and context match. Read translations with `context.tr(key)` so widgets respond to locale changes.
- Localize navigation, buttons, validation, notifications, empty states, toasts, dialogs, and accessibility labels. Keep user-entered content, preview names and titles, and API codes as data. Resolve controlled labels at the presentation boundary so filtering and sorting use stable values.
- Use named placeholders for dynamic copy and `context.plural` for quantities that change the wording. Keep placeholder names consistent across catalogs. Use the active locale when formatting dates and numbers.
- Return typed failures from data and state layers. Resolve them through `NetworkFailureLocalization` in the UI and keep raw diagnostics in sanitized logs.
- To add a language, create a matching JSON catalog, register its locale in `TmsApp` and the iOS Info.plist, and add its display name under `locales`. Check Flutter's Material, Cupertino, and Widgets delegates and date formatting support. Verify translated screens, text scaling, and directionality on a device.

Review related copy in `web_sample/web/src/i18n/locales/en/`. The web sample includes draft Hausa, Yoruba, Igbo, and Nigerian Pidgin catalogs. Review those translations and Flutter locale support before enabling them on mobile.

See the [easy_localization package guide](https://pub.dev/packages/easy_localization/versions/3.0.8) for catalog syntax and locale handling.
