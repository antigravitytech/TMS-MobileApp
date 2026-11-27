# People Onboarding Integration — Bulk CSV and Signup Links

Audience: frontend developers building the Admin **Users** screens and the
public workspace signup page.

Source contracts:

- [people_docs.md](people_docs.md) — bulk upload and directory fields
- [workspaces_docs.md](workspaces_docs.md) — signup-link and approval endpoints

## What this adds

Two ways to bring people into a workspace:

| Flow | Who starts it | Result |
| --- | --- | --- |
| Bulk CSV upload | Owner/admin uploads a `.csv` file from the Users screen | One pending email invite per valid row; people join by accepting the invite |
| Signup link | Owner/admin shares a public link | Visitors request access; an admin approves the pending request |

Signup requests are **not** email invites and are **not** active members.
They are pending memberships with `is_signup_request: true` in the people
directory.

## Access and conventions

- Base URL: `http://localhost:8081` locally, or the deployed API.
- Admin endpoints require `Authorization: Bearer <JWT>` and an active
  owner/admin membership in the workspace.
- Public endpoints take no JWT, are rate-limited per client IP and return
  `429` with `Retry-After` when exceeded.
- Workspace URL parameter is `workspace_id`; the public signup parameter is
  the opaque signup `token`.
- JSON errors use `{ "detail": "..." }`; `422` validation errors use the
  standard FastAPI array in `detail`.

## Screen map

| Screen | What to build | Endpoints |
| --- | --- | --- |
| Admin → Users → Upload users | File picker, template download, upload progress, result table | `POST /people/bulk-upload/{workspace_id}/`, `GET /people/get-bulk-upload-template/{workspace_id}/` |
| Admin → Users → Pending tab | Show pending invites and signup requests; distinguish with `is_signup_request`; Approve/Reject actions | `GET /people/list-people/{workspace_id}/?status=pending`, `POST /workspace/approve-signup/{workspace_id}/{membership_id}/`, `POST /workspace/reject-signup/{workspace_id}/{membership_id}/` |
| Admin → Company settings → Signup link | Enable/disable, copy link, regenerate link | `GET /workspace/get-signup-link/{workspace_id}/`, `PUT /workspace/update-signup-settings/{workspace_id}/`, `POST /workspace/regenerate-signup-link/{workspace_id}/` |
| Public `/join?token=...` | Load workspace details, render signup form, submit request | `GET /workspace/get-signup-public/{token}/`, `POST /workspace/signup-public/{token}/` |

The backend returns `signup_url`; prefer using that value instead of
constructing the URL yourself. The route is `/join?token=<token>`.

## Endpoint summary

| Method | Path | Auth | Purpose |
| --- | --- | --- | --- |
| `POST` | `/people/bulk-upload/{workspace_id}/` | Owner/admin | Upload a CSV of pending invites |
| `GET` | `/people/get-bulk-upload-template/{workspace_id}/` | Owner/admin | Download the CSV header template |
| `GET` | `/workspace/get-signup-link/{workspace_id}/` | Owner/admin | Read signup-link state |
| `PUT` | `/workspace/update-signup-settings/{workspace_id}/` | Owner/admin | Enable/disable the signup link |
| `POST` | `/workspace/regenerate-signup-link/{workspace_id}/` | Owner/admin | Rotate the signup token |
| `GET` | `/workspace/get-signup-public/{token}/` | Public | Public workspace details |
| `POST` | `/workspace/signup-public/{token}/` | Public | Submit a signup request |
| `POST` | `/workspace/approve-signup/{workspace_id}/{membership_id}/` | Owner/admin | Approve a pending signup request |
| `POST` | `/workspace/reject-signup/{workspace_id}/{membership_id}/` | Owner/admin | Reject a pending signup request |

## 1. Bulk CSV upload

### UI flow

1. The admin opens **Users → Upload users**.
2. The modal offers **Download template**.
3. The admin selects a `.csv` file. Client-side checks:
   - extension is `.csv`;
   - file is at most **2 MB**;
   - the header row matches the template.
4. Submit `multipart/form-data` with the field name `file`.
5. Show a result summary:
   - `invited` rows: “N invites sent”;
   - `skipped` rows: a table with row number, email and reason;
   - `total_rows`: total non-empty data rows read.
6. Refresh the pending list after the upload. Uploaded rows are **pending
   invites**, not active members, so they appear under `status=pending`.

### Upload contract

`POST /people/bulk-upload/{workspace_id}/`

- **Auth:** owner/admin.
- **Content type:** `multipart/form-data`.
- **Field:** `file`.
- **Limits:** 200 data rows, 2 MB.
- **Success:** `200 OK`, even when some rows were skipped.

```ts
interface BulkUploadResult {
  total_rows: number;
  invited: Array<{
    row: number;
    id: string;
    email: string;
  }>;
  skipped: Array<{
    row: number;
    email: string;
    reason: string;
  }>;
}
```

`row` is the 1-based CSV row number. The header is row 1, so the first data
row is row 2.

### CSV format

The header row must contain exactly these columns. Matching is
case-insensitive and surrounding whitespace is ignored.

```csv
Email,First Name,Last Name,Job Title,Role,Team,Reports To
ada@example.com,Ada,Okafor,Designer,member,Design,lead@example.com
sam@example.com,Sam,Bello,QA Engineer,member,Engineering,lead@example.com
```

| Column | Required | Rules |
| --- | --- | --- |
| `Email` | Yes | Valid email; lower-cased; unique within the file |
| `First Name` | No | Invitee first name |
| `Last Name` | No | Invitee last name |
| `Job Title` | No | Stored on the pending membership |
| `Role` | No | `member` (default) or `admin`; `owner` only when the uploader is an owner |
| `Team` | No | Team name or slug in this workspace; unknown team skips the row |
| `Reports To` | No | Email of an active workspace member; unknown manager skips the row |

Notes:

- Blank rows are ignored and are not counted in `total_rows`.
- An empty `Role` becomes `member`.
- An empty `Team` or `Reports To` leaves the field unset.
- The file must be UTF-8. Excel users should save as **CSV UTF-8**.
- Missing or unknown headers fail the whole request with `400`.
- Row-level problems go to `skipped`; the rest of the file still imports.

### Template

`GET /people/get-bulk-upload-template/{workspace_id}/`

- **Auth:** owner/admin.
- **Response:** `text/csv` attachment named
  `people-upload-template.csv`, containing only the header row.

### Example request

```ts
async function uploadPeople(
  apiUrl: string,
  workspaceId: string,
  token: string,
  file: File,
): Promise<BulkUploadResult> {
  const form = new FormData();
  form.append("file", file);

  const response = await fetch(
    `${apiUrl}/people/bulk-upload/${workspaceId}/`,
    {
      method: "POST",
      headers: { Authorization: `Bearer ${token}` },
      body: form,
    },
  );

  if (!response.ok) {
    const error = await response.json();
    throw new Error(error.detail ?? "Upload failed.");
  }

  return response.json();
}
```

### Result UI copy

| Backend outcome | Suggested UI |
| --- | --- |
| `invited.length > 0`, no skips | “N invite(s) sent.” |
| Some rows skipped | “N invite(s) sent. M row(s) need attention.” |
| All rows skipped | “No invites were sent. Check the errors below.” |
| `400` | “Check the file: use the template and keep it under 200 rows.” |
| `403` | Hide the upload action for non-managers. |

## 2. Signup links

### Admin settings flow

1. Load `GET /workspace/get-signup-link/{workspace_id}/`.
2. Render a toggle:
   - off: “Signup link is off”;
   - on: show the copyable `signup_url`.
3. Toggle calls `PUT /workspace/update-signup-settings/{workspace_id}/`.
   - Enabling generates a token if none exists.
   - Disabling clears the token, so the old URL is revoked.
4. **Regenerate** calls
   `POST /workspace/regenerate-signup-link/{workspace_id}/`. Confirm first:
   “The current link will stop working immediately.” Regenerating a disabled
   link returns `400`; enable it first.

### Signup-link state

```ts
interface SignupLinkRead {
  enabled: boolean;
  token: string | null;
  signup_url: string | null;
}
```

`GET /workspace/get-signup-link/{workspace_id}/`

```json
{
  "enabled": true,
  "token": "secure-signup-token",
  "signup_url": "https://app.example.com/join?token=secure-signup-token"
}
```

`PUT /workspace/update-signup-settings/{workspace_id}/`

```json
{ "enabled": true }
```

`POST /workspace/regenerate-signup-link/{workspace_id}/` takes no body and
returns the same shape. The old URL is invalid as soon as the token rotates.

### Public signup page

Route: `/join?token=<token>`

#### Load

`GET /workspace/get-signup-public/{token}/`

- **Auth:** public, rate-limited.
- **Response:** `404` when the token is unknown, disabled or the workspace is
  unavailable. Show a dead-end state, not a retry loop.

```ts
interface SignupPublicRead {
  workspace_id: string;
  workspace_name: string;
  logo: string | null;
  requires_approval: boolean;
}
```

#### Submit

`POST /workspace/signup-public/{token}/`

```ts
interface SignupPublicRequest {
  first_name: string;
  last_name?: string | null;
  email: string;
  password: string;
  phone?: string | null;
  job_title?: string | null;
}
```

```json
{
  "first_name": "Ada",
  "last_name": "Okafor",
  "email": "ada@example.com",
  "password": "strong-pass-123",
  "phone": "+234 803 555 0142",
  "job_title": "Designer"
}
```

```json
{ "message": "Your request was sent to the workspace admin." }
```

Form rules:

- `first_name` required, 1–255 characters.
- `last_name` optional, max 255.
- `email` valid email.
- `password` 8–128 characters.
- `phone` optional, max 50.
- `job_title` optional, max 255.

After a successful submit, show:

> **Request sent.** Check your email to verify your address. A workspace admin
> will review your request.

If the email already belongs to an account, the password is ignored and the
existing account keeps its current password. The response is intentionally
the same, so do not build UI around “account created”.

Example:

```ts
async function submitSignup(
  apiUrl: string,
  token: string,
  payload: SignupPublicRequest,
): Promise<{ message: string }> {
  const response = await fetch(
    `${apiUrl}/workspace/signup-public/${token}/`,
    {
      method: "POST",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify(payload),
    },
  );

  if (!response.ok) {
    const error = await response.json();
    throw new Error(
      typeof error.detail === "string"
        ? error.detail
        : "Check the form and try again.",
    );
  }

  return response.json();
}
```

### Approval flow

Signup requests appear in the existing pending directory:

`GET /people/list-people/{workspace_id}/?status=pending`

`PersonRead` now includes:

```ts
interface PersonReadOnboardingFields {
  is_signup_request: boolean;
  is_verified: boolean;
}
```

Use `is_signup_request` to distinguish a self-signup request from an email
invite:

| Row type | `is_signup_request` | Meaning |
| --- | --- | --- |
| Email invite | `false` | Token invite created by `invite-member` / `bulk-invite` / CSV upload |
| Signup request | `true` | Pending request from `/join?token=...` |

Approval rules:

- The Approve action must stay disabled while `is_verified` is `false`.
  Show “Waiting for email verification”.
- Approving activates the membership.
- Rejecting changes the membership to `cancelled`; the account is not
  deleted.

#### Approve

`POST /workspace/approve-signup/{workspace_id}/{membership_id}/`

- **Auth:** owner/admin.
- **Response:** the activated `MembershipRead`.
- **`409`** when the person is not verified yet or belongs to another
  organization under single-organization mode.
- **`404`** when the membership is not a pending signup request for this
  workspace.

```ts
async function approveSignup(
  apiUrl: string,
  workspaceId: string,
  membershipId: string,
  token: string,
) {
  const response = await fetch(
    `${apiUrl}/workspace/approve-signup/${workspaceId}/${membershipId}/`,
    {
      method: "POST",
      headers: { Authorization: `Bearer ${token}` },
    },
  );

  if (!response.ok) {
    const error = await response.json();
    throw new Error(error.detail ?? "Could not approve the request.");
  }

  return response.json();
}
```

#### Reject

`POST /workspace/reject-signup/{workspace_id}/{membership_id}/`

```json
{ "message": "Signup request rejected." }
```

Confirm before rejecting: “Reject this signup request? The person can request
access again with the link.”

## Error and status matrix

| Status | Where | Frontend handling |
| --- | --- | --- |
| `400` | Bulk upload | Bad file type, missing/unknown headers, too many rows or too large. Show the `detail`; keep the modal open. |
| `401` | Admin endpoints | Session expired; redirect to sign-in. |
| `403` | Admin endpoints | Caller is not an active owner/admin. Hide admin actions; show a permission message. |
| `404` | Workspace, signup link, signup request | Resource is gone or the public link is invalid/disabled. Show a dead-end state. |
| `409` | Public signup / approval | Duplicate email, already a member, pending invite/request, other organization, or unverified email at approval. Show the `detail` inline. |
| `422` | JSON/form payloads | Validation error; map array entries to form fields where possible. |
| `429` | Public signup GET/POST | Rate-limited. Read `Retry-After` and disable submit until it elapses. |
| `500` | Any | Generic error with retry; do not expose internals. |

## Edge cases

### Bulk upload

- **Duplicate emails in one file** — first row is attempted, later rows are
  skipped with “Duplicate email in this file.”
- **Already a member / pending invite** — row is skipped with the backend
  reason; no duplicate invite is created.
- **Member of another organization** — row is skipped under
  single-organization mode.
- **Unknown team or manager** — the row is skipped; other rows still import.
- **Admin uploads `owner` role** — row is skipped; only owners can grant the
  owner role.
- **Partial failure** — never treat a `200` as “all rows succeeded”; inspect
  `skipped`.

### Signup link

- **Disabled link** — public GET returns `404`; do not show the form.
- **Regenerated link** — the old URL stops working immediately. Update the
  copied URL in the settings UI.
- **Existing account with no workspace membership** — allowed; the account is
  linked to the pending request. The password field does not change the
  existing password.
- **Already an active/suspended member** — `409`; offer “Open workspace” or
  “Contact an admin” instead of retrying.
- **Existing email invite** — `409`; tell the person to use the invite email
  or ask an admin to resend it.
- **Unverified email** — the request is visible to admins but cannot be
  approved until verification completes.
- **Single-organization mode** — checked at signup and again at approval; a
  request can fail with `409` if the person joined another organization in
  between.
- **Suspended workspace** — public link returns `404`.

## Suggested TypeScript additions

```ts
type WorkspaceRole = "owner" | "admin" | "member";

interface BulkUploadInvitedRow {
  row: number;
  id: string;
  email: string;
}

interface BulkUploadSkippedRow {
  row: number;
  email: string;
  reason: string;
}

interface BulkUploadResult {
  total_rows: number;
  invited: BulkUploadInvitedRow[];
  skipped: BulkUploadSkippedRow[];
}

interface SignupLinkRead {
  enabled: boolean;
  token: string | null;
  signup_url: string | null;
}

interface SignupPublicRead {
  workspace_id: string;
  workspace_name: string;
  logo: string | null;
  requires_approval: boolean;
}

interface SignupPublicRequest {
  first_name: string;
  last_name?: string | null;
  email: string;
  password: string;
  phone?: string | null;
  job_title?: string | null;
}

// Extend the existing PersonRead used by the pending directory.
interface PersonRead {
  // ...existing fields...
  is_signup_request: boolean;
  is_verified: boolean;
}

// Abbreviated membership returned by approve-signup.
interface MembershipRead {
  id: string;
  workspace_id: string;
  user: {
    id: string;
    email: string;
    first_name: string | null;
    last_name: string | null;
    photo: string | null;
  };
  status: "active" | "suspended";
  role: WorkspaceRole;
  job_title: string | null;
  team_id: string | null;
  team_name: string | null;
  is_guest: boolean;
}
```

## QA checklist

### Bulk upload

- [ ] Owner can upload a valid CSV and sees invites created.
- [ ] Admin can upload; `owner` rows are skipped.
- [ ] Member receives `403`.
- [ ] Template endpoint returns the expected header row.
- [ ] Missing/unknown headers return `400`.
- [ ] Non-`.csv` file and >2 MB file are rejected.
- [ ] More than 200 data rows is rejected.
- [ ] Duplicate emails, unknown teams and unknown managers appear in
      `skipped` without blocking valid rows.
- [ ] Pending list refreshes after upload.

### Signup link

- [ ] Enabling generates a link; disabling revokes it.
- [ ] Regenerating invalidates the previous URL.
- [ ] Public `/join?token=...` loads workspace name/logo.
- [ ] Invalid/disabled token shows a dead-end page.
- [ ] New email creates an unverified account and a pending request.
- [ ] Existing account is linked without changing its password.
- [ ] Active member, pending invite and single-org conflicts show `409`.
- [ ] Verification email is received for a new account.
- [ ] Pending row shows `is_signup_request: true`.
- [ ] Approve is disabled until `is_verified: true`.
- [ ] Approve activates the membership; reject cancels it.
- [ ] Non-manager cannot approve/reject.
- [ ] `429` honours `Retry-After`.
