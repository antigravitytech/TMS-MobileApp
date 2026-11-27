# Event Planner API Documentation

Source: `tms/events/routers.py`

**Planner prefix:** `/event`

**Public prefix:** `/public`

The event planner is attached to a `specials` workspace whose subtype is
`event`. The event is created lazily from the workspace setup on the first
planner call.

Planner endpoints require `Authorization: Bearer <JWT>` and active workspace
membership. Public endpoints are unauthenticated and token-scoped.

## Enumerations

| Enum | Values |
| --- | --- |
| RSVP | `not_sent`, `invited`, `attending`, `maybe`, `declined` |
| Vendor category | `venue`, `catering`, `decor`, `photo`, `music`, `mc`, `cake`, `attire`, `beauty`, `transport`, `security`, `other` |
| Vendor status | `enquiry`, `quoted`, `booked`, `paid`, `cancelled` |
| Programme segment | `before`, `ceremony`, `reception`, `after` |
| Programme status | `pending`, `live`, `done` |
| Table shape | `round`, `long` |

---

## GET `/event/get-event/{workspace_id}/`

### Sample response

```json
{
  "id": "11111111-1111-4111-8111-111111111111",
  "name": "Chinwe & Dayo's Wedding",
  "hosts": "The Okafors",
  "tagline": "Come celebrate with us",
  "date": "2026-12-19",
  "start_time": "14:00",
  "venue": "Eko Hall",
  "address": "Lagos",
  "dress_code": "Aso-ebi",
  "description": "Join us for the day",
  "capacity": 300,
  "budget": 8500000,
  "rsvp_deadline": "2026-12-01",
  "meal_options": ["Jollof", "Fried rice"],
  "groups": ["Family", "Friends"],
  "tables": [
    {"id": "22222222-2222-4222-8222-222222222222", "name": "Table 1", "seats": 10, "shape": "round", "x": 12, "y": 20}
  ],
  "faqs": [{"q": "Is there parking?", "a": "Yes"}],
  "gift_note": "Your presence is enough",
  "color": "#9184d9",
  "share_token": "guest-share-token",
  "rsvp_open": true
}
```

## PUT `/event/update-event/{workspace_id}/`

Accepts any subset of the event fields above except `id`, `color` and
`share_token`. `meal_options`, `groups` and `faqs` replace their lists.
`tables` upserts by id and removes tables that are no longer present.
Returns the full event.

## Guests

### GET `/event/list-guests/{workspace_id}/`

Returns an array of guests:

```json
{
  "id": "33333333-3333-4333-8333-333333333333",
  "name": "Mr & Mrs Okafor",
  "email": null,
  "phone": "+2348000000000",
  "group": "Family",
  "party_size": 2,
  "attending_count": 2,
  "rsvp": "attending",
  "meal": null,
  "dietary": null,
  "table_id": null,
  "note": null,
  "vip": false,
  "code": "guest-code",
  "invited_at": "2026-11-19T10:00:00Z",
  "responded_at": "2026-11-19T10:05:00Z",
  "checked_in_at": null
}
```

### POST `/event/save-guest/{workspace_id}/`

```json
{
  "id": null,
  "name": "Mr & Mrs Okafor",
  "email": null,
  "phone": "+2348000000000",
  "group": "Family",
  "party_size": 2,
  "meal": null,
  "dietary": null,
  "table_id": null,
  "note": null,
  "vip": false
}
```

### POST `/event/import-guests/{workspace_id}/`

```json
{
  "text": "Mr & Mrs Okafor, +2348000000000, 2\nChinwe Eke, chinwe@mail.com",
  "group": "Family"
}
```

One guest per line: `name, phone-or-email, seats`. Returns the imported guests.

### POST `/event/guest-action/{workspace_id}/`

```json
{"action": "invite", "guest_ids": ["..."]}
```

| Action | Extra fields |
| --- | --- |
| `invite` | `guest_ids` |
| `delete` | `guest_ids` |
| `set_rsvp` | `guest_ids`, `rsvp` |
| `set_group` | `guest_ids`, `group` |
| `set_table` | `guest_ids`, `table_id` |
| `check_in` | `guest_ids`, optional `undo` |

## Vendors

### GET `/event/list-vendors/{workspace_id}/`

Returns vendors with a `payments` array.

### POST `/event/save-vendor/{workspace_id}/`

```json
{
  "id": null,
  "name": "Mama's Kitchen",
  "category": "catering",
  "contact_name": "Mama",
  "phone": "+2348000000000",
  "email": null,
  "status": "booked",
  "quote": 1800000,
  "next_due": "2026-12-01",
  "arrival_time": "12:00",
  "notes": "300 plates",
  "rating": 5
}
```

### POST `/event/vendor-action/{workspace_id}/`

| Action | Extra fields |
| --- | --- |
| `delete` | `vendor_id` |
| `invite` | `vendor_id` (marks the portal invitation as sent) |
| `pay` | `vendor_id`, `amount`, optional `note` |
| `set_status` | `vendor_id`, `status` |

Returns the updated vendor.

## Programme

### GET `/event/list-programme/{workspace_id}/`

```json
{
  "id": "44444444-4444-4444-8444-444444444444",
  "title": "Guests arrive",
  "segment": "before",
  "start": "14:00",
  "duration_min": 30,
  "location": "Eko Hall",
  "owner": "Ushers",
  "vendor_id": null,
  "notes": null,
  "public": true,
  "status": "pending"
}
```

### POST `/event/save-programme-item/{workspace_id}/`

Send the same shape with an optional `id`; `vendor_id` must belong to the
event. Returns the saved item.

### POST `/event/programme-action/{workspace_id}/`

| Action | Fields |
| --- | --- |
| `delete` | `item_id` |
| `move` | `item_id`, `dir` (`up`/`down`) |
| `retime` | `start` (`HH:MM`) |
| `set_status` | `item_id`, `status` (`pending`/`live`/`done`) |

`set_status` marks every earlier item `done`, matching the live run mode.

---

## Public guest page

### GET `/public/event/{share_token}/?code={guest_code}`

No auth. `code` is optional; when supplied it returns the guest's RSVP and
table.

```json
{
  "event": {
    "id": "...",
    "name": "Chinwe & Dayo's Wedding",
    "hosts": "The Okafors",
    "tagline": "...",
    "date": "2026-12-19",
    "start_time": "14:00",
    "venue": "Eko Hall",
    "address": "Lagos",
    "dress_code": "Aso-ebi",
    "description": "...",
    "capacity": 300,
    "rsvp_deadline": "2026-12-01",
    "meal_options": ["Jollof"],
    "faqs": [{"q": "Is there parking?", "a": "Yes"}],
    "gift_note": "...",
    "color": "#9184d9",
    "rsvp_open": true
  },
  "programme": [],
  "notices": [],
  "guest": null,
  "attending_total": 0
}
```

Only programme items with `public=true` are returned.

### POST `/public/rsvp/{share_token}/`

```json
{
  "code": "guest-code",
  "name": "Mr & Mrs Okafor",
  "email": null,
  "phone": "+2348000000000",
  "rsvp": "attending",
  "attending_count": 2,
  "meal": "Jollof",
  "dietary": null,
  "note": "Can't wait!"
}
```

When `code` matches a guest, the existing invitation is updated. Otherwise a
self-added guest is created. Capacity is enforced when the event has one.
Returns the public event payload.

## Vendor brief

### GET `/public/vendor/{portal_token}/`

No auth. Marks the brief as viewed.

```json
{
  "event": { "...": "public event fields" },
  "vendor": {
    "name": "Mama's Kitchen",
    "category": "catering",
    "arrival_time": "12:00",
    "notes": "300 plates",
    "quote": "1800000.00",
    "paid": "900000.00",
    "status": "booked"
  },
  "my_items": [],
  "programme": [],
  "host_contact": "The Okafors"
}
```
