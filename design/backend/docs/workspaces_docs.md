# Workspace API Documentation

Source: `tms/workspaces/routers.py`

**Prefix:** `/workspace`

All endpoints require `Authorization: Bearer <JWT>` except the public invite
and public signup endpoints. `set-logo` uses **multipart form-data**;
everything else is JSON. Public invite endpoints (`get-invite-public`,
`accept-invite-public`, `request-invite`) and public signup endpoints
(`get-signup-public`, `signup-public`) are rate-limited per client IP and
return `429` with `Retry-After` when exceeded.

## Workspace approval

Every workspace created by `POST /auth/signup/` or
`POST /workspace/create-workspace/` starts with
`approval_status: "pending"`. Until a platform operator approves it in the
SCP console:

- the workspace cannot be opened, and
- every workspace-scoped endpoint (`.../{workspace_id}/`) answers `403`:

```json
{
  "detail": "Acme Team is waiting for approval. We'll email you as soon as it's approved.",
  "code": "workspace_pending_approval"
}
```

A declined workspace answers `403` with `code: "workspace_rejected"` and the
operator's reason in `detail`. Invites into a workspace that is not approved
are blocked the same way.

`GET /workspace/list-workspaces/` still returns pending and declined
workspaces so the web app can show the waiting/declined screen. Existing
workspaces predate approval and are already `approved`.

Login is refused only when none of the user's active memberships is in an
approved workspace; a user with another approved workspace can still sign in.
See [`scp_changes_integration.md`](scp_changes_integration.md) for the full
login/OAuth and console integration contract.

## Workspace kinds and setup

`kind` is one of `business`, `individual`, `family` or `specials`. A
`specials` workspace also carries a `subtype`:

| Subtype | UI label |
| --- | --- |
| `church` | Specials · Church |
| `alumni` | Specials · Alumni |
| `estate` | Specials · Estate |
| `event` | Specials · Event |
| `committee` | Specials · Committee |
| `club` | Specials · Club |

`create-workspace`, `update-workspace` and `signup` accept a `setup` object:

```json
{
  "crest": "https://...",
  "members": [{"name": "Pastor Femi", "type": "co_head"}],
  "event_name": "Harvest thanksgiving",
  "event_date": "2026-11-29",
  "job": "Event planner",
  "has_clients": true,
  "team_size": "1-5"
}
```

`members[].type` is one of `co_head`, `child`, `relative`, `domestic_staff`,
`security`, `driver`. The setup members are not app users.

`GET /workspace/get-workspace/{workspace_id}/` and list responses return the
same normalized `setup` object. Non-business workspaces lazily seed their
space modules on the first `GET /home/get-space/{workspace_id}/` call.

## Roles

| Role   | Can do |
| ------ | ------ |
| Owner  | Everything: invite as any role, manage members, admins and other owners, delete the workspace (creator only). The owner who created the workspace cannot be demoted, suspended or removed. |
| Admin  | Update workspace, set logo, manage the public signup link, invite/cancel invites, and manage members and admins (promote/demote, suspend, remove). Cannot grant the owner role or manage owners. |
| Member | Read the workspace, list members, accept/reject their own invites. |

## Single-organization mode (temporary)

While `RESTRICT_SINGLE_WORKSPACE=true` (the default), a user may belong to
only one non-deleted organization. The rule is enforced when creating a
workspace, sending/resending an invite or copying an invite link, and
accepting an invite (authenticated or public). Violations return `409`.

- Signup still creates exactly one organization for a new account.
- The workspace auto-created at signup counts, so `create-workspace` returns
  `409` for users who already belong to an organization.
- Active and suspended memberships count. Removed memberships, pending
  invites and soft-deleted workspaces do not.
- Set `RESTRICT_SINGLE_WORKSPACE=false` to allow multiple organizations again.

## Pagination

List endpoints return:

```json
{ "items": [], "total": 0, "page": 1, "page_size": 20, "total_pages": 0 }
```

---

## GET `/workspace/list-workspaces/`

- **Auth:** `Authenticated`
- **Query:** `page` (default 1), `page_size` (default 20, max 100)
- **Description:** List workspaces the current user is an active member of.
  Pending and rejected workspaces are included so the client can show the
  approval screen; each item carries `approval_status` and, when declined,
  `rejected_reason`.

---

## POST `/workspace/create-workspace/`

- **Status Code:** `201 Created`
- **Description:** Create a workspace; the creator becomes the owner. The
  workspace is created with `approval_status: "pending"` and is locked until
  an SCP operator approves it.
- Returns `409` when single-organization mode is enabled and the user already
  belongs to an organization.

### Sample Payload

```json
{ "name": "Acme Team", "description": "Our team workspace" }
```

### Sample Response

```json
{
  "id": "11111111-1111-4111-8111-111111111111",
  "name": "Acme Team",
  "slug": "acme-team",
  "description": "Our team workspace",
  "logo": null,
  "owner_id": "eeeeeeee-eeee-4eee-8eee-eeeeeeeeeeee",
  "created_at": "2026-01-01T00:00:00Z",
  "updated_at": "2026-01-01T00:00:00Z"
}
```

---

## GET `/workspace/get-workspace/{workspace_id}/`

- **Auth:** `Authenticated`, any active member.

---

## PUT `/workspace/update-workspace/{workspace_id}/`

- **Auth:** `Authenticated`, owner/admin.

### Sample Payload

```json
{ "name": "Acme HQ", "description": "Renamed" }
```

---

## POST `/workspace/set-logo/{workspace_id}/`

- **Auth:** `Authenticated`, owner/admin.
- **Content type:** `multipart/form-data` — `file` (image, max
  `MAX_UPLOAD_FILE_SIZE_MB`; PNG, JPEG, GIF, WEBP, BMP or TIFF; SVG and
  active content are rejected).
- **Description:** Uploads the logo to B2 and returns the workspace with a
  signed `logo` URL (renewed automatically before expiry).

---

## DELETE `/workspace/delete-workspace/{workspace_id}/`

- **Auth:** `Authenticated`, **the owner who created the workspace only**.
- **Description:** Soft-deletes the workspace and cancels all pending
  invites.

---

## GET `/workspace/my-role/{workspace_id}/`

- **Auth:** `Authenticated`, any active member.

### Sample Response

```json
{ "workspace_id": "1111...", "role": "owner", "status": "active" }
```

---

## GET `/workspace/list-members/{workspace_id}/`

- **Auth:** `Authenticated`, any active member.
- **Query:** `search` (name/email), `status` (`active` or `suspended`; other
  values are rejected with `422` — pending memberships are invites and are
  listed by `list-invites`), `page`, `page_size`.

### Sample Response Item

```json
{
  "id": "2222...",
  "workspace_id": "1111...",
  "user": {
    "id": "eeee...",
    "email": "member@acme.co",
    "first_name": "Mia",
    "last_name": "Member",
    "photo": null
  },
  "status": "active",
  "role": "member",
  "created_at": "2026-01-01T00:00:00Z",
  "updated_at": "2026-01-01T00:00:00Z"
}
```

---

## PATCH `/workspace/update-member-role/{workspace_id}/{membership_id}/`

- **Auth:** `Authenticated`, owner/admin.
- **Description:** Set a member's role to `owner`, `admin` or `member`.
  Admins manage members and admins; only owners can grant the `owner` role
  and manage other owners. The role of the workspace owner (the creator)
  cannot be changed.

### Sample Payload

```json
{ "role": "admin" }
```

---

## PATCH `/workspace/update-member-status/{workspace_id}/{membership_id}/`

- **Auth:** `Authenticated`, owner/admin.
- **Description:** Set a member's status (`active` or `suspended`).
  Admins manage members and admins; owners additionally manage other owners.
  The workspace owner's status and your own status cannot be changed.
- Suspending a member who is the approver for open tasks returns `409`;
  resolve those reviews first.

### Sample Payload

```json
{ "status": "suspended" }
```

---

## DELETE `/workspace/remove-member/{workspace_id}/{membership_id}/`

- **Auth:** `Authenticated`, owner/admin.
- **Description:** Remove a member or admin (deletes the membership); owners
  can also remove other owners. The workspace owner (creator) cannot be
  removed and you cannot remove yourself. The member's team and project
  memberships in this workspace are also deleted, project alternate owner
  references to the member are cleared, and their task watcher/viewer rows
  are soft-deleted.
- Returns `409` when the member has open assigned tasks, is the approver for
  open tasks, is a team lead, or owns a project in the workspace; reassign or
  resolve those first with the task, team and project endpoints.

### Sample Response

```json
{ "message": "Member removed successfully." }
```

---

## POST `/workspace/invite-member/{workspace_id}/`

- **Status Code:** `201 Created`
- **Auth:** `Authenticated`, owner/admin.
- **Description:** Invite an email address to the workspace. Creates a
  **pending membership** carrying the invite `token` (valid 7 days) and sends
  the invite email. Admins can invite as `admin` or `member`; only an owner
  can invite as `owner`. Returns `409` when the email is already a member or
  has a pending invite, or when the email already belongs to another
  organization under single-organization mode.

### Sample Payload

```json
{ "email": "newbie@acme.co", "role": "member" }
```

### Sample Response

```json
{
  "id": "3333...",
  "workspace_id": "1111...",
  "workspace_name": "Acme Team",
  "email": "newbie@acme.co",
  "invited_by_name": "Alex Owner",
  "role": "member",
  "status": "pending",
  "expires_at": "2026-01-08T00:00:00Z",
  "created_at": "2026-01-01T00:00:00Z",
  "updated_at": "2026-01-01T00:00:00Z"
}
```

---

## GET `/workspace/list-invites/{workspace_id}/`

- **Auth:** `Authenticated`, owner/admin.
- **Query:** `status` (repeatable — `pending|expired|cancelled`; member
  statuses like `active`/`suspended` match nothing), `page`, `page_size`.
  Defaults to `pending`. Overdue pending invites are marked `expired` first.

---

## DELETE `/workspace/cancel-invite/{workspace_id}/{invite_id}/`

- **Auth:** `Authenticated`, owner/admin. Only pending invites can be
  cancelled.

---

## GET `/workspace/get-invite/{identifier}/`

- **Auth:** `Authenticated`, invitee only.
- **Description:** Fetch an invite by id or token (e.g. to render the
  invitation page before accepting); the response includes
  `invited_by_name`. Expired invites return `400` after being marked
  `expired`.

---

## GET `/workspace/my-invites/`

- **Auth:** `Authenticated`.
- **Description:** List pending invites for the current user's email
  (paginated). Overdue invites are marked `expired` and excluded.

---

## POST `/workspace/accept-invite/{token}/`

- **Auth:** `Authenticated` as the invited email.
- **Description:** Accept the invite; links the invited user to the pending
  membership (reactivating a suspended one when present) with the invited
  role. Returns `403` when the invite was sent to
  a different email address. Returns `409` when single-organization mode is
  enabled and the user already belongs to another organization.

### Sample Response

```json
{ "message": "You have joined Acme Team." }
```

---

## POST `/workspace/reject-invite/{token}/`

- **Auth:** `Authenticated` as the invited email.
- **Description:** Reject the invite (status becomes `cancelled`).

---

## PUT `/workspace/update-settings/{workspace_id}/`

- **Auth:** `Authenticated`, owner/admin.
- **Description:** Update the organization profile and defaults. Omitted
  fields are unchanged.

```json
{
  "industry": "Technology",
  "timezone": "Africa/Lagos",
  "working_hours_start": "09:00",
  "working_hours_end": "17:00",
  "working_days": ["Mon", "Tue", "Wed", "Thu", "Fri"],
  "default_task_visibility": "public",
  "gamification": { "points": true, "badges": true, "board": true }
}
```

`WorkspaceRead` includes `kind`, `industry`, `timezone`,
`working_hours_start`, `working_hours_end`, `working_days`,
`default_task_visibility`, `gamification`, `approval_status` and
`rejected_reason`.

## Membership response additions

`MembershipRead` now includes:

- `reports_to` — line manager (`UserBrief` or null)
- `job_title`
- `team_id`, `team_name`
- `is_guest`
- `last_active_at`

## Invite payload additions

`POST /workspace/invite-member/{workspace_id}/` also accepts `first_name`,
`last_name`, `job_title`, `team_id`, `reports_to_id`, `project_id` and
`is_guest`. These fields are stored on the pending membership and applied
when the invite is accepted. `InviteRead` returns the same metadata plus
`team_name`, `reports_to_name` and `project_name`.

---

## GET `/workspace/get-invite-link/{workspace_id}/{invite_id}/`

- **Auth:** Owner/admin.
- **Description:** Return a copyable invite token/link. Expired pending
  invites return `400`; use `resend-invite` to generate a new link. Returns
  `409` when the invitee already belongs to another organization under
  single-organization mode.

```json
{
  "invite_id": "99999999-9999-4999-8999-999999999999",
  "email": "newbie@acme.co",
  "token": "secure-invite-token",
  "invite_url": "https://app.example.com/invite?token=secure-invite-token",
  "expires_at": "2026-01-08T00:00:00Z"
}
```

## PATCH `/workspace/update-invite/{workspace_id}/{invite_id}/`

- **Auth:** Owner/admin.
- **Description:** Edit a pending invite's name, job title, team, manager,
  role or guest flag.

```json
{
  "first_name": "New",
  "last_name": "Bie",
  "job_title": "Senior Designer",
  "team_id": "33333333-3333-4333-8333-333333333333",
  "reports_to_id": "55555555-5555-4555-8555-555555555555",
  "role": "member"
}
```

## POST `/workspace/resend-invite/{workspace_id}/{invite_id}/`

- **Auth:** Owner/admin.
- **Description:** Regenerate the token/expiry, resend the invite email and
  return the new link. Pending and expired invites can be resent. Returns
  `409` when the invitee already belongs to another organization under
  single-organization mode.

---

## POST `/workspace/request-invite/`

- **Auth:** Public.
- **Description:** Ask the workspace admin/inviter for a fresh invite after
  an expiry. Always returns success.

```json
{ "email": "newbie@acme.co" }
```

---

## GET `/workspace/get-invite-public/{token}/`

- **Auth:** Public.
- **Description:** Invite details for the acceptance screen.

```json
{
  "workspace_id": "11111111-1111-4111-8111-111111111111",
  "workspace_name": "Acme Team",
  "email": "newbie@acme.co",
  "invited_by_name": "Alex Owner",
  "role": "member",
  "team_name": "Tech Team",
  "reports_to_name": "Chioma Okafor",
  "project_name": "Customer Portal Revamp",
  "expires_at": "2026-01-08T00:00:00Z"
}
```

## POST `/workspace/accept-invite-public/{token}/`

- **Auth:** Public.
- **Description:** Accept an invite and create the invited account in one
  call. The invite token proves ownership of the email, so the account is
  marked verified. Returns `409` when an existing account for the invite
  email already belongs to another organization under single-organization
  mode.

```json
{
  "first_name": "New",
  "last_name": "Bie",
  "password": "strong-pass-123",
  "phone": "+234 803 555 0142",
  "job_title": "Designer"
}
```

Returns the accepted invite shape with `status: "active"`; team/project
memberships carried by the invite are created automatically.

---

## Signup links

A signup link lets an owner/admin share a public workspace URL that people
can use to request access. The link is guarded by a secret token on the
workspace row and can be revoked at any time. See
[people_onboarding_integration.md](people_onboarding_integration.md) for the
frontend screens and approval flow.

- The public page route is `/join?token=<signup_token>`.
- Enabling the link generates a token; disabling it clears the token and
  revokes the URL immediately.
- A public signup creates (or links) an account, sends the normal email
  verification message and creates a **pending** membership. An owner/admin
  must approve the request before the person gets workspace access.
- The person must verify their email before approval.
- Public endpoints are rate-limited per client IP and return `429` with
  `Retry-After` when exceeded.
- Single-organization mode is enforced when the request is made and again
  when it is approved.

### GET `/workspace/get-signup-link/{workspace_id}/`

- **Auth:** Owner/admin.
- **Description:** Return the current signup link status.
- When disabled, `token` and `signup_url` are `null`.

```json
{
  "enabled": true,
  "token": "secure-signup-token",
  "signup_url": "https://app.example.com/join?token=secure-signup-token"
}
```

### PUT `/workspace/update-signup-settings/{workspace_id}/`

- **Auth:** Owner/admin.
- **Description:** Enable or disable the workspace signup link.
- Enabling a disabled link generates a fresh token. Disabling clears the
  token so the old URL cannot be reused if the link is enabled again.

```json
{ "enabled": true }
```

Returns the `SignupLinkRead` shape shown above.

### POST `/workspace/regenerate-signup-link/{workspace_id}/`

- **Auth:** Owner/admin.
- **Description:** Rotate the signup token and return the new link. The old
  URL stops working immediately. Returns `400` when the signup link is
  currently disabled; enable it first.

### GET `/workspace/get-signup-public/{token}/`

- **Auth:** Public. Rate-limited.
- **Description:** Public workspace details for the signup page. Returns
  `404` when the token is unknown, disabled or the workspace is unavailable.

```json
{
  "workspace_id": "11111111-1111-4111-8111-111111111111",
  "workspace_name": "Acme Team",
  "logo": null,
  "requires_approval": true
}
```

### POST `/workspace/signup-public/{token}/`

- **Auth:** Public. Rate-limited.
- **Description:** Submit a workspace access request.
- If the email has no account, an unverified account is created and the
  verification email is sent. If an account already exists, it is linked to
  the request and the submitted password is ignored.
- Returns `409` when the email is already an active member, already has a
  pending invite/signup request, or belongs to another organization under
  single-organization mode.
- The response is intentionally generic; the frontend should show the
  returned message.

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

### POST `/workspace/approve-signup/{workspace_id}/{membership_id}/`

- **Auth:** Owner/admin.
- **Description:** Approve a pending signup request and activate the
  membership.
- The membership must be a pending self-signup request (`is_signup_request`
  on the people directory).
- Returns `409` when the person has not verified their email yet or already
  belongs to another organization under single-organization mode.
- Returns `404` when the membership is not a pending signup request for this
  workspace.

Returns the activated `MembershipRead`.

### POST `/workspace/reject-signup/{workspace_id}/{membership_id}/`

- **Auth:** Owner/admin.
- **Description:** Reject a pending signup request. The membership status
  becomes `cancelled`; the person's account is not deleted.

```json
{ "message": "Signup request rejected." }
```

## Signup requests in the directory

Signup requests are **not** returned by `list-invites` or `my-invites`; those
endpoints only describe token-based email invites. Use
`GET /people/list-people/{workspace_id}/?status=pending` and filter on
`is_signup_request: true` to show requests that need approval.
