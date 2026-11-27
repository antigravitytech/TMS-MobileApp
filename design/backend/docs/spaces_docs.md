# Spaces, Family Home and Studio API Documentation

Source: `tms/spaces/routers.py`

**Prefix:** `/home`

Space endpoints power the family, individual and `specials` workspace hubs
(introduced in the v4 UI). Business workspaces do not have a space hub.
Studio invoices and proposals are stored against the id of the invoice or
proposal row in the relevant space module.

All endpoints require `Authorization: Bearer <JWT>` and an active membership
of the workspace.

## Workspace kinds and module templates

| Workspace | Seeded modules |
| --- | --- |
| `individual` | `clients` (people), `invoices` (money), `time` (time), `proposals` (checklist) |
| `family` | `chores` (checklist), `shopping` (checklist), `bills` (money), `school` (schedule) |
| `specials / church` | `services` (schedule), `giving` (money), `units` (board), `prayers` (checklist), `firsttimers` (people), `notices` |
| `specials / estate` | `levies` (money), `passes` (schedule), `issues` (checklist), `notices`, `poll` |
| `specials / event` | `guests` (people), `vendors` (money), `runsheet` (schedule), `prep` (checklist), `notices` |
| `specials / committee` | `meetings` (schedule), `actions` (checklist), `minutes` (notices), `decisions` (poll) |
| `specials / club` | `sessions` (schedule), `fees` (money), `attendance` (people), `notices` |
| `specials / alumni` | `dues` (money), `committees` (board), `poll`, `notices`, `directory` (people) |

Modules are created lazily on the first call and are stored as normalized
rows (`space_modules`, `space_items`, `space_notices`, `space_people`,
`space_poll_options`, `space_board_columns`). Empty templates are seeded; no
demo data is written.

---

## GET `/home/get-space/{workspace_id}/`

- **Auth:** Active member of a non-business workspace.

### Sample response

```json
{
  "kind": "family",
  "subtype": null,
  "headline": {
    "title": "The Adeyemis",
    "date": null,
    "members": 4
  },
  "modules": [
    {
      "type": "checklist",
      "key": "chores",
      "target": null,
      "rate": null,
      "items": [
        {
          "id": "11111111-1111-4111-8111-111111111111",
          "title": "Wash the plates",
          "owner": "Tobi",
          "status": "open",
          "count": 10,
          "note": null,
          "amount": null,
          "paid": null,
          "due": null,
          "member_id": null,
          "group": null,
          "role": null,
          "date": "2026-11-19",
          "time": null,
          "where": null,
          "lead": null,
          "client": null,
          "task": null,
          "hours": null,
          "billable": true,
          "column_id": null
        }
      ],
      "columns": [],
      "question": null,
      "options": [],
      "voted": null
    }
  ]
}
```

`modules[].type` is one of `money`, `checklist`, `schedule`, `board`,
`poll`, `notices`, `people`, `time`.

Board modules return `columns[]` with `id`, `name`, `lead`, `members` and
`items` (card titles). Each card in the module's `items[]` carries the same
`column_id`, so clients can group cards reliably instead of matching titles.
`column_id` is `null` for non-board modules.

---

## POST `/home/space-action/{workspace_id}/`

Generic action dispatcher. The response is the full `SpaceRead` above.

| Action | Fields | Effect |
| --- | --- | --- |
| `add` | `module`, `fields` | Add an item, person, notice, poll option, board column or money row |
| `status` | `module`, `item`, `status` | Update a checklist item or person status (`open/doing/done`, `yes/no/maybe/invited`) |
| `pay` | `module`, `item`, `amount` | Add to the item's `paid` amount |
| `count` | `module`, `item` | Increment a points/count value |
| `vote` | `module`, `option` | Replace the caller's poll vote (zero-based option index) |
| `remove` | `module`, `item` | Remove an item |
| `members` | `module`, `column`, `lead`, `user_ids` | Replace a board column's lead and members |
| `remove_column` | `module`, `column` | Remove a board column |
| `remove_card` | `module`, `column`, `index` | Remove a card from a board column |

### Add examples

```json
{
  "action": "add",
  "module": "chores",
  "fields": {
    "title": "Wash the plates",
    "owner": "Tobi",
    "due": "2026-11-20",
    "count": 10,
    "note": "Before dinner"
  }
}
```

```json
{
  "action": "add",
  "module": "notices",
  "fields": {"title": "Water will be off on Thursday"}
}
```

```json
{
  "action": "add",
  "module": "poll",
  "fields": {
    "title": "Upgrade the gate to card access?",
    "options": "Yes, No, Not now"
  }
}
```

To link a chore, bill, time or similar row to a workspace user, send
`fields.member` (the user id). The response exposes it as `member_id`.

---

## GET `/home/get-family/{workspace_id}/`

- **Auth:** Active member of a `family` workspace.

### Sample response

```json
{
  "errands": [],
  "points": [{"user_id": "22222222-2222-4222-8222-222222222222", "points": 140}],
  "rewards": [
    {"id": "33333333-3333-4333-8333-333333333333", "name": "Ice cream outing", "cost": 120, "icon": "IceCreamCone"}
  ],
  "visitor": {
    "id": "44444444-4444-4444-8444-444444444444",
    "name": "Mr Okon",
    "at": "2026-11-19T10:15:00Z",
    "state": "waiting",
    "logged_by": "Security"
  },
  "birthdays": [{"name": "Mama Bisi", "days": 3}],
  "brief": {"errands": 0, "homework": 2, "driver_free_from": "11:00"}
}
```

## POST `/home/family-action/{workspace_id}/`

| Action | Payload | Effect |
| --- | --- | --- |
| `add_errand` | `who`, `title`, optional `issued`, `spent` | Create an open errand |
| `change_received` | `errand_id` | Close an errand and mark the issued amount spent |
| `add_reward` | `name`, `cost`, optional `icon` | Add a reward that can be redeemed |
| `redeem` | `user_id`, `reward_id` | Spend points on a reward |
| `homework_done` | `user_id` | Award 10 points |
| `award_points` | `user_id`, `amount` | Award points to an active member |
| `add_visitor` | `name`, optional `logged_by` | Log a visitor waiting at the gate |
| `visitor` | `decision` (`allowed`/`wait`), optional `visitor_id` | Resolve a waiting visitor |

Returns the full family home payload. `award_points` validates that
`user_id` is an active member of the family workspace. `add_errand` requires
`who` and `title`; `add_reward` requires `name` and `cost`; `add_visitor`
requires `name`. Invalid or missing fields return `422`.

`add_visitor` creates a waiting visitor. `get-family` returns the newest
waiting visitor with its `id`; pass `visitor_id` to `visitor` to resolve a
specific visitor when several are waiting.

### Family action examples

```json
{
  "action": "add_errand",
  "who": "Kwame",
  "title": "Carry Madam to the market by 10:00",
  "issued": 20000
}
```

```json
{
  "action": "add_reward",
  "name": "Ice cream outing",
  "cost": 120,
  "icon": "IceCreamCone"
}
```

```json
{
  "action": "award_points",
  "user_id": "22222222-2222-4222-8222-222222222222",
  "amount": 15
}
```

```json
{
  "action": "add_visitor",
  "name": "Mr Okon",
  "logged_by": "Security"
}
```

---

## Studio documents

Invoices and proposals are addressed by the `SpaceItem` id that appears in
the `invoices`/`proposals` module.

### GET `/home/get-invoice/{workspace_id}/{item_id}/`

Returns the invoice form data:

```json
{
  "style": "classic",
  "accent": "primary",
  "number": "INV-204",
  "issue_date": "2026-11-19",
  "due_date": null,
  "logo_url": null,
  "logo_file_id": null,
  "from_name": "Acme Studio",
  "from_details": "Lagos",
  "bill_to_name": "Unique Engineering",
  "bill_to_details": "Victoria Island",
  "items": [
    {"id": null, "description": "Homepage layout", "qty": 1, "rate": 350000}
  ],
  "tax_rate": 7.5,
  "discount": 0,
  "notes": "Thank you",
  "payment_details": "Bank transfer"
}
```

### PUT `/home/save-invoice/{workspace_id}/{item_id}/`

Send the same shape. Existing line items are replaced. Returns the saved
invoice.

### GET `/home/get-proposal/{workspace_id}/{item_id}/`

```json
{
  "layout": {"size": "a4", "orientation": "portrait", "margins": "normal"},
  "html": "<h1>Proposal</h1>",
  "updated_at": "2026-11-19T13:00:00Z"
}
```

### PUT `/home/save-proposal/{workspace_id}/{item_id}/`

```json
{
  "html": "<h1>Proposal</h1>",
  "layout": {"size": "a4", "orientation": "portrait", "margins": "normal"},
  "file_ids": []
}
```

`file_ids` must be workspace files. Proposal documents and their referenced
files are included in the signed-URL renewal job.
