# Guest Check-In API Documentation

Source: `tms/guest_checkin/routers.py`

> **Legacy module.** The pass-based Visitors API now lives in
> [`visitor_docs.md`](visitor_docs.md). This guest check-in API remains live
> while the frontend migrates, and its data can be mirrored into Visitors by
> the legacy sync once enabled.

**Prefix:** `/guest-checkin`

For the frontend screen-by-screen guide, see
[`guest_checkin_integration.md`](guest_checkin_integration.md).

Guest check-in gives every workspace a permanent QR code. Guests scan the
code, check in on their phone, and scan the same code (or use a four-character
code) to check out. Admins see the visitor log and the live in-building count.

## Concepts

| Entity | Meaning |
| --- | --- |
| Organization | A workspace (`Workspace`). |
| Entry point | One printed QR code. It has a permanent 8-character slug and optionally belongs to a location. |
| Location | A branch/entrance (for example “Lagos HQ”). Each location gets its own code. |
| Visit | One guest's check-in. `party_size` records the whole group. |
| Visit token | A 128-bit random token stored only as a SHA-256 hash. It is sent in the `sp_visit` HttpOnly cookie. |
| Check-out code | Four characters shown on the welcome screen. It is unique among open visits at the same entry point. |
| Audit log | Immutable record of force check-outs, voids, flags, deletes, exports, QR regeneration and settings/location changes. |

## Statuses

| Status | Meaning |
| --- | --- |
| `IN_BUILDING` | Open visit. Counted in In Building Now. |
| `CHECKED_OUT` | The guest checked out with the cookie, code or one-tap link. |
| `FORCE_CHECKED_OUT` | An admin checked the guest out. |
| `AUTO_CLOSED` | The nightly job closed the visit. `check_out_at` is intentionally empty. |
| `VOIDED` | Marked as spam/void. |

`checked_out_by` is `GUEST`, `ADMIN` or `SYSTEM`. `flagged` is set when a visit
is closed within the suspicious-activity window (60 seconds by default) or
when an admin flags it manually.

## Roles

Workspace owners and admins have full guest-attendance access. Other members
need a guest-attendance role on their membership:

| Capability | Owner/admin | Security | Reception |
| --- | --- | --- | --- |
| View visitor log and In Building | Yes | Yes | Yes |
| Check out guests | Yes | Yes | Yes |
| Flag / void | Yes | Yes | No |
| Export CSV/XLSX | Yes | Yes | No |
| Delete visits (soft) | Yes | No | No |
| Settings, locations and QR codes | Yes | No | No |

`GET /guest-checkin/my-access/{workspace_id}/` returns the effective role and
capabilities for the signed-in user.

## QR code and URL

The QR code encodes:

```
{GUEST_CHECKIN_PUBLIC_URL or FRONTEND_URL}/g/{entry_slug}
```

`entry_slug` is generated once from an alphabet that excludes look-alike
characters. The code is permanent; regeneration is an emergency action that
creates a new entry point and leaves the old slug returning `replaced`.

Each location gets its own entry point and slug. The spec's nested
`/g/{org_slug}/{location_slug}` path is collapsed into one opaque entry-point
slug per printed code.

## Public flow

### Scan decision

`GET /guest-checkin/scan/{slug}/`

- `404` `Invalid code.` when the slug does not exist.
- `state=replaced` when the code was regenerated.
- `state=disabled` when the code was deactivated or the feature is off.
- `state=check_out_prompt` when the `sp_visit` cookie matches an open visit
  at this entry point.
- `state=check_in` otherwise.

**Sample response:**

```json
{
  "state": "check_in",
  "message": null,
  "organization": {
    "display_name": "Acme Group",
    "logo": "https://…",
    "welcome_message": "Welcome to Acme Group!"
  },
  "entry_point": {
    "slug": "k7Qm2xRp",
    "location_name": "Lagos HQ",
    "timezone": "Africa/Lagos"
  },
  "reasons": [
    "Meeting",
    "Interview",
    "Delivery",
    "Contractor / Maintenance",
    "Personal",
    "Other"
  ],
  "collect_phone": true,
  "collect_email": true,
  "host_search_enabled": true,
  "consent_text": "Acme Group records your visit for safety and security.",
  "privacy_policy_url": "https://samepeople.com/privacy",
  "active_visit": {
    "first_name": "Jane",
    "check_in_at": "2026-11-04T09:45:00Z",
    "party_size": 2
  }
}
```

`active_visit` is only present for `check_out_prompt` and only contains the
caller's own first name.

### Host suggestions

`GET /guest-checkin/list-hosts/{slug}/?search=tunde&limit=20`

Returns an empty list when host search is disabled. Results contain only
`id`, `name` and `job_title` — never email addresses or phone numbers.

### Check in

`POST /guest-checkin/check-in/{slug}/`

**Payload:**

```json
{
  "guest_name": "Jane Doe",
  "reason_category": "Meeting",
  "reason_note": null,
  "host_employee_id": "44444444-4444-4444-8444-444444444444",
  "party_size": 2,
  "phone": "+2348035550142",
  "email": "jane@example.com",
  "consent": true,
  "idempotency_key": "aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa"
}
```

Rules:

- `guest_name` is 2–120 characters.
- `reason_category` must be in the workspace's reason list. `Other` requires
  `reason_note`.
- `party_size` is 1–20.
- `phone` is normalised to E.164; email is validated.
- `host_employee_id` is only accepted when host search is enabled and the
  person is eligible under the workspace's host scope.
- `consent` must be `true`; `consent_at` is recorded.
- `idempotency_key` prevents duplicate visits from a double-tapped form.
- Per-IP and per-organization rate limits apply.

**Response `201`:**

```json
{
  "first_name": "Jane",
  "checked_in_at": "2026-11-04T09:45:00Z",
  "checkout_code": "K7M2",
  "organization_name": "Acme Group",
  "welcome_message": "Welcome to Acme Group!",
  "party_size": 2,
  "location_name": "Lagos HQ",
  "timezone": "Africa/Lagos",
  "checkout_link_sent": true
}
```

The response sets the `sp_visit` cookie. When an email was supplied, the
guest also receives a one-tap check-out email. Host notifications are sent
when enabled.

### Check out with the cookie

`POST /guest-checkin/check-out/{slug}/`

```json
{}
```

The server reads `sp_visit`, finds the open visit at this entry point, closes
it and clears that entry from the cookie.

### Check out with a code

```json
{
  "checkout_code": "K7M2"
}
```

Codes are case-insensitive. Five wrong attempts per device and per IP in ten
minutes returns `429`. A correct code still works after a cookie was lost.

### Request a new check-out link

`POST /guest-checkin/request-checkout-link/{slug}/`

```json
{
  "email": "jane@example.com"
}
```

A phone number may be supplied instead, but SMS is not configured yet.
The endpoint always returns the same `202` response so it cannot be used to
probe whether a phone/email is on file. Email links expire after 24 hours and
work once.

### Consume a one-tap link

`POST /guest-checkin/check-out-with-token/`

```json
{
  "token": "<token from the email link>"
}
```

The token is sent in the request body, not the URL, so it does not appear in
API access logs. It is valid for one check-out only.

## Admin endpoints

All admin endpoints require `Authorization: Bearer <JWT>` and an active
workspace membership.

### Access

| Method & path | Description |
| --- | --- |
| `GET /guest-checkin/my-access/{workspace_id}/` | Effective role and capabilities. |
| `GET /guest-checkin/get-settings/{workspace_id}/` | Settings for the Settings/QR tabs. |
| `PUT /guest-checkin/update-settings/{workspace_id}/` | Partial settings update. |
| `GET /guest-checkin/list-access/{workspace_id}/` | Members and guest roles. |
| `PUT /guest-checkin/set-access/{workspace_id}/{user_id}/` | Assign `security`/`reception` or clear with `null`. |

Settings update accepts any subset of:

```json
{
  "is_enabled": true,
  "display_name": "Acme Group",
  "welcome_message": "Welcome!",
  "consent_text": "Acme records your visit for safety and security.",
  "privacy_policy_url": "https://samepeople.com/privacy",
  "reasons": ["Meeting", "Interview", "Other"],
  "host_search_enabled": true,
  "host_scope": "custom",
  "host_member_ids": ["44444444-4444-4444-8444-444444444444"],
  "host_notifications": true,
  "collect_phone": true,
  "collect_email": true,
  "auto_close_time": "23:59",
  "timezone": "Africa/Lagos",
  "retention_days": 90,
  "checkin_limit_per_ip": 10,
  "org_limit_per_10min": 30,
  "code_attempt_limit": 5,
  "flag_under_seconds": 60
}
```

`host_scope` is `all_members`, `owners_admins` or `custom`. Enabling the
feature automatically creates the organization-wide code; creating a location
automatically creates that location's code. `privacy_policy_url` must be an
absolute `http://` or `https://` URL.

### Locations

| Method & path | Description |
| --- | --- |
| `GET /guest-checkin/list-locations/{workspace_id}/` | Branches/entrances, paginated. |
| `POST /guest-checkin/create-location/{workspace_id}/` | Create a location and its code. |
| `PUT /guest-checkin/update-location/{workspace_id}/{location_id}/` | Edit a location. |
| `DELETE /guest-checkin/delete-location/{workspace_id}/{location_id}/` | Soft-delete and deactivate its code. |

### Entry points and QR assets

| Method & path | Description |
| --- | --- |
| `GET /guest-checkin/list-entry-points/{workspace_id}/` | Active codes by default, paginated; `include_inactive=true` shows history. |
| `POST /guest-checkin/create-entry-point/{workspace_id}/` | Repair/create a code while enabled. |
| `GET /guest-checkin/get-entry-point-qr/{workspace_id}/{entry_point_id}/?format=svg|png` | Download the QR code. |
| `GET /guest-checkin/get-entry-point-poster/{workspace_id}/{entry_point_id}/?paper=a4|letter` | Download the PDF poster. |
| `POST /guest-checkin/regenerate-entry-point/{workspace_id}/{entry_point_id}/` | Emergency replacement; body `{"confirmation": "<current slug>"}`. |

Entry-point response items include `url`, `qr_svg_url`, `qr_png_url`,
`poster_a4_url` and `poster_letter_url`.

### Visitor log

`GET /guest-checkin/list-visits/{workspace_id}/`

Query:

| Param | Notes |
| --- | --- |
| `date_from`, `date_to` | Local calendar dates in the workspace timezone. |
| `status` | `IN_BUILDING`, `CHECKED_OUT`, `FORCE_CHECKED_OUT`, `AUTO_CLOSED`, `VOIDED`. |
| `reason` | Exact reason label. |
| `host_id` | Host user id. |
| `location_id` | Location id. |
| `search` | Guest name, phone, email or check-out code. |
| `page`, `page_size` | Default 1 / 20, max 100. |

**Sample item:**

```json
{
  "id": "bbbbbbbb-bbbb-4bbb-8bbb-bbbbbbbbbbbb",
  "guest_name": "Jane Doe",
  "party_size": 2,
  "reason_category": "Meeting",
  "reason_note": null,
  "host": {
    "id": "44444444-4444-4444-8444-444444444444",
    "email": "tunde@example.com",
    "first_name": "Tunde",
    "last_name": "Bakare",
    "photo": null
  },
  "location": {
    "id": "33333333-3333-4333-8333-333333333333",
    "name": "Lagos HQ"
  },
  "entry_point_id": "cccccccc-cccc-4ccc-8ccc-cccccccccccc",
  "check_in_at": "2026-11-04T09:45:00Z",
  "check_out_at": null,
  "status": "IN_BUILDING",
  "checked_out_by": null,
  "closed_by": null,
  "flagged": false,
  "phone": "+2348035550142",
  "email": "jane@example.com",
  "consent_at": "2026-11-04T09:45:00Z",
  "created_at": "2026-11-04T09:45:00Z"
}
```

| Method & path | Description |
| --- | --- |
| `GET /guest-checkin/get-visit/{workspace_id}/{visit_id}/` | Detail with `checkout_code` and `user_agent`. |
| `POST /guest-checkin/checkout-visit/{workspace_id}/{visit_id}/` | Force check-out. Body `{"note": "..."}`. |
| `POST /guest-checkin/void-visit/{workspace_id}/{visit_id}/` | Mark as spam. |
| `POST /guest-checkin/flag-visit/{workspace_id}/{visit_id}/` | Body `{"flagged": true, "note": "..."}`. |
| `DELETE /guest-checkin/delete-visit/{workspace_id}/{visit_id}/` | Soft delete (Owner-level only). |

### In Building Now

`GET /guest-checkin/in-building/{workspace_id}/?location_id=...`

```json
{
  "total_people": 14,
  "visit_count": 9,
  "items": [
    {
      "id": "bbbbbbbb-bbbb-4bbb-8bbb-bbbbbbbbbbbb",
      "guest_name": "Jane Doe",
      "party_size": 2,
      "host_name": "Tunde Bakare",
      "location_name": "Lagos HQ",
      "check_in_at": "2026-11-04T09:45:00Z",
      "flagged": false
    }
  ],
  "generated_at": "2026-11-04T10:00:00Z",
  "timezone": "Africa/Lagos"
}
```

`total_people` sums `party_size`, so a group of three counts as three people.

### Export

`GET /guest-checkin/export-visits/{workspace_id}/?format=csv|xlsx` plus the
same filters as the visitor log. Owner/admin and Security only. Every export
is written to the audit log. CSV and XLSX values starting with `=`, `+`, `-`,
`@`, tab or carriage return are prefixed with `'` to prevent spreadsheet
formula execution.

### Live updates

`GET /guest-checkin/stream-visits/{workspace_id}/`

Server-sent events. Each event is:

```
event: sync
data: {"marker":"2026-11-04T10:00:00+00:00"}
```

The frontend should refetch the visitor log and In Building Now when the
marker changes. `EventSource` cannot send an Authorization header, so consume
this with `fetch` and the normal Bearer token; fall back to polling every 15
seconds if the stream fails.

### Audit log

`GET /guest-checkin/list-audit-log/{workspace_id}/`

Filters: `action`, `actor_id`, `visit_id`, `date_from`, `date_to`, `page`,
`page_size`. Owner/admin only. Actions: `FORCE_CHECKOUT`, `VOID`, `FLAG`,
`DELETE`, `EXPORT`, `REGENERATE_QR`, `SETTINGS_CHANGE`, `LOCATION_CHANGE`,
`RETENTION_PURGE`.

## Cookies and deployment

- `sp_visit` contains an internal `entry_point_id → token` map so one phone
  can hold open visits at multiple locations. It is `HttpOnly`, `Secure`
  outside dev/test, `SameSite=Lax`, `Path=/` and expires after 24 hours.
- `sp_device` is a random identifier used for per-device check-in and
  check-out-code rate limits.
- The frontend and API must be same-site (for example API proxied under the
  same domain, or a sibling subdomain). Cross-site cookies will not be sent
  with `SameSite=Lax`.

The cookie path is `/` rather than the spec's `/g` because the API lives
under `/guest-checkin`; the guest page itself is a frontend route.

## Scheduled jobs

| Job | Schedule | Behaviour |
| --- | --- | --- |
| `guest_checkin.tasks.auto_close_visits` | Every 15 minutes | Closes `IN_BUILDING` visits after each entry point's local auto-close time. Sets `AUTO_CLOSED`, `checked_out_by=SYSTEM`, leaves `check_out_at` empty. |
| `guest_checkin.tasks.purge_guest_visits` | Daily at 03:00 UTC | Hard-deletes visits older than the workspace retention period and soft-deleted rows older than 30 days. Redacts phone/email from matching audit metadata and records the count. |

## Security and privacy mapping

1. Visit tokens are 128-bit random values stored as SHA-256 hashes.
2. Entry-point slugs are random and never sequential.
3. The visit token is in an HttpOnly cookie, never localStorage.
4. Guest input is returned as JSON; the admin frontend must render it as text,
   not HTML.
5. CSV/XLSX exports neutralize formula prefixes.
6. Check-in is limited per IP and per organization; code attempts are limited
   per device and per IP.
7. The guest API never lists other visitors, never confirms whether a contact
   is on file, and only shows the caller's own first name.
8. Every admin query is scoped by workspace and every public query by entry
   point.
9. Privileged actions are audited.
10. Consent is recorded and retention is enforced by the purge job.
11. Phone and email are optional and are not used for marketing.
12. HTTPS/HSTS is handled by the deployment proxy.

## Spec-to-API mapping

| Spec path | Implemented route |
| --- | --- |
| `GET /g/{org_slug}` | Frontend route; calls `GET /guest-checkin/scan/{slug}/`. |
| `POST /api/g/{slug}/checkins` | `POST /guest-checkin/check-in/{slug}/` |
| `POST /api/g/{slug}/checkouts` | `POST /guest-checkin/check-out/{slug}/` |
| `POST /api/g/{slug}/checkout-links` | `POST /guest-checkin/request-checkout-link/{slug}/` |
| `GET /g/{slug}/out/{signed_token}` | Frontend route; calls `POST /guest-checkin/check-out-with-token/`. |
| `GET /api/admin/visits` | `GET /guest-checkin/list-visits/{workspace_id}/` |
| `GET /api/admin/visits/stream` | `GET /guest-checkin/stream-visits/{workspace_id}/` |
| `POST /api/admin/visits/{id}/checkout` | `POST /guest-checkin/checkout-visit/{workspace_id}/{visit_id}/` |
| `POST /api/admin/visits/{id}/void` | `POST /guest-checkin/void-visit/{workspace_id}/{visit_id}/` |
| `DELETE /api/admin/visits/{id}` | `DELETE /guest-checkin/delete-visit/{workspace_id}/{visit_id}/` |
| `GET /api/admin/visits/export` | `GET /guest-checkin/export-visits/{workspace_id}/` |
| `GET /api/admin/entry-points` | `GET /guest-checkin/list-entry-points/{workspace_id}/` |
| `POST /api/admin/entry-points/{id}/regenerate` | `POST /guest-checkin/regenerate-entry-point/{workspace_id}/{entry_point_id}/` |

## Deferred

- Cloudflare Turnstile and the honeypot field (bot protection).
- SMS delivery for phone-only check-out links.
- The optional morning email summarising visits auto-closed overnight.
- Geofence and Wi-Fi IP allowlist.
- “Remember me” name pre-fill, multiple languages and weekly reports.
