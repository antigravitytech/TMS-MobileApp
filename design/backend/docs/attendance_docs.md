# Attendance API Documentation

Source: `tms/attendance/routers.py`

**Prefix:** `/attendance`

For the screen-by-screen client guide, see
[`attendance_integration.md`](attendance_integration.md).

Attendance lets each workspace define working hours, place checks, Wi-Fi
checks, holidays and exempt people. Members clock in and out; the server is
the authority on lateness, absences and place verification.

## Conventions

- Every route requires `Authorization: Bearer <JWT>` and an active
  workspace membership.
- `{workspace_id}` is the workspace UUID.
- Trailing slashes are required.
- Lists return `{items, total, page, page_size, total_pages}`; routes marked
  **plain array** return a bare JSON array.
- Timestamps are ISO 8601 with an offset. Dates are `yyyy-MM-dd`. Times of day
  are `HH:mm` (24-hour) and are interpreted in the workspace timezone.
- People are returned as `UserBrief`: `{id, email, first_name, last_name,
  photo}`.
- Errors are `{ "detail": "Human sentence." }`. Business-rule errors (403,
  409 and the custom 422s) use a single sentence; Pydantic type errors keep
  FastAPI's standard 422 body.

## Concepts

| Entity | Meaning |
| --- | --- |
| Settings | One document per workspace. Created with defaults on first read. |
| Location | A point with a radius, or a polygon drawn on the map. |
| Network | An office network identified by public IP addresses/CIDRs. Browsers cannot read the SSID. |
| Holiday | A public or custom day off. Only `observed` holidays suppress absences. |
| Exemption | A member who may clock in from anywhere and is never marked late or absent. |
| Record | One clock-in/clock-out for one workspace-local date. Unique per member per day. |

A workspace can be configured for location checks, Wi-Fi checks, both, or
neither. `require` decides whether either check is enough (`any`) or both are
needed (`all`).

## Statuses

`DayStatus`:

| Status | Meaning |
| --- | --- |
| `early` | Clocked in more than `early_minutes` before the start |
| `on_time` | Clocked in inside the window |
| `late` | Clocked in after the grace period |
| `absent` | A working day with no clock-in |
| `not_clocked_in` | Today, before `absent_after`, with no clock-in yet |
| `holiday` | An observed holiday |
| `off_day` | Not a configured working day |
| `exempt` | The person is exempt and has not clocked in |
| `upcoming` | A future day |

`in_status`: `early`, `on_time`, `late`.

`out_status`: `early_leave`, `on_time`, `overtime` (or `null` while still
clocked in).

`method`: `location`, `wifi`, `exempt`, `open`.

### How statuses are calculated

All times use the workspace timezone. `m` is minutes since local midnight.

```text
late_line = (strict ? start : start_until) + grace_minutes
in_status = early  if m < start - early_minutes
          = late   if m > late_line
          = on_time otherwise

out_status = early_leave if m < end
           = overtime    if m > (strict ? end : end_until) + 30
           = on_time     otherwise
```

Day status precedence:

```text
observed holiday       → holiday
exempt person          → record.in_status, or exempt
not a working day      → record.in_status, or off_day
record exists          → record.in_status
future date            → upcoming
today before absent_after → not_clocked_in
otherwise              → absent
```

On an observed holiday, a day off, or for an exempt person, a clock-in is
stored as `on_time`; those days never create a lateness alert.

## Who sees whose attendance

| Caller | Sees |
| --- | --- |
| Anyone | Themselves |
| Line manager (`reports_to_id`) | Themselves plus direct reports |
| Owner / admin | Every active member |

Asking for another person outside that set returns:

```json
{ "detail": "You can't see this person's attendance." }
```

## Defaults

Defaults are created on the first settings read (GET settings, Today,
clock-in, stats, history or board). Existing workspaces therefore need no data
migration.

| Workspace | Hours | Days | Checks |
| --- | --- | --- | --- |
| business | flexible 09:00–09:30 → 17:00–18:00 | Mon–Fri | location + Wi-Fi, either is enough |
| church | strict 08:00 → 11:00 | Sun, Wed | location |
| family | flexible 07:30–07:45 → 15:00–16:00 | Mon–Fri | location |
| estate | strict 07:00 → 19:00 | Mon–Sat | location + Wi-Fi |
| club / alumni / committee | strict 18:00 → 20:00 | Sat | location |
| event | flexible 08:00–08:30 → 22:00–23:30 | Fri, Sat | location |
| individual | flexible 09:00 → 17:00 | Mon–Fri | none |
| anything else | business defaults | | |

Lateness starts enabled except for individual workspaces. `max_late` is 5 for
business and 3 otherwise, per month, with line-manager alerts on.

New settings also seed Nigerian public holidays for the current and next year.
Islamic holiday dates are estimates and can be edited in Settings. No demo
locations or networks are seeded, so a new workspace is open until an admin
adds its first location/network.

---

## GET `/attendance/get-settings/{workspace_id}/`

Returns the full settings document. Active members may read it.

**Sample response:**

```json
{
  "enabled": true,
  "geofence_enabled": true,
  "wifi_enabled": true,
  "require": "any",
  "locations": [
    {
      "id": "5b2e8f7c-3e31-4f27-9aad-6d4f0b0f9a11",
      "name": "Head office",
      "address": "1 Adeola Odeku St, Victoria Island, Lagos",
      "kind": "point",
      "center": { "lat": 6.4281, "lng": 3.4219 },
      "radius_m": 150,
      "points": []
    },
    {
      "id": "e36c6d7a-1a59-4d9a-a7cb-03a2f0e5c7b4",
      "name": "Lekki annex",
      "address": null,
      "kind": "polygon",
      "center": { "lat": 6.4412, "lng": 3.4712 },
      "radius_m": 100,
      "points": [
        { "lat": 6.4419, "lng": 3.4702 },
        { "lat": 6.4421, "lng": 3.4721 },
        { "lat": 6.4405, "lng": 3.4724 }
      ]
    }
  ],
  "networks": [
    {
      "id": "7a1f2c3d-4b5e-4f60-8a91-b2c3d4e5f6a7",
      "name": "Acme Staff",
      "ip_addresses": ["102.89.4.17", "10.0.0.0/8"]
    }
  ],
  "schedule": {
    "mode": "flexible",
    "start": "09:00",
    "start_until": "09:30",
    "end": "17:00",
    "end_until": "18:00",
    "early_minutes": 30,
    "grace_minutes": 5,
    "absent_after": "12:00",
    "working_days": ["Monday", "Tuesday", "Wednesday", "Thursday", "Friday"]
  },
  "lateness": {
    "enabled": true,
    "max_late": 5,
    "period": "month",
    "notify_ids": [],
    "notify_line_manager": true
  },
  "holidays": [
    {
      "id": "c4d5e6f7-a8b9-4c0d-9e1f-2a3b4c5d6e7f",
      "date": "2026-12-25",
      "name": "Christmas Day",
      "source": "public",
      "observed": true
    }
  ],
  "exempt": [],
  "country": "NG",
  "timezone": "Africa/Lagos",
  "can_edit": true
}
```

`can_edit` is `true` for owners and admins.

---

## PUT `/attendance/update-settings/{workspace_id}/`

Owner/admin only. Replaces the **whole** document: locations, networks and
holidays are upserted by `id`; missing rows are removed; exemptions are
reconciled from `exempt_ids`.

Body: the GET response **without** `exempt` and `can_edit`, **plus**
`exempt_ids: string[]`.

**Sample request:**

```json
{
  "enabled": true,
  "geofence_enabled": true,
  "wifi_enabled": false,
  "require": "any",
  "locations": [
    {
      "id": "loc-existing-uuid-or-temporary-id",
      "name": "Head office",
      "address": "1 Adeola Odeku St, Victoria Island, Lagos",
      "kind": "point",
      "center": { "lat": 6.4281, "lng": 3.4219 },
      "radius_m": 150,
      "points": []
    }
  ],
  "networks": [],
  "schedule": {
    "mode": "strict",
    "start": "08:00",
    "start_until": "08:00",
    "end": "17:00",
    "end_until": "17:00",
    "early_minutes": 30,
    "grace_minutes": 5,
    "absent_after": "12:00",
    "working_days": ["Monday", "Tuesday", "Wednesday", "Thursday", "Friday"]
  },
  "lateness": {
    "enabled": true,
    "max_late": 5,
    "period": "month",
    "notify_ids": [],
    "notify_line_manager": true
  },
  "holidays": [],
  "exempt_ids": [],
  "country": "NG",
  "timezone": "Africa/Lagos"
}
```

Notes:

- A new nested item may send any temporary `id`; the server creates it and
  returns a real UUID. Existing items keep their id when re-sent.
- A polygon needs at least three `points`, otherwise 422
  `"An area needs at least three corners."`
- `strict` mode stores `start_until = start` and `end_until = end`.
- `notify_ids` and `exempt_ids` must be active members of the workspace.
- Network entries must be IPv4/IPv6 addresses or CIDR ranges.

Returns the fresh settings document.

**Errors:**

| Code | Detail |
| --- | --- |
| 403 | `Only workspace owners and admins can change attendance settings.` |
| 422 | `An area needs at least three corners.` |
| 422 | `Choose people from this workspace.` |

---

## GET `/attendance/get-today/{workspace_id}/`

Everything the Today screen needs for the caller.

**Sample response:**

```json
{
  "date": "2026-11-23",
  "status": "not_clocked_in",
  "record": null,
  "expected": true,
  "holiday": null,
  "exempt": false,
  "schedule": {
    "mode": "flexible",
    "start": "09:00",
    "start_until": "09:30",
    "end": "17:00",
    "end_until": "18:00",
    "early_minutes": 30,
    "grace_minutes": 5,
    "absent_after": "12:00",
    "working_days": ["Monday", "Tuesday", "Wednesday", "Thursday", "Friday"]
  },
  "checks": { "location": true, "wifi": true, "require": "any" },
  "locations": [
    {
      "id": "5b2e8f7c-3e31-4f27-9aad-6d4f0b0f9a11",
      "name": "Head office",
      "address": "1 Adeola Odeku St, Victoria Island, Lagos",
      "kind": "point",
      "center": { "lat": 6.4281, "lng": 3.4219 },
      "radius_m": 150,
      "points": []
    }
  ],
  "next_holiday": {
    "id": "c4d5e6f7-a8b9-4c0d-9e1f-2a3b4c5d6e7f",
    "date": "2026-12-25",
    "name": "Christmas Day",
    "source": "public",
    "observed": true
  },
  "enabled": true
}
```

`checks.location` is `geofence_enabled AND at least one location`;
`checks.wifi` is `wifi_enabled AND at least one network`.

---

## POST `/attendance/clock-in/{workspace_id}/`

**Body:**

```json
{
  "lat": 6.4282,
  "lng": 3.4220,
  "accuracy_m": 18,
  "note": null
}
```

`lat`/`lng` may both be `null` when the browser refused location access.
`note` is optional (max 280).

**Server rules, in order:**

1. Attendance disabled → 403
   `"Attendance is switched off in this workspace."`
2. A record already exists for today → 409
   `"You've already clocked in today."`
3. Place verification (see below).
4. `in_status` = `early` / `on_time` / `late`; on a holiday, off-day or for an
   exempt person it is stored as `on_time`.
5. `minutes_late` = minutes past the late line (0 unless late).
6. Late clock-ins run the lateness alert check.
7. Returns the fresh `AttendanceToday`.

**Place verification:**

- Exempt person → method `exempt`.
- No active checks → method `open`.
- Point: inside when `haversine ≤ radius_m + slack`.
- Polygon: inside when ray casting says so, or the centre is within `slack`.
- `slack = min(max(accuracy_m, 0), 75)` metres.
- Wi-Fi: the resolved client IP must be inside one of the network's
  IP/CIDR entries.
- `require=all` needs both configured checks; `require=any` needs either.

**403 messages:**

```json
{ "detail": "We need your location to clock you in. Allow location access and try again." }
```

```json
{ "detail": "You're 1.2 km from Head office. Clock in when you get to one of your workplace locations." }
```

```json
{ "detail": "Connect to Acme Staff to clock in." }
```

Distances under 1 km are shown in metres (`"350 m"`); otherwise one decimal
kilometre (`"1.2 km"`).

---

## POST `/attendance/clock-out/{workspace_id}/`

Same body as clock-in. The place is verified again.

**Errors:**

| Code | Detail |
| --- | --- |
| 409 | `You haven't clocked in today.` |
| 409 | `You've already clocked out today.` |
| 403 | Same place-verification sentences as clock-in |

Sets `clock_out_at` and `out_status`. A supplied `note` is appended to the
clock-in note with a newline. Returns the fresh `AttendanceToday`.

---

## GET `/attendance/get-stats/{workspace_id}/`

Query: `user_id` (default: caller), `period=week|month|quarter`
(default: `month`).

The period runs from Monday of this week, the 1st of this month, or the 1st of
the month two months ago, up to today. It is clamped to when attendance
tracking began for that person: the later of the workspace settings creation
date and the member's join date. Days before that are not counted as absences,
and `date_from` is the clamped start.

**Sample response:**

```json
{
  "period": "month",
  "date_from": "2026-11-01",
  "date_to": "2026-11-23",
  "expected_days": 16,
  "present_days": 15,
  "early": 3,
  "on_time": 10,
  "late": 2,
  "absent": 1,
  "punctuality": 81,
  "avg_clock_in": "08:57",
  "avg_clock_out": "17:22",
  "minutes_worked": 7420,
  "streak": 6,
  "late_limit": 5,
  "days": [
    { "date": "2026-11-01", "status": "off_day", "minutes_worked": null },
    { "date": "2026-11-02", "status": "on_time", "minutes_worked": 480 }
  ]
}
```

Field notes:

- `expected_days`: days whose status is `early`, `on_time`, `late` or
  `absent`.
- `present_days`: `early + on_time + late`.
- `punctuality`: `round((early + on_time) / expected_days * 100)`, or `100`
  when `expected_days` is 0.
- `avg_clock_in` / `avg_clock_out`: local `HH:mm`, or `null` with no records.
- `minutes_worked`: sum of closed records in the period.
- `streak`: consecutive `early`/`on_time` days walking back from today,
  skipping holidays, off-days, exempt days, `not_clocked_in` and `upcoming`.
  The first `late` or `absent` stops the count.
- `late_limit`: the workspace `max_late`, or `null` when lateness tracking is
  off.
- `days`: one entry per day from `date_from`, oldest first.

---

## GET `/attendance/list-records/{workspace_id}/`

Query: `user_id`, `date_from`, `date_to`, `status=early|on_time|late`,
`page` (default 1), `page_size` (default 30, max 100).

Newest `clock_in_at` first. Without `user_id`, returns everyone the caller may
see. `status` filters on `in_status`.

**Sample response:**

```json
{
  "items": [
    {
      "id": "0f0f9a6a-8f37-4f3a-9b4e-4d6e3d3f4a10",
      "user": {
        "id": "c2d3e4f5-a6b7-4c8d-9e0f-1a2b3c4d5e6f",
        "email": "ada@example.com",
        "first_name": "Ada",
        "last_name": "Obi",
        "photo": null
      },
      "date": "2026-11-21",
      "clock_in_at": "2026-11-21T08:02:00Z",
      "clock_out_at": "2026-11-21T17:15:00Z",
      "in_status": "on_time",
      "out_status": "on_time",
      "method": "location",
      "place": "Head office",
      "minutes_late": 0,
      "minutes_worked": 553,
      "note": null
    }
  ],
  "total": 1,
  "page": 1,
  "page_size": 30,
  "total_pages": 1
}
```

`minutes_worked` is `null` while the record is still open.

**Errors:**

| Code | Detail |
| --- | --- |
| 403 | `You can't see this person's attendance.` |

---

## GET `/attendance/list-board/{workspace_id}/`

Query: `date` (default: today). **Plain array.** Every active member the
caller may see, including people with no record.

**Sample response:**

```json
[
  {
    "user": {
      "id": "c2d3e4f5-a6b7-4c8d-9e0f-1a2b3c4d5e6f",
      "email": "ada@example.com",
      "first_name": "Ada",
      "last_name": "Obi",
      "photo": null
    },
    "job_title": "Accountant",
    "status": "late",
    "record": {
      "id": "0f0f9a6a-8f37-4f3a-9b4e-4d6e3d3f4a10",
      "user": {
        "id": "c2d3e4f5-a6b7-4c8d-9e0f-1a2b3c4d5e6f",
        "email": "ada@example.com",
        "first_name": "Ada",
        "last_name": "Obi",
        "photo": null
      },
      "date": "2026-11-21",
      "clock_in_at": "2026-11-21T08:42:00Z",
      "clock_out_at": null,
      "in_status": "late",
      "out_status": null,
      "method": "wifi",
      "place": "Acme Staff",
      "minutes_late": 7,
      "minutes_worked": null,
      "note": null
    },
    "late_count": 6,
    "over_limit": true
  }
]
```

`late_count` counts late records in the lateness period containing `date`.
`over_limit` is `lateness.enabled && late_count > max_late`.

For a date before a member's attendance tracking began (settings creation or
membership join), `status` is `not_clocked_in` when there is no record. Such
dates are not reported as absences.

---

## GET `/attendance/get-weather/{workspace_id}/`

Query: `lat`, `lng` (required).

**Sample response:**

```json
{
  "temperature_c": 30,
  "code": 2,
  "is_day": true,
  "place": "Head office"
}
```

`code` is the WMO weather code. `place` is the nearest workplace location
within 30 km, otherwise `null`. Weather is proxied by the server, cached for
20 minutes per rounded coordinate pair in a bounded process-local cache, and
returns 503 `"Weather is unavailable right now."` when the provider is
unreachable and no cached value exists.

---

## GET `/attendance/search-places/{workspace_id}/`

Query: `q`. Returns `[]` when `q` is shorter than 3 characters.
**Plain array.**

**Sample response:**

```json
[
  {
    "name": "Eko Hotel",
    "address": "Adetokunbo Ademola St, Victoria Island, Lagos",
    "lat": 6.4265,
    "lng": 3.4280
  }
]
```

The server proxies the configured geocoder, applies a real User-Agent,
throttles to at most one request per second per app process, and caches
results in a bounded process-local cache. If the provider fails, the route
returns `[]`.

---

## Lateness notifications

After a **late** clock-in, the server counts the person's late records from
the start of the current week/month. When the count is greater than
`lateness.max_late` and no alert has been sent for that period, it:

1. Creates an `attendance_late_flag` row for the person and period.
2. Notifies `lateness.notify_ids`, or every owner/admin when that list is
   empty, plus the line manager when `notify_line_manager` is true.

Notification kind: `attendance_late_limit`. Message:

```text
Ada Obi has been late 6 times this month (limit 5).
```

The alert is sent **once per person per period**. In the app, tapping the
notification opens `/attendance/team`.

## Background jobs

`absent`, `not_clocked_in` and overtime are derived when read, and lateness
alerts are sent inline during clock-in. One Celery beat task,
`attendance.tasks.refresh_public_holidays` (daily at 03:40 UTC), tops up the
public holidays for the current and next year when a workspace has none for
that year, so long-lived workspaces do not silently lose holidays.

## Configuration

| Env variable | Default | Purpose |
| --- | --- | --- |
| `ATTENDANCE_WEATHER_URL` | `https://api.open-meteo.com/v1/forecast` | Weather provider |
| `ATTENDANCE_WEATHER_TIMEOUT_SECONDS` | `5` | Weather request timeout |
| `ATTENDANCE_WEATHER_CACHE_SECONDS` | `1200` | Weather cache lifetime |
| `ATTENDANCE_GEOCODING_URL` | `https://nominatim.openstreetmap.org/search` | Place-search provider |
| `ATTENDANCE_GEOCODING_USER_AGENT` | built from `BRAND_NAME`/`SUPPORT_EMAIL` | Provider User-Agent |
| `ATTENDANCE_GEOCODING_CACHE_SECONDS` | `86400` | Place-search cache lifetime |
| `ATTENDANCE_GEOCODING_ENABLED` | `true` | Set false to return `[]` without calling the provider |
| `ATTENDANCE_DEFAULT_COUNTRY` | `NG` | Country whose public holidays are seeded |

## Out of scope (for now)

Project time (`/attendance/list-project-setups/`, `/attendance/start-session/`,
etc.) is not implemented yet. Visitors now has its own live API — see
[`visitor_docs.md`](visitor_docs.md). The attendance History screen's "Export
CSV" is generated by the client; there is no export route.
