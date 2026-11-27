# Visitors — Frontend Integration Guide

Audience: the web client developer.

The backend now implements the pass-based Visitors flow from
`designs/attendance-and-visitors-backend.md` §3 and the client mock. The
legacy guest check-in API (`/guest-checkin/…`) is unchanged and still works.

- Endpoint reference: [`visitor_docs.md`](visitor_docs.md)
- Legacy guide: [`guest_checkin_integration.md`](guest_checkin_integration.md)

## 1. What changed

The Visitors page gains four live surfaces:

| Surface | New routes |
| --- | --- |
| My Guests | `list-passes?scope=mine`, `create-pass`, `pass-action` |
| Front Desk | `list-passes?scope=desk`, `find-pass`, walk-in `create-pass`, `pass-action` |
| Desks (admin) | `list-desks`, `save-desk`, `delete-desk` |
| Public pass page `/pass/{code}` | `public-pass`, `public-pass-action` |

Unchanged:

- The old QR check-in/out flow, visitor log, in-building tab, QR codes and
  guest settings still use `/guest-checkin/…`.
- `GET /guest-checkin/my-access/{workspace_id}/` remains the page-level
  access call. `can_view` drives the Front Desk tab; `can_manage_settings`
  drives the Desks tab.
- The people picker and workspace member endpoints are unchanged.

Switch the Visitors mock handlers (`handlers.visitors.ts`) to the live routes
below. Do not remove the legacy guest check-in screens yet.

## 2. Base URL and auth

- Base path: `/visitor`
- All routes except the two public ones need
  `Authorization: Bearer <JWT>`.
- `{workspace_id}` is the workspace UUID.
- Trailing slashes are required.
- `list-desks` and `list-passes` return **plain arrays**, not the pagination
  envelope.
- Dates are `yyyy-MM-dd`; timestamps are ISO 8601 with an offset.

## 3. Routes at a glance

| Route name | Method and path |
| --- | --- |
| `visitor:list-desks` | `GET /visitor/list-desks/{workspace_id}/` |
| `visitor:save-desk` | `PUT /visitor/save-desk/{workspace_id}/` |
| `visitor:delete-desk` | `DELETE /visitor/delete-desk/{workspace_id}/{desk_id}/` |
| `visitor:create-pass` | `POST /visitor/create-pass/{workspace_id}/` |
| `visitor:find-pass` | `GET /visitor/find-pass/{workspace_id}/?code=` |
| `visitor:list-passes` | `GET /visitor/list-passes/{workspace_id}/?scope=mine\|desk&date=` |
| `visitor:pass-action` | `POST /visitor/pass-action/{workspace_id}/{pass_id}/` |
| `visitor:public-pass` | `GET /visitor/public-pass/{code}/` |
| `visitor:public-pass-action` | `POST /visitor/public-pass-action/{code}/` |

`save-desk`, `delete-desk` and `public-pass-action` return `null`.

## 4. TypeScript contracts

```ts
type UserBrief = {
  id: string;
  email: string;
  first_name: string | null;
  last_name: string | null;
  photo: string | null;
};

type Desk = {
  id: string;
  name: string;
  code: string;             // 2–4 uppercase letters
  directions: string | null;
  receivers: UserBrief[];
  is_default: boolean;
};

type PassStatus =
  | "expected"
  | "waiting"
  | "admitted"
  | "on_hold"
  | "hold_over"
  | "inside"
  | "declined"
  | "left"
  | "expired"
  | "cancelled";

type PassEvent = {
  at: string;
  action:
    | "issued"
    | "arrive"
    | "admit"
    | "hold"
    | "hold_over"
    | "decline"
    | "ping"
    | "inside"
    | "leave"
    | "cancel"
    | "expired";
  by: string | null;
  note: string | null;
};

type VisitPass = {
  id: string;
  code: string;             // "{DESK}-{4}"
  guest_name: string;
  guest_phone: string | null;
  party_size: number;
  purpose: string | null;
  desk: {
    id: string;
    name: string;
    code: string;
    directions: string | null;
  };
  host: UserBrief | null;
  created_by: UserBrief | null;
  created_via: "host" | "gate";
  valid_on: string;
  status: PassStatus;
  hold_until: string | null;
  reply: string | null;
  replied_by: UserBrief | null;
  arrived_at: string | null;
  events: PassEvent[];
  can_answer: boolean;
  can_desk: boolean;
};

type PublicPass = {
  code: string;
  guest_name: string;
  organization: string;
  desk: string;
  host_name: string | null;
  status: PassStatus;
  hold_until: string | null;
  reply: string | null;
  directions: string | null;   // only admitted/inside
  valid_on: string;
};
```

`hold_over` is derived by the server. Never compute it yourself for display:
use the returned `status`, but keep the `hold_until` countdown ticking
locally so the number reaches zero between polls.

## 5. Screen map

### My Guests (`/guests/my-guests`)

Data: `GET list-passes?scope=mine` (poll every 8 seconds).

The server already applies the "mine" scope:

- passes for the selected date,
- plus future `expected` passes,
- where the caller is the host, a desk receiver, or the creator.

Suggested sections:

| Section | Filter |
| --- | --- |
| Need an answer | `can_answer && status in (waiting, hold_over)` |
| Today | `status in (admitted, on_hold, inside)` |
| Expected | `status === "expected"` (today first, then future) |

Actions:

- `admit` / `hold` / `decline` only when `can_answer`.
- `hold` sends `{ action: "hold", minutes: 10|20|30|custom, note }`.
- `ping`, `inside`, `leave` when `can_answer || can_desk`.
- `cancel` when `can_answer || created_by.id === me.id || can_desk`.
- Use the shared "Invite guest" dialog:
  `POST create-pass` with `arrived: false`. Omit `host_id` to host it
  yourself.
- "Share via WhatsApp" and the QR code are client-side; build the public URL
  as `/pass/{code}`.

### Front Desk (`/guests/desk`)

Data: `GET list-passes?scope=desk` (poll every 8 seconds).

Features:

1. **Find by code**: `GET find-pass?code=`. The server accepts any case,
   with or without the dash. On 404 show the `detail` verbatim.
2. **QR scan**: the printed/scanned QR contains `/pass/{code}`; extract the
   code and call `find-pass`.
3. **Walk-in**: `POST create-pass` with `arrived: true`, a desk and today's
   date. The server creates the pass and immediately marks it `waiting`.
4. **Queue**: sort by status priority
   `hold_over → admitted → waiting → on_hold → inside`, then render actions:
   - `expected`: "Notify {host/desk}" → `arrive`.
   - `waiting` / `on_hold`: "Ask again" → `ping`.
   - `hold_over`: "Ask again" → `ping` (primary/red).
   - `admitted`: "Send in" → `inside`.
   - `inside`: "Check out" → `leave`.

Play the chime when a pass changes to `hold_over`, `admitted` or `declined`,
matching the design.

### Desks (`/guests/desks`)

Data: `GET list-desks`.

- Render the code, name, directions and receiver avatars.
- `PUT save-desk` with `id: null` to create, or the existing id to edit.
- `DELETE delete-desk`.
- The default desk has a star and cannot be deleted until another desk is
  made default.
- Show the server's `detail` verbatim for duplicate codes and the
  open-guests guard.

### Public pass page (`/pass/{code}`)

Data: `GET public-pass/{code}` (poll every 8 seconds).

- No auth header.
- `status` selects the screen copy/icon.
- Show the QR and code while the pass is `expected`, `waiting`, `on_hold` or
  `hold_over`.
- `expected` + `valid_on === today`: show "I'm here" → `POST
  public-pass-action` with `{ action: "arrive" }`.
- `admitted` or `inside`: show "I've left" → `{ action: "leave" }`.
- Show `reply` when present and `directions` when present.
- Unknown code shows the 404 `detail`.

`public-pass-action` returns `null`; refetch `public-pass` after it.

## 6. Action matrix

| Action | From | To | Side effects |
| --- | --- | --- | --- |
| `arrive` | `expected` (today only) | `waiting` | `arrived_at`, `guest_arrived` |
| `ping` | `waiting`, `on_hold`, `hold_over` | `waiting` | clears `hold_until`, re-sends `guest_arrived` |
| `admit` | `waiting`, `on_hold`, `hold_over`, `admitted` | `admitted` | reply defaults to desk directions |
| `hold` | Same | `on_hold` | `hold_until = now + minutes`; minutes default 15 |
| `decline` | Same | `declined` | reply is the note |
| `inside` | `admitted`, `waiting`, `on_hold`, `hold_over` | `inside` | — |
| `leave` | Any | `left` | repeated calls are a no-op |
| `cancel` | Any open status | `cancelled` | — |

Every action returns the fresh `VisitPass`, so replace the item in local
state instead of refetching the whole list.

## 7. Errors and polling

- Show `detail` verbatim. It is already a complete sentence.
- `409 "This pass is closed."` means another desk closed it; refetch.
- `409 "They have already arrived."` / `"Nothing to ask right now."` /
  `"The guest hasn’t arrived yet."` / `"Let them in first."` are state races;
  refetch the pass.
- `403` messages distinguish front-desk access from host/desk answering.
- `429` from the public routes means the IP/pass bucket is full; back off
  and show a short retry message.
- Poll intervals: My Guests, Front Desk and the public page every 8 seconds.
  The server runs hold-over and expiry housekeeping on reads, so a plain GET
  is enough.

## 8. Notifications

| Kind | Opens |
| --- | --- |
| `guest_arrived` | `/guests/my-guests` |
| `guest_hold_over` | `/guests/my-guests` |

The notification feed and preferences endpoints are unchanged. Both kinds
use the `other` preference event, so existing users get them in-app with no
settings migration.

## 9. Cutover and dual-running

The old flow is still live. The sync is off by default so the preview and
backfill can run first; once enabled, the backend mirrors it:

- Existing legacy visits are backfilled into passes.
- While `VISITORS_LEGACY_SYNC_ENABLED=true`, a beat task every 5 minutes
  copies **new** legacy check-ins and closes mirrored passes when the legacy
  guest checks out, is force-checked-out, auto-closed or voided.
- Legacy IDs are reused as pass IDs. A visit's old UUID is the pass `id`.
- Legacy four-character check-out codes are prefixed with the desk code:
  `K7M2` becomes `FIN-K7M2`. Old printed codes are not new pass codes; use
  the visitor log during the transition if a guest is already inside.
- Guest email is not copied into the new pass model. It remains in the
  legacy visitor log.
- A pass closed in the new flow is never reopened by the sync.

Cutover checklist:

1. Deploy the backend migration with `VISITORS_LEGACY_SYNC_ENABLED=false`
   (the default) and start the beat workers.
2. Run `make visitors-migrate-dry`, then `make visitors-migrate`.
3. Set `VISITORS_LEGACY_SYNC_ENABLED=true` and restart the celery beat worker
   so new legacy check-ins keep mirroring while both flows are live.
4. Switch the four Visitors surfaces to `/visitor/…`.
5. Keep the legacy guest check-in tabs live until the old QR posters and
   links are retired.
6. After the old flow is retired, set
   `VISITORS_LEGACY_SYNC_ENABLED=false` again.

## 10. QA checklist

- [ ] First `GET list-desks` seeds the right defaults for the workspace type.
- [ ] A seeded desk deleted by an admin does not reappear on the next list.
- [ ] Desk save validates duplicate codes, receivers and the default rule.
- [ ] Host invitation defaults `host` and `created_by` to the caller.
- [ ] Walk-in is rejected for non-front-desk members and non-today dates.
- [ ] Public pass codes are unique across workspaces.
- [ ] `find-pass` works with `FIN4K7Q`, `fin-4k7q` and `FIN-4K7Q`.
- [ ] `scope=mine` hides another member's passes and includes future
      expected passes.
- [ ] `scope=desk` is 403 for a normal member and shows all today's passes
      for reception.
- [ ] Admit/hold/decline are 403 for a member who is neither host nor desk
      receiver.
- [ ] Hold countdown reaches zero, the card turns red and a
      `guest_hold_over` notification arrives once.
- [ ] Ping re-sends `guest_arrived`.
- [ ] `leave` twice appends only one event.
- [ ] An advance invitation created the previous day is not auto-closed on
      the morning the guest arrives.
- [ ] A `waiting` or `admitted` pass from a previous day becomes `expired`.
- [ ] The public response has no phone, email or creator fields.
- [ ] The public "I'm here" and "I've left" buttons work without a token.
- [ ] A legacy visit checked out after the initial sync becomes `left` in
      the new list.
