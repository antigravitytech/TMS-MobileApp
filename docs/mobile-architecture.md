# Mobile architecture

The Flutter app targets Android and iOS. The [mobile prototype](../design/mobile/sabi-pipu-tms-prototype.html) is the visual reference for layout, motion, and copy. AutoRoute registers the native screens in [tms_routes.dart](../lib/router/tms_routes.dart) and maps them to widgets in [router_config.dart](../lib/router/router_config.dart). Flutter implements those screens in Dart.

The [backend docs](../design/backend/docs/) define API contracts. Use the local web sample under `web_sample/web/src/` or `lib/web_sample/web/src/` for unresolved workflow and permission details. Both paths are ignored by Git. The root `web/` directory is Flutter's platform scaffold.

## Code ownership

| Flutter path | Responsibility | Web reference |
| --- | --- | --- |
| `lib/main.dart`, `lib/app/` | Read build-time configuration, initialize localization and Riverpod, and assemble the app. The entry route opens the native splash screen. | `main.tsx`, `app/store.ts` |
| `lib/router/` | Register routes and deep links. The live guard redirects unsupported preview routes to Splash or Account according to session state. | `router/index.tsx`, `router/guards.tsx`, `features/auth/views.ts` |
| `lib/modules/<feature>/` | Own screens and feature widgets in `presentation/`, Riverpod controllers and providers in `application/`, and repositories and DTOs in `data/`. Add `domain/` when there are independent business rules or models to share. | `features/<feature>/`, `types/` |
| `design/mobile/` | Browser reference for layouts, copy, interactions, and motion. Flutter does not package or execute it. | Mobile design reference |
| `lib/core/` | Own the environment provider, Dio request stack, secure tokens, and platform services. Feature repositories own endpoint calls and transport mapping. | `api/baseApi.ts`, `lib/`, `features/*/api/` |
| `lib/shared/`, `lib/theme/` | Reuse UI across features and centralize design tokens in the Flutter theme. The native UI uses the reference’s light and dark palettes, Inter font and shared motion timings. | `components/common/`, `components/ui/`, `index.css` |
| `assets/translations/`, `lib/l10n/`, `test/` | Keep copy in JSON catalogs and translate typed failures at the UI boundary. Organize tests by feature. Use synthetic fixtures and override repository providers in tests. | `i18n/locales/`, `mock/` |

Widgets render state and send user events to controllers. Controllers call repositories and expose data, loading, and failure states. Repositories use the shared transport and translate payloads to the types their feature needs. Keep feature contracts out of `core/` and put a widget in `shared/` when multiple features use it.

## Data modes and backend coverage

[Development setup](development.md#environment-configuration) explains how to launch with `.env`. `main.dart` reads the build-time values through `AppEnvironment.fromDefines()` and supplies them through `environmentProvider`. The auth, profile setup, and workspace repository providers use this configuration to choose an implementation.

| Area | Mock mode | Live mode |
| --- | --- | --- |
| Authentication | Preview sign-in, demo entry, and local navigation | Signup, sign-in, session restoration, email verification and recovery, password and email changes, and optional Google or Microsoft OAuth |
| Account and enrollment | Local onboarding and workspace selection | Authenticated Account screen, workspace approval status, and API-backed enrollment for Business, Individual, Family, and all six Specials subtypes |
| Profile setup | Local profile, birthday, and notification preferences | Profile retrieval and edits, photo upload, birthday visibility, and supported notification preferences for an approved workspace |
| Dashboards and daily tools | Company, Individual, Family, and Specials preview workflows | Approved workspaces open API-backed Home. Business uses the company dashboard cards with its task, review, birthday, report, team and unread data. Personal and community dashboards use their workspace APIs and native cards. The standalone daily tools follow their own integration scope. |

`authentication` owns Splash, Welcome, Sign In, Account, public account links, and session state. Its shared repository contract and Riverpod provider sit next to separate mock and live implementation files. `onboarding` owns workspace selection during signup, personalization, and profile setup. Live onboarding progress is saved locally per account, so Splash can resume an unfinished setup.

Live auth uses `networkCallsRepositoryProvider` for API requests and `TokenUtils` for secure bearer token storage. Public auth requests omit bearer authorization. Splash checks the saved session and clears its token on an unauthorized response for the current session. Sign-out clears the local token, and renewal requires signing in again. The account flow lists server workspaces and polls pending approvals. Home opens the first approved workspace or the one picked in Account. Accounts with no approved workspace stay on the status screen. Workspace-scoped preferences require an approved workspace. Public workspace invite acceptance and public workspace signup links are pending integration.

## Live dashboards

Home keeps mock data in the preview providers. The live Home repository loads
workspace context and dashboard sections in parallel through the shared Dio
stack. Sections that fail can be retried with pull-to-refresh. The current Home
also refreshes once a minute while the route is visible and the app is active.

- Business Home uses the task, review, birthday, routine, team summary, chat
  endpoints and the shared notification badge. Dashboard actions submit reports, approve or
  return tasks, and send birthday wishes through the API. The Home tab bar
  links to the dashboard lists, conversation summaries, and Account.
- Individual and Family use the space hub plus their scoped project, task,
  school, poll, and family endpoints. Church and Event use dedicated dashboard
  feeds. Alumni, Estate, Committee, and Club use the space hub.
- The live space snapshot supplies role-specific Home cards and section lists
  in memory. Those lists are read-only. The local workspace store continues
  to own preview records.

## Live notifications

The bell opens the approved workspace’s inbox. The inbox loads paginated
notifications and supports an unread filter and individual and bulk read
actions. Home and the inbox share a workspace-scoped unread count that
refreshes after a read action.

## Local workspace previews

In mock mode use **More → Switch** to select a workspace or **New workspace** to create one. **Sign in → Try a demo** opens the selected preview with fictional records. Home shows workspace-specific totals, shortcuts and upcoming work. Plan uses a section selector, compact lists, and bottom sheets. Company uses its own tabs and preview state. Use the web workspace prototype when available to check the intended flows.

| Workspace | Mobile tools |
| --- | --- |
| Individual | Gigs, client pipeline, itemized invoices with discounts and VAT, payment history, weekly billable time by client, proposal templates, document preview and PDF or image export |
| Family | Household roles, multi-person chores and schoolwork, submit/return/approve, points and reward redemption, shopping, bills, errand change, visitor decisions and plans |
| Wedding & event | Event details and countdown, guest import, RSVP, check-in, table capacity and floor plan, vendor briefs and payments, live programme, checklist and notices |
| Church | Services and attendance, funds and pledge payments, units and duty rotas, member directory, prayer requests, first-timer follow-up and notices |
| Alumni | Dues, committees, polls, notices and directory |
| Estate | Levies, gate pass records, facility issues, notices and polls |
| Committee | Meetings, action items, minutes and decisions |
| Club | Sessions, fees, attendance and notices |

`LocalWorkspaces` coordinates selection, record updates, and sequential persistence through `LocalWorkspaceStore`. The directory, active selection, and workspace-scoped records are stored under `local_workspaces.v1` in SharedPreferences. Preserve those IDs and existing records when changing the model or seeding fixtures.

[WorkspaceRepository](../lib/modules/workspace/data/workspace_repository.dart) controls local seeding. The mock implementation fills eligible non-Business workspaces on load or creation while retaining supplied household members and setup details. The live implementation passes through the loaded directory and newly created local workspaces. Backend workspace listing and creation currently use the live auth repository. The local workspace controller runs its versioned legacy demo refreshes when opening a saved directory. Those migrations use preference flags and target known reference records, so keep their behavior in mind when checking an existing installation.

## Extending backend coverage

Read the relevant backend endpoint and mobile integration notes first. Check the web sample for route guards, role rules, and missing workflow details. Verify authorization, workspace scope, pagination, repeated query filters, multipart fields, and server workflow transitions against the contract.

Use the existing Dio and repository providers for requests. Keep live errors typed through the Riverpod controller and translate them in presentation. Model loading, empty, error, and permission states. On mutations, refresh dependent lists and badges and keep workspace-scoped state isolated. Preserve the mock workflow and test both data paths with synthetic fixtures. Expose a live route when the feature can exercise its backend workflow.

Use the shared Home, My Tasks, Chat, Approvals, and More navigation as the basis for future role-aware routing. Keep assigned approvals accessible according to the backend's permission rules. Journal maps to the backend's notes resource. Keep public guest QR check-in and emailed checkout links outside the authenticated shell when those flows are integrated.
