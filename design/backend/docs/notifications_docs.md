# Notification API Documentation

Source: `tms/notifications/routers.py`

**Prefix:** `/notification`

All endpoints require `Authorization: Bearer <JWT>` and an active workspace
membership.

## Notification kinds

| Kind | Category | Created when |
| --- | --- | --- |
| `task_assigned` | other | A task is created for an assignee, or reassigned |
| `task_submitted` | reviews | An assignee submits or resubmits for review |
| `task_returned` | reviews | An approver returns a submission |
| `task_approved` | reviews | An approver approves a submission |
| `task_due_date_changed` | other | A target date changes |
| `task_comment` | mentions | A watched task receives a comment |
| `task_mention` | mentions | A comment explicitly mentions a member |
| `task_access_request` | other | A member requests confidential-task access |
| `task_access_granted` | other | Access is granted |
| `invite_accepted` | other | An invited person accepts |
| `invite_requested` | other | An invitee requests a fresh invite |
| `routine_log_submitted` | other | A routine report is submitted |
| `routine_log_reviewed` | other | A routine report is reviewed |
| `routine_due` | other | A routine is due |
| `chat_message` | chat | A new message arrives in a DM, group chat or task conversation |
| `chat_mention` | mentions | A chat message explicitly mentions a member |
| `chat_request` | chat | Someone sends the first message in an external DM |
| `chat_request_accepted` | chat | The recipient accepts an external chat request |
| `birthday_today` | other | A colleague is celebrating a birthday today |
| `attendance_late_limit` | other | A member exceeds the workspace's lateness limit for the period |
| `guest_arrived` | other | A visitor pass guest arrives, or reception pings them again |
| `guest_hold_over` | other | A visitor pass hold reaches its `hold_until` |
| `daily_digest` | other | Digest marker |

Visitor notifications go to the pass host, or to every receiver of the
pass's desk when there is no host. Tapping `guest_arrived` or
`guest_hold_over` opens `/guests/my-guests`.

Actors never receive notifications for their own actions. Every event is
in-app by default. Email delivery is opt-in per event through preferences.
Mentions are delivered even when the mentioned member is not a watcher, but
only to members who can view the task. The daily digest uses each workspace's
timezone to match `digest_time`; when no explicit `digest` preference row
exists, email follows `digest_enabled`.

Chat mentions use the existing `mention` preference. Other chat messages in
DMs, group chats and task conversations use the `chat` preference and are
skipped when the recipient muted the conversation or chose mentions-only.
Standard-channel chatter only raises unread badges. Chat notifications include
`conversation_id`, `conversation_kind`, `conversation_title` and
`conversation_workspace_id`.

External chat participants are not workspace members, so their notifications
are stored in their **primary workspace**: the first workspace they own,
otherwise their earliest active membership. For those rows `workspace_id` is
the notification workspace, while `conversation_workspace_id` is the workspace
that stores the external conversation. Messages written before an external
request is accepted do not create `chat_message` notifications; the first
message creates `chat_request` instead. Accepting creates
`chat_request_accepted` for the requester.

`birthday_today` notifications use the `birthday` preference and carry
`celebrant_id` (null on every other kind). They are created once per
`(workspace, recipient, celebrant, workspace-local date)` by the daily job, so
re-running the job never duplicates them. The celebrant is never notified
about their own birthday, and `private` birthdays produce no notifications.

## Pagination

List endpoints return:

```json
{
  "items": [],
  "total": 0,
  "page": 1,
  "page_size": 20,
  "total_pages": 0
}
```

---

## GET `/notification/list-notifications/{workspace_id}/`

- **Description:** List the current user's notifications in a workspace.
- **Query:**
  - `unread_only` (default `false`)
  - `kind` — one of the notification kinds
  - `category` — `mentions`, `reviews` or `chat`
  - `page` (default 1)
  - `page_size` (default 20, max 100)

**Sample response item:**

```json
{
  "id": "bbbbbbbb-bbbb-4bbb-8bbb-bbbbbbbbbbbb",
  "workspace_id": "22222222-2222-4222-8222-222222222222",
  "kind": "task_submitted",
  "message": "Tunde Bakare submitted 'Payment webhook retry handler' for review.",
  "actor": {
    "id": "44444444-4444-4444-8444-444444444444",
    "email": "tunde@example.com",
    "first_name": "Tunde",
    "last_name": "Bakare",
    "photo": null
  },
  "task_id": "11111111-1111-4111-8111-111111111111",
  "task_reference": "TK-142",
  "task_title": "Payment webhook retry handler",
  "conversation_id": null,
  "conversation_kind": null,
  "conversation_title": null,
  "conversation_workspace_id": null,
  "celebrant_id": null,
  "is_read": false,
  "read_at": null,
  "created_at": "2026-10-23T10:00:00Z",
  "updated_at": "2026-10-23T10:00:00Z"
}
```

---

## GET `/notification/get-unread-count/{workspace_id}/`

```json
{ "unread": 3 }
```

---

## POST `/notification/mark-read/{notification_id}/`

- **Description:** Mark one of the current user's notifications as read.
- **Response:**

```json
{ "message": "Notification marked as read." }
```

Returns `404` when the notification does not belong to the current user.

---

## POST `/notification/mark-all-read/{workspace_id}/`

- **Description:** Mark every notification in the workspace as read.
- **Response:**

```json
{ "message": "All notifications marked as read." }
```

---

## GET `/notification/get-preferences/{workspace_id}/`

- **Description:** Return the notification matrix and digest settings.

```json
{
  "events": [
    { "event": "assigned", "in_app": true, "email": true },
    { "event": "submitted", "in_app": true, "email": true },
    { "event": "returned", "in_app": true, "email": true },
    { "event": "approved", "in_app": true, "email": false },
    { "event": "date", "in_app": true, "email": true },
    { "event": "mention", "in_app": true, "email": false },
    { "event": "access", "in_app": true, "email": false },
    { "event": "invite", "in_app": true, "email": true },
    { "event": "routine", "in_app": true, "email": false },
    { "event": "chat", "in_app": true, "email": false },
    { "event": "digest", "in_app": false, "email": true },
    { "event": "reminder", "in_app": true, "email": true },
    { "event": "birthday", "in_app": true, "email": false }
  ],
  "digest_enabled": true,
  "digest_time": "09:00"
}
```

## PUT `/notification/update-preferences/{workspace_id}/`

- **Description:** Upsert event preferences and optional digest settings.

```json
{
  "events": [
    { "event": "assigned", "in_app": true, "email": true },
    { "event": "mention", "in_app": true, "email": false }
  ],
  "digest_enabled": true,
  "digest_time": "08:00"
}
```

Returns the full preferences object.

## Email delivery and digests

When `email` is enabled for an event, the notification is also enqueued to
the `notifications.tasks.send_notification_email` Celery task. A daily digest
is sent by `notifications.tasks.send_daily_digests`, which runs hourly and
matches each user's `digest_time` hour in the workspace timezone. Setting
`digest_enabled` to
`false` suppresses it.

Task due reminders are sent by `tasks.tasks.send_task_due_reminders`, which
runs hourly and matches each workspace's `working_hours_start` hour in its
local timezone. The `reminder` preference defaults to email-on; setting its
`email` to `false` suppresses the reminder for that workspace. Reminders are
email-only and do not create an in-app notification row. Each user receives
one consolidated email per workspace per day for tasks due tomorrow that are
not submitted or completed.


---

## v4 notification kinds

| Kind | When |
| --- | --- |
| `school_item` | A school diary item is created or updated for a checker |
| `routine_summary_reaction` | Someone reacts to your daily summary |
| `birthday_calendar` | A manually added birthday reminder is due |
| `event_rsvp` | Reserved for public RSVP notifications |

These map to the existing preference events `reminder`, `routine`, `birthday`
and `other` respectively.
