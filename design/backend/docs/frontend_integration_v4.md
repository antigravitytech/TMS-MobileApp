# Frontend Integration Summary — v4 UI

Reference design: `designs/tms-app 4.html`

This is the integration guide for the v4 UI. The backend now covers every
API call the v4 bundle makes. Base URL: `http://localhost:8081` (or the
deployed API); all authenticated calls send
`Authorization: Bearer <JWT>`.

**Pagination:** every list endpoint returns
`{items, total, page, page_size, total_pages}` unless documented as a plain
array. **Public endpoints** require no JWT and are called by `share_token`,
guest `code`, vendor `portal_token` or signup-token.

## Screen → endpoints

| Screen / route | Endpoints |
| --- | --- |
| Sign in / signup / onboarding | `POST /auth/signup/`, `POST /auth/login/`, `GET /auth/check-auth/`, `GET /auth/get-profile/`, `PATCH /auth/update-profile-json/`, `PUT /auth/update-profile/` |
| OAuth callback | `GET /auth/oauth/{provider}/start/`, `POST /auth/oauth/{provider}/callback/` |
| Password / email / unsubscribe | `POST /auth/request-password-reset/`, `POST /auth/confirm-password-reset/`, `POST /auth/update-password/`, `POST /auth/request-email-change/`, `POST /auth/confirm-email-change/`, `POST /auth/verify-email/`, `POST /auth/resend-verification/`, `POST /auth/unsubscribe/` |
| Invite pages | `GET /workspace/get-invite-public/{token}/`, `POST /workspace/accept-invite-public/{token}/`, `POST /workspace/request-invite/` |
| Public signup link (`/join?token=`) | `GET /workspace/get-signup-public/{token}/`, `POST /workspace/signup-public/{token}/` |
| Workspace switcher | `GET /workspace/list-workspaces/`, `GET /workspace/get-workspace/{id}/`, `GET /people/my-context/{id}/`, `PUT /workspace/update-workspace/{id}/` |
| My Day / dashboard | `GET /task/get-summary/{id}/`, `GET /report/get-overview/{id}/`, `GET /note/get-summary/{id}/`, `GET /note/list-due-reminders/{id}/`, `GET /birthday/get-feed/{id}/`, `GET /chat/get-unread-summary/{id}/`, `GET /chat/get-external-unread-summary/`, `GET /notification/get-unread-count/{id}/`, `GET /routine/list-my-routines/{id}/`, `GET /routine/list-summaries/{id}/`, `GET /home/get-family/{id}/`, `GET /people/list-statuses/{id}/` |
| Tasks | existing task endpoints (list, create, update, workflow, comments, checklist, attachments, watchers, approvals, saved views, activity) |
| Projects + detail | `GET/POST/PUT/DELETE /project/...` plus `GET /project/get-plan/{id}/`, `PUT /project/update-plan/{id}/`, `GET /project/list-plans/{id}/`, `GET /project/list-leave/{id}/`, `GET/POST/DELETE /project/...template...` |
| Approvals | `GET /task/list-approvals/{id}/`, `POST /task/approve-task/{id}/`, `POST /task/return-task/{id}/`, `POST /task/submit-task/{id}/` |
| Performance / reports | `GET /report/get-overview/{id}/`, `GET /report/get-person/{id}/{user}/`, `GET /report/list-activity/{id}/`, `GET /report/export-appraisal/{id}/`, `GET /gamification/leaderboard/{id}/`, `GET /gamification/get-profile/{id}/{user}/`, `GET /routine/list-summaries/{id}/` |
| Teams / people / organogram | existing team and people endpoints; `GET /people/list-statuses/{id}/`, `PUT /people/set-status/{id}/` |
| Admin users / company | `GET /people/list-people/{id}/`, `GET/PUT /people/...`, `GET/PUT /workspace/...settings`, `GET /people/get-organogram/{id}/`, `GET /people/export-people/{id}/`, `POST /people/bulk-invite/{id}/`, `POST /people/bulk-upload/{id}/`, `GET /people/get-bulk-upload-template/{id}/`, `GET /workspace/get-signup-link/{id}/`, `PUT /workspace/update-signup-settings/{id}/`, `POST /workspace/regenerate-signup-link/{id}/`, `POST /workspace/approve-signup/{id}/{membership_id}/`, `POST /workspace/reject-signup/{id}/{membership_id}/` |
| Chat | existing chat endpoints plus poll messages (`POST /poll/create-poll/{id}/` with `conversation_id`) |
| Notes / journal | existing note endpoints |
| Birthdays | `GET /birthday/get-feed/{id}/`, `GET /birthday/list-today/{id}/`, `GET /birthday/list-upcoming/{id}/`, `GET/POST/DELETE/PUT /birthday/...`, `GET /birthday/get-calendar/{id}/`, `POST /birthday/save-entry/{id}/`, `DELETE /birthday/delete-entry/{entry}/`, `POST /birthday/celebrate-entry/{entry}/` |
| Guest check-in | existing guest-checkin endpoints |
| Files | existing file endpoints |
| Notifications | `GET /notification/list-notifications/{id}/`, `POST /notification/mark-read/{id}/`, `POST /notification/mark-all-read/{id}/`, `GET/PUT /notification/preferences` |
| Spaces hub (`/space/:key`, family, individual, specials) | `GET /home/get-space/{id}/`, `POST /home/space-action/{id}/`, `GET /home/get-family/{id}/`, `POST /home/family-action/{id}/` |
| Studio invoice | `GET /home/get-invoice/{id}/{item}/`, `PUT /home/save-invoice/{id}/{item}/` |
| Studio proposal | `GET /home/get-proposal/{id}/{item}/`, `PUT /home/save-proposal/{id}/{item}/` |
| School | `GET /school/list-items/{id}/`, `POST /school/save-item/{id}/`, `POST /school/item-action/{id}/` |
| Polls | `GET /poll/list-polls/{id}/`, `GET /poll/get-poll/{poll}/`, `POST /poll/create-poll/{id}/`, `POST /poll/vote-poll/{poll}/`, `POST /poll/close-poll/{poll}/`, `DELETE /poll/delete-poll/{poll}/` |
| Event planner | `GET /event/get-event/{id}/`, `PUT /event/update-event/{id}/`, guests/vendors/programme endpoints |
| Public event page (`/e/:token`) | `GET /public/event/{token}/?code=...`, `POST /public/rsvp/{token}/` |
| Vendor brief (`/v/:token`) | `GET /public/vendor/{token}/` |
| Church | `GET /church/get-church/{id}/`, `POST /church/action/{id}/` |
| Sharing dialogs | `GET /share/get-access/{type}/{id}/`, `POST /share/update-access/{type}/{id}/`, `GET /share/list-collaborators/{id}/` |

## People onboarding

The Admin **Users** screen has two related onboarding paths. Both are
documented screen-by-screen in
[people_onboarding_integration.md](people_onboarding_integration.md).

- **Bulk CSV upload** — `POST /people/bulk-upload/{workspace_id}/` creates one
  pending invite per valid CSV row. Use
  `GET /people/get-bulk-upload-template/{workspace_id}/` for the template.
- **Signup link** — an owner/admin enables a public `/join?token=...` link.
  Public requests create pending memberships that appear in
  `GET /people/list-people/{workspace_id}/?status=pending` with
  `is_signup_request: true`. Approve or reject them from that screen; the
  Approve action stays disabled until `is_verified` is `true`.

## Workspace setup and navigation

`GET /people/my-context/{workspace_id}/` now returns
`workspace_subtype`. Use it with `workspace_kind` to choose navigation:

| `workspace_kind` | UI |
| --- | --- |
| `business` | Existing business navigation; no space hub |
| `individual` | Personal hub with `clients`, `invoices`, `time`, `proposals` |
| `family` | Family home + `chores`, `shopping`, `bills`, `school` |
| `specials` | Use `workspace_subtype`: `church`, `alumni`, `estate`, `event`, `committee`, `club` |

`WorkspaceRead` includes `setup`:

```json
{
  "kind": "specials",
  "subtype": "church",
  "setup": {
    "crest": null,
    "members": [{"id": "...", "name": "Pastor Femi", "type": "co_head", "position": 0}],
    "event_name": "Harvest thanksgiving",
    "event_date": "2026-11-29",
    "job": null,
    "has_clients": null,
    "team_size": null
  }
}
```

Signup accepts `workspace_type`, `workspace_subtype` and `workspace_setup`.
If the signup screen has already collected the setup, send it once; otherwise
the user can complete it in Settings and call `PUT /workspace/update-workspace/`.

## Spaces / home

`GET /home/get-space/{workspace_id}/` creates the module template on first
call and returns:

```json
{
  "kind": "family",
  "subtype": null,
  "headline": {"title": "The Adeyemis", "date": null, "members": 4},
  "modules": [
    {"type": "checklist", "key": "chores", "items": [], "columns": [], "options": []}
  ]
}
```

Module types and their item shape:

| Module type | `items` content |
| --- | --- |
| `money` | Amount, paid, due, member, note |
| `checklist` | Title, owner, due, status, count, note |
| `schedule` | Title, date, time, where, lead, note |
| `board` | `columns`: name, lead, members, items |
| `poll` | `question`, `options`, `voted` (0-based index) |
| `notices` | id, text, at, read, of |
| `people` | id, name, role, status, group |
| `time` | Client, task, date, hours, billable |

`POST /home/space-action/{workspace_id}/` returns the full space payload.
Use the action table in [spaces_docs.md](spaces_docs.md).

Family home uses `GET /home/get-family/` and
`POST /home/family-action/`; see [spaces_docs.md](spaces_docs.md).

### Studio

The `invoices` money module items are the invoice ids. Open an invoice with
`GET /home/get-invoice/{workspace_id}/{item_id}/` and save it with the same
URL (`PUT`). Proposals use the `proposals` checklist item id and
`GET/PUT /home/get-proposal/` / `save-proposal`. Invoice saves accept the
full invoice document; proposal saves accept `{html, layout, file_ids}`.

## Events

The planner is only available for `kind=specials, subtype=event`.
`GET /event/get-event/{id}/` lazily creates the event from the workspace
setup. Guests, vendors and programme are separate lists:

- `GET /event/list-guests/{id}/`
- `GET /event/list-vendors/{id}/`
- `GET /event/list-programme/{id}/`

Mutations return the saved row (or arrays for bulk actions). Full payloads
are in [events_docs.md](events_docs.md).

### Public pages

- Guest page: `GET /public/event/{share_token}/?code={guest_code}`.
  `guest` is `null` when no code is supplied or the code is unknown.
- RSVP: `POST /public/rsvp/{share_token}/`.
- Vendor brief: `GET /public/vendor/{portal_token}/`.

These three endpoints need no JWT. The frontend routes are `/e/:token` and
`/v/:token`; pass the personal guest code as `?code=` for the “remember me”
behaviour.

## Church

`GET /church/get-church/{workspace_id}/` returns all church collections and
`can_manage`. `POST /church/action/{workspace_id}/` is a single action
dispatcher; every action returns the full updated payload. See
[church_docs.md](church_docs.md) for the action list.

## School

`GET /school/list-items/{id}/` returns a plain array. `POST /school/save-item/`
creates or updates; `POST /school/item-action/` supports
`done/check/redo/reopen/delete`. Use the permission flags on each row to show
or hide controls (`can_mark_done`, `can_check`, `can_edit`).

## Polls

Poll list is paginated. `GET /poll/get-poll/{poll_id}/` returns the detail.
`POST /poll/create-poll/{workspace_id}/` accepts `conversation_id`; when set,
a chat message of type `poll` is created and will appear in
`GET /chat/list-messages/{conversation_id}/` with a `poll` payload.
`POST /poll/vote-poll/{poll_id}/` replaces votes. Close/delete are
creator/manager only.

## Project plans

`GET /project/get-plan/{project_id}/` returns the plan object. The first call
creates a `Simple` plan. `PUT /project/update-plan/{project_id}/` replaces the
whole plan and increments `version`; send the `base_version` you last read.
A stale version returns **409** — reload and merge before retrying.

`GET /project/list-plans/{workspace_id}/` powers the project portfolio
filter by plan mode. Templates are stored with `POST /project/save-template/`
and listed with `GET /project/list-templates/`. `GET /project/list-leave/`
returns leave windows for resource scheduling. See
[project_plans_docs.md](project_plans_docs.md).

## Sharing

Use `resource_type` + `resource_id` (project or task). The first
`GET /share/get-access/` creates the link token. Send one action per
`POST /share/update-access/` request (`invite`, `set_client`, `set_level`,
`remove`, `resend`, `set_link`). See [sharing_docs.md](sharing_docs.md).

## Presence

`GET /people/list-statuses/{workspace_id}/` returns every active member's
presence. `PUT /people/set-status/{workspace_id}/` sets the caller's own
status. Directory rows also include `presence`, `presence_custom` and
`presence_until`.

## Routine summaries

`GET /routine/list-summaries/{workspace_id}/?days=14` returns the daily
summary grid. IDs are `"{user_id}:{YYYY-MM-DD}"`; use that id with
`POST /routine/react-summary/{workspace_id}/{id}/` and body `{"emoji": "🔥"}`.
Only managers/admins or the person's line manager can react.

## Birthday calendar

`GET /birthday/get-calendar/{workspace_id}/` returns `{members, entries
mine_set}`. Save entries with `POST /birthday/save-entry/`, delete with
`DELETE /birthday/delete-entry/{id}/`, and toggle the “celebrated” state with
`POST /birthday/celebrate-entry/{id}/`. See
[birthday_docs.md](birthday_docs.md#birthday-calendar-entries).

## Refresh / polling guidance

| Data | Suggested refresh |
| --- | --- |
| My Day summary, task counts | 60s |
| Chat conversations/messages | 10–30s (or WebSocket/SSE when available) |
| Notifications | 60s |
| Birthday feed | 5 min |
| Space hub / family home | on focus and after each action |
| Event planner | on focus; lists refetch after each mutation |
| Church | after each action (response already contains full payload) |
| Presence | 60s |
| Public event page | 60s or on focus |

## Error handling

- **401** — expired/missing token; clear the session and go to `/signin`.
- **403** — caller is not an active member or lacks the role.
- **404** — wrong workspace/resource, or a feature is not enabled for the
  workspace kind (for example `/home/get-space/` on a business workspace,
  `/church/` outside a church workspace, `/event/` outside an event
  workspace).
- **409** — stale project plan version; reload the plan. Signup requests also
  use `409` for duplicate emails, an existing pending request, a member of
  another organization, or an unverified email at approval time.
- **422** — invalid action payload or unknown enum value; show the `detail`.
- **429** — public signup endpoints are rate-limited; honor `Retry-After`
  before retrying.
- **Public 404** — invalid/expired share token, vendor portal token or
  disabled signup link.

## Notes for the frontend

1. Business workspaces should not call `/home/*`, `/church/*` or `/event/*`.
2. Poll and space module payloads are already normalized; do not expect
   arbitrary JSON.
3. The event planner and space hub seed empty templates on first read, so an
   empty state is normal.
4. Invoice/proposal item ids come from the `invoices`/`proposals` module
   items in `GET /home/get-space/`.
5. Public RSVP and vendor brief requests must not send the `Authorization`
   header (they still work if sent, but the endpoints are public).
6. Pending signup requests are not email invites. Show them in the pending
   tab only when `is_signup_request` is `true`, and block approval until the
   person verifies their email (`is_verified: true`).
