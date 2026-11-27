# Visitors API Documentation

Source: `tms/visitors/routers.py`

**Prefix:** `/visitor`

For the screen-by-screen client guide, see
[`visitors_changes_integration.md`](visitors_changes_integration.md).

Visitors is the pass-based flow that sits alongside the legacy guest
check-in module (`/guest-checkin/…`, see
[`guest_checkin_docs.md`](guest_checkin_docs.md)). The legacy endpoints and
tables remain live while the frontend migrates.

A **desk** is a place guests are going: Finance, a house, a gate, a pastor's
office. A **pass** is one guest or party invited to a desk. The guest or
reception arrives the pass, the host (or the desk's receivers) admits,
holds or declines it, and the desk sends the guest in and later marks them
gone.

## Conventions

- Every route except the two public routes requires
  `Authorization: Bearer <JWT>` and an active workspace membership.
- `{workspace_id}` is the workspace UUID; the design's `{ws}`.
- Trailing slashes are required.
- `list-desks` and `list-passes` return a **plain JSON array**. They are not
  wrapped in the pagination envelope.
- Timestamps are ISO 8601 with an offset. Dates are `yyyy-MM-dd`.
- People are returned as `UserBrief`: `{id, email, first_name, last_name,
  photo}`.
- Errors are `{ "detail": "Human sentence." }`. The client shows `detail`
  verbatim.

## Roles

Visitors reuses the legacy guest-attendance roles on the workspace
membership, so no new role column is needed:

| Capability | Who |
| --- | --- |
| Create an invitation | Any active member |
| Create a walk-in (`arrived: true`) | Front desk |
| Find a pass by code | Front desk |
| `list-passes?scope=desk` | Front desk |
| List desks | Any active member |
| Save/delete desks | Owner or admin |
| Answer a pass (`admit`, `hold`, `decline`) | The pass host, or a receiver of the pass's desk |
| Arrive, ping, send in, leave | Front desk, or the pass host/receiver |
| Cancel | The host/receiver, the creator, or the front desk |

**Front desk** means owner, admin, or a member whose legacy
`guest_checkin_role` is `security` or `reception`.

`GET /guest-checkin/my-access/{workspace_id}/` remains the source of the
page-level `can_view` and `can_manage_settings` flags. The new pass routes
use the same roles server-side.

## Status lifecycle

```
host invite ─→ expected ─(arrive)─→ waiting ─(admit)─→ admitted ─(inside)─→ inside ─(leave)─→ left
walk-in ────────┘                  │
                                   ├─(hold N)─→ on_hold ─(timer ends)─→ hold_over
                                   │                └─(ping)───────────→ waiting
                                   └─(decline)────→ declined
any open pass ─(cancel)─→ cancelled
unresolved pass whose day passed ─→ expired
```

`hold_over` is **derived**, never stored: a pass with status `on_hold` whose
`hold_until` is in the past is returned as `hold_over`. The first time that
happens the server adds a `hold_over` event and sends `guest_hold_over` once.

Stored statuses: `expected`, `waiting`, `admitted`, `on_hold`, `inside`,
`declined`, `left`, `expired`, `cancelled`.

Event actions: `issued`, `arrive`, `admit`, `hold`, `hold_over`, `decline`,
`ping`, `inside`, `leave`, `cancel`, `expired`.

## Default desks

Desks are created lazily on the first `GET list-desks`. The defaults are
seeded once per workspace: deleting or renaming a seeded desk is permanent
and does not cause it to reappear. One desk is marked `is_default`; it cannot
be deleted until another desk is made default.

| Workspace type | Default desks (code) |
| --- | --- |
| business | Front office (GEN), Finance (FIN), Logistics (LOG), Human resources (HR) |
| estate | Estate office (EST), Block A residents (BLA), Block B residents (BLB) |
| church | Pastor's office (PAS), Church admin (ADM) |
| family | Home (HOM) |
| event | Main gate (GAT), VIP & family table (VIP) |
| club / alumni / committee | Front desk (DSK) |
| individual | Meetings with me (MTG) |
| anything else | Front desk (DSK) |

The first desk receives every owner/admin. Extra desks receive one active
member where possible, falling back to the managers. Individual workspaces
give the single desk to the owner.

## Desks

### GET `/visitor/list-desks/{workspace_id}/`

Any active member. Returns a **plain array**.

```json
[
  {
    "id": "4f1a0dfa-4f6e-4d0e-9f3d-2f7a57f2f4e1",
    "name": "Front office",
    "code": "GEN",
    "directions": "Ground floor, reception",
    "receivers": [
      {
        "id": "9d0c4c6d-0b1f-4a3c-8d6f-9f0f6a2c1b7e",
        "email": "ada@example.com",
        "first_name": "Ada",
        "last_name": "Obi",
        "photo": null
      }
    ],
    "is_default": true
  }
]
```

### PUT `/visitor/save-desk/{workspace_id}/`

Owner/admin only. `id: null` creates a desk; an existing id edits it.
Response is `null`.

```json
{
  "id": null,
  "name": "Finance",
  "code": "FIN",
  "directions": "3rd floor, room 4",
  "is_default": false,
  "receiver_ids": ["9d0c4c6d-0b1f-4a3c-8d6f-9f0f6a2c1b7e"]
}
```

Validation:

- `name` 2–60 characters; `code` 2–4 letters, stored uppercase.
- `directions` up to 140 characters.
- At least one `receiver_ids` entry; every id must be an active member.
- Duplicate active code → `409 "FIN is already used by another desk."`
- Setting `is_default: true` clears the flag on every other desk.
- Editing the current default with `is_default: false` keeps it default,
  because a workspace must always have exactly one.

Errors:

| Status | Detail |
| --- | --- |
| 403 | `Only owners and admins can set up desks.` |
| 404 | `Desk not found.` |
| 409 | `{code} is already used by another desk.` |

### DELETE `/visitor/delete-desk/{workspace_id}/{desk_id}/`

Owner/admin only. Soft-deletes the desk. Response is `null`.

- Deleting the default desk → `409 "Make another desk the default first."`
- Any pass on the desk still in `expected`, `waiting`, `admitted`,
  `on_hold` or `inside` → `409 "This desk has guests today. Close their
  passes first."`
- Closed passes keep their desk details.

## Passes

### POST `/visitor/create-pass/{workspace_id}/`

Any active member. A walk-in (`arrived: true`) is front desk only.

```json
{
  "guest_name": "John Okafor",
  "guest_phone": "+2348031234567",
  "party_size": 1,
  "purpose": "Interview",
  "desk_id": "4f1a0dfa-4f6e-4d0e-9f3d-2f7a57f2f4e1",
  "host_id": null,
  "valid_on": "2026-11-23",
  "arrived": false
}
```

Validation:

- `guest_name` 2–80; `guest_phone` up to 20; `party_size` 1–50.
- `purpose` up to 140; `note` on actions up to 200.
- `desk_id` must be an active desk in the workspace.
- `host_id` must be an active member. When omitted and `arrived` is false,
  the creator becomes the host.
- A walk-in must use today's local date. A future date returns
  `409 "This pass is for 2026-11-23."`

The code is always `{desk.code}-{4 characters}`. Characters skip `0/O` and
`1/I`. Codes are globally unique because the public route only receives the
code.

Creates an `issued` event. A walk-in also immediately runs `arrive`, so the
first two events are `issued`, `arrive`. Status: `expected` for an
invitation, `waiting` for a walk-in.

Response: `VisitPass`, status `201`.

Errors:

| Status | Detail |
| --- | --- |
| 403 | `Only the front desk can let walk-ins in.` |
| 404 | `Desk not found.` |
| 409 | `This pass is for {date}.` |
| 422 | `Choose a valid host.` |

### GET `/visitor/find-pass/{workspace_id}/?code=`

Front desk only. Accepts codes in any case, with or without the dash:
`fin4k7q` → `FIN-4K7Q`.

Errors:

| Status | Detail |
| --- | --- |
| 403 | `Only the front desk can look up codes.` |
| 404 | `No pass with that code. Check it with the guest.` |

### GET `/visitor/list-passes/{workspace_id}/?scope=mine|desk&date=yyyy-MM-dd`

**Plain array**, newest arrival first. `date` defaults to today in the
workspace timezone.

- `scope=mine` (default): passes for `date`, **plus** future `expected`
  passes, where the caller is the host, a receiver of the pass's desk, or
  the creator.
- `scope=desk`: every pass for `date`. Front desk only.

Sort order is `arrived_at`, or the first event's `at` for a pass that has
not arrived, newest first.

Errors:

| Status | Detail |
| --- | --- |
| 403 | `Only the front desk sees every guest.` |

### POST `/visitor/pass-action/{workspace_id}/{pass_id}/`

```json
{
  "action": "hold",
  "minutes": 20,
  "note": "In a meeting"
}
```

`action` is one of `arrive`, `admit`, `hold`, `decline`, `ping`, `inside`,
`leave`, `cancel`. `minutes` is 1–240 and defaults to 15 for `hold`. `note`
is up to 200 characters.

| Action | Allowed from | Result |
| --- | --- | --- |
| `arrive` | `expected` and today's date | `waiting`, sets `arrived_at`, sends `guest_arrived` |
| `ping` | `waiting`, `on_hold`, `hold_over` | `waiting`, clears `hold_until`, sends `guest_arrived` again |
| `admit` | `waiting`, `on_hold`, `hold_over`, `admitted` | `admitted`, clears `hold_until`, `reply = note or desk.directions` |
| `hold` | Same as admit | `on_hold`, `hold_until = now + minutes`, resets hold-over |
| `decline` | Same as admit | `declined`, `reply = note` |
| `inside` | `admitted`, `waiting`, `on_hold`, `hold_over` | `inside` |
| `leave` | Any status | `left`; repeating it is a no-op |
| `cancel` | Any open status | `cancelled` |

Every action appends an event. `hold` stores its event note as
`"20 min · In a meeting"`. `admit`/`decline` store the reply as the event
note.

Errors:

| Status | Detail |
| --- | --- |
| 403 | `Only the front desk can do that.` |
| 403 | `Only {desk} can answer this guest.` |
| 403 | `You can't cancel this pass.` |
| 404 | `Pass not found.` |
| 409 | `This pass is closed.` |
| 409 | `They have already arrived.` |
| 409 | `This pass is for {date}.` |
| 409 | `Nothing to ask right now.` |
| 409 | `The guest hasn’t arrived yet.` |
| 409 | `Let them in first.` |

### `VisitPass`

```json
{
  "id": "0d3f7d5e-1a2b-4c3d-8e9f-0a1b2c3d4e5f",
  "code": "FIN-4K7Q",
  "guest_name": "John Okafor",
  "guest_phone": "+2348031234567",
  "party_size": 1,
  "purpose": "Interview",
  "desk": {
    "id": "4f1a0dfa-4f6e-4d0e-9f3d-2f7a57f2f4e1",
    "name": "Finance",
    "code": "FIN",
    "directions": "3rd floor, room 4"
  },
  "host": {
    "id": "9d0c4c6d-0b1f-4a3c-8d6f-9f0f6a2c1b7e",
    "email": "ada@example.com",
    "first_name": "Ada",
    "last_name": "Obi",
    "photo": null
  },
  "created_by": {
    "id": "9d0c4c6d-0b1f-4a3c-8d6f-9f0f6a2c1b7e",
    "email": "ada@example.com",
    "first_name": "Ada",
    "last_name": "Obi",
    "photo": null
  },
  "created_via": "host",
  "valid_on": "2026-11-23",
  "status": "on_hold",
  "hold_until": "2026-11-23T10:45:00Z",
  "reply": "In a meeting",
  "replied_by": {
    "id": "9d0c4c6d-0b1f-4a3c-8d6f-9f0f6a2c1b7e",
    "email": "ada@example.com",
    "first_name": "Ada",
    "last_name": "Obi",
    "photo": null
  },
  "arrived_at": "2026-11-23T10:25:00Z",
  "events": [
    {
      "at": "2026-11-23T09:30:00Z",
      "action": "issued",
      "by": "Ada Obi",
      "note": null
    },
    {
      "at": "2026-11-23T10:25:00Z",
      "action": "arrive",
      "by": "Reception",
      "note": null
    },
    {
      "at": "2026-11-23T10:25:00Z",
      "action": "hold",
      "by": "Ada Obi",
      "note": "20 min · In a meeting"
    }
  ],
  "can_answer": true,
  "can_desk": false
}
```

`can_answer` is true when the caller hosts the pass or receives for its
desk. `can_desk` is true when the caller works the front desk.

## Public routes

Both routes are unauthenticated. The public payload never contains a phone
number, email, creator, workspace id or another guest's data.

### GET `/visitor/public-pass/{code}/`

Rate-limited per client IP and pass code (120/minute per code per IP).
Repeated unknown codes are slowed with a second per-IP bucket. The guest
page polls this every 8 seconds.

```json
{
  "code": "FIN-4K7Q",
  "guest_name": "John Okafor",
  "organization": "Acme Group",
  "desk": "Finance",
  "host_name": "Ada Obi",
  "status": "admitted",
  "hold_until": null,
  "reply": "3rd floor, room 4",
  "directions": "3rd floor, room 4",
  "valid_on": "2026-11-23"
}
```

- `directions` is only present for `admitted` or `inside`; it is the reply,
  falling back to the desk's directions.
- Unknown code → `404 "We couldn’t find that pass. Check the code with
  whoever gave it to you."`

### POST `/visitor/public-pass-action/{code}/`

```json
{ "action": "arrive" }
```

Allowed actions are `arrive` and `leave`; anything else is
`400 "Unknown action."`. Same state rules as the authenticated actions. The
event's `by` label is the guest's name. Response is `null`.

- `arrive` sends `guest_arrived` to the host or desk receivers.
- `leave` marks the guest left.

## Notifications

New notification kinds, delivered through the normal notification feed:

| Kind | Sent to | When | Opens |
| --- | --- | --- | --- |
| `guest_arrived` | The pass host, or every receiver of its desk when there is no host | A guest arrives, or reception pings them again | `/guests/my-guests` |
| `guest_hold_over` | The same people | A hold reaches `hold_until` | `/guests/my-guests` |

Messages:

```text
John Okafor (+2) is at reception for Finance · Interview.
John Okafor has waited the 20 minutes you asked. Let them in or ask them to wait again.
```

Actors never receive their own notification. The hold-over alert is sent
once per hold; holding again resets it.

## Background jobs

| Task | Schedule | Does |
| --- | --- | --- |
| `visitors.tasks.housekeep_visitors` | every minute | Expires unresolved passes (`expected`, `waiting`, `admitted`, `on_hold`) whose day has passed; sends `guest_hold_over` once |
| `visitors.tasks.auto_close_visitors` | every 15 minutes | Marks `inside` passes `left` once their arrival is before the workspace-local cut-off/day boundary |
| `visitors.tasks.sync_legacy_visits` | every 5 minutes | Mirrors new/changed legacy `GuestVisit` rows while enabled |

`housekeep` also runs lazily before pass reads and actions, so a screen open
at the moment a hold expires shows `hold_over` without waiting for the beat
task.

Auto check-out reads the legacy `GuestCheckInSettings.auto_close_time` when
present and falls back to `23:59` workspace-local. It keys off `arrived_at`,
not the pass creation time, so an advance invitation is not closed on the
morning of the visit. It is a transition behaviour: the new module has no
settings document of its own.

## Legacy migration and sync

The legacy flow remains live. The sync copies legacy data into the new
tables without changing the old rows.

### Backfill / preview

```bash
make visitors-migrate-dry
make visitors-migrate

# Or inside the container:
python -m visitors.migrate_from_guest_checkin --dry-run
python -m visitors.migrate_from_guest_checkin --workspace <uuid> --full
```

Options: `--dry-run`, `--workspace <uuid>`, `--full` (ignore the
watermark), `--include-deleted`, `--batch-size N`.

The periodic task uses the same code with a per-workspace watermark stored
in `visitor_legacy_syncs`. It is off by default so the dry run and backfill
can finish first; set `VISITORS_LEGACY_SYNC_ENABLED=true` to keep mirroring
while the old flow is still live, then set it back to `false` when the flow is
retired.

### Mapping

| Legacy | Visitors |
| --- | --- |
| `GuestLocation` | `VisitorDesk`, reusing the location UUID and address |
| `GuestVisit` | `VisitPass`, reusing the visit UUID |
| `IN_BUILDING` | `inside` |
| `CHECKED_OUT` / `FORCE_CHECKED_OUT` / `AUTO_CLOSED` | `left` |
| `VOIDED` | `cancelled` |
| Soft-deleted visit | `cancelled` when `--include-deleted` is used; otherwise skipped |
| `check_in_at` | `arrived_at`, local `valid_on`, `issued`/`arrive`/`inside` events |
| `check_out_at` / `updated_at` | `leave` event |
| `reason_category` + `reason_note` | `purpose`, truncated to 140 |
| `phone` | `guest_phone` |
| `host_employee` | `host` |
| `checkout_code` | `{desk.code}-{checkout_code}` when free, otherwise a random suffix |

The guest's legacy **email is not copied** because the new pass model has no
email field; the legacy table keeps it. Names, desk names and directions are
truncated to the new column limits.

The sync only closes mirrored passes. It never reopens or overwrites a pass
that was closed in the new module, and it never sends notifications.

## Configuration

| Env variable | Default | Purpose |
| --- | --- | --- |
| `VISITORS_LEGACY_SYNC_ENABLED` | `false` | Enable after preview/backfill to mirror new legacy visits |
| `VISITORS_LEGACY_SYNC_BATCH_SIZE` | `500` | Legacy rows read per sync batch |
