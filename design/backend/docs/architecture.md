# TMS Backend Architecture

This document explains how the backend is organised and how the main product
flows cross module boundaries. Endpoint-level contracts live in the other
files in this folder.

## Layering

Every package follows the same four-file pattern:

```
{routers,schemas,services,tasks}.py
```

- `routers.py` — thin FastAPI routes, authentication and response models.
  Every route has an explicit `name=` used by tests via `app.url_path_for`.
- `schemas.py` — Pydantic request/response contracts.
- `services.py` — business rules, access checks and transactions.
- `tasks.py` — Celery jobs, used when work should happen off-request.

Tortoise models live in `tms/models/` and are registered in
`database/database.py`. The app package is `tms/`; the entrypoint is
`tms/server.py` (`get_application()` and module-level `app`).

## Modules

| Package | Responsibility |
| --- | --- |
| `auth` | Signup/login, social OAuth, profile, password reset, email verification, email change, unsubscribe |
| `workspaces` | Workspace CRUD/settings, memberships, roles, invites, public invite acceptance |
| `people` | Unified directory, reporting lines, organogram, bulk invites, offboarding/handover, my-context |
| `teams` | Team CRUD, lead/member roles, lane definitions and assignments |
| `projects` | Project CRUD, members, milestones, visibility, approval policy, email invites, normalized plan graph, templates and leave |
| `tasks` | Task creation/recurrence, listing, workflow, approvals, comments, links, reactions, checklist, attachments, watchers, access requests, saved views |
| `routines` | Recurring reports, report fields/logs/reviews, recurring-task templates, reminders |
| `reports` | Dashboard aggregates, activity feed, person reports, appraisal CSV |
| `gamification` | Points ledger, streaks, badges, leaderboard |
| `files` | Workspace file library over task attachments, standalone inline uploads and orphan cleanup |
| `chat` | Chat groups, channels, DMs, group chats, task conversations, messages, threads, reactions, chat attachments and unread state |
| `notes` | Private journal notes, pinning, archive, seven-day trash and reminders |
| `birthdays` | Birthday feeds, visibility, birthday cards in chat, manually added calendar entries and the daily reminder job |
| `spaces` | Family/individual/specials workspace hubs, module rows, family home and studio invoices/proposals |
| `events` | Event planner (guests, vendors, seating, programme), public RSVP page and vendor brief |
| `church` | Church services, giving/funds/pledges, units, prayers and first-timers |
| `school` | Family school diary and checker workflow |
| `polls` | Standalone and chat-linked polls |
| `sharing` | Project/task share links and collaborator access |
| `guest_checkin` | Legacy permanent QR entry points, guest check-in/out, visitor log, in-building count, settings, exports, audit log and retention jobs |
| `visitors` | Pass-based visitors: desks, host invitations, front desk actions, public pass page, hold-over/expiry jobs and the legacy guest check-in sync |
| `attendance` | Workspace clock-in settings, geofence/Wi-Fi checks, clock-in/out, holidays, lateness alerts, stats, history, team board and weather/place proxies |
| `scp` | Platform control unit: operator accounts/permissions, tenant billing actions, plans, support tickets, audit logs, activity feed and free-access expiry |
| `notifications` | In-app notifications, preferences, email delivery, daily digest |

## Identity and workspace access

A `Users` row is global. A `WorkspaceMembership` row carries the per-workspace
role (`owner`, `admin`, `member`), status (`active`, `suspended`, pending
invite), reporting line (`reports_to_id`), team/project invite targets and
profile metadata.

Access helpers live in `workspaces/access.py`:

- `require_membership` — active membership required.
- `require_roles` / `require_manager` — owner/admin checks.
- `get_workspace_or_404` — consistent 404 for deleted workspaces.

SCP suspension is enforced in the access helpers and on public workspace entry
points: suspended tenants cannot use authenticated workspace routes, accept
invites or run guest check-in/check-out.

A pending membership is an invite. It carries email, token, expiry, invited
name, job title, team, manager and optional project. Accepting the invite
(`/workspace/accept-invite/{token}/` after login, or the public
`/workspace/accept-invite-public/{token}/`) links/creates the user, flips the
status to active and creates the team/project memberships.

While `RESTRICT_SINGLE_WORKSPACE` is enabled (the default) a user may belong
to only one non-deleted organization. Workspace creation, invite sending and
invite acceptance all reject a second organization with `409`. Active and
suspended memberships count; removed memberships, pending invites and
soft-deleted workspaces do not. Set the flag to `false` to restore
multi-organization membership.

## Reporting lines and approvals

`reports_to_id` lives on membership so a person can have different managers
in different workspaces. Cycles and self-management are rejected.

Approval resolution:

- **Project tasks:** `Project.approval_policy` (`pm`, `pm_alt`, `any`).
- **Non-project tasks:** the assignee's line manager, when configured.
- **Fallback:** legacy team-lead (for team tasks) and assigner routing keeps
  older workspaces working until reporting lines are populated.
- An assignee is never their own approver. Project changes, manager changes
  and team-lead changes recalculate open-task approvers.

## Task workflow

```
not_started → in_progress → submitted → returned → in_progress
                                  ↘ completed
```

- Any transition appends a `TaskActivity` row.
- Submit supports resubmission and increments `submission_round`.
- Return requires a quality note; changing the target date also requires a
  reason and records a `due_date_changed` activity.
- Approve awards gamification points when enabled and writes a `PointEntry`.
- Personal tasks (no approver) complete directly by the assignee.
- Confidential tasks are visible to the assignee, assigner, approvers,
  explicit viewers and watchers; access can be requested and approved.

Recurring tasks use `RecurringTaskRule`. The current occurrence is created
immediately and future occurrences are generated idempotently by the
`generate_recurring_tasks` beat task.

## Routines

A `Routine` is either a structured report (`kind=report`) or a recurring-task
template (`kind=task`).

- Report routines have ordered `RoutineField` definitions and `RoutineLog`
  submissions.
- `occurrence_date` + user is unique, so submitting twice updates the same
  report unless it has already been reviewed.
- Late/catch-up rules are evaluated against the workspace timezone and the
  routine's `opens_before_minutes`, `late_policy` and `late_days`.
- Manager review writes reviewer/timestamp/note and notifies the author.
- Recurring task routines generate tasks for every applicable member.

## Reporting and activity

`ReportService` builds scoped metrics (`me`, `team`, `org`, `person`) for a
named period and a previous comparison period. It queries only tasks visible
to the caller and aggregates completed/on-time/FTR/rounds/overdue/saved-time/
recurring-compliance figures.

The same service exposes a cross-task activity feed (`TaskActivity`) filtered
by project, team, actor, kind and date. It powers My Day pulse, project/team
activity, profile activity and the dashboard.

## Chat

Chat lives in `tms/chat/` and is deliberately separate from teams and projects:

- `ChatGroup` is a chat space with `owner`/`member` membership; it optionally
  links to a project. A group starts with a `General` channel.
- Every conversation is a `ChatConversation` row: `channel`, `dm`, `group` or
  `task`. Channels point at their group; DMs carry a unique sorted
  `direct_key`; task conversations are unique per task.
- Standard channels inherit group membership. DMs, group chats, task
  conversations and private channels use `ChatConversationMember`.
- `ChatConversationState` stores `last_read_at`, `last_read_message`,
  `is_muted`, `mentions_only` and `is_pinned` per user. Unread and mention
  counts are derived from main-feed messages after the read position.
- Messages support text, system messages, task cards, birthday cards,
  attachments, quotes, threads, emoji reactions, pinning and mentions.
  `#TK-123` text is parsed into `linked_task_ids`.
- Task conversations are created on demand and backfilled from `TaskActivity`;
  `chat/events.py` appends future start/submit/return/approve/complete events
  without creating conversations for tasks nobody discusses.
- Chat attachments are signed B2 URLs and are renewed by `renew-file-urls`.
- Workspace managers can see all groups/channels, but only accrue unread where
  they are actual members. DMs and task conversations remain member-only.

## Guest check-in

Guest attendance lives in `tms/guest_checkin/` and is deliberately separate
from teams and projects:

- `GuestEntryPoint` is one permanent printed QR code. It carries an 8-character
  random slug and optionally points at a `GuestLocation`; regeneration marks
  the old row inactive and links it to its replacement.
- `GuestCheckInSettings` holds branding, reason list, host rules, collection
  toggles, auto-close time, timezone and retention.
- `GuestVisit` is one check-in. The cookie token is stored only as a SHA-256
  hash; the four-character check-out code is unique among open visits at the
  entry point. `party_size` keeps group counts accurate for fire roll-call.
- `sp_visit` is an HttpOnly/SameSite=Lax cookie containing an
  `entry_point_id → token` map, so one phone can hold visits at several
  locations. `sp_device` only powers code-attempt rate limits.
- The public flow (`scan`, `check-in`, `check-out`, recovery links and host
  search) never lists visitors and only shows the caller's own first name.
- Admins get the visitor log, force check-out/void/flag/delete, CSV/XLSX
  exports, In Building Now and an SSE sync stream. Owners/admins have full
  access; other members need the `security` or `reception` role on their
  workspace membership.
- Every privileged action writes to `GuestAuditLog`.

## Visitors

Visitors lives in `tms/visitors/` and is the pass-based flow that runs
alongside the legacy guest check-in module:

- `VisitorDesk` is a place guests go (finance, a house, a gate). Active desk
  codes are unique per workspace and a partial unique index enforces that
  among non-deleted rows. `VisitorDeskReceiver` lists the members who answer
  for a desk.
- `VisitPass` carries a globally unique `{DESK}-{4}` code, the host,
  creator, valid date, lifecycle status and the derived hold state. A pass
  whose `hold_until` has passed is returned as `hold_over`; the stored status
  stays `on_hold`.
- `VisitPassEvent` is the immutable event stream. Actions are authorised by
  the pass host, its desk receivers or the legacy guest-check-in roles
  (`security`/`reception` plus owners/admins) acting as the front desk.
- Desks are seeded lazily on the first list with workspace-type defaults:
  business, estate, church, family, event, club-type and individual.
- `visitors.tasks.housekeep_visitors` expires unresolved passes once their
  valid day ends and sends one hold-over notification per hold.
  `visitors.tasks.auto_close_visitors` closes inside passes whose arrival is
  before the legacy `auto_close_time`/day boundary (23:59 fallback).
- `VisitorLegacySync` keeps a per-workspace watermark. While
  `VISITORS_LEGACY_SYNC_ENABLED` is true, the sync mirrors new legacy
  `GuestVisit` rows, reuses their UUIDs and closes mirrored passes when the
  old flow checks out/voids/deletes them. It never reopens a pass closed in
  the new flow and sends no notifications.
- The public pass routes return only the guest-safe fields and are
  rate-limited per IP and pass code.

## Attendance

Attendance lives in `tms/attendance/` and is separate from guest check-in
(visitors) and project time:

- `AttendanceSettings` is one row per workspace, created lazily on first read
  with schedule/lateness flags based on the workspace kind/subtype. Public
  holidays for the current and next year are seeded with it; the daily
  `attendance.tasks.refresh_public_holidays` beat task tops up later years.
- Locations, networks, holidays and exemptions are normalized child tables.
  The settings PUT replaces the whole document: incoming ids are upserted,
  unknown ids are created, removed rows are soft-deleted and exemptions are
  reconciled.
- `AttendanceRecord` is unique per `(workspace, user, date)`, where `date` is
  workspace-local. In/out statuses, minutes late and worked minutes are
  computed by `attendance/rules.py`.
- The server verifies clock-ins: haversine for point fences, ray casting for
  polygons, a 75 m accuracy slack, and client public IP matching against
  network IP/CIDR entries. `clock_in_ip`, coordinates and accuracy are kept
  for audit and never returned.
- Visibility is self + direct reports for members, everyone active for
  owners/admins. Stats, history and the team board share that helper.
- Stats and the board clamp to when tracking began (settings creation and
  the member's join date), so a mid-period rollout is not reported as a run
  of absences.
- A late clock-in can raise `attendance_late_limit` once per user per period;
  `attendance_late_flags` is the idempotency guard.
- Weather and place search are proxied by `attendance/providers.py` with
  configurable URLs, bounded TTL caches, a real geocoder User-Agent and
  graceful degradation. Absences and overtime are derived on read.

## Files and signed URLs

All uploads go through `shared/utils/file_storage.py` (Backblaze B2) and
return a signed URL plus object key. Keys and expiry are persisted so the
`renew-file-urls` beat task can re-sign them before expiry:

- `Users.photo_key` / `photo_expires_at`
- `Workspace.logo_key` / `logo_expires_at`
- `WorkspaceFile.file_key` / `expires_at`
- `TaskAttachment.file_key` / `expires_at`
- `ChatAttachment.file_key` / `expires_at`
- Routine log `files` JSON entries (`file_key` / `expires_at`)

These are native B2 download URLs
(`https://f00x.backblazeb2.com/file/<bucket>/<key>?Authorization=<token>`),
not S3 pre-signed URLs. File-bearing API responses expose `file_url` for
inline previews and a separately signed `download_url` whose token is minted
with `b2ContentDisposition=attachment; filename="..."` so the browser saves
the original filename. Both URLs share the same expiry; see
`docs/download_integration.md`.

Cross-origin `fetch()` requests to B2 require a CORS rule on the bucket
(`b2_download_file_by_name`). The API's `CORS_ALLOW_ORIGINS` setting does not
apply to B2. Direct download links and `<img>` previews work without a CORS
rule.

`WorkspaceFile` rows are standalone uploads created before a task exists
(inline images in descriptions). They are bound to tasks through
`TaskAttachment.workspace_file`, or claimed when a recurring-rule
description uses them; unclaimed rows are purged by the daily
`purge-orphan-uploads` beat task. The public `/file/view/{file_id}/` endpoint
redirects to a freshly signed URL so description markdown can keep a stable
link.

The file library is a read/upload view over task attachments; files remain
task-owned. Chat attachments belong to their message and are exposed through
`/chat/list-conversation-files/{conversation_id}/`.

## Notifications

`notifications.services.notify` is the single write path. It:

1. suppresses self-notifications;
2. checks `NotificationPreference` for the event/channel;
3. writes the in-app `Notification` when enabled;
4. enqueues the email Celery task when email is enabled.

`NotificationPreference` defaults to in-app-on, email-off. Daily digests run
hourly and match each user's `digest_time` hour in the workspace timezone.
Mentions, invite accepted, access requests, routine events, task lifecycle
events and chat events all emit notifications.

Chat notifications use two kinds: `chat_mention` (the existing `mention`
preference) and `chat_message` (the `chat` preference). Standard-channel
messages only notify `@mentions`; DMs, group chats and task conversations also
notify other participants unless their conversation is muted or mentions-only.
Notifications carry `conversation_id` for deep links.

## Background jobs

Celery configuration is `celery_config.py`; the beat schedule includes:

- `renew-file-urls` — every six hours;
- `purge-orphan-uploads` — daily at 03:30 UTC, deleting unclaimed inline
  uploads after `ORPHAN_UPLOAD_TTL_HOURS`;
- `generate-recurring-tasks` — hourly at :05 (idempotent per workspace-local date);
- `send-daily-digests` — hourly;
- `send-routine-reminders` — hourly, at each routine's due hour in the
  workspace timezone;
- `auto-close-guest-visits` — every 15 minutes, at each entry point's local
  cut-off;
- `purge-guest-visits` — daily at 03:00 UTC, applying each workspace's
  retention period;
- `fire-note-reminders` — every minute, flipping due note reminders to fired;
- `purge-trashed-notes` — daily at 03:00 UTC, hard-deleting notes after their
  seven-day trash window;
- `send-birthday-reminders` — hourly, at each workspace's working-hours start,
  idempotent per workspace/recipient/celebrant/local date;
- `expire-scp-free-access` — daily at 00:15 UTC, clearing expired free-access
  grants and writing one system audit entry per tenant;
- `purge-scp-deleted-organizations` — daily at 03:30 UTC, hard-deleting
  organizations whose soft-delete retention window has passed;
- `housekeep-visitor-passes` — every minute, expiring unresolved visitor
  passes whose day has passed and notifying hold-overs once;
- `auto-close-visitor-passes` — every 15 minutes, closing inside visitor
  passes after their arrival day/cut-off;
- `sync-legacy-visitor-passes` — every 5 minutes while enabled, mirroring
  new/changed legacy guest check-ins into visit passes.

Async jobs use `run_async_task()` so Tortoise can be initialized inside a
worker or reused inside the web process.

## Testing and migrations

- Tests run in the dedicated `tms_test` database; `TESTING=1` reroutes
  the configured DSN and Celery dispatch is disabled.
- `clean_database` deletes children before parents; add new models there.
- Schema changes use aerich migrations (`make db-migrate`, `make db-upgrade`).
  The guest-checkin migration adds the partial unique index on open,
  non-deleted visit codes and the open-phone lookup index manually because
  Tortoise's model metadata cannot express partial indexes. The visitors
  migration does the same for active desk codes so a deleted desk's code can
  be reused, and adds a global unique constraint on visit-pass codes plus the
  `(workspace_id, updated_at)` index used by the legacy sync.
- Ruff (line length 79, double quotes, isort) is enforced in CI with pytest.
