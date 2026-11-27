# SCP Workspace Approval — Integration Summary

Audience: the SCP console and TMS web client developers.

This release adds the workspace approval gate, the derived tenant statuses in
the SCP Organizations tab, the tenant `kind` filter and the new
`organizations.approve` permission.

Reference:

- Endpoint contract: [`scp_docs.md`](scp_docs.md)
- Main-app workspace contract: [`workspaces_docs.md`](workspaces_docs.md)
- Auth contract: [`auth_docs.md`](auth_docs.md)
- Design: `designs/admin-README 1.md` and `designs/scp-prototype 1.html`

## 1. What changed

| Area | Change |
| --- | --- |
| New workspaces | `POST /auth/signup/` and `POST /workspace/create-workspace/` create the workspace with `approval_status: "pending"` |
| Main-app lockout | Pending and rejected workspaces answer `403` with a machine-readable `code` on every workspace-scoped route |
| Login | `/auth/login/`, `/auth/form-login/` and existing-user OAuth callbacks refuse users whose only active memberships are unapproved |
| SCP tenant list | `GET /scp/list-organizations/` accepts `status=pending` or `status=rejected` plus `kind`, and returns `kind`, `subtype` and the approval columns |
| SCP approval actions | New `POST /scp/approve-organization/{id}/` and `POST /scp/reject-organization/{id}/` |
| SCP dashboard | `GET /scp/get-overview/` returns `pending_organizations` |
| SCP permissions | New `organizations.approve`; it is in `DEFAULT_ADMIN_PERMISSIONS` and all 23 keys are returned for a super admin |
| Emails | The owner receives an approval or decline email; the decline includes the operator's reason |
| Audit | `organization.approve` and `organization.reject` are written for every decision |

## 2. Approval lifecycle

A workspace has both the existing usage status and a separate approval status:

| Field | Values | Notes |
| --- | --- | --- |
| `approval_status` | `pending` / `approved` / `rejected` | Existing workspaces are `approved` |
| `approved_at` | timestamp or `null` | Set when an operator approves |
| `approved_by` | operator display name or `null` | Display name, not an id |
| `rejected_at` | timestamp or `null` | Set when an operator declines |
| `rejected_by` | operator display name or `null` | Display name, not an id |
| `rejected_reason` | string or `null` | Sent to the owner verbatim |

The SCP `organization.status` is derived, never stored:

| Approval | Workspace status | SCP `status` |
| --- | --- | --- |
| `pending` | any | `pending` |
| `rejected` | any | `rejected` |
| `approved` | `active` | `active` |
| `approved` | `suspended` | `suspended` |

Existing workspaces were marked `approved` by the migration and have
`approved_at = created_at`. `approved_by` is `null` for those rows, so the
console should only render the "Approved by …" line when `approved_by` is
present.

## 3. Main app integration

### 3.1 Signup and workspace creation

`POST /auth/signup/` still returns `201` with an access token, even though the
workspace is pending. The token exists so the user can verify their email and
read `GET /workspace/list-workspaces/`; it does not open any workspace-scoped
route. `POST /workspace/create-workspace/` also creates a `pending` workspace
and returns it in `WorkspaceRead`.

`WorkspaceRead` now includes:

```json
{
  "approval_status": "pending",
  "rejected_reason": null
}
```

### 3.2 Login and OAuth

The approval rule only applies when the user has active memberships and none
of them is in an approved workspace:

| User state | Result |
| --- | --- |
| At least one active membership in an approved workspace | Normal token |
| Only pending workspaces | `403` `workspace_pending_approval` |
| Only rejected workspaces | `403` `workspace_rejected`, reason in `detail` |
| No active memberships (for example, only a pending invite) | Normal token |

`/auth/login/`, `/auth/form-login/` and the OAuth callback all enforce this.
A brand-new OAuth user is created with a pending personal workspace and still
receives a session, matching `/auth/signup/`; an existing OAuth user follows
the login rule above.

### 3.3 Scoped workspace access

Any route that resolves a workspace through the shared access helpers
(`.../{workspace_id}/` routes, invite acceptance, signup links) returns:

```json
{
  "detail": "Tarkwa Grace Chapel is waiting for approval. We'll email you as soon as it's approved.",
  "code": "workspace_pending_approval"
}
```

or, for a declined workspace:

```json
{
  "detail": "Tarkwa Grace Chapel wasn't approved. Looks like a duplicate workspace.",
  "code": "workspace_rejected"
}
```

`code` is `workspace_pending_approval` or `workspace_rejected`. Switch on
`code`, not on `detail`, because the workspace name and rejection reason are
dynamic. Invites into a pending or rejected workspace are blocked the same
way.

### 3.4 Workspace list and the waiting screen

`GET /workspace/list-workspaces/` returns the user's pending and rejected
workspaces alongside approved ones (active memberships only). Each item
carries `approval_status` and, when declined, `rejected_reason`. Use this list
for the waiting/declined screen:

1. Show the pending or declined workspace from the list.
2. Poll the list roughly every 15 seconds while the screen is open.
3. When a workspace flips to `approved`, retry the scoped call and enter the
   app.

The login `403` already contains enough text to render the waiting screen
before a token exists. Do not assume the pending workspace is the only one:
a user may belong to another approved workspace and sign in normally.

### 3.5 Invites and signup links

- `GET /workspace/get-invite-public/{token}/` and
  `POST /workspace/accept-invite-public/{token}/` answer the approval `403`
  for a pending or rejected workspace.
- `GET /workspace/get-signup-public/{token}/` and
  `POST /workspace/signup-public/{token}/` behave the same way.
- A declined workspace keeps its row so an operator can approve it later; it
  is not deleted automatically.

### 3.6 Emails

- Approval email: the owner is told they can sign in and invite their people.
  The CTA points at the app's `/signin` route.
- Decline email: includes the operator's reason.

Both are transactional and ignore the marketing unsubscribe list.

## 4. SCP console integration

### 4.1 List organizations

`GET /scp/list-organizations/` extends `status` and adds the `kind` filter:

| Parameter | Values |
| --- | --- |
| `status` | `pending`, `active`, `suspended`, `rejected` |
| `kind` | `business`, `individual`, `family`, `specials` |

- `status=active` and `status=suspended` only return approved workspaces.
- `status=pending` and `status=rejected` filter on `approval_status`.
- Omitting `status` returns every non-deleted tenant.
- `kind` can be combined with any status.

Each item includes the existing fields plus:

```json
{
  "kind": "specials",
  "subtype": "church",
  "status": "pending",
  "approved_at": null,
  "approved_by": null,
  "rejected_at": null,
  "rejected_by": null,
  "rejected_reason": null
}
```

`mrr` is `0` for a workspace that is not approved, is suspended or has free
access. (The design's platform-wide billing freeze is not part of this
change; see section 7.)

### 4.2 Approve a workspace

`POST /scp/approve-organization/{organization_id}/`

- Permission: `organizations.approve`
- Body: optional, `{ "note": "Verified the business details" }`
- Allowed from: `pending` or `rejected`
- Effect: sets `approval_status = approved`, sets `approved_at` and
  `approved_by`, clears the rejected columns, emails the owner and writes
  `organization.approve`
- Response: the updated `ScpOrganizationRead`, with `status: "active"` (or
  `suspended` if the already-approved workspace is suspended)
- Errors:
  - `400` `"This workspace is already approved."`
  - `404` organization not found
  - `403` without `organizations.approve`

`note` is used only in the audit summary. It is not stored on the workspace
and is not emailed.

### 4.3 Decline a workspace

`POST /scp/reject-organization/{organization_id}/`

- Permission: `organizations.approve`
- Body: `{ "reason": "Looks like a duplicate workspace" }`
- Allowed from: `pending` only
- Effect: sets `approval_status = rejected`, sets `rejected_at` and
  `rejected_by`, stores `rejected_reason`, emails the owner and writes
  `organization.reject`
- Response: the updated `ScpOrganizationRead`, with `status: "rejected"`
- Errors:
  - `400` `"Only a workspace awaiting approval can be declined."`
  - `400` `"A reason is required."` for a blank reason
  - `422` when `reason` is missing
  - `404` organization not found
  - `403` without `organizations.approve`

A rejected workspace can still be approved later with
`approve-organization`.

### 4.4 Dashboard

`GET /scp/get-overview/` includes `pending_organizations`. The existing
counters exclude unapproved tenants:

- `active_organizations`: approved and active
- `suspended_organizations`: approved and suspended
- `pending_organizations`: awaiting approval
- `total_organizations`: every non-deleted tenant, including pending and
  rejected

### 4.5 Suspend and reactivate

`POST /scp/suspend-organization/{id}/` and
`POST /scp/reactivate-organization/{id}/` return `400` for a workspace whose
approval status is not `approved`. Approve or reject a sign-up instead.

### 4.6 Permissions

The new key is `organizations.approve`. It belongs to the Organizations
group and `organizations.view` remains the group gate. Existing operators
with `organizations.view` were backfilled with the new key by the migration.

`DEFAULT_ADMIN_PERMISSIONS` is now:

```json
[
  "dashboard.view",
  "organizations.view",
  "organizations.inspect",
  "organizations.approve",
  "operators.view",
  "help.view",
  "help.reply",
  "help.resolve",
  "audit.view"
]
```

A super admin still implicitly holds every permission and now returns all 23
keys. `normalize_permissions` keeps its existing rule: sending any key in a
group adds the group gate, and a gate cannot be granted without its group.

### 4.7 Audit events

| Action | Category | Severity | When |
| --- | --- | --- | --- |
| `organization.created` | `system` | `info` | A workspace is created and starts pending |
| `organization.approve` | `admin_action` | `warning` | An operator approves a sign-up |
| `organization.reject` | `admin_action` | `warning` | An operator declines a sign-up |

The approve summary includes the optional note. The reject summary includes
the reason.

## 5. Screen map

| Screen | Data / actions |
| --- | --- |
| Main-app waiting screen | `GET /workspace/list-workspaces/`, poll every ~15s; read `approval_status` |
| Main-app declined screen | Same list; read `approval_status` and `rejected_reason` |
| Main-app login | `POST /auth/login/`, `POST /auth/form-login/`; handle `403` + `code` |
| Main-app OAuth callback | `POST /auth/oauth/{provider}/callback/`; existing users can receive the same `403` + `code` |
| SCP Organizations · All tenants | `GET /scp/list-organizations/` |
| SCP Organizations · Awaiting approval | `GET /scp/list-organizations/?status=pending` |
| SCP Organizations · Declined | `GET /scp/list-organizations/?status=rejected` |
| SCP Organizations · Active / Suspended | `?status=active` / `?status=suspended` |
| SCP tenant detail | `GET /scp/get-organization/{id}/`; show approval banner with Approve / Decline |
| SCP approve / decline | `POST /scp/approve-organization/{id}/`, `POST /scp/reject-organization/{id}/` |
| SCP dashboard | `GET /scp/get-overview/`; use `pending_organizations` for the "review sign-ups" bar |
| SCP admin permissions | `PUT /scp/update-operator-permissions/{id}/`; include `organizations.approve` in the matrix |

## 6. Verification checklist

- [ ] Signup and create-workspace return `approval_status: "pending"`.
- [ ] `GET /workspace/list-workspaces/` includes pending and rejected
      workspaces with `rejected_reason`.
- [ ] Login, form-login and OAuth answer `403` + `workspace_pending_approval`
      when every active membership is pending.
- [ ] Login answers `403` + `workspace_rejected` with the reason when every
      active membership is rejected.
- [ ] A user with at least one approved workspace can still sign in.
- [ ] A workspace-scoped route and an invite into a pending workspace return
      the same `403` + `code`.
- [ ] `list-organizations?status=pending` and `?status=rejected` return the
      right rows and `kind` filters by tenant type.
- [ ] `get-overview` returns a matching `pending_organizations` count.
- [ ] Approve unlocks the owner, emails them, audits `organization.approve`
      and clears any previous decline fields.
- [ ] Decline requires a reason, emails it, audits `organization.reject` and
      makes login return `workspace_rejected`.
- [ ] Suspend and reactivate return `400` for an unapproved workspace.
- [ ] An admin without `organizations.approve` gets `403` from both decision
      endpoints.
- [ ] A super admin returns all 23 permission keys.

## 7. Not in this change

The design's platform-wide billing freeze (every `mrr` and overview money
figure at `0` until payments go live) is not implemented here. Revenue fields
keep their existing plan-based behaviour for approved active tenants, and are
`0` for pending, rejected, suspended or free-access tenants.
