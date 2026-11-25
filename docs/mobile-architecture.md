# Mobile architecture

The Flutter app targets Android and iOS. The [mobile design](../design/mobile/sabi-pipu-tms.html) is the reference for screen structure, animation, and design copy. The 27 native routes are registered with AutoRoute and rendered as Dart widgets. A Riverpod preview controller shares local fixture changes across screens. The browser design stays under `design/mobile/` for reference. The local web reference is at `web_sample/web/src/` in this checkout. If the sample is placed under `lib/web_sample/web/`, use the same relative paths inside it. Both sample locations are ignored by Git, so provide the relevant source files to an agent working from a fresh checkout. The root `web/` directory is Flutter's platform scaffold. The reference depends on workspace packages such as `@tms/schemas` and `@tms/tokens` that are outside this copy, so inspect the source and use the backend contract to settle API questions.

## Code ownership

| Flutter path | Responsibility | Web reference |
| --- | --- | --- |
| `lib/main.dart`, `lib/app/` | Bootstrap Riverpod and assemble the app, theme, router, and localization. The entry route opens the native splash screen. | `main.tsx`, `app/store.ts` |
| `lib/router/` | Register routes, deep links, and guards. Keep permission decisions in one workspace context shared by the router and navigation. | `router/index.tsx`, `router/guards.tsx`, `features/auth/views.ts` |
| `lib/modules/<feature>/` | Own screens and feature widgets in `presentation/`, Riverpod controllers and providers in `application/`, and repositories and DTOs in `data/`. Add `domain/` when there are independent business rules or models to share. | `features/<feature>/`, `types/` |
| `design/mobile/` | Browser reference for layouts, copy, interactions, and motion. Flutter does not package or execute it. | Mobile design reference |
| `lib/core/` | Reuse the Dio client, network and storage services, and platform adapters. Feature repositories own endpoint calls and transport mapping. | `api/baseApi.ts`, `lib/`, `features/*/api/` |
| `lib/shared/`, `lib/theme/` | Reuse UI across features and centralize design tokens in the Flutter theme. The native UI uses the reference’s light and dark palettes, Inter font and shared motion timings. | `components/common/`, `components/ui/`, `index.css` |
| `assets/translations/`, `lib/l10n/`, `test/` | Keep copy in JSON catalogs and translate typed failures at the UI boundary. Organize tests by feature. Use synthetic fixtures and override repository providers in tests. | `i18n/locales/`, `mock/` |

Widgets render state and send user events to controllers. Controllers call repositories and expose data, loading, and failure states. Repositories use the shared transport and translate payloads to the types their feature needs. Keep feature contracts out of `core/` and put a widget in `shared/` when multiple features use it.

## Individual, Family and Specials workspaces

The [web prototype](../design/web/tms-app-6.html) is the reference for workspace types and tools. On mobile, use **More → Switch** to choose a workspace or **New workspace** to create one. Home shows workspace-specific totals, shortcuts and upcoming work. **Sign in → Try a demo** populates the default spaces with fictional examples on a fresh installation. Creating a workspace starts a separate set of records. Plan uses one route with a section selector, compact lists, and bottom sheets for adding and updating records. Company uses its existing tabs and workflows.

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

Workspace records and the active selection are persisted on the device under a versioned local key. Records are scoped by workspace ID. The preview supports local entry and review, including manual RSVP updates, payment recording and voting. Cross-device synchronization, role enforcement, public invite and vendor pages, and transaction processing require backend integration.

## Connecting features to the backend

1. **Session and workspace.** Start with sign-in, email verification, and workspace restoration. Then add onboarding, invites, password reset, and other token links. Check `features/auth/api/authApi.ts`, `features/workspace/api/workspaceApi.ts`, and the public and protected route groups. Store session tokens using secure storage. Derive access from server workspace context and clear workspace data on sign-out or workspace switch.
2. **Authenticated shell and daily work.** The mobile design’s shared `TabBar` defines Home, My Tasks, Chat, Approvals, and More. Use `components/layout/nav.ts` and `MobileTabBar.tsx` when wiring up workspace role rules. Keep notifications accessible from the shell. Port My Day and tasks first, including requests and approvals, then Chat and Projects. Treat an assigned approval independently of whether the user gets an Approvals tab.
3. **Additional modules.** Map Journal to `notes`, and port teams, people, routines, profile, settings, files, notifications, birthdays, and performance as needed. Use the sample's role matrix for admin and reporting. Model guest attendance separately from workspace roles and keep public QR check-in and emailed checkout links outside the authenticated shell.

For a port, cross-check the route and role, feature API, DTOs, mock behavior, and English catalog. Preserve contract details such as workspace scope, repeated query filters, pagination, multipart fields, and server workflow transitions. Model loading, empty, error and retry, and permission states. Refresh dependent lists and badges after mutations and keep workspace-scoped caches isolated. Use mobile layouts with safe areas, keyboard handling, and scalable text.
