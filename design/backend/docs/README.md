# TMS API Documentation

This folder documents all backend endpoints for frontend integration.

- Each `{package}_docs.md` corresponds to `tms/{package}/routers.py`
- Each endpoint lists URL, auth status, description, sample payload and
  sample response
- Response models are Pydantic schemas defined in
  `tms/{package}/schemas.py`

## Start here

- [mobile_integration.md](mobile_integration.md) — screen-by-screen mobile
  integration guide for `designs/tms-mobile-prototype.html`: endpoints,
  workspace-kind routing, polling, onboarding and known gaps.
- [architecture.md](architecture.md) — module map, request flows, approvals,
  routines, reports, files, notifications, background jobs and testing.
- [frontend_integration_v4.md](frontend_integration_v4.md) — screen-by-screen
  integration summary for the v4 UI (spaces, events, church, school, polls,
  project plans, sharing, presence, birthday calendar and studio documents).
- [people_onboarding_integration.md](people_onboarding_integration.md) —
  frontend guide for bulk CSV user invites, workspace signup links, pending
  signup requests and the admin approval screen.
- [chat_integration.md](chat_integration.md) — screen-by-screen frontend
  integration guide for the chat UI (endpoints, data and polling).
- [external_chat_integration.md](external_chat_integration.md) — people
  search, external chat requests, cross-workspace chats and external groups.
- [inline_image_upload_integration.md](inline_image_upload_integration.md) —
  pasted screenshots in task descriptions, standalone uploads, markdown URLs
  and file binding.
- [attendance_integration.md](attendance_integration.md) — screen-by-screen
  frontend guide for the attendance tabs, location picker, weather and
  lateness notifications.
- [visitors_changes_integration.md](visitors_changes_integration.md) —
  screen-by-screen guide for the pass-based Visitors flow, the public pass
  page, notifications and the legacy guest check-in cutover.
- [scp_changes_integration.md](scp_changes_integration.md) — workspace
  approval lifecycle, main-app lockout codes, SCP tenant statuses and filters,
  approval/decline actions, `organizations.approve` and the audit events.

## Packages

- [auth_docs.md](auth_docs.md) — signup, login, profile, social sign-in,
  verification codes, password reset, unsubscribe
- [workspaces_docs.md](workspaces_docs.md) — workspace CRUD, settings,
  members, roles, invites, public invite acceptance and signup links
- [teams_docs.md](teams_docs.md) — team CRUD, lead/member roles, lanes,
  members
- [projects_docs.md](projects_docs.md) — project CRUD, members, visibility,
  milestones, email invites
- [tasks_docs.md](tasks_docs.md) — task creation, recurring tasks, my tasks,
  approvals, workflow, comments, reactions, links, checklist, attachments,
  watchers, access requests, saved views
- [chat_docs.md](chat_docs.md) — chat groups, channels, DMs, group chats,
  task conversations, messages, threads, reactions, files, unread state and
  external chat requests
- [journal_docs.md](journal_docs.md) — private notes, pinning, archive,
  seven-day trash, reminders and reminder jobs
- [birthday_docs.md](birthday_docs.md) — birthday feeds, visibility, profile
  settings, birthday cards in chat and the daily reminder job
- [notifications_docs.md](notifications_docs.md) — in-app notifications,
  preferences, email delivery and daily digests
- [attendance_docs.md](attendance_docs.md) — workspace clock-in settings,
  geofence/Wi-Fi checks, clock-in/out, holidays, lateness alerts, stats,
  history, team board and weather/place proxies
- [visitor_docs.md](visitor_docs.md) — pass-based visitors: desks, host
  invitations, front desk, public pass page, hold-overs, background jobs and
  the legacy guest check-in sync
- [people_docs.md](people_docs.md) — directory, profiles, reporting lines,
  organogram, bulk invites, bulk CSV upload, signup requests,
  deactivation/handover
- [routines_docs.md](routines_docs.md) — recurring reports, routine logs,
  team status and recurring task generation
- [reports_docs.md](reports_docs.md) — dashboard metrics, activity feed,
  person reports, appraisal export
- [gamification_docs.md](gamification_docs.md) — points, streaks, badges and
  leaderboard
- [files_docs.md](files_docs.md) — workspace file library, project/team file
  views and uploads
- [scp_docs.md](scp_docs.md) — SCP admin control panel: operator auth,
  permissions, organizations, billing actions, plans, support tickets and the
  audit log
- [spaces_docs.md](spaces_docs.md) — workspace space hubs, family home and
  studio invoices/proposals
- [events_docs.md](events_docs.md) — event guests, vendors, seating, programme,
  public RSVP page and vendor brief
- [project_plans_docs.md](project_plans_docs.md) — project plan graph,
  templates and resource leave
- [polls_docs.md](polls_docs.md) — standalone and chat-linked polls
- [school_docs.md](school_docs.md) — family school diary
- [church_docs.md](church_docs.md) — church services, giving, units, prayers
  and first-timers
- [sharing_docs.md](sharing_docs.md) — project/task share links and
  collaborators

## Auth

- `Public` endpoints require no JWT (e.g., `/auth/signup/`, `/auth/login/`,
  `/workspace/get-invite-public/{token}/`,
  `/workspace/get-signup-public/{token}/`,
  `/workspace/signup-public/{token}/`, `/file/view/{file_id}/`,
  `/scp/login/`, `/scp/get-access-link/{token}/`,
  `/scp/set-password/{token}/`, `/public/event/{token}/`,
  `/public/rsvp/{token}/`, `/public/vendor/{token}/`,
  `/visitor/public-pass/{code}/`, `/visitor/public-pass-action/{code}/`)
- `Authenticated` endpoints require `Authorization: Bearer <JWT>`
  (see `/auth/login/` and `/scp/login/`)

## Pagination

Every list endpoint returns:

```json
{
  "items": [],
  "total": 0,
  "page": 1,
  "page_size": 20,
  "total_pages": 0
}
```

Exceptions are intentionally non-paginated collections (e.g. organogram
nodes, team lanes, saved views, activity feed selections, routine cards,
routine summaries, journal due reminders, birthday today/upcoming and
calendar entries, event guests/vendors/programme, church data, school items,
presence statuses, share collaborators, project plans/templates/leave,
attendance board/search, visitor desks/passes, SCP plans and SCP activity).

## Content types

Most bodies are JSON. Exceptions:

| Endpoint | Content type |
| --- | --- |
| `POST /auth/form-login/` | `application/x-www-form-urlencoded` (`username`, `password`) |
| `PUT /auth/update-profile/` | `multipart/form-data` (`first_name`, `last_name`, `job_title`, `department`, `phone`, `theme`, `language`, `digest_enabled`, `digest_time`, `photo`) |
| `POST /workspace/set-logo/{workspace_id}/` | `multipart/form-data` (`file`) |
| `POST /people/bulk-upload/{workspace_id}/` | `multipart/form-data` (`file`) |
| `GET /people/get-bulk-upload-template/{workspace_id}/` | `text/csv` response |
| `POST /task/upload-attachment/{task_id}/` | `multipart/form-data` (`file`) |
| `POST /task/create-task-with-files/{workspace_id}/` | `multipart/form-data` (`payload`, `files`) |
| `POST /chat/send-message/{conversation_id}/` | `multipart/form-data` (`body`, `attachments`, `mentioned_user_ids`, `reply_to_id`, `thread_root_id`, `also_send_to_channel`, `task_id`) |
| `POST /file/upload-file/{workspace_id}/` | `multipart/form-data` (`task_id`, `file`) |
| `POST /file/upload/{workspace_id}/` | `multipart/form-data` (`file`) |
| `POST /routine/upload-attachment/{routine_id}/` | `multipart/form-data` (`file`) |
| `GET /scp/export-audit-logs/` | `text/csv` response |

## Base URL

- Local: `http://localhost:8081`
- Docs: `http://localhost:8081/docs` (OpenAPI, when `ENABLE_DOCS=true`)
