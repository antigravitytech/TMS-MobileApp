# Attendance — Frontend Integration Guide

Audience: the web client developer.

The backend implements the Attendance feature from
`designs/attendance-and-visitors-backend.md`. Endpoint contracts are in
[`attendance_docs.md`](attendance_docs.md). This guide maps the design's four
tabs to the live routes and lists the behaviour the client should expect.

**Not live yet:** Project time (`/attendance/list-project-setups/`,
`start-session`, `session-event`, `stop-session`, `list-sessions`). Keep
those screens on mocks until their backend pass. Visitors is live in a
separate module — see
[`visitors_changes_integration.md`](visitors_changes_integration.md). The
History screen's "Export CSV" remains client-side.

## Base URL and auth

- Base path: `/attendance`
- Every route needs `Authorization: Bearer <JWT>`.
- `{workspace_id}` is the workspace UUID (the design's `{ws}`).
- Trailing slashes are required.

## Routes at a glance

| Route name | Method and path |
| --- | --- |
| `attendance:get-settings` | `GET /attendance/get-settings/{workspace_id}/` |
| `attendance:update-settings` | `PUT /attendance/update-settings/{workspace_id}/` |
| `attendance:get-today` | `GET /attendance/get-today/{workspace_id}/` |
| `attendance:clock-in` | `POST /attendance/clock-in/{workspace_id}/` |
| `attendance:clock-out` | `POST /attendance/clock-out/{workspace_id}/` |
| `attendance:get-stats` | `GET /attendance/get-stats/{workspace_id}/?user_id=&period=` |
| `attendance:list-records` | `GET /attendance/list-records/{workspace_id}/?user_id=&date_from=&date_to=&status=&page=&page_size=` |
| `attendance:list-board` | `GET /attendance/list-board/{workspace_id}/?date=` |
| `attendance:get-weather` | `GET /attendance/get-weather/{workspace_id}/?lat=&lng=` |
| `attendance:search-places` | `GET /attendance/search-places/{workspace_id}/?q=` |

`list-board` and `search-places` are **plain arrays**, not paginated
envelopes. `list-records` is paginated with the standard
`{items, total, page, page_size, total_pages}` shape.

## Screen map

### Navigation

The design has four tabs: `Today`, `History`, `Team`, `Settings`.

- `can_edit` on the settings response drives the Settings save button and the
  admin-only sections.
- The Team tab is safe to show to everyone. The server scopes it: members see
  themselves and their direct reports; owners/admins see every active member.
- Weather is optional chrome. If `get-weather` returns 503, hide the card
  rather than blocking the screen.

### Today

Call `GET get-today` on mount and after every clock action.

Use `enabled`, `expected`, `status`, `holiday`, `exempt`, `schedule`,
`checks`, `locations` and `record`:

| Field | Client use |
| --- | --- |
| `enabled: false` | Show "Attendance is switched off in this workspace." |
| `status` | Pick the day-state copy and colour |
| `record` | Show the running timer, clock-in/out times and note |
| `expected` | Whether this is a normal working day |
| `holiday` | Show the holiday banner (people may still clock in) |
| `exempt` | Show "you can clock in from anywhere" |
| `schedule` | Show the expected window / preview |
| `checks` | Explain the requirement: location, Wi-Fi, either, both, anywhere |
| `locations` | Weather fallback and "you're near…" copy |
| `next_holiday` | Optional footer line |

`status` values and suggested labels:

| Status | Label |
| --- | --- |
| `early` | Early |
| `on_time` | On time |
| `late` | Late |
| `absent` | Absent |
| `not_clocked_in` | Not clocked in |
| `holiday` | Holiday |
| `off_day` | Day off |
| `exempt` | Exempt |
| `upcoming` | Upcoming |

**Clock-in flow:**

1. Try `navigator.geolocation.getCurrentPosition` with a reasonable timeout.
   If the user refuses, send `lat: null, lng: null` — the server will only
   reject when a location check is active.
2. Send `accuracy_m` from the position object.
3. Include an optional `note` (≤ 280 chars).
4. On 200, replace state with the returned `AttendanceToday`.
5. On 403, show `detail` verbatim. The server's message already explains
   distance or which network to join.
6. On 409, refresh `get-today`; the record may already exist from another tab.

**Clock-out flow:** same body. Send the note if the user typed one; it is
appended to the clock-in note on the server. On 200, replace state. On 409,
refresh `get-today`.

The timer should be computed from `record.clock_in_at`, not from a
client-started stopwatch, so a reload keeps the correct time.

### History

Call `GET list-records` with `page`, `page_size` (default 30, max 100),
`date_from`, `date_to` and `status`.

- `status` filters on `in_status` only.
- Results are newest clock-in first.
- `minutes_worked` is `null` while the record is open.
- The person filter uses `user_id`; omit it to show everyone the caller may
  see.
- A 403 with `"You can't see this person's attendance."` means the selected
  person is outside the caller's reporting scope.
- Export CSV from the loaded/filtered rows on the client; there is no export
  endpoint.

Date pickers should send `yyyy-MM-dd`. The server compares the stored
workspace-local `date`, not UTC timestamps.

### Team

Call `GET list-board?date=yyyy-MM-dd` (default today). The response is a plain
array. Each entry has:

- `user` — build the avatar and name.
- `job_title` — from the workspace membership.
- `status` — same `DayStatus` union as Today. For a date before the
  person's attendance tracking began, it is `not_clocked_in` when there is
  no record (not `absent`).
- `record` — `null` when the person has not clocked in.
- `late_count` — late records in the lateness period containing `date`.
- `over_limit` — show the red "over the limit" treatment.

Group rows for the board as:

- `early` / `on_time` / `late` → In / Late
- `absent` → Absent
- `not_clocked_in` → Not in yet
- `holiday` / `off_day` / `exempt` → Away
- `upcoming` → Upcoming (only for future dates)

Polling: the design refreshes the board every 30 seconds while visible. Call
`get-today` after clocking; there is no websocket for attendance.

Selecting a row opens History with `user_id` and `get-stats` for that person.

### Settings

Call `GET get-settings` on mount. The response **is** the form model, with two
extra read-only fields:

- `exempt`: `UserBrief[]` — render names/avatars.
- `can_edit`: `boolean` — hide/disable editing.

To save, send the same document **without** `exempt` and `can_edit`, **plus**
`exempt_ids: string[]`:

```ts
const { exempt, can_edit, ...rest } = settings;
const body = { ...rest, exempt_ids: exempt.map((person) => person.id) };
await api.put(`/attendance/update-settings/${workspaceId}/`, body);
```

The PUT replaces the whole document. Always send every location, network and
holiday you want to keep. New nested items can keep their temporary client id
(e.g. `loc_new_1`); the server creates them and returns real UUIDs. Existing
items keep their id when re-sent.

Sections:

- **General:** `enabled`, `geofence_enabled`, `wifi_enabled`, `require`.
  Location and Wi-Fi checks only take effect when there is at least one
  location / network.
- **Hours:** `schedule.mode` (`strict` or `flexible`), start/end windows,
  `early_minutes`, `grace_minutes`, `absent_after`, `working_days`. Send full
  weekday names (`Monday`…). In strict mode the server normalises
  `start_until = start` and `end_until = end`; mirror that in the form when
  the user switches mode.
- **Locations:** point or polygon. A polygon needs at least three corners.
  `center` is used for messages and weather. `radius_m` is 20–5000.
- **Wi-Fi:** the browser cannot read the SSID. The admin enters the office's
  public IP addresses or CIDR ranges. The server matches the request's
  resolved client IP; the client sends nothing.
- **Lateness:** `enabled`, `max_late` (1–60), `period` (`week`/`month`),
  `notify_ids`, `notify_line_manager`. People picker uses workspace members;
  the server validates them.
- **Holidays:** full replacement. `source` is `public` or `custom`; only
  `observed: true` days suppress absences. The seeded Nigerian holidays are
  ordinary rows, so the client can edit or delete them.
- **Exemptions:** people picker; serialise to `exempt_ids`.

The save endpoint returns the fresh document. Replace local state with it so
new UUIDs are picked up.

### Location picker

- `GET search-places?q=` is for the search box. Call it only when the query is
  at least 3 characters; debounce input. It returns up to 6 results as
  `{name, address, lat, lng}`.
- Use the map click / drag handlers for the actual pin or polygon. The search
  result only moves the map and fills the address.
- "Go to my location" should request browser geolocation and centre the map.
- A point location sends `kind: "point"`, `center`, `radius_m`, `points: []`.
- A polygon sends `kind: "polygon"`, `center` (centroid), `radius_m` (used for
  the centre slack and weather), and `points` with at least three corners.
- When the user saves a new location, keep its temporary id in the draft; the
  server response replaces it with a UUID.

### Weather

Call `GET get-weather?lat=&lng=` with the device coordinates, or with the
first location's centre when geolocation is unavailable. `code` is a WMO code
(the design's background mapping is unchanged); `place` is the nearest
workplace within 30 km.

The route is cached server-side. A 503 means the weather provider is
unreachable; hide the card and keep the clock usable.

## Notifications

New kind: `attendance_late_limit`.

- The in-app notification message is
  `"{name} has been late {n} times this {week|month} (limit {max})."`
- Tapping it should navigate to `/attendance/team`.
- It is sent once per person per week/month. `notify_ids` receives it; when
  that list is empty, all owners/admins do; the line manager is added when
  `notify_line_manager` is true. The late person is never notified about
  their own lateness.
- Delivery follows the default in-app preference. The existing Settings
  notification matrix has no attendance row, so no new preference checkbox is
  required.

## Permissions and visibility

| Caller | Settings | Today/clock | Stats/history | Team board |
| --- | --- | --- | --- | --- |
| Member | read (`can_edit: false`) | own | own + direct reports | own + direct reports |
| Owner/admin | read/write | own | everyone active | everyone active |

- A member who is not a line manager sees only themselves on Team.
- `update-settings` for a non-manager returns 403 with the exact sentence in
  the docs.
- A person outside the caller's scope returns 403
  `"You can't see this person's attendance."`

## Dates, times and timezones

- All schedule times are `HH:mm` in the workspace timezone
  (`settings.timezone`).
- `date` fields and `valid_on`-style fields are `yyyy-MM-dd`.
- `clock_in_at` / `clock_out_at` are ISO timestamps with an offset. Render
  them in the workspace timezone, not the device timezone, when the workspace
  timezone differs.
- The day boundary for records is the workspace-local date.
- `avg_clock_in` and `avg_clock_out` are already formatted local `HH:mm`.

## Error handling

The client shows `detail` verbatim. Common cases:

| Code | Where | Detail |
| --- | --- | --- |
| 403 | clock-in | Attendance disabled / location needed / outside a location / wrong network |
| 403 | settings update | Only owners and admins |
| 403 | stats/history/board person filter | You can't see this person's attendance. |
| 409 | clock-in | You've already clocked in today. |
| 409 | clock-out | You haven't clocked in today. / You've already clocked out today. |
| 422 | settings | A polygon with fewer than 3 points, unknown people, bad IPs |

Pydantic type errors still use FastAPI's standard 422 body (`detail` is a
list). For business-rule failures above, `detail` is a string.

## Suggested local state

```ts
type AttendanceSettings = {
  enabled: boolean;
  geofence_enabled: boolean;
  wifi_enabled: boolean;
  require: "any" | "all";
  locations: AttendanceLocation[];
  networks: AttendanceNetwork[];
  schedule: AttendanceSchedule;
  lateness: AttendanceLateness;
  holidays: AttendanceHoliday[];
  exempt: UserBrief[];
  country: string;
  timezone: string | null;
  can_edit: boolean;
};

type AttendanceToday = {
  date: string;
  status: DayStatus;
  record: AttendanceRecord | null;
  expected: boolean;
  holiday: AttendanceHoliday | null;
  exempt: boolean;
  schedule: AttendanceSchedule;
  checks: { location: boolean; wifi: boolean; require: "any" | "all" };
  locations: AttendanceLocation[];
  next_holiday: AttendanceHoliday | null;
  enabled: boolean;
};
```

The design's Zod files can be used unchanged for responses, except that this
build does not return `project`/work-session shapes yet.

## QA checklist

- [ ] First read of a business workspace creates settings and Nigerian
      holidays; `can_edit` is true for the owner.
- [ ] A member sees `can_edit: false` and cannot save.
- [ ] Strict/flexible hours produce the documented Today copy.
- [ ] Location refused → the 403 sentence is shown, not a generic error.
- [ ] Wi-Fi clock-in works from the office IP and fails elsewhere.
- [ ] Duplicate clock-in/out shows the 409 sentence.
- [ ] History pagination/filter and client-side CSV work.
- [ ] Team board is an array, scoped correctly, with `over_limit` styling.
- [ ] Weather 503 hides the card without breaking the clock.
- [ ] Search places debounces and handles `[]`.
- [ ] `attendance_late_limit` opens `/attendance/team`.
