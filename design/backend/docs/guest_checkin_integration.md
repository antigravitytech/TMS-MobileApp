# Guest Check-In Frontend Integration Guide

> **Legacy flow.** The new pass-based Visitors screens are documented in
> [`visitors_changes_integration.md`](visitors_changes_integration.md). This
> guide remains valid for the old QR check-in/out and visitor-log tabs.

Companion to [`guest_checkin_docs.md`](guest_checkin_docs.md). This maps the
SamePeople guest check-in spec to the API: which screen calls which endpoint,
what to render, and how to keep the visitor log fresh.

All routes are under the API base URL. Admin routes require
`Authorization: Bearer <JWT>`; public guest routes do not. List endpoints
return the standard envelope:

```json
{
  "items": [],
  "total": 0,
  "page": 1,
  "page_size": 20,
  "total_pages": 0
}
```

**Realtime note:** there is no WebSocket API. The visitor log can use the SSE
stream with `fetch`, with polling every 15 seconds as a fallback.

---

## 1. Deployment and cookies

The guest page lives at:

```
{GUEST_CHECKIN_PUBLIC_URL or FRONTEND_URL}/g/{entry_slug}
```

The QR code encodes that URL. The page calls the public API with:

```ts
fetch(`${API_BASE}/guest-checkin/scan/${entrySlug}/`, {
  credentials: "include",
});
```

Requirements:

- **Same-site deployment.** The guest cookies are `SameSite=Lax`. Serve the
  API from the same registrable domain as the frontend (for example an
  `/api` reverse proxy, or `api.samepeople.com` + `samepeople.com`), and set
  `CORS_ALLOW_ORIGINS` to the exact frontend origin so credentialed CORS
  works.
- **Do not store the visit token in localStorage.** It is HttpOnly by design.
- `GUEST_CHECKIN_PUBLIC_URL` defaults to `FRONTEND_URL`; set it to
  `https://samepeople.com` for the production QR codes.

Cookies:

| Cookie | Purpose |
| --- | --- |
| `sp_visit` | Hidden `entry_point_id → token` map. Enables check-out prompts and multi-location visits. |
| `sp_device` | Random id used for per-device check-in and check-out-code attempt limits. |

`sp_visit` expires after 24 hours. If it is missing, the guest can check out
with their four-character code.

---

## 2. Screen map

| Screen | Endpoint(s) |
| --- | --- |
| Guest landing / router | `GET /guest-checkin/scan/{slug}/` |
| Screen 1: check-in form | `GET /guest-checkin/scan/{slug}/`, `GET /guest-checkin/list-hosts/{slug}/`, `POST /guest-checkin/check-in/{slug}/` |
| Screen 2: welcome | response from `POST /guest-checkin/check-in/{slug}/` |
| Screen 3: check-out prompt | `GET /guest-checkin/scan/{slug}/`, `POST /guest-checkin/check-out/{slug}/` |
| Screen 4: goodbye | response from check-out |
| Fallback: code form | `POST /guest-checkin/check-out/{slug}/` |
| Fallback: lost code | `POST /guest-checkin/request-checkout-link/{slug}/` |
| One-tap email link | `POST /guest-checkin/check-out-with-token/` |
| Admin QR Code tab | `GET /guest-checkin/get-settings/{workspace_id}/`, `GET /guest-checkin/list-entry-points/{workspace_id}/`, QR/poster download routes, regenerate route |
| Admin Visitor Log | `GET /guest-checkin/list-visits/{workspace_id}/`, actions, export, `GET /guest-checkin/stream-visits/{workspace_id}/` |
| Admin In Building Now | `GET /guest-checkin/in-building/{workspace_id}/` |
| Admin Settings | `GET /guest-checkin/get-settings/{workspace_id}/`, `PUT /guest-checkin/update-settings/{workspace_id}/`, location routes, access routes |
| Admin access/roles | `GET /guest-checkin/my-access/{workspace_id}/`, `GET /guest-checkin/list-access/{workspace_id}/`, `PUT /guest-checkin/set-access/{workspace_id}/{user_id}/` |

---

## 3. Core data shapes

### Scan result

```ts
type GuestScan = {
  state: "check_in" | "check_out_prompt" | "replaced" | "disabled";
  message: string | null;
  organization: {
    display_name: string;
    logo: string | null;
    welcome_message: string | null;
  };
  entry_point: {
    slug: string;
    location_name: string | null;
    timezone: string;
  };
  reasons: string[];
  collect_phone: boolean;
  collect_email: boolean;
  host_search_enabled: boolean;
  consent_text: string;
  privacy_policy_url: string | null;
  active_visit: {
    first_name: string;
    check_in_at: string;
    party_size: number;
  } | null;
};
```

### Check-in result

```ts
type GuestCheckIn = {
  first_name: string;
  checked_in_at: string;       // UTC ISO timestamp
  checkout_code: string;       // 4 characters
  organization_name: string;
  welcome_message: string | null;
  party_size: number;
  location_name: string | null;
  timezone: string;            // IANA, format times locally
  checkout_link_sent: boolean;
};
```

### Check-out result

```ts
type GuestCheckOut = {
  message: string;
  checked_out_at: string;
  organization_name: string;
  first_name: string;
  party_size: number;
};
```

### Visitor

```ts
type GuestVisit = {
  id: string;
  guest_name: string;
  party_size: number;
  reason_category: string;
  reason_note: string | null;
  host: ChatPerson | null;       // id, email, first/last name, photo
  location: { id: string; name: string } | null;
  entry_point_id: string;
  check_in_at: string;
  check_out_at: string | null;
  status: "IN_BUILDING" | "CHECKED_OUT" | "FORCE_CHECKED_OUT" |
    "AUTO_CLOSED" | "VOIDED";
  checked_out_by: "GUEST" | "ADMIN" | "SYSTEM" | null;
  closed_by: ChatPerson | null;
  flagged: boolean;
  phone: string | null;
  email: string | null;
  consent_at: string;
  created_at: string;
};
```

`GET /guest-checkin/get-visit/{workspace_id}/{visit_id}/` adds
`checkout_code` and `user_agent`.

### Entry point

```ts
type GuestEntryPoint = {
  id: string;
  slug: string;
  url: string;                  // permanent frontend URL
  location: { id: string; name: string } | null;
  timezone: string;
  active: boolean;
  replaced_by_id: string | null;
  qr_svg_url: string;
  qr_png_url: string;
  poster_a4_url: string;
  poster_letter_url: string;
  created_at: string;
};
```

### Settings

```ts
type GuestSettings = {
  workspace_id: string;
  is_enabled: boolean;
  display_name: string;
  organization_name: string;
  logo: string | null;
  welcome_message: string | null;
  consent_text: string;
  privacy_policy_url: string | null;
  reasons: string[];
  host_search_enabled: boolean;
  host_scope: "all_members" | "owners_admins" | "custom";
  host_member_ids: string[];
  host_notifications: boolean;
  collect_phone: boolean;
  collect_email: boolean;
  auto_close_time: string;      // HH:MM local
  timezone: string;
  retention_days: number;
  limits: {
    checkin_limit_per_ip: number;
    org_limit_per_10min: number;
    code_attempt_limit: number;
    flag_under_seconds: number;
  };
  updated_at: string;
};
```

---

## 4. Guest router

On page load, read `entry_slug` from `/g/:slug`.

```ts
const scan = await api.get(`/guest-checkin/scan/${entrySlug}/`);

if (scan.state === "replaced") showReplaced(scan.message);
else if (scan.state === "disabled") showDisabled(scan.message);
else if (scan.state === "check_out_prompt") showCheckOutPrompt(scan);
else showCheckInForm(scan);
```

`scan.active_visit` is only ever the caller's own visit. Never render a list
of visitors on this page.

---

## 5. Screen 1 — Check-in form

Use `scan.organization`, `scan.reasons`, `scan.collect_phone`,
`scan.collect_email`, `scan.host_search_enabled`, `scan.consent_text` and
`scan.privacy_policy_url`.

Fields:

| Field | Rules |
| --- | --- |
| Full name | Required, 2–120 characters. |
| Reason | Required, one of `scan.reasons`. |
| Reason note | Required when the reason is `Other`; max 500. |
| Host | Optional; only when `host_search_enabled`. |
| Party size | 1–20, default 1. |
| Phone | Optional when `collect_phone`; international/E.164. |
| Email | Optional when `collect_email`. |
| Consent | Checkbox; must be true. |

Generate an idempotency key when the form mounts:

```ts
const idempotencyKey = crypto.randomUUID();
```

Submit:

```ts
await fetch(`/guest-checkin/check-in/${entrySlug}/`, {
  method: "POST",
  credentials: "include",
  headers: { "Content-Type": "application/json" },
  body: JSON.stringify({
    guest_name,
    reason_category,
    reason_note: reason === "Other" ? reasonNote : null,
    host_employee_id: hostId || null,
    party_size: partySize,
    phone: phone || null,
    email: email || null,
    consent: true,
    idempotency_key: idempotencyKey,
  }),
});
```

Host suggestions:

```ts
const hosts = await api.get(
  `/guest-checkin/list-hosts/${entrySlug}/?search=${encodeURIComponent(q)}`,
);
```

Render only `name` and `job_title`; the response never contains email/phone.

---

## 6. Screen 2 — Welcome

Render from the check-in response:

- “Welcome to {organization_name}!”
- “You checked in at {formatLocal(checked_in_at, timezone)}.”
- “Your check-out code: {checkout_code}.”
- “Scan the same QR code when you leave. Keep this code in case your phone
  forgets you.”
- If `checkout_link_sent` is true, “We also emailed you a one-tap check-out
  link.”

Show the code in a large, copyable box. Do not put the token anywhere in the
page.

---

## 7. Screen 3 — Check-out prompt

When scanning again while checked in, `scan.state === "check_out_prompt"`:

- “Hi {active_visit.first_name}, ready to check out?”
- Confirm button:

```ts
await fetch(`/guest-checkin/check-out/${entrySlug}/`, {
  method: "POST",
  credentials: "include",
  headers: { "Content-Type": "application/json" },
  body: JSON.stringify({}),
});
```

- “Not John? Check in instead” calls the check-in endpoint with a fresh
  idempotency key. The previous visit stays open, as required.

## 8. Screen 4 — Goodbye

Use the check-out response:

- “Thanks for visiting! You checked out at {checked_out_at}.”
- “Safe travels.”

## 9. Fallback — check out with a code

Show “Already checked in? Check out with your code” at the bottom of the
check-in form. The code is four characters, excluding look-alike characters.

```ts
const result = await fetch(`/guest-checkin/check-out/${entrySlug}/`, {
  method: "POST",
  credentials: "include",
  headers: { "Content-Type": "application/json" },
  body: JSON.stringify({ checkout_code: code.toUpperCase() }),
});
```

- Five wrong attempts per device and per IP in ten minutes returns `429` with
  `Retry-After`.
- Correct codes work even when the cookie was lost.

Lost the code? Show a phone/email form:

```ts
await fetch(`/guest-checkin/request-checkout-link/${entrySlug}/`, {
  method: "POST",
  credentials: "include",
  headers: { "Content-Type": "application/json" },
  body: JSON.stringify({ email }),
});
```

The response is always the same `202` message. Do not tell the guest whether
the contact matched.

## 10. One-tap email link

The email link points at the frontend:

```
{FRONTEND_URL}/g/out/{token}
```

Extract the token and call:

```ts
await fetch(`/guest-checkin/check-out-with-token/`, {
  method: "POST",
  headers: { "Content-Type": "application/json" },
  body: JSON.stringify({ token }),
});
```

The token expires after 24 hours and works once. Show the goodbye screen or a
friendly “this link is no longer valid” message.

---

## 11. Admin — QR Code tab

1. `GET /guest-checkin/get-settings/{workspace_id}/`
2. `GET /guest-checkin/list-entry-points/{workspace_id}/?include_inactive=true&page=1&page_size=100`
   (use `items`)
3. If `is_enabled` is false, show an Enable button that PUTs
   `{ "is_enabled": true }`. The org code is created automatically.
4. Render one card per entry point:
   - organization or location name;
   - permanent short URL;
   - SVG and PNG download buttons;
   - A4 and Letter poster buttons;
   - `replaced` badge for inactive history.
5. Download routes are authenticated. Fetch them with the Bearer token and
   save the blob; do not point an `<img>` directly at an admin URL that needs
   an Authorization header.
6. Regenerate: require the admin to type the current slug, then POST
   `{ "confirmation": currentSlug }`. Show the warning that the printed code
   will stop working.

## 12. Admin — Visitor Log

`GET /guest-checkin/list-visits/{workspace_id}/`

Query:

| Param | Notes |
| --- | --- |
| `date_from`, `date_to` | Local workspace dates (`YYYY-MM-DD`). |
| `status` | One visit status. |
| `reason` | Exact reason label. |
| `host_id`, `location_id` | UUID filters. |
| `search` | Name, phone, email or check-out code. |
| `page`, `page_size` | Default 1 / 20. |

Columns: Visitor, Group, Reason, Host, Location, Date, Check-in, Check-out,
Status, Actions.

Badges:

- `IN_BUILDING` → “In building”
- `CHECKED_OUT` → “Checked out”
- `FORCE_CHECKED_OUT` → “Checked out by admin”
- `AUTO_CLOSED` → “Auto-closed”
- `VOIDED` → “Voided”
- `flagged === true` → red flag indicator

Actions:

| Action | Request |
| --- | --- |
| View | `GET /guest-checkin/get-visit/{workspace_id}/{visit_id}/` |
| Check out | `POST /guest-checkin/checkout-visit/{workspace_id}/{visit_id}/` `{ "note": "..." }` |
| Flag | `POST /guest-checkin/flag-visit/{workspace_id}/{visit_id}/` `{ "flagged": true, "note": "..." }` |
| Void | `POST /guest-checkin/void-visit/{workspace_id}/{visit_id}/` `{ "note": "..." }` |
| Delete | `DELETE /guest-checkin/delete-visit/{workspace_id}/{visit_id}/` |

Only show Delete for `my-access.can_delete`; Flag/Void for
`my-access.can_flag` / `can_void`; Check out for `can_checkout`.

### Live updates

Use `fetch` with the Bearer token:

```ts
const response = await fetch(
  `${API_BASE}/guest-checkin/stream-visits/${workspaceId}/`,
  { headers: { Authorization: `Bearer ${token}` } },
);
const reader = response.body!.getReader();
// parse "event: sync" frames, then refetch the log
```

Fallback: poll `list-visits` and `in-building` every 15 seconds while the tab
is visible. Pause polling when the document is hidden.

## 13. Admin — In Building Now

`GET /guest-checkin/in-building/{workspace_id}/?location_id=...`

- Show `total_people` in a large counter. It sums group sizes, so a party of
  three counts as three.
- Render `items` as a roll-call list: name, group size, host, location,
  check-in time and a blank tick column.
- Use `window.print()` with a print stylesheet for the evacuation list.
- Refresh on the SSE `sync` event and every 15 seconds as a fallback.

## 14. Admin — Settings

`PUT /guest-checkin/update-settings/{workspace_id}/` accepts any subset:

```ts
{
  display_name,
  welcome_message,
  consent_text,
  privacy_policy_url,
  reasons: string[],
  host_search_enabled,
  host_scope: "all_members" | "owners_admins" | "custom",
  host_member_ids,
  host_notifications,
  collect_phone,
  collect_email,
  auto_close_time: "23:59",
  timezone,
  retention_days,
  checkin_limit_per_ip,
  org_limit_per_10min,
  code_attempt_limit,
  flag_under_seconds,
  is_enabled,
}
```

- `reasons` must contain at least one label; `Other` is only special when it
  is present in the list.
- `host_scope=custom` requires at least one `host_member_ids` value.
- `timezone` is an IANA name, e.g. `Africa/Lagos`.
- Retention defaults to 90 days; the UI can offer 30/90/180/365.
- Logo upload uses the existing workspace logo endpoint; settings display the
  workspace logo as the organization mark.

### Locations

- List: `GET /guest-checkin/list-locations/{workspace_id}/?page=1&page_size=100`
  (use `items`)
- Create: `POST /guest-checkin/create-location/{workspace_id}/`

```json
{ "name": "Lagos HQ", "address": "12 Marina Road", "timezone": "Africa/Lagos" }
```

- Update/delete use the corresponding routes above.
- Creating an active location while the feature is enabled creates that
  location's permanent code automatically.
- Deleting a location deactivates its code immediately.

### Access

- `GET /guest-checkin/list-access/{workspace_id}/` returns members with
  `effective_role` (`owner`, `security`, `reception`, `none`).
- `PUT /guest-checkin/set-access/{workspace_id}/{user_id}/`

```json
{ "role": "security" }
```

Send `{ "role": null }` to clear. Workspace owners/admins already have full
access and cannot be assigned a reduced role.

## 15. Export

`GET /guest-checkin/export-visits/{workspace_id}/?format=csv|xlsx` with the
same filters as the visitor log.

- Only show export for `my-access.can_export`.
- Fetch with the Bearer token and save the blob using the
  `Content-Disposition` filename.
- Every export is audited.

## 16. Polling strategy

| Data | Endpoint | Suggested interval |
| --- | --- | --- |
| Guest scan | `GET /guest-checkin/scan/{slug}/` | On page focus |
| Visitor log | `GET /guest-checkin/list-visits/{workspace_id}/` | SSE, or 15 s |
| In Building | `GET /guest-checkin/in-building/{workspace_id}/` | SSE, or 15 s |
| Admin badge | `GET /guest-checkin/my-access/{workspace_id}/` | On login/focus |

Pause polling when `document.visibilityState === "hidden"`. Merge rows by
`id` rather than replacing the whole table while an admin is acting on a row.

## 17. Error handling

| Status | Meaning |
| --- | --- |
| `400` | Invalid code, already closed, or no open visit. |
| `403` | Missing guest-attendance role/capability. |
| `404` | Invalid entry-point slug or deleted visit/location. |
| `409` | Duplicate active code, or an idempotency key reused at another entry point. |
| `410` | Check-in attempted on a replaced code. |
| `422` | Validation error (reason, consent, party size, phone, timezone, etc.). |
| `429` | Rate limit; show `Retry-After`. |
| `503` | Could not issue a unique code; ask the guest to retry/reception. |

## 18. Minimal boot sequence

```ts
// Guest page
const slug = new URL(location.href).pathname.split("/").filter(Boolean).pop();
const scan = await api.get(`/guest-checkin/scan/${slug}/`, {
  credentials: "include",
});

// Admin shell
const access = await api.get(`/guest-checkin/my-access/${workspaceId}/`);

// Visitor Log
const [visits, building] = await Promise.all([
  api.get(`/guest-checkin/list-visits/${workspaceId}/?page=1`),
  api.get(`/guest-checkin/in-building/${workspaceId}/`),
]);

// QR tab
const [settings, entryPoints] = await Promise.all([
  api.get(`/guest-checkin/get-settings/${workspaceId}/`),
  api.get(
    `/guest-checkin/list-entry-points/${workspaceId}/?include_inactive=true&page=1&page_size=100`,
  ),
]);
```

## 19. Rendering and privacy

- Render guest names, reasons and notes with `textContent` (or React text
  nodes), never `innerHTML`. A guest named `<script>` must appear as text.
- Never cache visitor data in localStorage.
- Do not expose the visitor log on a public page.
- Do not show other visitors' names on the guest screens.
- The check-out link request must always display the same neutral message.
