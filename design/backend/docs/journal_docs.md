# Journal API Documentation

Source: `tms/notes/routers.py`

**Prefix:** `/note`

All endpoints require `Authorization: Bearer <JWT>` and an active membership
of the workspace in the path (or the workspace that owns the note).

## Privacy rule

**A note belongs to its author and nobody else.** There is no sharing,
visibility field or permissions object. Every single-note endpoint resolves
the note by **id *and* `owner_id = current_user`** and answers
`404 "Note not found."` when it does not match — never `403`. That is
deliberate: a `403` would confirm the note exists.

List endpoints only ever return the caller's notes. Workspace owners,
admins and managers have no access to anyone else's journal.

## Enumerations

| Enum | Values |
| --- | --- |
| `NoteColor` | `slate`, `amber`, `rose`, `violet`, `teal`, `sky`, `lime` |
| `NoteState` | `active`, `archived`, `trashed` |
| `NoteAlarm` | `ring`, `voice` |
| `NoteReminderState` | `none`, `scheduled`, `fired`, `done` |

`color` is a name, never a hex value. `alarm` tells the client how to
announce a reminder; the server only stores and returns it.

## Ordering and pagination

Every note list is ordered **pinned first, then `updated_at` descending**:

```sql
ORDER BY pinned DESC, updated_at DESC
```

List endpoints return:

```json
{
  "items": [],
  "total": 0,
  "page": 1,
  "page_size": 60,
  "total_pages": 0
}
```

`GET /note/list-due-reminders/{workspace_id}/` is a **plain array**, not the
envelope.

## Note response object

Every endpoint that returns a note returns all of these fields:

```json
{
  "id": "8f2a1c3e-4b5d-4e6f-8a9b-0c1d2e3f4a5b",
  "workspace_id": "22222222-2222-4222-8222-222222222222",
  "owner_id": "33333333-3333-4333-8333-333333333333",
  "title": "Call the supplier back",
  "body": "They want the revised quantities before the end of the week.",
  "color": "rose",
  "pinned": false,
  "state": "active",
  "remind_at": "2026-11-09T15:30:00Z",
  "alarm": "voice",
  "reminder_state": "scheduled",
  "reminded_at": null,
  "trashed_at": null,
  "purge_at": null,
  "archived_at": null,
  "created_at": "2026-11-09T09:12:00Z",
  "updated_at": "2026-11-09T14:48:00Z"
}
```

---

## GET `/note/list-notes/{workspace_id}/`

- **Description:** List one shelf of the caller's private journal.
- **Query:**

| Param | Type | Default | Notes |
| --- | --- | --- | --- |
| `page` | int | `1` | 1-based |
| `page_size` | int | `60` | max 100 |
| `state` | `NoteState` | `active` | which shelf |
| `pinned_only` | bool | – | only pinned notes |
| `has_reminder` | bool | – | `true`: reminder not `done`; `false`: no reminder or `done` |
| `color` | `NoteColor` | – | filter by paper colour |
| `search` | string | – | case-insensitive substring of `title` or `body` |

**Sample request:**

```http
GET /note/list-notes/22222222-2222-4222-8222-222222222222/?state=active&page_size=60
```

**Sample response:** `200 OK`

```json
{
  "items": [
    {
      "id": "8f2a1c3e-4b5d-4e6f-8a9b-0c1d2e3f4a5b",
      "workspace_id": "22222222-2222-4222-8222-222222222222",
      "owner_id": "33333333-3333-4333-8333-333333333333",
      "title": "Call the supplier back",
      "body": "They want the revised quantities before the end of the week.",
      "color": "rose",
      "pinned": true,
      "state": "active",
      "remind_at": "2026-11-09T15:30:00Z",
      "alarm": "voice",
      "reminder_state": "scheduled",
      "reminded_at": null,
      "trashed_at": null,
      "purge_at": null,
      "archived_at": null,
      "created_at": "2026-11-09T09:12:00Z",
      "updated_at": "2026-11-09T14:48:00Z"
    }
  ],
  "total": 1,
  "page": 1,
  "page_size": 60,
  "total_pages": 1
}
```

---

## GET `/note/get-summary/{workspace_id}/`

- **Description:** Counts for the journal's tabs. Also fires any overdue
  reminder before counting it.

**Sample response:** `200 OK`

```json
{
  "active": 12,
  "pinned": 2,
  "reminders": 3,
  "archived": 5,
  "trashed": 1,
  "ringing": 1
}
```

Counters:

- `active` — `state = active`
- `pinned` — `state = active AND pinned`
- `reminders` — `state = active AND remind_at IS NOT NULL AND reminder_state != done`
- `archived` — `state = archived`
- `trashed` — `state = trashed`
- `ringing` — `state = active AND reminder_state = fired`

---

## GET `/note/list-due-reminders/{workspace_id}/`

- **Description:** Notes that should ring now. The client polls this every
  20 seconds and sounds the alarm for the first item. Overdue scheduled
  reminders are flipped to `fired` before the query.
- **Response:** **Plain array of `Note`** — not the envelope.

**Sample response:** `200 OK`

```json
[
  {
    "id": "8f2a1c3e-4b5d-4e6f-8a9b-0c1d2e3f4a5b",
    "workspace_id": "22222222-2222-4222-8222-222222222222",
    "owner_id": "33333333-3333-4333-8333-333333333333",
    "title": "Call the supplier back",
    "body": "",
    "color": "rose",
    "pinned": false,
    "state": "active",
    "remind_at": "2026-11-09T15:30:00Z",
    "alarm": "ring",
    "reminder_state": "fired",
    "reminded_at": "2026-11-09T15:30:04Z",
    "trashed_at": null,
    "purge_at": null,
    "archived_at": null,
    "created_at": "2026-11-09T09:12:00Z",
    "updated_at": "2026-11-09T14:48:00Z"
  }
]
```

---

## POST `/note/create-note/{workspace_id}/`

- **Description:** Create a note owned by the caller. Sets `state = active`
  and `owner_id` from the token. If `remind_at` is present,
  `reminder_state = scheduled`; otherwise `none`.
- **Status Code:** `201 Created`

**Payload:**

```json
{
  "title": "Call the supplier back",
  "body": "They want the revised quantities before the end of the week.",
  "color": "rose",
  "pinned": false,
  "remind_at": "2026-11-09T15:30:00Z",
  "alarm": "voice"
}
```

All fields are optional. Defaults: `title=""`, `body=""`, `color="amber"`,
`pinned=false`, `remind_at=null`, `alarm="ring"`.

**Response:** `201 Created` with the full `Note` object:

```json
{
  "id": "8f2a1c3e-4b5d-4e6f-8a9b-0c1d2e3f4a5b",
  "workspace_id": "22222222-2222-4222-8222-222222222222",
  "owner_id": "33333333-3333-4333-8333-333333333333",
  "title": "Call the supplier back",
  "body": "They want the revised quantities before the end of the week.",
  "color": "rose",
  "pinned": false,
  "state": "active",
  "remind_at": "2026-11-09T15:30:00Z",
  "alarm": "voice",
  "reminder_state": "scheduled",
  "reminded_at": null,
  "trashed_at": null,
  "purge_at": null,
  "archived_at": null,
  "created_at": "2026-11-09T09:12:00Z",
  "updated_at": "2026-11-09T09:12:00Z"
}
```

**Errors:**

- `422` — `{ "detail": "Pick a time in the future." }` when `remind_at` is
  not in the future.

---

## POST `/note/empty-trash/{workspace_id}/`

- **Description:** Permanently delete **all** of the caller's trashed notes in
  this workspace.

**Payload:** none.

**Response:** `200 OK`

```json
{ "message": "3 notes deleted." }
```

One deleted note reads `"1 note deleted."`; an empty trash reads
`"0 notes deleted."`.

---

## GET `/note/get-note/{note_id}/`

- **Description:** Return one of the caller's notes.
- **Response:** `200 OK` with the full `Note` object (see the shape above).

**Errors:**

- `404` — `{ "detail": "Note not found." }` when the note does not exist or
  is not owned by the caller.
- `403` — `{ "detail": "Not a member of this workspace." }` when the caller
  has left the note's workspace.

---

## PATCH `/note/update-note/{note_id}/`

- **Description:** Partial autosave. Only keys present in the body change.
  Bumps `updated_at`.
- **Status Code:** `200 OK`

**Payload:**

```json
{
  "title": "Call the supplier back",
  "body": "They want the revised quantities before the end of the week.",
  "color": "teal",
  "pinned": true
}
```

Any subset may be sent. `title` is trimmed.

**Response:** `200 OK` with the full updated `Note` object:

```json
{
  "id": "8f2a1c3e-4b5d-4e6f-8a9b-0c1d2e3f4a5b",
  "workspace_id": "22222222-2222-4222-8222-222222222222",
  "owner_id": "33333333-3333-4333-8333-333333333333",
  "title": "Call the supplier back",
  "body": "They want the revised quantities before the end of the week.",
  "color": "teal",
  "pinned": true,
  "state": "active",
  "remind_at": null,
  "alarm": "ring",
  "reminder_state": "none",
  "reminded_at": null,
  "trashed_at": null,
  "purge_at": null,
  "archived_at": null,
  "created_at": "2026-11-09T09:12:00Z",
  "updated_at": "2026-11-09T14:48:00Z"
}
```

**Errors:**

- `404` — `{ "detail": "Note not found." }`
- `409` — `{ "detail": "Restore this note before editing it." }` when the
  note is in the trash.

---

## POST `/note/pin-note/{note_id}/`

- **Description:** Pin or unpin a note. Allowed on archived notes. Bumps
  `updated_at`.

**Payload:**

```json
{ "pinned": true }
```

**Response:** `200 OK` with the full `Note` object, for example:

```json
{
  "id": "8f2a1c3e-4b5d-4e6f-8a9b-0c1d2e3f4a5b",
  "workspace_id": "22222222-2222-4222-8222-222222222222",
  "owner_id": "33333333-3333-4333-8333-333333333333",
  "title": "Call the supplier back",
  "body": "",
  "color": "rose",
  "pinned": true,
  "state": "active",
  "remind_at": null,
  "alarm": "ring",
  "reminder_state": "none",
  "reminded_at": null,
  "trashed_at": null,
  "purge_at": null,
  "archived_at": null,
  "created_at": "2026-11-09T09:12:00Z",
  "updated_at": "2026-11-09T14:48:00Z"
}
```

**Errors:**

- `404` — `{ "detail": "Note not found." }`
- `409` — `{ "detail": "Restore this note before editing it." }` when the
  note is in the trash.

---

## POST `/note/archive-note/{note_id}/`

- **Description:** Archive a note or move it back to the journal.

**Payload:**

```json
{ "archived": true }
```

- `true` → `state = archived`, `archived_at = now`, **and `pinned = false`**.
- `false` → `state = active`, `archived_at = null`.

**Response:** `200 OK` with the full `Note` object, for example:

```json
{
  "id": "8f2a1c3e-4b5d-4e6f-8a9b-0c1d2e3f4a5b",
  "workspace_id": "22222222-2222-4222-8222-222222222222",
  "owner_id": "33333333-3333-4333-8333-333333333333",
  "title": "Old meeting notes",
  "body": "",
  "color": "slate",
  "pinned": false,
  "state": "archived",
  "remind_at": null,
  "alarm": "ring",
  "reminder_state": "none",
  "reminded_at": null,
  "trashed_at": null,
  "purge_at": null,
  "archived_at": "2026-11-09T14:48:00Z",
  "created_at": "2026-11-01T09:12:00Z",
  "updated_at": "2026-11-09T14:48:00Z"
}
```

**Errors:**

- `404` — `{ "detail": "Note not found." }`
- `409` — `{ "detail": "Restore this note from the trash first." }` when the
  note is in the trash.

---

## POST `/note/trash-note/{note_id}/`

- **Description:** Soft-delete a note for seven days. No request body.

**Response:** `200 OK` with the full `Note` object:

```json
{
  "id": "8f2a1c3e-4b5d-4e6f-8a9b-0c1d2e3f4a5b",
  "workspace_id": "22222222-2222-4222-8222-222222222222",
  "owner_id": "33333333-3333-4333-8333-333333333333",
  "title": "Draft agenda",
  "body": "",
  "color": "teal",
  "pinned": false,
  "state": "trashed",
  "remind_at": null,
  "alarm": "ring",
  "reminder_state": "none",
  "reminded_at": null,
  "trashed_at": "2026-11-09T14:48:00Z",
  "purge_at": "2026-11-16T14:48:00Z",
  "archived_at": null,
  "created_at": "2026-11-01T09:12:00Z",
  "updated_at": "2026-11-09T14:48:00Z"
}
```

**Errors:**

- `404` — `{ "detail": "Note not found." }`

---

## POST `/note/restore-note/{note_id}/`

- **Description:** Restore a trashed note into the journal. Clears
  `trashed_at`, `purge_at` **and `archived_at`**. No request body.

**Response:** `200 OK` with the full `Note` object:

```json
{
  "id": "8f2a1c3e-4b5d-4e6f-8a9b-0c1d2e3f4a5b",
  "workspace_id": "22222222-2222-4222-8222-222222222222",
  "owner_id": "33333333-3333-4333-8333-333333333333",
  "title": "Draft agenda",
  "body": "",
  "color": "teal",
  "pinned": false,
  "state": "active",
  "remind_at": null,
  "alarm": "ring",
  "reminder_state": "none",
  "reminded_at": null,
  "trashed_at": null,
  "purge_at": null,
  "archived_at": null,
  "created_at": "2026-11-01T09:12:00Z",
  "updated_at": "2026-11-09T14:48:00Z"
}
```

**Errors:**

- `404` — `{ "detail": "Note not found." }`
- `409` — `{ "detail": "That note is not in the trash." }`

---

## DELETE `/note/delete-note/{note_id}/`

- **Description:** Permanently delete a note. Only allowed from the trash, so
  nothing can be destroyed in a single click. No request body.

**Response:** `200 OK`

```json
{ "message": "Note deleted." }
```

**Errors:**

- `404` — `{ "detail": "Note not found." }`
- `409` — `{ "detail": "Move the note to the trash before deleting it." }`

---

## PUT `/note/set-reminder/{note_id}/`

- **Description:** Schedule a reminder. Sets `reminder_state = scheduled` and
  clears `reminded_at`.

**Payload:**

```json
{
  "remind_at": "2026-11-10T09:00:00Z",
  "alarm": "voice"
}
```

`alarm` defaults to `ring`.

**Response:** `200 OK` with the full `Note` object:

```json
{
  "id": "8f2a1c3e-4b5d-4e6f-8a9b-0c1d2e3f4a5b",
  "workspace_id": "22222222-2222-4222-8222-222222222222",
  "owner_id": "33333333-3333-4333-8333-333333333333",
  "title": "Call the supplier back",
  "body": "",
  "color": "rose",
  "pinned": true,
  "state": "active",
  "remind_at": "2026-11-10T09:00:00Z",
  "alarm": "voice",
  "reminder_state": "scheduled",
  "reminded_at": null,
  "trashed_at": null,
  "purge_at": null,
  "archived_at": null,
  "created_at": "2026-11-09T09:12:00Z",
  "updated_at": "2026-11-09T14:48:00Z"
}
```

**Errors:**

- `404` — `{ "detail": "Note not found." }`
- `422` — `{ "detail": "Pick a time in the future." }`

---

## DELETE `/note/clear-reminder/{note_id}/`

- **Description:** Remove a reminder. Sets `remind_at = null`,
  `alarm = ring`, `reminder_state = none`, `reminded_at = null`. No request
  body.

**Response:** `200 OK` with the full `Note` object:

```json
{
  "id": "8f2a1c3e-4b5d-4e6f-8a9b-0c1d2e3f4a5b",
  "workspace_id": "22222222-2222-4222-8222-222222222222",
  "owner_id": "33333333-3333-4333-8333-333333333333",
  "title": "Call the supplier back",
  "body": "",
  "color": "rose",
  "pinned": true,
  "state": "active",
  "remind_at": null,
  "alarm": "ring",
  "reminder_state": "none",
  "reminded_at": null,
  "trashed_at": null,
  "purge_at": null,
  "archived_at": null,
  "created_at": "2026-11-09T09:12:00Z",
  "updated_at": "2026-11-09T14:48:00Z"
}
```

**Errors:**

- `404` — `{ "detail": "Note not found." }`

---

## POST `/note/dismiss-reminder/{note_id}/`

- **Description:** Stop a ringing reminder. Sets `reminder_state = done` and
  keeps `remind_at` as history. Dismissing an already-dismissed reminder is
  idempotent; a reminder that is `none` or `scheduled` is not ringing. No
  request body.

**Response:** `200 OK` with the full `Note` object:

```json
{
  "id": "8f2a1c3e-4b5d-4e6f-8a9b-0c1d2e3f4a5b",
  "workspace_id": "22222222-2222-4222-8222-222222222222",
  "owner_id": "33333333-3333-4333-8333-333333333333",
  "title": "Call the supplier back",
  "body": "",
  "color": "rose",
  "pinned": true,
  "state": "active",
  "remind_at": "2026-11-10T09:00:00Z",
  "alarm": "voice",
  "reminder_state": "done",
  "reminded_at": "2026-11-10T09:00:03Z",
  "trashed_at": null,
  "purge_at": null,
  "archived_at": null,
  "created_at": "2026-11-09T09:12:00Z",
  "updated_at": "2026-11-10T09:00:03Z"
}
```

**Errors:**

- `404` — `{ "detail": "Note not found." }`
- `409` — `{ "detail": "That reminder is not ringing." }` when the reminder is
  not `fired`.

---

## POST `/note/snooze-reminder/{note_id}/`

- **Description:** Push a ringing reminder forward. Sets
  `remind_at = now + snooze_minutes`, `reminder_state = scheduled`,
  `reminded_at = null`. Only a `fired` reminder can be snoozed.

**Payload:**

```json
{ "snooze_minutes": 15 }
```

`snooze_minutes` must be an integer from `1` to `10080` (one week).

**Response:** `200 OK` with the full `Note` object:

```json
{
  "id": "8f2a1c3e-4b5d-4e6f-8a9b-0c1d2e3f4a5b",
  "workspace_id": "22222222-2222-4222-8222-222222222222",
  "owner_id": "33333333-3333-4333-8333-333333333333",
  "title": "Call the supplier back",
  "body": "",
  "color": "rose",
  "pinned": true,
  "state": "active",
  "remind_at": "2026-11-10T09:15:00Z",
  "alarm": "voice",
  "reminder_state": "scheduled",
  "reminded_at": null,
  "trashed_at": null,
  "purge_at": null,
  "archived_at": null,
  "created_at": "2026-11-09T09:12:00Z",
  "updated_at": "2026-11-10T09:00:03Z"
}
```

**Errors:**

- `404` — `{ "detail": "Note not found." }`
- `409` — `{ "detail": "That reminder is not ringing." }` when the reminder is
  not `fired`.
- `422` — `{ "detail": "Choose how long to snooze for." }`

---

## Background jobs

| Beat name | Schedule | Behaviour |
| --- | --- | --- |
| `fire-note-reminders` | every minute | `scheduled` → `fired` when `remind_at <= now`; archived and trashed notes are ignored |
| `purge-trashed-notes` | daily at 03:00 UTC | permanently deletes rows where `state = trashed AND purge_at <= now` |

The reminder job is also applied lazily by `get-summary` and
`list-due-reminders`, so polling stays correct even if a beat tick is missed.
