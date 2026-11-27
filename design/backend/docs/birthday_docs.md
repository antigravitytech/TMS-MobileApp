# Birthday API Documentation

Source: `tms/birthdays/routers.py`

**Prefix:** `/birthday`

Workspace-scoped endpoints require `Authorization: Bearer <JWT>` and an
active membership of the workspace in the path. The two `my-birthday`
endpoints only require authentication.

## Privacy rule

**The year of birth is never published.** Other people's responses contain
only `day` as `MM-DD`; no endpoint that describes another person returns a
year, an age or a full date.

The full `date_of_birth` is only returned in the caller's own responses:

- `GET /birthday/get-my-birthday/`
- `PUT /birthday/set-my-birthday/` (same `MyBirthday` shape)
- the caller's own `UserPublic` (`GET /auth/get-profile/`, login responses)

`UserBrief` — the compact shape embedded across the API — never carries
`date_of_birth` or `birthday_visibility`.

## Visibility

`users.birthday_visibility` is `workspace` or `private`.

- `workspace` — colleagues are reminded on the day and see `MM-DD`.
- `private` — never announced, excluded from every feed and no reminder is
  created.

A member with `date_of_birth = null` or visibility `private` is excluded
everywhere.

## Dates and timezones

- `day` is `MM-DD` of the date of birth.
- `days_away` is the number of whole days until the next occurrence: `0` is
  today, `1` tomorrow.
- `is_today` is `days_away == 0`.
- All calculations use the **workspace timezone**.
- **29 February:** in non-leap years the birthday is celebrated on
  **1 March**. The rule is applied consistently in `days_away`, the feeds and
  the daily job. `day` still reports `02-29`.

## BirthdayPerson object

```json
{
  "user": {
    "id": "44444444-4444-4444-8444-444444444444",
    "email": "chioma@acme.com",
    "first_name": "Chioma",
    "last_name": "Okafor",
    "photo": null
  },
  "job_title": "Finance Manager",
  "day": "11-09",
  "is_today": true,
  "days_away": 0,
  "i_wished": false,
  "wish_count": 4,
  "conversation_id": "bbbbbbbb-bbbb-4bbb-8bbb-bbbbbbbbbbbb"
}
```

- `i_wished` — has the **caller** sent this person a card today?
- `wish_count` — distinct senders who have sent them a card today.
- `conversation_id` — the existing DM with them in this workspace, or `null`.
- `i_wished`, `wish_count` and `conversation_id` are scoped to the workspace
  and count cards since local midnight.

## Enumerations

| Enum | Values |
| --- | --- |
| `BirthdayVisibility` | `workspace`, `private` |
| `BirthdayTheme` | `confetti`, `balloons`, `cake`, `fireworks`, `sparkle`, `bloom` |
| `BirthdaySticker` | `cake`, `party`, `balloon`, `gift`, `sparkles`, `bouquet`, `fizz`, `heart` |

---

## GET `/birthday/get-feed/{workspace_id}/`

- **Description:** Everything the dashboard birthday strip needs in one call.
  The client polls it every five minutes.

**Sample response:** `200 OK`

```json
{
  "today": [
    {
      "user": {
        "id": "44444444-4444-4444-8444-444444444444",
        "email": "chioma@acme.com",
        "first_name": "Chioma",
        "last_name": "Okafor",
        "photo": null
      },
      "job_title": "Finance Manager",
      "day": "11-09",
      "is_today": true,
      "days_away": 0,
      "i_wished": false,
      "wish_count": 4,
      "conversation_id": "bbbbbbbb-bbbb-4bbb-8bbb-bbbbbbbbbbbb"
    }
  ],
  "upcoming": [
    {
      "user": {
        "id": "55555555-5555-4555-8555-555555555555",
        "email": "tunde@acme.com",
        "first_name": "Tunde",
        "last_name": "Bello",
        "photo": null
      },
      "job_title": "Operations Lead",
      "day": "11-12",
      "is_today": false,
      "days_away": 3,
      "i_wished": false,
      "wish_count": 0,
      "conversation_id": null
    }
  ],
  "mine_is_today": false,
  "wishes_received": 0
}
```

Rules:

- `today` — everyone celebrating today whose birthday is shared, **including
  the caller**. The client filters themselves out and greets them instead.
- `upcoming` — `days_away` 1–30, **excluding the caller**, soonest first.
- `mine_is_today` — true when the caller's birthday is today, even when the
  caller's visibility is `private`.
- `wishes_received` — distinct senders who have sent the caller a card today
  in this workspace.

---

## GET `/birthday/list-today/{workspace_id}/`

- **Description:** Everyone celebrating today.
- **Response:** **Plain array of `BirthdayPerson`** — not the envelope.

**Sample response:** `200 OK`

```json
[
  {
    "user": {
      "id": "44444444-4444-4444-8444-444444444444",
      "email": "chioma@acme.com",
      "first_name": "Chioma",
      "last_name": "Okafor",
      "photo": null
    },
    "job_title": "Finance Manager",
    "day": "11-09",
    "is_today": true,
    "days_away": 0,
    "i_wished": false,
    "wish_count": 4,
    "conversation_id": "bbbbbbbb-bbbb-4bbb-8bbb-bbbbbbbbbbbb"
  }
]
```

---

## GET `/birthday/list-upcoming/{workspace_id}/`

- **Description:** Birthdays in the next 30 days, soonest first, excluding the
  caller.
- **Response:** **Plain array of `BirthdayPerson`** — not the envelope.

**Sample response:** `200 OK`

```json
[
  {
    "user": {
      "id": "55555555-5555-4555-8555-555555555555",
      "email": "tunde@acme.com",
      "first_name": "Tunde",
      "last_name": "Bello",
      "photo": null
    },
    "job_title": "Operations Lead",
    "day": "11-12",
    "is_today": false,
    "days_away": 3,
    "i_wished": false,
    "wish_count": 0,
    "conversation_id": null
  }
]
```

---

## GET `/birthday/get-my-birthday/`

- **Description:** The caller's own birthday settings. Not workspace-scoped.
  This is one of the only places a full date is returned.
- **`next_at`:** the next occurrence in the caller's first active workspace
  (earliest membership), converted from that workspace's local midnight to
  UTC. For a UTC workspace this is UTC midnight on the birthday date; other
  zones return the UTC instant of their local midnight. `null` when no date is
  set, visibility is `private`, or the caller has no workspace.

**Sample response:** `200 OK`

```json
{
  "date_of_birth": "1995-11-09",
  "visibility": "workspace",
  "next_at": "2026-11-09T00:00:00Z"
}
```

When nothing is set:

```json
{
  "date_of_birth": null,
  "visibility": "workspace",
  "next_at": null
}
```

---

## PUT `/birthday/set-my-birthday/`

- **Description:** Set or clear the caller's date of birth and visibility.
  `date_of_birth: null` clears the date. Omitting `visibility` leaves the
  current choice unchanged.

**Payload:**

```json
{
  "date_of_birth": "1995-11-09",
  "visibility": "workspace"
}
```

**Response:** `200 OK` — same shape as `get-my-birthday`:

```json
{
  "date_of_birth": "1995-11-09",
  "visibility": "workspace",
  "next_at": "2026-11-09T00:00:00Z"
}
```

**Errors:**

- `422` — `{ "detail": "That date is in the future." }`

---

## POST `/birthday/send-wish/{user_id}/`

- **Description:** Post a birthday card as a chat message into the DM between
  the caller and `{user_id}`, creating the DM when it does not exist. Sending
  more than one card to the same person on the same day is allowed.

**Payload:**

```json
{
  "message": "Happy birthday! Hope today is a good one. 🎉",
  "theme": "confetti",
  "sticker": "cake"
}
```

All fields are optional. Defaults: `message=""`, `theme="confetti"`,
`sticker="cake"`. `message` is trimmed, may be empty and is capped at 500
characters.

**Response:** `201 Created`

```json
{
  "conversation_id": "bbbbbbbb-bbbb-4bbb-8bbb-bbbbbbbbbbbb",
  "message_id": "aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa",
  "celebrant": {
    "id": "44444444-4444-4444-8444-444444444444",
    "email": "chioma@acme.com",
    "first_name": "Chioma",
    "last_name": "Okafor",
    "photo": null
  }
}
```

What the server does:

1. Resolves a workspace shared by both users (prefers one that already has a
   DM, otherwise the earliest shared workspace).
2. Validates that the recipient is an active member, has `date_of_birth`, and
   is not `private`.
3. Finds or creates the DM using the same rules as `POST /chat/start-dm/`.
4. Creates a chat message with `type = birthday`, the caller's words in
   `body` (null when empty) and the card payload below. As with any message,
   `#PREFIX-123` references in the body are linked to tasks.
5. Creates a `chat_message` notification:
   `"{Sender name} sent you a birthday card 🎂"`, carrying the conversation id.
   As with any DM message, the notification is skipped when the recipient
   muted the conversation or chose mentions-only.

The resulting message has this payload in `ChatMessageRead`:

```json
{
  "type": "birthday",
  "body": "Happy birthday! Hope today is a good one. 🎉",
  "birthday": {
    "celebrant": {
      "id": "44444444-4444-4444-8444-444444444444",
      "email": "chioma@acme.com",
      "first_name": "Chioma",
      "last_name": "Okafor",
      "photo": null
    },
    "theme": "confetti",
    "sticker": "cake",
    "day": "11-09"
  }
}
```

Message previews in conversation lists and notifications read
`"🎂 Birthday card"`.

**Errors:**

- `422` — `{ "detail": "That person has not shared a birthday." }` when the
  recipient is not a shared active member, has no date of birth or is
  `private`.
- `422` — `{ "detail": "You can't send yourself a birthday card." }`

---

## Automatic reminder

A Celery beat job (`send-birthday-reminders`) runs hourly. For each
workspace, at the hour of its `working_hours_start` (default `09:00`) in the
workspace's timezone, it creates a notification for **every other active
member** of every visible celebrant:

```json
{
  "kind": "birthday_today",
  "message": "Chioma Okafor is celebrating a birthday today. Send them a card!",
  "actor": {
    "id": "44444444-4444-4444-8444-444444444444",
    "email": "chioma@acme.com",
    "first_name": "Chioma",
    "last_name": "Okafor",
    "photo": null
  },
  "celebrant_id": "44444444-4444-4444-8444-444444444444",
  "task_id": null
}
```

Idempotency is enforced per
`(workspace, recipient, celebrant, workspace-local date)`, so re-running the
job never produces a duplicate. The celebrant never receives a notification
about their own birthday, and `private` birthdays produce none.

To send a card from a notification, the client calls
`POST /chat/start-dm/{workspace_id}/` with `celebrant_id` as the target.

---

## Birthday calendar entries

Workspace birthday feeds cover app users. The calendar page also supports
manually added birthdays (family, friends, clients, church members) that do
not have a user account.

### Entry object

```json
{
  "id": "11111111-1111-4111-8111-111111111111",
  "name": "Mama Bisi",
  "day": "03-14",
  "year": 1962,
  "relation": "family",
  "phone": "+2348000000000",
  "note": "Loves ofada rice",
  "remind_days": 3,
  "added_by": {"id": "...", "email": "...", "first_name": "...", "last_name": "...", "photo": null},
  "is_mine": true,
  "is_today": false,
  "days_away": 115,
  "turning": 64,
  "celebrated": false
}
```

`relation` is `family`, `friend`, `colleague`, `client`, `church` or `other`.
Entries are private to the person who added them.

### GET `/birthday/get-calendar/{workspace_id}/`

```json
{
  "members": [],
  "entries": [],
  "mine_set": true
}
```

`members` uses the `BirthdayPerson` shape; `entries` uses the entry shape.

### POST `/birthday/save-entry/{workspace_id}/`

```json
{
  "id": null,
  "name": "Mama Bisi",
  "month": 3,
  "date": 14,
  "year": 1962,
  "relation": "family",
  "phone": "+2348000000000",
  "note": "Loves ofada rice",
  "remind_days": 3
}
```

Sending an existing `id` updates the entry. Returns the saved entry.

### DELETE `/birthday/delete-entry/{entry_id}/`

Only the person who added the entry can delete it.

### POST `/birthday/celebrate-entry/{entry_id}/`

Toggles this year's `celebrated` flag and returns the entry.

The daily `send_birthday_reminders` job also creates reminders for calendar
entries when `remind_days` is reached and again on the day.
