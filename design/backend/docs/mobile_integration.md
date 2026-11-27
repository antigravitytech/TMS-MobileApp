# Mobile App Integration Guide

Reference design: `designs/tms-mobile-prototype.html`

Audience: the mobile engineer building the Sabi Pipu TMS app.

This guide maps every screen in the mobile prototype to the live API: which
endpoints to call, which fields drive the UI, and how to keep state fresh. It
is the mobile equivalent of [`frontend_integration_v4.md`](frontend_integration_v4.md)
and [`chat_integration.md`](chat_integration.md). Full request/response
schemas stay in the per-package documents linked throughout this guide.

The prototype contains 26 primary routes plus workspace-kind variants
(family/individual/church/alumni/estate/event/committee/club). All routes below
are under the API base URL and require `Authorization: Bearer <JWT>` unless
marked **Public**.

**Base URL:** `http://localhost:8081` locally; use the deployed API elsewhere.
OpenAPI is available at `/docs` when `ENABLE_DOCS=true`.

**Trailing slashes matter.** Every path below is written exactly as the router
expects. Do not strip the trailing `/`.

---

## 1. API basics

### Auth

- Login returns `{user, access_token, token_type}`. Store the token in the
  platform keychain/keystore.
- There is no refresh-token endpoint. On `401`, clear the session and return
  to Sign in.
- `remember_me: true` issues a 30-day token instead of the default lifetime.
- `/auth/check-auth/` validates a stored token and returns the current user.
- Public endpoints (invite pages, signup link, public event/RSVP/vendor,
  visitor public pass, `/file/view/`) must not send the token.

### Content types

Most bodies are JSON. Multipart endpoints:

| Endpoint | Fields |
| --- | --- |
| `PUT /auth/update-profile/` | profile fields + `photo` file |
| `POST /file/upload/{workspace_id}/` | `file` (inline image; 10 MB default) |
| `POST /file/upload-file/{workspace_id}/` | `task_id`, `file` |
| `POST /task/create-task-with-files/{workspace_id}/` | `payload` JSON + `files[]` |
| `POST /task/upload-attachment/{task_id}/` | `file` |
| `POST /chat/send-message/{conversation_id}/` | `body`, `attachments[]`, `mentioned_user_ids[]`, `reply_to_id`, `thread_root_id`, `also_send_to_channel`, `task_id` |
| `POST /routine/upload-attachment/{routine_id}/` | `file` |
| `POST /people/bulk-upload/{workspace_id}/` | `file` (web admin only) |
| `POST /workspace/set-logo/{workspace_id}/` | `file` (web admin only) |

### Pagination

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

Documented exceptions are plain arrays: attendance board/search, routine
summaries, space hub/family home, church, school items, event guests/vendors/
programme, visitor passes/desks, birthday today/upcoming, presence statuses,
gamification leaderboard, note due-reminders and project plans/leave.

### Dates, time and money

- Dates (`due_date`, `valid_on`, `date`) are `YYYY-MM-DD`; do not convert them
  to UTC.
- Timestamps are ISO 8601 UTC. Render in the workspace timezone returned by
  `GET /workspace/get-workspace/{workspace_id}/`.
- Money values are decimal numbers or decimal strings depending on the
  endpoint. Parse with a decimal type, never binary float.
- Birthday `day` is `MM-DD` and never includes a year.

### File URLs

- `file_url` is a signed URL for inline previews. It expires.
- `download_url` is a separately signed URL that forces the original filename.
- If a preview or download fails with 401/403/404, refetch the containing
  message/task/file row; the URL is re-signed server-side.
- Inline uploads (`/file/upload/`) return a stable `/file/view/{file_id}/` URL
  that can live permanently in task descriptions.
- Task/library uploads require a task id. The design's “attach it to a task”
  rule is enforced by the API.

### Errors

| Status | Mobile handling |
| --- | --- |
| `401` | Clear the session, go to Sign in. |
| `403` | Show `detail`. Check `code` first for workspace approval. |
| `404` | Wrong/removed resource, or the feature is unavailable for this workspace kind. |
| `409` | Invalid state change, duplicate workspace/member, task transition conflict, or single-organization restriction. Refresh before retrying. |
| `422` | Validation error. FastAPI returns a list in `detail`; show the first message. |
| `429` | Honor `Retry-After`; auth and public invite endpoints are rate-limited. |

Workspace approval errors include a machine-readable `code`:

```json
{
  "detail": "Acme Group is waiting for approval. We'll email you as soon as it's approved.",
  "code": "workspace_pending_approval"
}
```

`workspace_rejected` means the SCP operator declined the workspace; show
`detail` and offer “contact support”.

### Feature availability

Do not call endpoints that do not apply to the current workspace kind.

| Feature | business | individual | family | specials |
| --- | --- | --- | --- | --- |
| `/home/get-space/`, `/home/space-action/` | No | Yes | Yes | Yes |
| `/home/get-family/`, `/home/family-action/` | No | No | Yes | No |
| `/school/*` | No | No | Yes | No |
| `/church/*` | No | No | No | church only |
| `/event/*` | No | No | No | event only |
| Studio invoices/proposals | No | Yes | No | No |
| `/visitor/*` | Yes | Yes | Yes | Yes |
| `/attendance/*` | Yes, if enabled | Yes, if enabled | Yes, if enabled | Yes, if enabled |
| `/task/*`, `/chat/*`, `/note/*`, `/birthday/*`, `/file/*` | Yes | Yes | Yes | Yes |
| `/project/*`, `/team/*` | Yes | Yes | Yes | Yes |

`GET /home/get-space/{workspace_id}/` returns `404` on a business workspace.

---

## 2. App shell and navigation

### Boot sequence

```
Splash
  ├─ stored JWT → GET /auth/check-auth/
  │     ├─ 200 → GET /workspace/list-workspaces/
  │     └─ 401 → Welcome / Sign in
  └─ no token → Welcome / Sign in
        → GET /workspace/list-workspaces/
        → choose last workspace, or the first approved one
        ├─ all pending  → approval waiting screen (poll list-workspaces)
        ├─ all rejected → declined screen
        └─ approved     → GET /people/my-context/{workspace_id}/
                        → GET /workspace/get-workspace/{workspace_id}/
                        → route by kind/subtype
```

`GET /workspace/list-workspaces/` returns pending and rejected workspaces so
the client can show approval screens. Each row carries `approval_status` and,
for rejected workspaces, `rejected_reason`.

`GET /people/my-context/{workspace_id}/` returns:

```json
{
  "workspace_id": "...",
  "workspace_name": "Acme Group",
  "workspace_kind": "business",
  "workspace_subtype": null,
  "role": "member",
  "is_guest": false,
  "is_manager": false,
  "is_line_manager": true,
  "is_project_manager": true,
  "is_team_lead": false,
  "is_assigner": true,
  "direct_report_count": 3,
  "review_count": 2,
  "open_task_count": 6
}
```

Use `workspace_kind` + `workspace_subtype` to select the home screen:

| Kind | Subtype | Home screen |
| --- | --- | --- |
| `business` | — | Home |
| `individual` | — | Individual home |
| `family` | — | Family home |
| `specials` | `church` | Church |
| `specials` | `alumni` | Alumni |
| `specials` | `estate` | Estate |
| `specials` | `event` | Wedding / event |
| `specials` | `committee` | Committee |
| `specials` | `club` | Club |

### Tab bar badges

| Tab | Badge source |
| --- | --- |
| Home | none |
| My tasks | `GET /task/get-summary/{workspace_id}/` → `my_tasks.open` |
| Chat | `GET /chat/get-unread-summary/{workspace_id}/` → `total_unread` |
| Approvals | `GET /task/get-summary/{workspace_id}/` → `review.waiting` |
| More | `GET /notification/get-unread-count/{workspace_id}/` → `unread` |

Refresh badges with the home summary every 60 seconds while the app is
foregrounded. Do not poll in the background.

### Pending approval

Signup and `POST /workspace/create-workspace/` create the tenant with
`approval_status: "pending"`. Every workspace-scoped endpoint then answers
`403` with `code: "workspace_pending_approval"` until an SCP operator
approves it.

The design has no waiting screen; add one after Building:

1. Show workspace name and “We're setting things up”.
2. Poll `GET /workspace/list-workspaces/` every 15–30 seconds. Do not poll
   `GET /workspace/get-workspace/{workspace_id}/` while pending; it answers
   `403` like every other workspace-scoped route.
3. On `approved`, call the normal boot sequence and open Home.
4. On `rejected`, show `rejected_reason`.

Do not retry workspace-scoped requests while pending; they will all fail.
If the app is restarted and the token is gone, `/auth/login/` also answers
`403` with the same `code` while every workspace is pending. Show the waiting
screen from that response instead of treating it as a bad password.

### Workspace switching

`GET /workspace/list-workspaces/` powers the More sheet. Include the kind and
`approval_status`; fetch the caller's role with
`GET /workspace/my-role/{workspace_id}/` (or from `my-context`). When
switching workspaces:

- store the new workspace id,
- clear workspace-scoped caches (tasks, chat, notes, attendance, files),
- refetch `my-context` and the home screen.

`RESTRICT_SINGLE_WORKSPACE=true` is the default. In that mode a user can belong
to only one organization; creating/inviting into another workspace returns
`409`. The mobile UI should still render the switcher, but handle the `409`
with a clear message.

---

## 3. Onboarding and workspace setup

### Screens

| Screen | Purpose |
| --- | --- |
| Splash | Brand animation; skip to Welcome |
| Welcome (`Main`) | Sign in or create an account |
| Setup | Choose Business / Individual & Family / Specials, enter workspace name |
| SetupKind | Individual or Family |
| SetupWork | Individual job, client toggle, workspace name |
| SetupFamily | Family name, members and roles |
| SetupSpecials | Special kind, name, event/milestone and date |
| ProfileSetup | Name, photo, job, birthday, notification nudges |
| Building | “Setting up roles/templates/home” animation + invite |
| SignIn | Email/password, social, forgot password |

### Signup

`POST /auth/signup/` creates the user and the first workspace in one call.
This is the preferred path for a new account.

```json
{
  "first_name": "Chioma",
  "last_name": "Okafor",
  "workspace_name": "Acme Group",
  "email": "chioma@acmegroup.com",
  "password": "sup3rs3cret!",
  "phone": "+234 803 555 0142",
  "workspace_type": "business",
  "workspace_subtype": null,
  "workspace_setup": null,
  "industry": "Technology",
  "timezone": "Africa/Lagos"
}
```

`workspace_type` is `business`, `individual`, `family` or `specials`.
`workspace_subtype` is required for `specials` and is one of `church`,
`alumni`, `estate`, `event`, `committee`, `club`.

`workspace_setup` is the wizard payload:

```json
{
  "crest": "https://...",
  "members": [
    {"name": "Funmi", "type": "co_head"},
    {"name": "Tobi", "type": "child"},
    {"name": "Kwame", "type": "driver"}
  ],
  "event_name": "Harvest thanksgiving",
  "event_date": "2026-11-29",
  "job": "Designer",
  "has_clients": true,
  "team_size": "1-5"
}
```

`members[].type` is `co_head`, `child`, `relative`, `domestic_staff`,
`security` or `driver`. **Setup members are labels, not user accounts.** They
do not receive email, cannot log in and cannot be task assignees until invited
as real workspace members.

If the account already exists and the user is adding a workspace, call
`POST /workspace/create-workspace/` with the same `kind`,
`subtype` and `setup`. It also creates the workspace `pending`.

If the user was invited, do not create a workspace:

- new account: `GET /workspace/get-invite-public/{token}/` (public) then
  `POST /workspace/accept-invite-public/{token}/` with first name, last name,
  password, phone and job title;
- existing session: `POST /workspace/accept-invite/{token}/`;
- pending invites: `GET /workspace/my-invites/`.

Public signup link (the URL created from Building):

- `GET /workspace/get-signup-public/{token}/` (Public) returns the workspace
  name/logo and `requires_approval`.
- `POST /workspace/signup-public/{token}/` (Public) creates an access request
  with first name, last name, email, password, phone and job title. It returns
  `{message}`; the membership stays pending.
- An owner/admin approves or rejects it with
  `POST /workspace/approve-signup/{workspace_id}/{membership_id}/` or
  `POST /workspace/reject-signup/{workspace_id}/{membership_id}/`. The person
  must have verified their email before approval.

### Sign in

`POST /auth/login/`:

```json
{
  "email": "chioma@acmegroup.com",
  "password": "sup3rs3cret!",
  "remember_me": true
}
```

Social sign-in:

1. `GET /auth/oauth/{provider}/start/` (`google` or `microsoft`).
2. Open `authorization_url` in a secure browser session.
3. Handle the redirect URI and `POST /auth/oauth/{provider}/callback/` with
   `code`, `state` and `redirect_uri`.

The callback returns the same `AuthResponse`. New OAuth users get a personal
workspace, also `pending`.

Forgot password:

- `POST /auth/request-password-reset/` with `{email}`.
- `POST /auth/confirm-password-reset/` with `{token, new_password}`.

“Try a demo / sign in as anyone” has no backend endpoint. Remove it or point it
at seeded development accounts.

### Profile setup

- `PATCH /auth/update-profile-json/` for text fields, theme, language and
  `date_of_birth`.
- `PUT /auth/update-profile/` (multipart) when the user picks a photo.
- `PUT /birthday/set-my-birthday/` with `{date_of_birth, visibility}` where
  visibility is `workspace` or `private`.
- `PUT /notification/update-preferences/{workspace_id}/` for the “Stay in the
  loop” toggles (`events[]`, `digest_enabled`, `digest_time`).

The design's “roles I do” multi-select has no dedicated backend field. Send the
closest `job_title` and keep the selection local, or defer it.

### Building screen

The three progress steps are client animation. Real work:

1. Signup/create-workspace (already done). The tenant is `pending`.
2. The Building animation runs client-side. While pending, **every
   workspace-scoped route returns `403`**, including `get-space`, invites and
   the signup link. Do not call them yet.
3. Poll `GET /workspace/list-workspaces/` until `approval_status` becomes
   `approved`. Then:
   - for non-business workspaces, call `GET /home/get-space/{workspace_id}/`
     once to seed the default modules;
   - load the invite options:
     - email invite: `POST /workspace/invite-member/{workspace_id}/`
       `{email, role}`;
     - signup link: `GET /workspace/get-signup-link/{workspace_id}/`, enable
       with `PUT /workspace/update-signup-settings/{workspace_id}/`
       `{enabled: true}`, rotate with
       `POST /workspace/regenerate-signup-link/{workspace_id}/`.
4. QR code and phone-contact pickers are client-side. Generate the QR from
   `signup_url`; do not look for a QR endpoint.
5. “Open my space” routes by workspace kind after approval.

While pending, show the invite options disabled with “Available after
approval” rather than firing requests that will fail. The stable workspace
signup URL is returned as `signup_url`; share that, not a locally assembled
path.

### Email verification

`POST /auth/signup/` returns a token but does not verify the email. Show a
non-blocking banner until `user.is_verified` is true:

- `POST /auth/resend-verification/` with `{email}`;
- `POST /auth/verify-email/` with `{token}` or `{email, code}`.

Approval of a public signup request requires a verified email. Workspace
membership otherwise works while unverified.

---

## 4. Business Home

### Calls

Load in parallel on first paint and on pull-to-refresh:

| Section | Endpoint |
| --- | --- |
| Greeting / workspace | `GET /workspace/get-workspace/{workspace_id}/`, `GET /people/my-context/{workspace_id}/` |
| Due / overdue / review counts | `GET /task/get-summary/{workspace_id}/` |
| Birthday strip | `GET /birthday/get-feed/{workspace_id}/` |
| Daily report card | `GET /routine/list-my-routines/{workspace_id}/` |
| Today’s tasks | `GET /task/list-tasks/{workspace_id}/?scope=mine&due=today&sort_by=due&sort_dir=asc` |
| Awaiting my review | `GET /task/list-approvals/{workspace_id}/?sort=oldest` |
| Team today | `GET /routine/list-summaries/{workspace_id}/?days=1` |
| Coming up (7 days) | `GET /task/list-tasks/{workspace_id}/?scope=mine&due=week&sort_by=due&sort_dir=asc` |
| Badges | `GET /chat/get-unread-summary/{workspace_id}/`, `GET /notification/get-unread-count/{workspace_id}/` |

### Mapping

- `task/get-summary` gives `my_tasks.due_today`, `my_tasks.overdue`,
  `my_tasks.returned_to_me`, `review.waiting`, `review.avg_review_hours`,
  `review.approved_this_week`, `review.returned_this_week` and tab counts.
- Birthday card: show `today[]`; hide the user themselves (`mine_is_today` is
  for “greet yourself”). `POST /birthday/send-wish/{user_id}/` sends the card.
- Daily report card: use `current_occurrence.state` and `can_log`; open
  `GET /routine/get-routine/{routine_id}/` for fields, then
  `POST /routine/submit-log/{routine_id}/`. Hide the card when there is no
  report routine.
- Team today: group `list-summaries` by `user_id`; `submitted` is “sent”,
  non-null `blockers` is “blocker raised”.
- Coming up: use task `due_date`, `title`, `reference` and `assignee`.
- Review queue: a swipe right/left can call
  `POST /task/approve-task/{task_id}/` /
  `POST /task/return-task/{task_id}/`. Refresh `get-summary` after each action.
- Quick create actions map to New task, Reports, Attendance, Journal, Visitors
  and Birthdays.

Refresh: 60 seconds on Home, and immediately after any action.

---

## 5. Tasks, task detail and approvals

### Task list

`GET /task/list-tasks/{workspace_id}/`

| UI tab | `scope` |
| --- | --- |
| My tasks | `mine` |
| My requests | `requests` |
| Team | `team` |
| All | `all` |

Filters:

| UI | Query |
| --- | --- |
| Status chips | `status=not_started|in_progress|submitted|returned|completed` (repeatable) |
| Overdue | `due=overdue` |
| Due today | `due=today` |
| This week | `due=week` |
| Priority | `priority=low|medium|high|critical` (repeatable) |
| Project | `project_id` (map the project name to its id) |
| Team | `team_id` |
| Sort | `sort_by=due|priority|status|title|created|updated|last_activity` |
| Direction | `sort_dir=asc|desc` |
| Search | `search` |
| Page | `page`, `page_size` |

`scope=team` includes tasks assigned to anyone sharing an active team with
the caller. The API does not expose “sort by project”; if the design's project
sort is required, sort the current page client-side.

Task card fields: `reference`, `title`, `status`, `priority`, `project`,
`team`, `assignee`, `due_date`, `original_due_date`, `is_overdue`,
`overdue_days`, `submission_round`, `return_count`, `comment_count`,
`attachment_count`, `checklist_done/total` and `permissions`.

### Task detail

`GET /task/get-task/{task_id}/` returns `TaskDetailRead`:

- base task fields above,
- `description`, `visible_to`, `watchers`,
- `checklist[]`,
- `recent_activity[]`,
- `links[]`,
- `access_requests[]`,
- `latest_submission_note`, `latest_return_note`, `latest_return_by`,
  `approved_by`.

Supporting calls:

| UI | Endpoint |
| --- | --- |
| Timeline | `GET /task/list-activity/{task_id}/` |
| Comments | `GET /task/list-comments/{task_id}/`, `POST /task/add-comment/{task_id}/`, `DELETE /task/delete-comment/{task_id}/{comment_id}/` |
| Comment like | `POST /task/toggle-comment-like/{task_id}/{comment_id}/` |
| Checklist | `POST /task/add-checklist-item/{task_id}/`, `PUT /task/update-checklist-item/{task_id}/{item_id}/`, `DELETE /task/delete-checklist-item/{task_id}/{item_id}/` |
| Attachments | `GET /task/list-attachments/{task_id}/`, `POST /task/upload-attachment/{task_id}/`, `DELETE /task/delete-attachment/{task_id}/{attachment_id}/` |
| Watchers | `GET /task/list-watchers/{task_id}/`, `POST /task/add-watcher/{task_id}/`, `DELETE /task/remove-watcher/{task_id}/{user_id}/` |
| Links | `GET /task/list-links/{task_id}/`, `POST /task/add-link/{task_id}/`, `DELETE /task/remove-link/{task_id}/{link_id}/` |
| Task chat | `POST /chat/start-task-conversation/{task_id}/` |
| Confidential access | `POST /task/request-access/{task_id}/`, `GET /task/list-access-requests/{task_id}/`, `POST /task/review-access-request/{request_id}/` |

Original vs current target: `original_due_date` never changes; `due_date` is
the current target. “On original date” is simply equality.

### Workflow

| Button | Endpoint | Payload |
| --- | --- | --- |
| Start | `POST /task/start-task/{task_id}/` | none |
| Submit for review | `POST /task/submit-task/{task_id}/` | `{"note": "..."}` |
| Return | `POST /task/return-task/{task_id}/` | `{"note": "...", "due_date": null, "reason": null}` |
| Approve | `POST /task/approve-task/{task_id}/` | `{"comment": "..."}` |
| Complete personal task | `POST /task/complete-task/{task_id}/` | none |
| Reopen | `POST /task/reopen-task/{task_id}/` | none |
| Change target | `POST /task/change-due-date/{task_id}/` | `{"due_date": "...", "reason": "..."}` |

Rules:

- submit increments `submission_round`;
- personal tasks have no approver and must use `complete-task`;
- return requires a note; a new due date also requires a reason;
- invalid transitions return `409`; refetch the task.

### New task

`POST /task/create-task/{workspace_id}/`:

```json
{
  "title": "Q4 hiring plan for Tech Team",
  "description": "Headcount, roles and timeline for Q4.",
  "type": "standalone",
  "project_id": null,
  "team_id": null,
  "milestone_id": null,
  "assignee_ids": ["44444444-4444-4444-8444-444444444444"],
  "priority": "high",
  "visibility": "public",
  "visible_to": [],
  "start_date": "2026-11-23",
  "due_date": "2026-11-27",
  "due_time": "17:00",
  "repeat_frequency": null,
  "repeat_weekday": null,
  "repeat_time": null,
  "file_ids": []
}
```

- `type`: `standalone`, `project`, `team` or `recurring`.
- Recurring tasks: set `type: "recurring"` and `repeat_frequency` to `daily`,
  `weekdays`, `weekly` or `monthly`; use `repeat_weekday` for weekly/monthly
  and `repeat_time` for the time of day.
- Confidential tasks: `visibility: "confidential"` plus `visible_to` for extra
  viewers.
- Files: call `POST /file/upload/{workspace_id}/` first, then pass returned
  `file_id`s in `file_ids`, or use
  `POST /task/create-task-with-files/{workspace_id}/` with a JSON `payload`
  part and `files` parts.
- Approver preview: `GET /task/resolve-approver/{workspace_id}/?assignee_id=...`
  tells the UI who will review.

### Approvals

- Queue: `GET /task/list-approvals/{workspace_id}/?sort=oldest|newest|round`
  plus optional `assignee_id`, `project_id`, `team_id`, `search`.
- Stats: `GET /task/get-summary/{workspace_id}/` → `review`.
- Approve/return one task at a time. There is no bulk approve endpoint.

### Search

The Search screen has no aggregate backend endpoint. Debounce the query
(250–300 ms) and fan out in parallel:

| Group | Endpoint |
| --- | --- |
| Tasks | `GET /task/list-tasks/{workspace_id}/?search={q}&page_size=5` |
| Projects | `GET /project/list-projects/{workspace_id}/?search={q}&page_size=5` |
| People | `GET /people/list-people/{workspace_id}/?search={q}&page_size=5` |
| Messages (optional) | `GET /chat/search-messages/{workspace_id}/?q={q}&page_size=5` |
| New chat people | `GET /chat/search-people/{workspace_id}/?q={q}` (min 2 chars, includes external) |

Quick actions (new task, log report, clock in, new note, invite guest, send
card) are local commands that route to the relevant screen. Recent searches are
client-side. Skip requests under 2 characters and cancel in-flight calls when
the query changes.

---

## 6. Chat

### Chat list

| Section | Endpoint |
| --- | --- |
| Conversations | `GET /chat/list-conversations/{workspace_id}/` |
| Filter chips | `filter=all|unread|mentions|tasks` |
| Search | `search` |
| External requests | `GET /chat/list-chat-requests/` |
| External conversations | `GET /chat/list-external-conversations/` |
| Unread badge | `GET /chat/get-unread-summary/{workspace_id}/` |
| Presence / “online now” | `GET /people/list-statuses/{workspace_id}/` |
| Start DM / new chat | `POST /chat/start-dm/{workspace_id}/` |
| New group | `POST /chat/create-conversation/{workspace_id}/` |
| People search | `GET /chat/search-people/{workspace_id}/?q=` (min 2 chars) |

Conversation rows include `kind`, `title`, `peer`, `group`, `task`, `is_external`,
`request_status`, `last_message`, `unread_count`, `mention_count`, `is_muted`,
`mentions_only` and `is_pinned`.

“Groups” in the design can mean:

- **Chat group trees** (workspace/team spaces with channels): `GET /chat/list-groups/{workspace_id}/`
  and `GET /chat/get-group/{group_id}/`.
- **Ad-hoc group chats**: `create-conversation` with `kind: "group"` and
  `member_ids`.

Use the former for channel navigation and the latter for the “New group”
composer.

### Chat request

An external DM starts as a request. The first message is hidden until the
recipient responds.

- `POST /chat/start-dm/{workspace_id}/` with `{user_id}`.
- Send the first message with `POST /chat/send-message/{conversation_id}/`.
- Recipient: `POST /chat/accept-chat-request/{conversation_id}/` or
  `POST /chat/decline-chat-request/{conversation_id}/`.

### Conversation

| UI | Endpoint |
| --- | --- |
| Header/detail | `GET /chat/get-conversation/{conversation_id}/` |
| Messages | `GET /chat/list-messages/{conversation_id}/?order=desc&page_size=...` |
| Send | `POST /chat/send-message/{conversation_id}/` (multipart) |
| Edit | `PATCH /chat/edit-message/{message_id}/` |
| Delete | `DELETE /chat/delete-message/{message_id}/` |
| React | `POST /chat/toggle-reaction/{message_id}/` `{emoji}` |
| Pin | `PATCH /chat/pin-message/{message_id}/` `{pinned}` |
| Pinned panel | `GET /chat/list-pinned-messages/{conversation_id}/` |
| Thread | `GET /chat/list-thread-replies/{message_id}/` |
| Files tab | `GET /chat/list-conversation-files/{conversation_id}/` |
| Linked tasks | `GET /chat/list-linked-tasks/{conversation_id}/` |
| Create task from chat | `POST /chat/create-task/{conversation_id}/` |
| Mark read | `POST /chat/mark-read/{conversation_id}/` |
| Mark unread | `POST /chat/mark-unread/{conversation_id}/` |
| Mute/pin conversation | `PUT /chat/update-conversation-state/{conversation_id}/` |
| Add/remove member | `POST /chat/add-conversation-member/{conversation_id}/`, `DELETE /chat/remove-conversation-member/{conversation_id}/{user_id}/` |

`list-messages` defaults to newest first (`order=desc`); reverse the page
client-side when rendering an oldest-to-newest feed. Voice notes are ordinary
audio attachments. Send them in the same multipart request with an empty
`body` if needed.

Message types are `text`, `system`, `task`, `birthday` and `poll`. Render:

- `task` from `message.task` (TaskBrief) and link to Task detail;
- `birthday` from `message.birthday` (celebrant, theme, sticker, `MM-DD`);
- `poll` from `message.poll`; vote through `/poll/vote-poll/{poll_id}/`.

`#TK-123` references are parsed into `linked_task_ids` for internal
conversations. External conversations reject task cards.

### Realtime

There is no WebSocket, typing indicator or message push. Poll:

- conversation list: 30 seconds while visible;
- open thread: 10 seconds;
- presence: 60 seconds.

Optimistically append the result of `send-message`, but do not auto-retry a
failed send without user action (there is no idempotency key).

---

## 7. Notifications

| UI | Endpoint |
| --- | --- |
| List | `GET /notification/list-notifications/{workspace_id}/` |
| Unread only | `unread_only=true` |
| Category tabs | `category=mentions|reviews|chat` |
| Kind filter | `kind=<notification kind>` |
| Badge | `GET /notification/get-unread-count/{workspace_id}/` |
| Mark one | `POST /notification/mark-read/{notification_id}/` |
| Mark all | `POST /notification/mark-all-read/{workspace_id}/` |
| Preferences | `GET /notification/get-preferences/{workspace_id}/`, `PUT /notification/update-preferences/{workspace_id}/` |

Deep links:

| Kind family | Open |
| --- | --- |
| `task_*`, `task_mention`, `task_access_*` | Task detail (`task_id`) |
| `routine_*` | Reports / routine log |
| `chat_*` | Conversation (`conversation_id`, `conversation_workspace_id`) |
| `birthday_today`, `birthday_calendar` | Birthdays |
| `attendance_late_limit` | Attendance |
| `guest_arrived`, `guest_hold_over` | Visitors |
| `school_item` | School |
| `invite_*` | More / invites |

External chat notifications may belong to a different workspace than the
notification row. Always use `conversation_workspace_id` when opening the
conversation.

There is no push/device-token endpoint yet. The app should poll the list and
count while foregrounded. Do not promise background push in v1.

---

## 8. Attendance

### Today

`GET /attendance/get-today/{workspace_id}/` returns everything the screen
needs: `status`, `record`, `expected`, `holiday`, `exempt`, `schedule`,
`checks`, `locations`, `next_holiday`, `enabled`.

Map:

| Field | UI |
| --- | --- |
| `enabled: false` | “Attendance is switched off in this workspace.” |
| `status` | Day-state copy/colour |
| `record.clock_in_at`, `clock_out_at`, `minutes_worked` | Timer and logged hours |
| `schedule.start / start_until / end` | “Arrive 9:00–9:30 · leave from 17:00” |
| `checks.location`, `checks.wifi`, `checks.require` | Explain why clock-in is blocked |
| `locations` | “Head office geofence”, weather fallback |
| `holiday`, `next_holiday` | Holiday banners |

Status labels: `early`, `on_time`, `late`, `absent`, `not_clocked_in`,
`holiday`, `off_day`, `exempt`, `upcoming`.

### Clock in/out

`POST /attendance/clock-in/{workspace_id}/` and
`POST /attendance/clock-out/{workspace_id}/`:

```json
{
  "lat": 6.4282,
  "lng": 3.4220,
  "accuracy_m": 18,
  "note": null
}
```

Flow:

1. Ask location permission with a short timeout.
2. If refused, send `lat: null, lng: null`; the server only rejects when a
   location check is active.
3. On 200 replace state with the returned `AttendanceToday`.
4. On 403 show `detail` verbatim (it contains the distance or Wi-Fi message).
5. On 409 refresh `get-today`.

The timer must come from `record.clock_in_at`, not a local stopwatch.

### Month / team

- `GET /attendance/get-stats/{workspace_id}/?period=month` for the “Your month”
  cards, usual arrival/leaving, minutes worked, late limit, streak and day
  strip. `period` is `week`, `month` or `quarter`.
- `GET /attendance/list-board/{workspace_id}/?date=YYYY-MM-DD` for the team
  board. Plain array.
- `GET /attendance/list-records/{workspace_id}/?date_from=&date_to=&status=&page=`
  for history. Paginated.
- `GET /attendance/get-weather/{workspace_id}/?lat=&lng=` is optional chrome;
  hide the card on 503.
- `GET /attendance/search-places/{workspace_id}/?q=` is the place picker.

Team board polling: 30 seconds while visible.

---

## 9. Reports and performance

### Daily reports

| UI | Endpoint |
| --- | --- |
| My routine cards | `GET /routine/list-my-routines/{workspace_id}/` |
| Form definition | `GET /routine/get-routine/{routine_id}/` |
| Submit/update | `POST /routine/submit-log/{routine_id}/` |
| Existing log | `GET /routine/get-log/{routine_id}/?occurrence_date=` |
| Team summaries | `GET /routine/list-summaries/{workspace_id}/?days=7` |
| Completion counts | `GET /routine/team-status/{workspace_id}/?occurrence_date=YYYY-MM-DD` |
| Admin grid | `GET /routine/logs-grid/{routine_id}/` |
| Evidence upload | `POST /routine/upload-attachment/{routine_id}/` |
| React to summary | `POST /routine/react-summary/{workspace_id}/{summary_id}/` |

Submit body:

```json
{
  "occurrence_date": "2026-11-23",
  "answers": {
    "bbbbbbbb-bbbb-4bbb-8bbb-bbbbbbbbbbbb": "Shortlisted 6 candidates."
  },
  "files": [
    {"name": "evidence.pdf", "url": "https://..."}
  ]
}
```

Build the form from `fields[]`, keyed by field id. `field_type` is `long`,
`short`, `number`, `choice` or `rating`. Use `current_occurrence` for the
Today card and `occurrences` for the week strip.

“Link to a project” is not a first-class routine field. Add a `choice`/`short`
field to the routine definition and store the project name/id in
`answers[field_id]`, or keep the link client-side. “I'm blocked” should reveal
a text field whose label contains `block`; `list-summaries` reads that field
into `blockers`.

Per-person “100% this month / 10-day streak” is not a single field. Derive it
from `list-summaries?days=30` (submitted count and consecutive days) or call
`GET /report/get-person/{workspace_id}/{user_id}/` for the selected person.

Routine logs do **not** award gamification points. The prototype's “+10
points” toast is illustrative; omit it or label it as pending.

### Performance

- `GET /report/get-overview/{workspace_id}/` with `scope=me|team|org`,
  `preset=Today|This Week|Last Week|This Month|Last Month|This Quarter|Custom`,
  optional `person_id`, `team_id`, `date_from`, `date_to`.
- `metrics[]` → KPI cards.
- `gauges[]` → thermometer.
- `weekly[]` → completed vs returned chart.
- `attention[]` → “Needs attention”.
- `people[]` → team table.
- `leaderboard[]` → podium.
- `GET /report/get-person/{workspace_id}/{user_id}/` → 90-day streak heatmap,
  badges, direct reports, completed tasks.
- `GET /gamification/get-profile/{workspace_id}/{user_id}/` → points, level,
  points to next level, streak, badges.
- `GET /gamification/leaderboard/{workspace_id}/?limit=` → ranked members.
- `GET /report/export-appraisal/{workspace_id}/?person_id=&preset=` returns a
  CSV attachment. Let the platform share sheet save/send it.

“Performance thermometer” = `saved_days` (average days early vs the original
target; negative is late). “Level/points” = gamification profile. “Best
streak” is not returned; derive the longest run from the heatmap if needed.

---

## 10. Projects, teams and files

### Projects

| UI | Endpoint |
| --- | --- |
| List | `GET /project/list-projects/{workspace_id}/?health=&team_id=&owner_id=&visibility=&search=&mine=` |
| Detail | `GET /project/get-project/{project_id}/` |
| Create | `POST /project/create-project/{workspace_id}/` |
| Update | `PUT /project/update-project/{project_id}/` |
| Delete | `DELETE /project/delete-project/{project_id}/` |
| Members | `GET /project/list-members/{project_id}/`, `POST /project/add-member/{project_id}/`, `DELETE /project/remove-member/{project_id}/{membership_id}/` |
| Milestones | `GET /project/list-milestones/{project_id}/`, `POST /project/create-milestone/{project_id}/`, `PUT /project/update-milestone/{project_id}/{milestone_id}/`, `DELETE /project/delete-milestone/{project_id}/{milestone_id}/` |
| Tasks tab | `GET /task/list-tasks/{workspace_id}/?project_id={project_id}` |
| Files tab | `GET /file/list-files/{workspace_id}/?project_id={project_id}` |
| Chat tab | `GET /chat/list-groups/{workspace_id}/` and find the group whose `project_id` matches; then list its channels |
| Activity | `GET /report/list-activity/{workspace_id}/?project_id={project_id}` |
| Sharing | `GET /share/get-access/{resource_type}/{resource_id}/`, `POST /share/update-access/{resource_type}/{resource_id}/` (`resource_type=project`) |

Project card fields: `health` (`on_track`, `at_risk`, `off_track`), `visibility`,
`owner`, `alternate_owner`, `target_date`, `next_milestone`, `stats.progress`,
`stats.on_time_rate`, `stats.first_time_right_rate`, `stats.overdue_tasks`.

“Tasks done %” = `stats.progress`; “Accepted %” = `stats.first_time_right_rate`
(or `on_time_rate` if the design means on-time delivery). “Forecast” is not a
backend field; derive it from open tasks/milestones or hide it.

Project sharing is the supported client-portal mechanism. Send one action per
request (`invite`, `set_client`, `set_level`, `remove`, `resend`, `set_link`)
and use `client_can` = `progress`, `timeline`, `files`, `invoices`, `comment`.

### Teams

- `GET /team/list-teams/{workspace_id}/` → cards with `lead`, `member_count`,
  `member_preview`, `stats.weekly_progress`, `completed_this_month`,
  `on_time_rate`, `first_time_right_rate`, `avg_rework_rounds`.
- `GET /team/get-team/{team_id}/` → members with `in_progress_tasks`.
- Create/update/member/lane endpoints as needed; team management is
  owner/admin (lanes are manager/lead).

### Files

- `GET /file/list-files/{workspace_id}/?project_id=&team_id=&task_id=&uploader_id=&kind=&search=`
- `GET /file/file-stats/{workspace_id}/`
- `GET /file/upload-policy/` for client-side size/type validation.
- `POST /file/upload-file/{workspace_id}/` requires `task_id`; show a task
  picker when the user taps “Add a file”.
- `POST /file/upload/{workspace_id}/` is for inline images that will be bound
  to a task later (or pasted into a description).
- `GET /file/view/{file_id}/` is public and stable for inline rendering.

The “Anyone” uploader filter maps to `uploader_id` from the people picker.

---

## 11. Journal, birthdays, visitors, profile and settings

### Journal

| UI | Endpoint |
| --- | --- |
| All notes | `GET /note/list-notes/{workspace_id}/?state=active` |
| Pinned | `pinned_only=true` |
| Reminders | `has_reminder=true` |
| Archive | `state=archived` |
| Trash | `state=trashed` |
| Summary counts | `GET /note/get-summary/{workspace_id}/` |
| Due reminders | `GET /note/list-due-reminders/{workspace_id}/` |
| Create | `POST /note/create-note/{workspace_id}/` |
| Get/update | `GET /note/get-note/{note_id}/`, `PATCH /note/update-note/{note_id}/` |
| Pin | `POST /note/pin-note/{note_id}/` |
| Archive | `POST /note/archive-note/{note_id}/` |
| Trash/restore/delete | `POST /note/trash-note/{note_id}/`, `POST /note/restore-note/{note_id}/`, `DELETE /note/delete-note/{note_id}/` |
| Reminder | `PUT /note/set-reminder/{note_id}/`, `DELETE /note/clear-reminder/{note_id}/`, `POST /note/dismiss-reminder/{note_id}/`, `POST /note/snooze-reminder/{note_id}/` |
| Empty trash | `POST /note/empty-trash/{workspace_id}/` |

Notes are private to the author; every single-note endpoint returns 404 for
someone else's note. Clear journal caches on sign-out/workspace switch.
The alarm type is `ring` or `voice`; the server only stores it, the app
schedules the local notification.

### Birthdays

| UI | Endpoint |
| --- | --- |
| Dashboard strip | `GET /birthday/get-feed/{workspace_id}/` |
| Today | `GET /birthday/list-today/{workspace_id}/` |
| Upcoming | `GET /birthday/list-upcoming/{workspace_id}/` |
| Full calendar | `GET /birthday/get-calendar/{workspace_id}/` |
| Send card | `POST /birthday/send-wish/{user_id}/` |
| My birthday | `GET /birthday/get-my-birthday/`, `PUT /birthday/set-my-birthday/` |
| Personal entry | `POST /birthday/save-entry/{workspace_id}/`, `DELETE /birthday/delete-entry/{entry_id}/`, `POST /birthday/celebrate-entry/{entry_id}/` |

`get-calendar` merges workspace `members[]` (BirthdayPerson) and private
`entries[]` (family/friends/clients). Month counts are client-side from those
arrays. `send-wish` creates a birthday chat card in the DM and returns the
`conversation_id`.

### Visitors

| UI | Endpoint |
| --- | --- |
| Desks | `GET /visitor/list-desks/{workspace_id}/` |
| My passes | `GET /visitor/list-passes/{workspace_id}/?scope=mine&date=YYYY-MM-DD` |
| Front desk | `GET /visitor/list-passes/{workspace_id}/?scope=desk&date=YYYY-MM-DD` |
| Invite | `POST /visitor/create-pass/{workspace_id}/` |
| Find code | `GET /visitor/find-pass/{workspace_id}/?code=` |
| Answer | `POST /visitor/pass-action/{workspace_id}/{pass_id}/` |
| Public guest page | `GET /visitor/public-pass/{code}/` (Public) |
| Public guest reply | `POST /visitor/public-pass-action/{code}/` (Public) |

Create pass:

```json
{
  "guest_name": "Folake Adebayo",
  "guest_phone": "+2348031234567",
  "party_size": 1,
  "purpose": "Interview",
  "desk_id": "4f1a0dfa-4f6e-4d0e-9f3d-2f7a57f2f4e1",
  "host_id": null,
  "valid_on": "2026-11-23",
  "arrived": false
}
```

Use the desk with `is_default` when the design has no desk picker. A walk-in
(`arrived: true`) must use today.

Pass actions:

| Design button | Action |
| --- | --- |
| Come in | `admit` |
| Wait 10 min | `hold` with `minutes: 10` |
| Not today | `decline` with `note` |
| Reception told | `ping` |
| Leave | `leave` |
| Cancel | `cancel` |

The response is a `VisitPass` with `code`, `status`, `can_answer`, `can_desk`
and `events[]`. Display `code` in the sheet and share it; the guest page needs
no app.

Poll `list-passes?scope=mine` every 30 seconds on the Visitors screen and
refresh after every action. The public guest page polls every 8 seconds.

### Profile

| UI | Endpoint |
| --- | --- |
| Header, reports-to, teams, direct reports, badges | `GET /people/get-person/{workspace_id}/{user_id}/` |
| Points/level/streak/badges | `GET /gamification/get-profile/{workspace_id}/{user_id}/` |
| Streak heatmap | `GET /report/get-person/{workspace_id}/{user_id}/` |
| Appraisal CSV | `GET /report/export-appraisal/{workspace_id}/?person_id=` |
| Set presence | `PUT /people/set-status/{workspace_id}/` |
| Edit profile | `PATCH /auth/update-profile-json/`, `PUT /auth/update-profile/` |
| My birthday | `GET /birthday/get-my-birthday/`, `PUT /birthday/set-my-birthday/` |

Presence body: `{"presence": "dnd", "custom": "Deep work", "until": "..."}`;
`presence` is `available`, `busy`, `meeting`, `away`, `dnd`, `leave` or
`offline`.

The design's “Best 11” streak is not returned; derive the longest run from the
90-day heatmap. Badge count is `badges.filter(earned).length`.

### Settings

| UI | Endpoint |
| --- | --- |
| Name, photo, job, department, phone | `PATCH /auth/update-profile-json/`, `PUT /auth/update-profile/` |
| Password | `POST /auth/update-password/` |
| Email change | `POST /auth/request-email-change/`, `POST /auth/confirm-email-change/` |
| Birthday + visibility | `GET /birthday/get-my-birthday/`, `PUT /birthday/set-my-birthday/` |
| Notifications | `GET /notification/get-preferences/{workspace_id}/`, `PUT /notification/update-preferences/{workspace_id}/` |
| Appearance/language | `PATCH /auth/update-profile-json/` (`theme`, `language`) |
| Face ID | client-side secure storage; no API |
| Sign out | drop the token and clear caches; no revocation endpoint |

`theme` supports `light` and `dark`. “Follow the phone” is a client-side
choice; send the resolved light/dark value.

### More

- Profile header: `GET /auth/get-profile/` +
  `GET /people/get-person/{workspace_id}/{user_id}/`.
- Workspace card: `GET /workspace/list-workspaces/` and
  `GET /workspace/get-workspace/{workspace_id}/`.
- Role label: `GET /people/my-context/{workspace_id}/`.
- Notification count: `GET /notification/get-unread-count/{workspace_id}/`.
- “Set up a new workspace”: `POST /workspace/create-workspace/` (subject to the
  single-organization restriction).

---

## 12. Family workspace

### Home payloads

| Data | Endpoint |
| --- | --- |
| Space modules (chores, shopping, bills, school) | `GET /home/get-space/{workspace_id}/` |
| Family dashboard (errands, points, rewards, visitor, birthdays, brief) | `GET /home/get-family/{workspace_id}/` |
| School diary | `GET /school/list-items/{workspace_id}/` |
| Polls | `GET /poll/list-polls/{workspace_id}/` |
| Team summaries | `GET /routine/list-summaries/{workspace_id}/?days=1` |

`get-space` returns a `SpaceRead` with `modules[]`. Each module has `type`,
`key`, `target`, `rate`, `items[]`, `columns[]`, `question`, `options[]` and
`voted`. Use `key` to route: `chores`, `shopping`, `bills`, `school`.

`get-family` returns:

```json
{
  "errands": [],
  "points": [{"user_id": "...", "points": 140}],
  "rewards": [{"id": "...", "name": "Ice cream outing", "cost": 120, "icon": "IceCreamCone"}],
  "visitor": {"id": "...", "name": "Mr Okon", "at": "...", "state": "waiting", "logged_by": "Security"},
  "birthdays": [{"name": "Mama Bisi", "days": 3}],
  "brief": {"errands": 0, "homework": 2, "driver_free_from": "11:00"}
}
```

### Space actions

`POST /home/space-action/{workspace_id}/`

| Action | Fields | Use |
| --- | --- | --- |
| `add` | `module`, `fields` | Add a chore, shopping item, bill, issue, notice, person, poll or time entry |
| `status` | `module`, `item`, `status` | Mark a checklist row/committee etc. |
| `pay` | `module`, `item`, `amount` | Record a bill/levy/fee payment |
| `count` | `module`, `item` | Increment a points/count value |
| `vote` | `module`, `option` | Vote in a space poll (zero-based index) |
| `members` | `module`, `column`, `lead`, `user_ids` | Set a board column's lead/members |
| `remove_column` | `module`, `column` | Remove a board column |
| `remove_card` | `module`, `column`, `index` | Remove a card from a column |
| `remove` | `module`, `item` | Delete an item/person/notice |

Common `fields`: `title`, `owner`, `due`, `count`, `note`, `amount`, `paid`,
`member`, `group`, `role`, `date`, `time`, `where`, `lead`, `client`, `task`,
`hours`, `billable`.

Recommended status values:

- chores / actions / issues: `open`, `doing`, `done`;
- people / attendance: `invited`, `yes`, `no`, `maybe`;
- event RSVP (dedicated event API): `not_sent`, `invited`, `attending`,
  `maybe`, `declined`.

Board modules now return `columns[].id` and each card's `column_id`, so group
cards by id rather than matching titles.

### Family actions

`POST /home/family-action/{workspace_id}/`

| Action | Payload | Use |
| --- | --- | --- |
| `add_errand` | `who`, `title`, optional `issued`, `spent` | “Say an errand” |
| `change_received` | `errand_id` | “Change received” |
| `add_reward` | `name`, `cost`, optional `icon` | “Add a reward” |
| `redeem` | `user_id`, `reward_id` | Spend points |
| `homework_done` | `user_id` | +10 points |
| `award_points` | `user_id`, `amount` | Award chore/homework points |
| `add_visitor` | `name`, optional `logged_by` | Visitor at the gate |
| `visitor` | `decision` (`allowed`/`wait`), optional `visitor_id` | Let in / ask to wait |

All return the full family home payload.

`get-family.visitor` includes the waiting visitor's `id`; pass `visitor_id`
to `visitor` to resolve a specific visitor when more than one is waiting.
`award_points` only checks that the target is an active member; any active
member can call it. There is no parent-only role in the API, so treat
owner/admin as parents if points should be parent-controlled.

`add_errand` creates the errand but does not notify the person named. `who`
is a display name, not a user id, so the errand only appears on the family
home until the app sends a chat message or a notification endpoint exists.

### Screen mapping

#### Family home

- “3 chores left”: count `chores.items` with status `open`/`doing`.
- “School to check”: `get-family.brief.homework`.
- “Bill due”: first `bills` item with `due <= today` and `paid < amount`.
- “Needs you”: `get-family.visitor` plus overdue chores/bills; call
  `family-action visitor` with `visitor.id` as `visitor_id`.
- “Points & rewards”: `get-family.points` / `rewards`; join `user_id` to
  workspace members.
- “Errands & money”: `get-family.errands`; `change_received` closes.
  `add_errand` only creates the row — there is no per-person delivery yet.
- “Coming up”: school items + bills due within 7 days.
- Quick add: see FamilyTask below.

#### Bills

- Data: `bills` money module. Each item has `title`, `amount`, `paid`, `due`,
  `member_id`.
- Progress: sum `paid` / sum `amount`.
- Pay: `space-action` `{action:"pay", module:"bills", item, amount}`.
- The payment method (`Transfer`/`Cash`/`POS`) is not persisted; keep it
  client-side.
- New bill: `space-action add` with `title`, `amount`, `due`, optional
  `member` (workspace user id) and `note`.

#### Chores

- Data: `chores` checklist module. `owner` is a display name; `member_id` is
  an app user when available; `count` is the point value.
- Add: `space-action add` with `title`, `owner`, `due`, `count`, `note`;
  use `member` (user id) instead of `member_id` to link an app user.
- Start/finish: `space-action status` `open` → `doing` → `done`.
- Award points when a parent checks the work:
  `family-action award_points` with `user_id` and `amount` (use `count`).
- Children without accounts can appear as `owner` strings but cannot earn
  `FamilyPoint` rows. Invite them as app users if points are needed.

#### Shopping

- Data: `shopping` checklist module.
- Add: `space-action add` with `title`, optional `count`, `note`, `where`,
  `group` (use `where` for market/store and `group` for category).
- Tick/untick: `space-action status` `open`/`done`.
- Delete: `space-action remove`.
- “Bisi is at Mile 12” is presence/chat, not a shopping endpoint.

#### School

- `GET /school/list-items/{workspace_id}/` (plain array).
- Create/update: `POST /school/save-item/{workspace_id}/` with `kind`
  (`assignment`, `test`, `pta`, `event`, `form`, `fees`, `supplies`,
  `report`), `title`, `child_id`, `subject`, `due`, `checker_id`, `note`.
- Actions: `POST /school/item-action/{workspace_id}/` with
  `{id, action, note}` where action is `done`, `check`, `redo`,
  `reopen` or `delete`.
- “Looks good” = `check`; “Do it again” = `redo` with `note` (returned as
  `feedback` on the item).
- Photo proof has no attachment field. If needed, upload an inline image with
  `/file/upload/` and put the stable URL in `note`; otherwise defer to a later
  backend field.

#### Rewards

- Leaderboard: derive from `get-family.points` joined to members.
- Star of the week: highest points.
- Redeem: `family-action redeem`.
- Add reward: `family-action add_reward`.
- `+ points`: `family-action award_points`.
- Cheer/message: send a chat message; there is no dedicated cheer endpoint.

#### Household

- App users: `GET /workspace/list-members/{workspace_id}/`.
- Setup-only people: `GET /workspace/get-workspace/{workspace_id}/` →
  `setup.members[]` (`name`, `type`).
- Points: `get-family.points`.
- The family tablet/PIN profile switch is **not implemented** in the backend.
  A shared tablet cannot securely switch between child profiles yet. Hide the
  PIN flow or treat each child as a normal signed-in account.

#### FamilyTask

Choose the backend based on the task:

| Task type | API |
| --- | --- |
| Chore with points / non-user owner | `space-action add` on `chores` |
| Errand with cash | `family-action add_errand` |
| General to-do for an app user | `POST /task/create-task/{workspace_id}/` |
| Bill | `space-action add` on `bills` |
| Shopping item | `space-action add` on `shopping` |
| School item | `POST /school/save-item/{workspace_id}/` |

The design's “repeat”, “buy list”, “photo proof” and “remind at” have no
single family-task endpoint. For app users, use task recurrence and
attachments; otherwise keep the repeat/buy list client-side and create the
rows on save.

#### Family plans

There is no family-plan model. Map a plan to a project:

1. `POST /project/create-project/{workspace_id}/` with the plan name,
   `target_date` and member ids (app users only).
2. `POST /project/create-milestone/{project_id}/` for each step.
3. `POST /task/create-task/{workspace_id}/` with `type:"project"`,
   `project_id`, `milestone_id`, `assignee_ids`, `due_date`.
4. Progress: `GET /project/get-project/{project_id}/` → `stats.progress` and
   `milestones[].progress`.

“Pick an idea” templates are client-side payloads. Setup-only children cannot
be project members; invite them first.

#### Kid home

- Use the child's own session when they have an account.
- Homework: `GET /school/list-items/{workspace_id}/` filtered by `child`.
- Chores: `chores.items` filtered by `owner`/`member_id`.
- Points/rewards: `get-family`.
- “Parent view” is client-side; there is no role-switch endpoint.
- “I’ve arrived at school” has no endpoint; send a chat message to a parent
  or hide the button.
- Photo proof is the same unsupported attachment field as School.

---

## 13. Individual workspace

### Home payloads

| Data | Endpoint |
| --- | --- |
| Modules (`clients`, `invoices`, `time`, `proposals`) | `GET /home/get-space/{workspace_id}/` |
| Invoice document | `GET /home/get-invoice/{workspace_id}/{item_id}/` |
| Save invoice | `PUT /home/save-invoice/{workspace_id}/{item_id}/` |
| Proposal document | `GET /home/get-proposal/{workspace_id}/{item_id}/` |
| Save proposal | `PUT /home/save-proposal/{workspace_id}/{item_id}/` |
| Clients | `clients` people module + `GET /share/list-collaborators/{workspace_id}/` |
| Projects/gigs | `GET /project/list-projects/{workspace_id}/` |
| Tasks | `GET /task/list-tasks/{workspace_id}/` |
| Files | `GET /file/list-files/{workspace_id}/` |

### Clients and proposals

- Clients can be space people (`clients` module) and/or project share
  collaborators (`share/list-collaborators`).
- Add a client: `space-action add` on `clients` with `title` (name), `role`,
  `group`, `status`.
- Proposals are checklist items in `proposals`; open/save the document with the
  item id.
- **Not live:** sending a proposal to a client for acceptance, approval stages
  and “Mark accepted”. The supported client portal is project sharing:
  `GET /share/get-access/{resource_type}/{resource_id}/` and
  `POST /share/update-access/{resource_type}/{resource_id}/` with
  `resource_type=project`; use `client_can` choices. Use project
  progress/files/timeline/comments for the client-visible view.

### Gigs

A gig is a project:

1. Create with `POST /project/create-project/{workspace_id}/` (`name`,
   `target_date`, `health`, `member_ids`, optional `invite_emails`).
2. Add deliverables as tasks or milestones.
3. Client access through `share/update-access` (`role: "client"`,
   `client_can`).
4. “Accepted delivery” = task approval/first-time-right, or
   `stats.first_time_right_rate`.
5. Templates are client-side create payloads; there is no gig template
   endpoint.

Invoices are separate studio documents. There is no project-to-invoice link
yet; keep the invoice list on the invoices module and show it independently.

### Invoices

- List: `invoices` money module items (`title`, `amount`, `paid`, `client`).
- Create: `space-action add` on `invoices` (title/client/amount), then
  `PUT /home/save-invoice/{workspace_id}/{item_id}/` for line items.
- Mark payment: `space-action pay` on `invoices`.
- Remind: no endpoint; use chat/email manually or defer.
- Status is client-derived: `paid >= amount` → paid; `due < today` and not
  paid → overdue.

### Time

- Data: `time` module. Each item has `client`, `task`, `date`, `hours`,
  `billable`; the module has `rate` (hourly).
- Add a manual entry: `space-action add` on `time`.
- Timer: keep the running state locally; on stop add the hours entry.
- “Bill it”: create a new invoice item and save a document whose line items
  are the selected time entries. There is no automatic time-to-invoice link.

---

## 14. Specials workspaces

Common for church/alumni/estate/event/committee/club:

- Headline/countdown: `GET /workspace/get-workspace/{workspace_id}/` →
  `setup.event_name`, `setup.event_date`.
- Team pulse: `GET /routine/list-summaries/{workspace_id}/?days=1`.
- Generic modules: `GET /home/get-space/{workspace_id}/` and
  `/home/space-action/` (except where a dedicated module below is richer).
- Notices, polls, boards and people use the space actions above.

### Church

Use `GET /church/get-church/{workspace_id}/` (not the space modules) and
`POST /church/action/{workspace_id}/`. Every action returns the full church
payload.

| Screen | Action |
| --- | --- |
| Home cards | Payload totals: `giving`, `pledges`, `units`, `prayers`, `first_timers` |
| Services | `save_service`, `delete_service`, `set_roster`, `record_attendance` |
| Giving | `record_giving`, `delete_giving`, `save_fund`, `delete_fund`, `add_pledge`, `pay_pledge` |
| Units | `save_unit`, `delete_unit`, `unit_members`, `unit_notice`, `remove_unit_notice`, `set_unit_chat`, `add_duty`, `remove_duty` |
| Prayer | `add_prayer` (`private`, `anonymous`), `pray`, `answer_prayer` |
| First-timers | `add_first_timer`, `first_timer_stage`, `first_timer_assign`, `first_timer_note` |

`can_manage` controls admin-only buttons. Unit leaders can manage their own
unit notices/duties. Private prayers are hidden unless the caller is an admin
or the author.

### Alumni

Use the space hub:

| Tab | Module | Key actions |
| --- | --- | --- |
| Overview | all | Totals client-side |
| Dues & pledges | `dues` (money) | `add`, `pay`, `remove` |
| Committees | `committees` (board) | `add` column/card, `members`, `remove_card` |
| Poll | `poll` | `add` question+options, `vote` |
| Notices | `notices` | `add`; `read/of` counts |
| Directory | `directory` (people) | `add`, `status`, `remove` |

A dues row is `title` (name), `amount`, `paid`. “Add classmate” is a people
row; send the workspace signup link for a real account.

### Estate

| Tab | Module/API | Key actions |
| --- | --- | --- |
| Levies | `levies` (money) | `add`, `pay` |
| Gate passes | `passes` (schedule) or `/visitor/*` | For real codes/security, use the visitor API with the estate gate desk; otherwise schedule rows |
| Issues | `issues` (checklist) | `add`, `status`, `remove` |
| Notices | `notices` | `add` |
| Poll | `poll` | `add`, `vote` |

For gate passes, `GET /visitor/list-desks/{workspace_id}/` returns
`Estate office` etc. Choose `is_default`,
`POST /visitor/create-pass/{workspace_id}/`, then `pass-action` for
`admit`/`hold`/`decline`. The pass `code` is the gate code.

### Wedding / event workspace

Use the dedicated event API, not the space modules.

| Screen | Endpoint |
| --- | --- |
| Event header/budget | `GET /event/get-event/{workspace_id}/` |
| Edit event/tables | `PUT /event/update-event/{workspace_id}/` |
| Guest list | `GET /event/list-guests/{workspace_id}/` |
| Add/update guest | `POST /event/save-guest/{workspace_id}/` |
| Import guests | `POST /event/import-guests/{workspace_id}/` |
| Guest actions | `POST /event/guest-action/{workspace_id}/` (`invite`, `delete`, `set_rsvp`, `set_group`, `set_table`, `check_in`) |
| Vendors | `GET /event/list-vendors/{workspace_id}/`, `POST /event/save-vendor/{workspace_id}/` |
| Vendor actions | `POST /event/vendor-action/{workspace_id}/` (`delete`, `invite`, `pay`, `set_status`) |
| Programme | `GET /event/list-programme/{workspace_id}/`, `POST /event/save-programme-item/{workspace_id}/`, `POST /event/programme-action/{workspace_id}/` |
| Public guest page | `GET /public/event/{share_token}/?code=` (Public) |
| Public RSVP | `POST /public/rsvp/{share_token}/` (Public) |
| Vendor brief | `GET /public/vendor/{portal_token}/` (Public) |

Derived UI:

- RSVP progress: count guests by `rsvp`; seats = sum `attending_count`.
- Budget used: sum vendor `quote`/payments against `event.budget`.
- Payments due: vendor `next_due`.
- Seating: `event.tables[]` and `guest.table_id`; auto-seat by grouping
  `guest.group` and calling `guest-action set_table` per guest.
- Door check-in: `guest-action` `{action:"check_in", guest_ids:[...]}`; undo
  with `undo:true`.
- Programme run mode: `programme-action` `set_status` (`pending`/`live`/`done`);
  `set_status` marks earlier items done.

“Share invite”/“Guest page” copy uses `event.share_token`; do not build a
different URL.

### Committee

| Tab | Module | Actions |
| --- | --- | --- |
| Overview | all | Totals client-side |
| Meetings | `meetings` (schedule) | `add`, `status`, `remove` |
| Action items | `actions` (checklist) | `add`, `status`, `remove` |
| Minutes | `minutes` (notices) | `add`; read counts |
| Decisions | `decisions` (poll) | `add`, `vote` |

Per-meeting “Coming / Maybe / Can't” RSVP has no model. Use a poll on the
meeting (`decisions` or `/poll/`) as the v1 fallback, or defer the control.

### Club

| Tab | Module | Actions |
| --- | --- | --- |
| Overview | all | Totals client-side |
| Sessions | `sessions` (schedule) | `add`, `status`, `remove` |
| Fees | `fees` (money) | `add`, `pay` |
| Attendance | `attendance` (people) | `add`, `status` (`yes`/`maybe`/`no`) |
| Notices | `notices` | `add` |

Session RSVP (“I'm in / Maybe / Out”) also has no per-session model. Use a poll
per session or the people module status as a lightweight indicator; document
that it is not stored per session.

---

## 15. Cross-cutting mobile behaviour

### Refresh cadence

| Data | Poll / refresh |
| --- | --- |
| Home summary and badges | 60s |
| Task list / detail | On focus; 30–60s while visible |
| Approvals queue | 30–60s |
| Chat conversation list | 30s |
| Open chat thread | 10s |
| Notifications | 60s |
| Presence / online now | 60s |
| Attendance board | 30s |
| Space hub / family home | On focus and after each action |
| Church | After each action (response is the full payload) |
| Event planner | On focus; refetch lists after mutations |
| Visitor passes | 30s; public guest page 8s |
| Project/team lists | On focus |
| Files | On focus |
| Journal | On focus; local drafts |
| Birthday feed | 5 min |

Stop all timers when the app backgrounds. Use pull-to-refresh on every list.

### Permissions and roles

- `my-context` flags (`is_manager`, `is_line_manager`, `is_project_manager`,
  `is_team_lead`, `is_assigner`) drive navigation and action visibility.
- Workspace role is `owner`, `admin` or `member`; owners manage admins, admins
  manage members.
- `can_manage`/`can_*` fields on church, school, visitor, project and task
  responses are authoritative; hide controls when false.
- A `pending` membership is an invite, not a member.
- Family/specials setup members are labels until invited as users.

### Caching and security

- Store the JWT and refresh it only by logging in again.
- Clear all workspace-scoped caches on sign-out and workspace switch.
- Journal notes are private; never cache them in shared storage.
- Signed file URLs are bearer-like; do not log or share them.
- Public event/RSVP/vendor/pass endpoints must not send the JWT.
- Do not persist message attachments outside the app sandbox.

### Not live / phase 2

| Feature | Status | v1 approach |
| --- | --- | --- |
| Push notifications | No device token or FCM/APNs dispatch | Poll in-app notifications |
| Realtime chat/typing | No WebSocket/typing API | Poll; hide typing indicator |
| Family tablet / child PIN | No profile or PIN model | Use real accounts; hide PIN flow |
| Family plans | No model | Map to projects/milestones/tasks |
| Gigs | No model | Map to projects/tasks/sharing |
| Proposal send/accept portal | No API | Project sharing; show proposal document read-only |
| Committee/club per-session RSVP | No model | Use a poll per session |
| Family errand delivery | No notification/recipient endpoint | Show on the family home; chat manually |
| Kid school arrival | No endpoint | Send a chat message or hide the button |
| Bill/dues payment method | `space-action pay` records the amount only | Keep the method client-side |
| School/family photo proof | No attachment field | Inline upload URL in `note` or defer |
| Routine points toast | No points award for logs | Omit or label as pending |
| Best streak | Only current streak/heatmap returned | Derive from heatmap |
| “Follow phone” theme | API supports light/dark | Resolve locally |
| Multi-workspace | Single-org restriction by default | Handle 409; enable via env if needed |
| Demo login | No endpoint | Use seeded accounts |

### Endpoint index

```
Auth
  POST /auth/signup/
  POST /auth/login/
  POST /auth/form-login/
  GET  /auth/oauth/{provider}/start/
  POST /auth/oauth/{provider}/callback/
  GET  /auth/check-auth/
  GET  /auth/get-profile/
  PATCH /auth/update-profile-json/
  PUT  /auth/update-profile/
  POST /auth/update-password/
  POST /auth/request-password-reset/
  POST /auth/confirm-password-reset/
  POST /auth/request-email-change/
  POST /auth/confirm-email-change/
  POST /auth/verify-email/
  POST /auth/resend-verification/

Workspaces and people
  GET  /workspace/list-workspaces/
  POST /workspace/create-workspace/
  GET  /workspace/get-workspace/{workspace_id}/
  GET  /workspace/my-role/{workspace_id}/
  PUT  /workspace/update-workspace/{workspace_id}/
  GET  /workspace/list-members/{workspace_id}/
  POST /workspace/invite-member/{workspace_id}/
  GET  /workspace/my-invites/
  GET  /workspace/get-invite-public/{token}/
  POST /workspace/accept-invite-public/{token}/
  POST /workspace/accept-invite/{token}/
  GET  /workspace/get-signup-link/{workspace_id}/
  PUT  /workspace/update-signup-settings/{workspace_id}/
  POST /workspace/regenerate-signup-link/{workspace_id}/
  GET  /workspace/get-signup-public/{token}/
  POST /workspace/signup-public/{token}/
  POST /workspace/approve-signup/{workspace_id}/{membership_id}/
  POST /workspace/reject-signup/{workspace_id}/{membership_id}/
  GET  /people/my-context/{workspace_id}/
  GET  /people/get-person/{workspace_id}/{user_id}/
  GET  /people/list-statuses/{workspace_id}/
  PUT  /people/set-status/{workspace_id}/

Tasks
  POST /task/create-task/{workspace_id}/
  POST /task/create-task-with-files/{workspace_id}/
  GET  /task/resolve-approver/{workspace_id}/
  GET  /task/list-tasks/{workspace_id}/
  GET  /task/get-task/{task_id}/
  PUT  /task/update-task/{task_id}/
  POST /task/start-task/{task_id}/
  POST /task/submit-task/{task_id}/
  POST /task/return-task/{task_id}/
  POST /task/approve-task/{task_id}/
  POST /task/complete-task/{task_id}/
  POST /task/reopen-task/{task_id}/
  POST /task/change-due-date/{task_id}/
  GET  /task/list-approvals/{workspace_id}/
  GET  /task/get-summary/{workspace_id}/
  GET  /task/list-activity/{task_id}/
  GET  /task/list-comments/{task_id}/
  POST /task/add-comment/{task_id}/
  GET  /task/list-attachments/{task_id}/
  POST /task/upload-attachment/{task_id}/
  GET  /task/list-watchers/{task_id}/
  POST /task/add-watcher/{task_id}/
  GET  /task/list-links/{task_id}/
  POST /task/add-link/{task_id}/
  POST /chat/start-task-conversation/{task_id}/

Chat
  GET  /chat/list-conversations/{workspace_id}/
  GET  /chat/list-groups/{workspace_id}/
  GET  /chat/get-group/{group_id}/
  POST /chat/start-dm/{workspace_id}/
  POST /chat/create-conversation/{workspace_id}/
  GET  /chat/search-people/{workspace_id}/
  GET  /chat/search-messages/{workspace_id}/
  GET  /chat/list-chat-requests/
  POST /chat/accept-chat-request/{conversation_id}/
  POST /chat/decline-chat-request/{conversation_id}/
  GET  /chat/list-external-conversations/
  GET  /chat/get-conversation/{conversation_id}/
  GET  /chat/list-messages/{conversation_id}/
  POST /chat/send-message/{conversation_id}/
  PATCH /chat/edit-message/{message_id}/
  DELETE /chat/delete-message/{message_id}/
  POST /chat/toggle-reaction/{message_id}/
  PATCH /chat/pin-message/{message_id}/
  GET  /chat/list-pinned-messages/{conversation_id}/
  GET  /chat/list-thread-replies/{message_id}/
  GET  /chat/list-conversation-files/{conversation_id}/
  GET  /chat/list-linked-tasks/{conversation_id}/
  POST /chat/create-task/{conversation_id}/
  POST /chat/mark-read/{conversation_id}/
  POST /chat/mark-unread/{conversation_id}/
  PUT  /chat/update-conversation-state/{conversation_id}/
  GET  /chat/get-unread-summary/{workspace_id}/

Notifications
  GET  /notification/list-notifications/{workspace_id}/
  GET  /notification/get-unread-count/{workspace_id}/
  POST /notification/mark-read/{notification_id}/
  POST /notification/mark-all-read/{workspace_id}/
  GET  /notification/get-preferences/{workspace_id}/
  PUT  /notification/update-preferences/{workspace_id}/

Attendance
  GET  /attendance/get-today/{workspace_id}/
  POST /attendance/clock-in/{workspace_id}/
  POST /attendance/clock-out/{workspace_id}/
  GET  /attendance/get-stats/{workspace_id}/
  GET  /attendance/list-records/{workspace_id}/
  GET  /attendance/list-board/{workspace_id}/
  GET  /attendance/get-weather/{workspace_id}/
  GET  /attendance/search-places/{workspace_id}/

Routines and reports
  GET  /routine/list-my-routines/{workspace_id}/
  GET  /routine/get-routine/{routine_id}/
  POST /routine/submit-log/{routine_id}/
  GET  /routine/get-log/{routine_id}/
  GET  /routine/list-summaries/{workspace_id}/
  GET  /routine/team-status/{workspace_id}/
  POST /routine/react-summary/{workspace_id}/{summary_id}/
  POST /routine/upload-attachment/{routine_id}/
  GET  /routine/logs-grid/{routine_id}/
  GET  /report/get-overview/{workspace_id}/
  GET  /report/get-person/{workspace_id}/{user_id}/
  GET  /report/list-activity/{workspace_id}/
  GET  /report/export-appraisal/{workspace_id}/

Projects, teams, files
  GET  /project/list-projects/{workspace_id}/
  POST /project/create-project/{workspace_id}/
  GET  /project/get-project/{project_id}/
  PUT  /project/update-project/{project_id}/
  GET  /project/list-milestones/{project_id}/
  POST /project/create-milestone/{project_id}/
  PUT  /project/update-milestone/{project_id}/{milestone_id}/
  DELETE /project/delete-milestone/{project_id}/{milestone_id}/
  GET  /team/list-teams/{workspace_id}/
  GET  /team/get-team/{team_id}/
  GET  /file/list-files/{workspace_id}/
  GET  /file/file-stats/{workspace_id}/
  GET  /file/upload-policy/
  POST /file/upload-file/{workspace_id}/
  POST /file/upload/{workspace_id}/
  GET  /file/view/{file_id}/

Journal, birthdays, visitors
  GET  /note/list-notes/{workspace_id}/
  GET  /note/get-summary/{workspace_id}/
  GET  /note/list-due-reminders/{workspace_id}/
  POST /note/create-note/{workspace_id}/
  GET  /note/get-note/{note_id}/
  PATCH /note/update-note/{note_id}/
  POST /note/pin-note/{note_id}/
  POST /note/archive-note/{note_id}/
  POST /note/trash-note/{note_id}/
  POST /note/restore-note/{note_id}/
  DELETE /note/delete-note/{note_id}/
  PUT  /note/set-reminder/{note_id}/
  DELETE /note/clear-reminder/{note_id}/
  GET  /birthday/get-feed/{workspace_id}/
  GET  /birthday/list-today/{workspace_id}/
  GET  /birthday/list-upcoming/{workspace_id}/
  GET  /birthday/get-calendar/{workspace_id}/
  POST /birthday/send-wish/{user_id}/
  GET  /birthday/get-my-birthday/
  PUT  /birthday/set-my-birthday/
  POST /birthday/save-entry/{workspace_id}/
  DELETE /birthday/delete-entry/{entry_id}/
  POST /birthday/celebrate-entry/{entry_id}/
  GET  /visitor/list-desks/{workspace_id}/
  GET  /visitor/list-passes/{workspace_id}/
  POST /visitor/create-pass/{workspace_id}/
  GET  /visitor/find-pass/{workspace_id}/
  POST /visitor/pass-action/{workspace_id}/{pass_id}/
  GET  /visitor/public-pass/{code}/
  POST /visitor/public-pass-action/{code}/

Spaces, family, studio
  GET  /home/get-space/{workspace_id}/
  POST /home/space-action/{workspace_id}/
  GET  /home/get-family/{workspace_id}/
  POST /home/family-action/{workspace_id}/
  GET  /home/get-invoice/{workspace_id}/{item_id}/
  PUT  /home/save-invoice/{workspace_id}/{item_id}/
  GET  /home/get-proposal/{workspace_id}/{item_id}/
  PUT  /home/save-proposal/{workspace_id}/{item_id}/

Specials
  GET  /school/list-items/{workspace_id}/
  POST /school/save-item/{workspace_id}/
  POST /school/item-action/{workspace_id}/
  GET  /poll/list-polls/{workspace_id}/
  POST /poll/create-poll/{workspace_id}/
  POST /poll/vote-poll/{poll_id}/
  GET  /church/get-church/{workspace_id}/
  POST /church/action/{workspace_id}/
  GET  /event/get-event/{workspace_id}/
  PUT  /event/update-event/{workspace_id}/
  GET  /event/list-guests/{workspace_id}/
  POST /event/save-guest/{workspace_id}/
  POST /event/import-guests/{workspace_id}/
  POST /event/guest-action/{workspace_id}/
  GET  /event/list-vendors/{workspace_id}/
  POST /event/save-vendor/{workspace_id}/
  POST /event/vendor-action/{workspace_id}/
  GET  /event/list-programme/{workspace_id}/
  POST /event/save-programme-item/{workspace_id}/
  POST /event/programme-action/{workspace_id}/
  GET  /public/event/{share_token}/
  POST /public/rsvp/{share_token}/
  GET  /public/vendor/{portal_token}/

Gamification and sharing
  GET  /gamification/get-profile/{workspace_id}/{user_id}/
  GET  /gamification/leaderboard/{workspace_id}/
  GET  /share/get-access/{resource_type}/{resource_id}/
  POST /share/update-access/{resource_type}/{resource_id}/
  GET  /share/list-collaborators/{workspace_id}/
```

Use the per-package documents for complete request/response examples:

- [`auth_docs.md`](auth_docs.md)
- [`workspaces_docs.md`](workspaces_docs.md)
- [`people_docs.md`](people_docs.md)
- [`tasks_docs.md`](tasks_docs.md)
- [`chat_docs.md`](chat_docs.md)
- [`notifications_docs.md`](notifications_docs.md)
- [`attendance_docs.md`](attendance_docs.md)
- [`routines_docs.md`](routines_docs.md), [`reports_docs.md`](reports_docs.md)
- [`projects_docs.md`](projects_docs.md), [`teams_docs.md`](teams_docs.md)
- [`files_docs.md`](files_docs.md)
- [`journal_docs.md`](journal_docs.md), [`birthday_docs.md`](birthday_docs.md)
- [`visitor_docs.md`](visitor_docs.md)
- [`spaces_docs.md`](spaces_docs.md), [`school_docs.md`](school_docs.md)
- [`church_docs.md`](church_docs.md), [`events_docs.md`](events_docs.md)
- [`polls_docs.md`](polls_docs.md), [`sharing_docs.md`](sharing_docs.md)
- [`gamification_docs.md`](gamification_docs.md)
