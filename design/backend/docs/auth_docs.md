# Auth API Documentation

Source: `tms/auth/routers.py`

**Prefix:** `/auth`

All JSON bodies use `Content-Type: application/json` unless marked otherwise.
`/auth/form-login/` uses **form-urlencoded** and `/auth/update-profile/` uses
**multipart form-data**.

Public credential endpoints are rate-limited per client IP (defaults:
10 requests/minute and 60/hour; override with `AUTH_RATE_LIMIT_PER_MINUTE` and
`AUTH_RATE_LIMIT_PER_HOUR`). Exceeding the limit returns `429 Too Many
Requests` with a `Retry-After` header. The 6-digit email verification code
expires after 15 minutes (`EMAIL_VERIFICATION_CODE_EXPIRE_MINUTES`); emailed
verification links use `EMAIL_VERIFICATION_TOKEN_EXPIRE_MINUTES`.

---

## Workspace type and setup at signup

`POST /auth/signup/` accepts:

| Field | Values |
| --- | --- |
| `workspace_type` | `business`, `individual`, `family`, `specials` |
| `workspace_subtype` | `church`, `alumni`, `estate`, `event`, `committee`, `club` (required for `specials`) |
| `workspace_setup` | optional `{crest, members[], event_name, event_date, job, has_clients, team_size}` |

The setup members and workspace profile are persisted on the new workspace.
See [workspaces_docs.md](workspaces_docs.md#workspace-kinds-and-setup).

## POST `/auth/signup/`

- **Function:** `signup`
- **Auth:** `Public`
- **Status Code:** `201 Created`
- **Response Model:** `AuthResponse`
- **Description:** Register a new user. Returns the user plus a JWT. An
  initial workspace is created automatically with the given `workspace_name`
  (or its `company_name` alias used by the onboarding form).
  Returns `409` when the email is already registered.

### Request Fields

| Field            | Type | Required | Notes                |
| ---------------- | ---- | -------- | -------------------- |
| `first_name`     | str  | Yes      | 1–255 chars          |
| `last_name`      | str  | No       | Max 255 chars        |
| `workspace_name` | str  | Yes      | 1–255 chars          |
| `email`          | email| Yes      | Must be unique       |
| `password`       | str  | Yes      | Min 8 chars, max 128 |
| `phone`          | str  | No       | Max 50 chars         |
| `workspace_type` | str  | No       | `business` (default) or `individual` |
| `industry`       | str  | No       | Max 100 chars        |
| `timezone`       | str  | No       | IANA name, default `UTC` |

The initial workspace stores the organization profile fields, and the signup
response includes the new profile/preference fields on `user`.

The workspace is created with `approval_status: "pending"`: the returned token
can verify the email and read `/workspace/list-workspaces/`, but every
workspace-scoped endpoint answers `403` until an SCP operator approves it.
`POST /workspace/create-workspace/` follows the same rule.

### Sample Payload

```json
{
  "first_name": "Alex",
  "last_name": "Owner",
  "workspace_name": "Acme Inc",
  "email": "alex@acme.co",
  "password": "sup3rs3cret!",
  "phone": "+234 803 555 0142",
  "workspace_type": "business",
  "industry": "Technology",
  "timezone": "Africa/Lagos"
}
```

### Sample Response

```json
{
  "user": {
    "id": "eeeeeeee-eeee-4eee-8eee-eeeeeeeeeeee",
    "email": "alex@acme.co",
    "first_name": "Alex",
    "last_name": "Owner",
    "is_verified": false,
    "photo": null,
    "job_title": null,
    "department": null,
    "phone": "+234 803 555 0142",
    "theme": "dark",
    "language": null,
    "digest_enabled": true,
    "digest_time": "09:00",
    "date_of_birth": null,
    "birthday_visibility": "workspace"
  },
  "access_token": "eyJhbGciOiJIUzI1NiIs...",
  "token_type": "bearer"
}
```

### cURL Example

```bash
curl -X POST http://localhost:8081/auth/signup/ \
  -H "Content-Type: application/json" \
  -d '{"first_name":"Alex","last_name":"Owner","workspace_name":"Acme Inc","email":"alex@acme.co","password":"sup3rs3cret!"}'
```

---

## POST `/auth/login/`

- **Function:** `login`
- **Auth:** `Public`
- **Status Code:** `200 OK`
- **Response Model:** `AuthResponse`
- **Description:** Login with email and password. A background worker task
  (`record_login_activity`) records the login — geolocated from the client IP
  — and sends the informational notification email (best effort).

### Request Fields

| Field         | Type  | Required |
| ------------- | ----- | -------- |
| `email`       | email | Yes      |
| `password`    | str   | Yes      |
| `remember_me` | bool  | No — issues a 30-day token |

### Sample Payload

```json
{
  "email": "alex@acme.co",
  "password": "sup3rs3cret!",
  "remember_me": true
}
```

### Sample Response

Same shape as `/auth/signup/`. Returns `401` for unknown email or bad password.
`remember_me=true` issues a 30-day token instead of the default lifetime.

If the user belongs only to workspaces that are awaiting approval or were
declined, login answers `403` instead of issuing a token:

```json
{
  "detail": "Acme Inc is waiting for approval. We'll email you as soon as it's approved.",
  "code": "workspace_pending_approval"
}
```

The code is `workspace_rejected` for a declined workspace, with the reason in
`detail`. A user who belongs to at least one approved workspace signs in
normally. `/auth/form-login/` and the existing-user OAuth callback follow the
same rule.

---

## POST `/auth/form-login/`

- **Function:** `form_login`
- **Auth:** `Public`
- **Status Code:** `200 OK`
- **Response Model:** `AuthResponse`
- **Description:** OAuth2-compatible form login (used by Swagger UI's
  Authorize button). Uses `application/x-www-form-urlencoded` with
  `username` (the email) and `password`.

### cURL Example

```bash
curl -X POST http://localhost:8081/auth/form-login/ \
  -d "username=alex@acme.co&password=sup3rs3cret!"
```

---

## GET `/auth/get-profile/`

- **Function:** `get_profile`
- **Auth:** `Authenticated`
- **Status Code:** `200 OK`
- **Response Model:** `UserPublic`

---

## PUT `/auth/update-profile/`

- **Function:** `update_profile`
- **Auth:** `Authenticated`
- **Status Code:** `200 OK`
- **Response Model:** `UserPublic`
- **Description:** Update the current user's profile. Multipart form — send
  only the fields you want to change. `photo` is uploaded to Backblaze B2 and
  returned as a signed URL (renewed automatically before expiry); images only
  (PNG, JPEG, GIF, WEBP, BMP or TIFF; SVG and active content are rejected),
  limited to `MAX_UPLOAD_FILE_SIZE_MB`.

### Form Fields

| Field            | Type   | Required | Notes                |
| ---------------- | ------ | -------- | -------------------- |
| `first_name`     | str    | No       | Max 500 chars        |
| `last_name`      | str    | No       | Max 500 chars        |
| `job_title`      | str    | No       | Max 255 chars        |
| `department`     | str    | No       | Max 255 chars        |
| `phone`          | str    | No       | Max 50 chars         |
| `theme`          | str    | No       | `light` or `dark`    |
| `language`       | str    | No       | Max 50 chars; a code (`en-GB`) or display name (`English (United States)`) |
| `digest_enabled` | bool   | No       | Daily digest toggle  |
| `digest_time`    | str    | No       | `HH:MM`              |
| `photo`          | file   | No       | Image file           |

### cURL Example

```bash
curl -X PUT http://localhost:8081/auth/update-profile/ \
  -H "Authorization: Bearer <token>" \
  -F "first_name=Alex" \
  -F "photo=@avatar.png"
```

---

## PATCH `/auth/update-profile-json/`

- **Function:** `update_profile_json`
- **Auth:** `Authenticated`
- **Status Code:** `200 OK`
- **Response Model:** `UserPublic`
- **Description:** JSON alternative to the multipart profile endpoint. Omit
  fields you do not want to change. `date_of_birth` may be a `YYYY-MM-DD`
  string or `null` to clear it; future dates are rejected with
  `422 "That date is in the future."`.

### Sample Payload

```json
{
  "first_name": "Alex",
  "last_name": "Owner",
  "job_title": "Operations Director",
  "department": "Operations",
  "phone": "+234 803 555 0142",
  "theme": "light",
  "language": "English (United States)",
  "digest_enabled": true,
  "digest_time": "08:00",
  "date_of_birth": "1995-11-09"
}
```

**Sample response:** `200 OK` with `UserPublic`, including the caller's own
`date_of_birth` and `birthday_visibility`. `UserBrief` never includes either
field.

---

## POST `/auth/request-email-change/`

- **Auth:** `Authenticated`
- **Description:** Send a confirmation link to a new sign-in email. Requires
  the current password and rejects addresses already in use.

```json
{ "new_email": "new@acme.co", "password": "sup3rs3cret!" }
```

## POST `/auth/confirm-email-change/`

- **Auth:** `Public` (token proves ownership of the new address).

```json
{ "token": "<email-change-token>" }
```

The new address becomes verified; the old address stops working immediately.

---

## POST `/auth/update-password/`

- **Function:** `update_password`
- **Auth:** `Authenticated`
- **Status Code:** `200 OK`
- **Response Model:** `MessageResponse`
- **Description:** Change the current user's password (`new_password` is
  8–128 chars). Every existing token — including the one used for this
  request — is invalidated, so log in again afterwards.

### Sample Payload

```json
{ "current_password": "old-pass", "new_password": "new-pass-123" }
```

Returns `400` when the current password is incorrect.

---

## POST `/auth/request-password-reset/`

- **Function:** `request_password_reset`
- **Auth:** `Public`
- **Status Code:** `200 OK`
- **Response Model:** `MessageResponse`
- **Description:** Always returns success to prevent account enumeration. When
  the account exists, a reset email is enqueued (JWT link valid for
  `PASSWORD_RESET_TOKEN_EXPIRE_MINUTES`).

### Sample Payload

```json
{ "email": "alex@acme.co" }
```

---

## POST `/auth/confirm-password-reset/`

- **Function:** `confirm_password_reset`
- **Auth:** `Public`
- **Status Code:** `200 OK`
- **Response Model:** `MessageResponse`
- **Description:** Reset the password with the emailed token (`new_password`
  is 8–128 chars). Tokens are single-use: a token stops working once it has
  been used, or once the password changes.

### Sample Payload

```json
{ "token": "<reset-token>", "new_password": "new-pass-123" }
```

Returns `400`/`401` for invalid, already-used or expired tokens.

---

## POST `/auth/verify-email/`

- **Function:** `verify_email`
- **Auth:** `Public`
- **Status Code:** `200 OK`
- **Response Model:** `MessageResponse`
- **Description:** Verify an email with either the link token or the 6-digit
  code sent during signup.

### Sample Payloads

```json
{ "token": "<email-verification-token>" }
```

```json
{ "email": "alex@acme.co", "code": "482913" }
```

---

## POST `/auth/resend-verification/`

- **Function:** `resend_verification`
- **Auth:** `Public`
- **Status Code:** `200 OK`
- **Response Model:** `MessageResponse`
- **Description:** Regenerate and resend a verification code/link. Always
  returns success to prevent account enumeration.

```json
{ "email": "alex@acme.co" }
```

---

## GET `/auth/oauth/{provider}/start/`

- **Function:** `oauth_start`
- **Auth:** `Public`
- **Providers:** `google`, `microsoft`
- **Status Code:** `200 OK`
- **Response Model:** `OAuthStartResponse`
- **Description:** Return the provider authorization URL and signed state
  token. Requires the provider client id/secret in environment settings.

```json
{
  "provider": "google",
  "authorization_url": "https://accounts.google.com/o/oauth2/v2/auth?...",
  "state": "eyJhbGciOi..."
}
```

---

## POST `/auth/oauth/{provider}/callback/`

- **Function:** `oauth_callback`
- **Auth:** `Public`
- **Status Code:** `200 OK`
- **Response Model:** `AuthResponse`
- **Description:** Exchange the provider authorization code for a TMS
  JWT. Unknown OAuth users are created with a personal workspace.

Existing OAuth users follow the same workspace approval rule as
`/auth/login/`: if none of their active memberships is in an approved
workspace, the callback answers `403` with `code`
`workspace_pending_approval` or `workspace_rejected` (the reason is in
`detail`). A new OAuth user is treated like signup: the personal workspace is
created `pending` and the response still contains a session so the client can
show the waiting screen.

```json
{
  "code": "provider-authorization-code",
  "state": "signed-state-token",
  "redirect_uri": "https://app.example.com/auth/callback"
}
```

---

## POST `/auth/unsubscribe/`

- **Function:** `unsubscribe`
- **Auth:** `Public`
- **Status Code:** `200 OK`
- **Response Model:** `MessageResponse`
- **Description:** Opt an email out of future Sabipipu emails (idempotent).

### Sample Payload

```json
{ "email": "alex@acme.co" }
```

---

## GET `/auth/check-auth/`

- **Function:** `check_auth`
- **Auth:** `Authenticated`
- **Status Code:** `200 OK`
- **Response Model:** `UserPublic`
- **Description:** Validate the bearer token and return the current user.
