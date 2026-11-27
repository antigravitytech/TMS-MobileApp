# SCP Admin Control Panel API Documentation

Source: `tms/scp/routers.py`

**Prefix:** `/scp`

SCP is the platform-level control unit. Its operators are **not** workspace
users: `ScpOperator` is a separate account table, and an SCP token never
authenticates a main-app user endpoint (or the other way round).

For implementation details see `tms/scp/services.py`, `tms/scp/schemas.py`
and `tms/scp/permissions.py`. For the workspace approval flow and console
integration map see
[`scp_changes_integration.md`](scp_changes_integration.md).

## Authentication

Public endpoints:

- `POST /scp/login/`
- `GET /scp/get-access-link/{token}/`
- `POST /scp/set-password/{token}/`

Every other endpoint requires:

```http
Authorization: Bearer <scp_access_token>
```

The token is issued by `POST /scp/login/` and identifies an operator. The
acting operator is always taken from the token; do not send an operator id.

## Pagination

List endpoints return:

```json
{
  "items": [],
  "total": 0,
  "page": 1,
  "page_size": 10,
  "total_pages": 0
}
```

`page` is 1-based. `page_size` is capped at 100. If `page` is beyond the last
page, SCP returns the last page and echoes that page number back.

`GET /scp/list-activity/` and `GET /scp/list-plans/` return **plain arrays**,
not the envelope.

## Errors

```json
{ "detail": "This tenant is already suspended." }
```

`detail` is written for direct display to the operator. Status codes:

| Status | Meaning |
| --- | --- |
| `400` | Validation or invalid state transition |
| `401` | Missing, expired or invalid token; bad login credentials |
| `403` | Authenticated but missing permission, revoked account, or a suspended/pending/rejected workspace |
| `404` | Resource not found |
| `409` | Duplicate operator email |
| `422` | Pydantic validation failure |

Workspace approval errors carry a machine-readable `code` next to `detail`:

```json
{
  "detail": "Tarkwa Grace Chapel is waiting for approval. We'll email you as soon as it's approved.",
  "code": "workspace_pending_approval"
}
```

`code` is `workspace_pending_approval` or `workspace_rejected`.

## Permissions

A `super_admin` implicitly holds every permission and cannot be narrowed. An
`admin` holds exactly the keys in `permissions`.

| Group | Keys |
| --- | --- |
| Dashboard | `dashboard.view`, `dashboard.view_revenue` |
| Organizations | `organizations.view`, `organizations.inspect`, `organizations.approve`, `organizations.change_plan`, `organizations.grant_free_access`, `organizations.suspend`, `organizations.delete` |
| Admin team | `operators.view`, `operators.invite`, `operators.manage_roles`, `operators.manage_permissions`, `operators.reset_password`, `operators.revoke`, `operators.delete` |
| Monetization | `monetization.view`, `monetization.edit_plans` |
| Help center | `help.view`, `help.reply`, `help.resolve` |
| Audit logs | `audit.view`, `audit.export` |

Default permissions for a new admin:

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

When saving permissions, SCP normalises server-side:

- adding any key in a group adds that group's first key (the gate);
- a gate is always stored with any of its group keys;
- unknown keys are rejected with `400`.

## Operator shape

```json
{
  "id": "8f8d8f60-3c30-4c1a-9c71-3d2a8d7b2f11",
  "email": "support.lead@sabipipu.com",
  "first_name": "Chinedu",
  "last_name": "Okafor",
  "photo": null,
  "role": "admin",
  "status": "active",
  "last_login_at": "2026-11-10T11:04:00+00:00",
  "invited_by": "Micheal Peter",
  "created_at": "2026-01-14T09:00:00+00:00",
  "has_password": true,
  "password_reset_at": null,
  "permissions": [
    "dashboard.view",
    "organizations.view",
    "help.view",
    "help.reply",
    "help.resolve",
    "audit.view"
  ]
}
```

For a `super_admin`, `permissions` contains all 23 keys.

## Access-link shape

```json
{
  "token": "sZQ9...",
  "kind": "invite",
  "url": "https://scp.sabipipu.com/accept-invite?token=sZQ9...",
  "email": "tola.bakare@sabipipu.com",
  "expires_at": "2026-11-17T15:10:00+00:00"
}
```

Invite links expire after `SCP_INVITE_TOKEN_EXPIRE_DAYS` (default 7 days).
Reset links expire after `SCP_RESET_TOKEN_EXPIRE_HOURS` (default 24 hours).
Issuing a new token of the same kind invalidates the outstanding one. Links
are single use.

## Organization shape

```json
{
  "id": "9e9e4a5c-1f22-4dd2-b3a3-82b6f2e9a111",
  "name": "Adunni Logistics",
  "slug": "adunni-logistics-1",
  "color": "#9184d9",
  "kind": "business",
  "subtype": null,
  "status": "active",
  "plan": "small",
  "billing_cycle": "yearly",
  "owner_name": "Tunde Adeyemi",
  "owner_email": "tunde.adeyemi@adunni.com",
  "country": "Nigeria",
  "user_count": 13,
  "task_count": 1229,
  "project_count": 6,
  "storage_used_mb": 1638,
  "storage_limit_mb": 10240,
  "mrr": 38250,
  "open_tickets": 1,
  "created_at": "2025-06-28T10:00:00+00:00",
  "last_active_at": "2026-11-09T14:12:00+00:00",
  "suspended_at": null,
  "suspended_reason": null,
  "approved_at": "2025-06-28T10:00:00+00:00",
  "approved_by": "Micheal Peter",
  "rejected_at": null,
  "rejected_by": null,
  "rejected_reason": null,
  "free_access": false,
  "free_until": null,
  "free_reason": null,
  "free_granted_by": null
}
```

- `kind` is `business`, `individual`, `family` or `specials`. `subtype` is
  set only for specials (`church`, `alumni`, `estate`, `event`, `committee`,
  `club`).
- `status` is derived: `pending` and `rejected` come from the workspace's
  approval state; approved workspaces report `active` or `suspended`.
- `approved_at` / `approved_by` are set when an operator approves the
  workspace. `rejected_*` are cleared by an approval.
- `mrr` is `0` while the tenant is not approved, suspended or on free access.
  Yearly billing applies `SCP_YEARLY_DISCOUNT_PERCENT` (default 15%). Example:
  `round(45000 * 0.85) = 38250`.
- `storage_limit_mb` is `null` for an unlimited plan.
- `country` is taken from the owner's latest login record when available.
- `color` is a stable palette colour derived from the workspace id.
- `last_active_at` is the latest member activity in the workspace.

---

# Auth

## POST `/scp/login/`

- **Summary:** Sign in to the control unit.
- **Auth:** Public. Rate limited per client IP.

**Payload:**

```json
{
  "email": "omega@sabipipu.com",
  "password": "strong-password"
}
```

**Response `200`:**

```json
{
  "access_token": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...",
  "token_type": "bearer",
  "operator": {
    "id": "8f8d8f60-3c30-4c1a-9c71-3d2a8d7b2f11",
    "email": "omega@sabipipu.com",
    "first_name": "Micheal",
    "last_name": "Peter",
    "photo": null,
    "role": "super_admin",
    "status": "active",
    "last_login_at": "2026-11-11T08:30:00+00:00",
    "invited_by": null,
    "created_at": "2025-11-01T09:00:00+00:00",
    "has_password": true,
    "password_reset_at": null,
    "permissions": ["dashboard.view", "dashboard.view_revenue", "organizations.view", "organizations.inspect", "organizations.approve", "organizations.change_plan", "organizations.grant_free_access", "organizations.suspend", "organizations.delete", "operators.view", "operators.invite", "operators.manage_roles", "operators.manage_permissions", "operators.reset_password", "operators.revoke", "operators.delete", "monetization.view", "monetization.edit_plans", "help.view", "help.reply", "help.resolve", "audit.view", "audit.export"]
  }
}
```

**Errors:**

- `401` `"No control-unit account with that email."`
- `403` `"This account has been revoked. Ask a super admin for access."`
- `403` `"This invite has not been accepted yet. Open the invite link to set a password first."`
- `401` `"That email and password don't match."`

A successful sign-in writes an `operator.login` audit entry and updates
`last_login_at`.

---

## GET `/scp/get-me/`

- **Summary:** Return the operator behind the bearer token.
- **Auth:** Any active SCP operator.

**Payload:** none.

**Response `200`:** the full [operator shape](#operator-shape).

**Errors:** `401` when the token is invalid, expired or the account is no
longer active.

---

## GET `/scp/get-access-link/{token}/`

- **Summary:** Read an invite or reset link without consuming it.
- **Auth:** Public. Rate limited per client IP.

**Path parameter:** `token` — the opaque link token.

**Payload:** none.

**Response `200`:**

```json
{
  "token": "sZQ9...",
  "kind": "invite",
  "email": "tola.bakare@sabipipu.com",
  "first_name": "Tola",
  "last_name": "Bakare",
  "role": "admin",
  "expires_at": "2026-11-17T15:10:00+00:00"
}
```

**Errors:**

- `400` `"This link has already been used. Ask a super admin for a new one."`
  Also returned for an unknown token.
- `400` `"This link has expired. Ask a super admin for a new one."`
- `400` `"This account has been revoked. Ask a super admin for access."`

---

## POST `/scp/set-password/{token}/`

- **Summary:** Set a password from an invite or reset link.
- **Auth:** Public. Rate limited per client IP.

**Path parameter:** `token` — the opaque link token.

**Payload:**

```json
{
  "password": "new-strong-password",
  "confirm_password": "new-strong-password"
}
```

**Response `200` — invite:**

```json
{
  "message": "Your account is ready. Sign in to open the control unit.",
  "email": "tola.bakare@sabipipu.com"
}
```

**Response `200` — reset:**

```json
{
  "message": "Password changed. Sign in with your new password.",
  "email": "tola.bakare@sabipipu.com"
}
```

**Errors:**

- `422` when a password is shorter than 8 characters or longer than 128.
- `400` `"Both passwords must match."`
- `400` `"This link has already been used. Ask a super admin for a new one."`
- `400` `"This link has expired. Ask a super admin for a new one."`
- `400` `"This account has been revoked. Ask a super admin for access."`

On success the operator becomes `active`, `password_reset_at` is cleared, the
token is marked used, and the password change invalidates earlier JWTs.

---

# Dashboard

## GET `/scp/get-overview/`

- **Summary:** Return platform totals, plan breakdown and the revenue trend.
- **Auth/Permission:** `dashboard.view`.

**Payload:** none.

**Response `200`:**

```json
{
  "total_organizations": 142,
  "active_organizations": 124,
  "suspended_organizations": 18,
  "pending_organizations": 9,
  "total_users": 3184,
  "platform_mrr": 6920000,
  "platform_arr": 83040000,
  "open_tickets": 23,
  "new_organizations_30d": 4,
  "plan_breakdown": [
    { "tier": "free", "organizations": 34, "mrr": 0 },
    { "tier": "small", "organizations": 46, "mrr": 1890000 },
    { "tier": "medium", "organizations": 41, "mrr": 4130000 },
    { "tier": "custom", "organizations": 21, "mrr": 900000 }
  ],
  "revenue_trend": [
    { "month": "Dec", "mrr": 3100000, "organizations": 68 },
    { "month": "Jan", "mrr": 3260000, "organizations": 72 }
  ]
}
```

`revenue_trend` always has **12 entries**, oldest first, ending with the
current month. `open_tickets` counts `open` and `pending`. The trend is
derived from current plan assignments and workspace creation dates; there is
no separate billing-history table.

`active_organizations` and `suspended_organizations` count only approved
workspaces; `pending_organizations` counts workspaces awaiting approval.
`total_organizations` includes every non-deleted tenant.

Without `dashboard.view_revenue`, the endpoint still returns `200` but sends
`platform_mrr`, `platform_arr`, every `plan_breakdown[].mrr` and every
`revenue_trend[].mrr` as `null`. It never sends zeros in their place.

**Errors:** `403` without `dashboard.view`.

---

## GET `/scp/list-activity/`

- **Summary:** Return the newest audit entries as a plain array.
- **Auth/Permission:** `audit.view`.

**Query parameters:**

| Name | Type | Default | Notes |
| --- | --- | --- | --- |
| `limit` | int | `8` | 1–50 |

**Response `200`:** plain array of [audit-log shapes](#audit-log-shape).

```json
[
  {
    "id": "e9d3b4c2-6a71-4ca8-a7a2-8f16f0f0f111",
    "category": "admin_action",
    "severity": "critical",
    "action": "organization.suspend",
    "summary": "Suspended Adunni Logistics — payment failed for two cycles",
    "actor_name": "Micheal Peter",
    "actor_role": "super_admin",
    "target": "Adunni Logistics",
    "ip_address": "102.89.14.7",
    "created_at": "2026-11-10T16:11:00+00:00"
  }
]
```

**Errors:** `403` without `audit.view`.

---

# Organizations

## GET `/scp/list-organizations/`

- **Summary:** List every workspace as an SCP organization.
- **Auth/Permission:** `organizations.view`.

**Query parameters:**

| Name | Type | Default | Notes |
| --- | --- | --- | --- |
| `search` | string | — | Matches name, slug, owner name or owner email, case-insensitive |
| `status` | `pending` / `active` / `suspended` / `rejected` | — | Derived tenant status. `active`/`suspended` only return approved workspaces |
| `kind` | `business` / `individual` / `family` / `specials` | — | Workspace type |
| `plan` | `free` / `small` / `medium` / `custom` | — | Tier |
| `date_from` | `yyyy-MM-dd` | — | Inclusive `created_at` lower bound |
| `date_to` | `yyyy-MM-dd` | — | Inclusive `created_at` upper bound |
| `sort_by` | `name` / `created_at` / `mrr` / `user_count` / `last_active_at` | `created_at` | |
| `sort_dir` | `asc` / `desc` | `desc` | |
| `page` | int | `1` | |
| `page_size` | int | `10` | Max 100 |

**Payload:** none.

**Response `200`:**

```json
{
  "items": [
    {
      "id": "9e9e4a5c-1f22-4dd2-b3a3-82b6f2e9a111",
      "name": "Adunni Logistics",
      "slug": "adunni-logistics-1",
      "color": "#9184d9",
      "kind": "business",
      "subtype": null,
      "status": "active",
      "plan": "small",
      "billing_cycle": "yearly",
      "owner_name": "Tunde Adeyemi",
      "owner_email": "tunde.adeyemi@adunni.com",
      "country": "Nigeria",
      "user_count": 13,
      "task_count": 1229,
      "project_count": 6,
      "storage_used_mb": 1638,
      "storage_limit_mb": 10240,
      "mrr": 38250,
      "open_tickets": 1,
      "created_at": "2025-06-28T10:00:00+00:00",
      "last_active_at": "2026-11-09T14:12:00+00:00",
      "suspended_at": null,
      "suspended_reason": null,
      "approved_at": "2025-06-28T10:00:00+00:00",
      "approved_by": "Micheal Peter",
      "rejected_at": null,
      "rejected_by": null,
      "rejected_reason": null,
      "free_access": false,
      "free_until": null,
      "free_reason": null,
      "free_granted_by": null
    }
  ],
  "total": 142,
  "page": 1,
  "page_size": 10,
  "total_pages": 15
}
```

**Errors:** `400` when `date_from` is after `date_to`; `422` for an
unsupported sort field; `403` without `organizations.view`.

---

## GET `/scp/get-organization/{organization_id}/`

- **Summary:** Return one tenant with six-month usage and workspace admins.
- **Auth/Permission:** `organizations.inspect`.

**Path parameter:** `organization_id` — workspace UUID.

**Payload:** none.

**Response `200`:** the [organization shape](#organization-shape) plus:

```json
{
  "usage": [
    { "month": "Jun", "active_users": 9, "tasks_created": 180 },
    { "month": "Jul", "active_users": 10, "tasks_created": 204 },
    { "month": "Aug", "active_users": 11, "tasks_created": 221 },
    { "month": "Sep", "active_users": 12, "tasks_created": 239 },
    { "month": "Oct", "active_users": 12, "tasks_created": 255 },
    { "month": "Nov", "active_users": 13, "tasks_created": 88 }
  ],
  "admins": [
    {
      "name": "Tunde Adeyemi",
      "email": "tunde.adeyemi@adunni.com",
      "role": "Owner"
    },
    {
      "name": "Adunni Admin 1",
      "email": "admin1@adunni.com",
      "role": "Admin"
    }
  ]
}
```

`usage` always has six entries, oldest first. `active_users` counts distinct
workspace members with a login in that month.

**Errors:** `404` `"Organization not found."`; `403` without
`organizations.inspect`.

---

## POST `/scp/approve-organization/{organization_id}/`

- **Summary:** Approve a new workspace so its owner can use the app.
- **Auth/Permission:** `organizations.approve`.

**Path parameter:** `organization_id` — workspace UUID.

**Payload:** optional.

```json
{
  "note": "Verified the business details"
}
```

`note` is written to the audit summary only.

**Response `200`:** the updated [organization shape](#organization-shape) with
`status: "active"`, `approved_at`, `approved_by` set and the `rejected_*`
columns cleared.

The owner is emailed that they can sign in and invite their people. Every
workspace-scoped main-app endpoint stops returning
`workspace_pending_approval` immediately. The audit entry is
`organization.approve`.

**Errors:**

- `400` `"This workspace is already approved."`
- `404` `"Organization not found."`
- `403` without `organizations.approve`.

---

## POST `/scp/reject-organization/{organization_id}/`

- **Summary:** Decline a workspace that is awaiting approval.
- **Auth/Permission:** `organizations.approve`.

**Path parameter:** `organization_id` — workspace UUID.

**Payload:**

```json
{
  "reason": "Looks like a duplicate of an existing workspace"
}
```

`reason` is required and is emailed to the owner verbatim.

**Response `200`:** the updated [organization shape](#organization-shape) with
`status: "rejected"`, `rejected_at`, `rejected_by` and `rejected_reason` set.
The owner's sign-in now answers `403` with `code: "workspace_rejected"` and
the reason.

**Errors:**

- `400` `"Only a workspace awaiting approval can be declined."`
- `400` `"A reason is required."` when the reason is blank.
- `404` `"Organization not found."`
- `422` when `reason` is missing.
- `403` without `organizations.approve`.

A rejected workspace can still be approved later with
`approve-organization`.

---

## PATCH `/scp/change-organization-plan/{organization_id}/`

- **Summary:** Move a tenant to another tier or billing cycle.
- **Auth/Permission:** `organizations.change_plan`.

**Path parameter:** `organization_id` — workspace UUID.

**Payload:**

```json
{
  "plan": "medium",
  "billing_cycle": "yearly"
}
```

**Response `200`:** the updated [organization shape](#organization-shape).

**Errors:**

- `404` `"Organization not found."`
- `400` `"That plan is not available."`
- `403` without `organizations.change_plan`.

Existing tenants keep their current billing cycle until changed explicitly.
Moving a tenant that is not approved, suspended or on free access keeps `mrr`
at `0`.

---

## POST `/scp/grant-free-access/{organization_id}/`

- **Summary:** Give a tenant complimentary access.
- **Auth/Permission:** `organizations.grant_free_access`.

**Path parameter:** `organization_id` — workspace UUID.

**Payload:**

```json
{
  "duration_days": 90,
  "reason": "Design-partner pilot"
}
```

Use `"duration_days": null` for free access with no end date. `reason` is
required.

**Response `200`:** the updated [organization shape](#organization-shape) with
`free_access: true`, `free_until` set to today + 90 days (or `null`),
`free_reason`, `free_granted_by` and `mrr: 0`.

**Errors:**

- `404` `"Organization not found."`
- `422` when `reason` is missing/blank or `duration_days` is below 1.
- `403` without `organizations.grant_free_access`.

---

## DELETE `/scp/end-free-access/{organization_id}/`

- **Summary:** End a tenant's complimentary access.
- **Auth/Permission:** `organizations.grant_free_access`.

**Path parameter:** `organization_id` — workspace UUID.

**Payload:** none.

**Response `200`:** the updated [organization shape](#organization-shape) with
the free-access columns cleared and `mrr` restored from the plan (`0` while
suspended).

**Errors:**

- `400` `"This organization is not on free access."`
- `404` `"Organization not found."`
- `403` without `organizations.grant_free_access`.

---

## POST `/scp/suspend-organization/{organization_id}/`

- **Summary:** Suspend a tenant and lock its members out of the main app.
- **Auth/Permission:** `organizations.suspend`.

**Path parameter:** `organization_id` — workspace UUID.

**Payload:**

```json
{
  "reason": "Payment failed for two cycles"
}
```

**Response `200`:** the updated [organization shape](#organization-shape) with
`status: "suspended"`, `suspended_at`, `suspended_reason` and `mrr: 0`.

While suspended, every workspace-scoped main-app endpoint that uses the
workspace access checks returns `403` with
`"This workspace is suspended. Contact support to restore access."`

**Errors:**

- `400` `"This tenant is already suspended."`
- `400` `"Only an approved workspace can be suspended."`
- `404` `"Organization not found."`
- `422` when `reason` is missing/blank.
- `403` without `organizations.suspend`.

---

## POST `/scp/reactivate-organization/{organization_id}/`

- **Summary:** Reactivate a suspended tenant.
- **Auth/Permission:** `organizations.suspend`.

**Path parameter:** `organization_id` — workspace UUID.

**Payload:** none.

**Response `200`:** the updated [organization shape](#organization-shape) with
`status: "active"`, suspension columns cleared and `mrr` restored (`0` if the
tenant is on free access).

**Errors:**

- `400` `"This tenant is not suspended."`
- `400` `"Only an approved workspace can be reactivated."`
- `404` `"Organization not found."`
- `403` without `organizations.suspend`.

---

## DELETE `/scp/delete-organization/{organization_id}/`

- **Summary:** Delete a tenant, its data and its support tickets.
- **Auth/Permission:** `organizations.delete`.

**Path parameter:** `organization_id` — workspace UUID.

**Payload:** none.

**Response `200`:**

```json
{
  "message": "Adunni Logistics deleted."
}
```

The workspace is soft-deleted and disappears immediately from SCP and the
main app. Pending invites are cancelled and support tickets are removed.
Audit entries are never deleted. The tenant's rows are hard-deleted by the
daily purge job after `SCP_DELETED_ORG_RETENTION_DAYS` (default `30`); object
storage should have a matching bucket lifecycle rule.

**Errors:**

- `404` `"Organization not found."`
- `403` without `organizations.delete`.

---

# Operators

## GET `/scp/list-operators/`

- **Summary:** List control-unit operators.
- **Auth/Permission:** `operators.view`.

**Query parameters:**

| Name | Type | Default | Notes |
| --- | --- | --- | --- |
| `search` | string | — | Matches name or email |
| `role` | `super_admin` / `admin` | — | |
| `status` | `active` / `pending` / `revoked` | — | |
| `sort_by` | `name` / `created_at` / `last_login_at` | `created_at` | |
| `sort_dir` | `asc` / `desc` | `desc` | |
| `page` | int | `1` | |
| `page_size` | int | `10` | Max 100 |

**Payload:** none.

**Response `200`:**

```json
{
  "items": [
    {
      "id": "8f8d8f60-3c30-4c1a-9c71-3d2a8d7b2f11",
      "email": "support.lead@sabipipu.com",
      "first_name": "Chinedu",
      "last_name": "Okafor",
      "photo": null,
      "role": "admin",
      "status": "active",
      "last_login_at": "2026-11-10T11:04:00+00:00",
      "invited_by": "Micheal Peter",
      "created_at": "2026-01-14T09:00:00+00:00",
      "has_password": true,
      "password_reset_at": null,
      "permissions": [
        "dashboard.view",
        "organizations.view",
        "help.view",
        "help.reply",
        "help.resolve",
        "audit.view"
      ]
    }
  ],
  "total": 8,
  "page": 1,
  "page_size": 10,
  "total_pages": 1
}
```

**Errors:** `422` for an unsupported sort field; `403` without
`operators.view`.

---

## POST `/scp/invite-operator/`

- **Summary:** Invite a new operator and return a one-time link.
- **Auth/Permission:** `operators.invite`.

**Payload:**

```json
{
  "email": "tola.bakare@sabipipu.com",
  "first_name": "Tola",
  "last_name": "Bakare",
  "role": "admin",
  "permissions": ["dashboard.view", "help.view"]
}
```

`permissions` is optional. Omitted means `DEFAULT_ADMIN_PERMISSIONS`; for
`super_admin` the full 23 are stored.

**Response `201`:**

```json
{
  "operator": {
    "id": "b5b0f0a2-5a7f-4a77-b6d9-2a3f9f7e5a11",
    "email": "tola.bakare@sabipipu.com",
    "first_name": "Tola",
    "last_name": "Bakare",
    "photo": null,
    "role": "admin",
    "status": "pending",
    "last_login_at": null,
    "invited_by": "Micheal Peter",
    "created_at": "2026-11-11T08:30:00+00:00",
    "has_password": false,
    "password_reset_at": null,
    "permissions": ["dashboard.view", "help.view"]
  },
  "link": {
    "token": "sZQ9...",
    "kind": "invite",
    "url": "https://scp.sabipipu.com/accept-invite?token=sZQ9...",
    "email": "tola.bakare@sabipipu.com",
    "expires_at": "2026-11-18T08:30:00+00:00"
  }
}
```

The invite email is sent as well as the link being returned.

**Errors:**

- `409` `"An operator with that email already exists."`
- `400` `"Unknown permission: <key>."`
- `403` without `operators.invite`.

---

## PATCH `/scp/change-operator-role/{operator_id}/`

- **Summary:** Promote or demote an operator.
- **Auth/Permission:** `operators.manage_roles`.

**Path parameter:** `operator_id` — operator UUID.

**Payload:**

```json
{
  "role": "super_admin"
}
```

**Response `200`:** the updated [operator shape](#operator-shape).

Promoting to `super_admin` stores all 23 permissions. Demoting to `admin`
resets permissions to `DEFAULT_ADMIN_PERMISSIONS`.

**Errors:**

- `400` `"You cannot change your own role."`
- `404` `"Operator not found."`
- `403` without `operators.manage_roles`.

---

## PUT `/scp/update-operator-permissions/{operator_id}/`

- **Summary:** Replace an admin's permission set.
- **Auth/Permission:** `operators.manage_permissions`.

**Path parameter:** `operator_id` — operator UUID.

**Payload:**

```json
{
  "permissions": ["organizations.delete"]
}
```

The server normalises the list. The example above is stored as:

```json
["organizations.view", "organizations.delete"]
```

**Response `200`:** the updated [operator shape](#operator-shape).

**Errors:**

- `400` `"Super admins always hold every permission. Make them an admin first to limit what they can do."`
- `400` `"Unknown permission: <key>."`
- `404` `"Operator not found."`
- `403` without `operators.manage_permissions`.

---

## POST `/scp/reset-operator-password/{operator_id}/`

- **Summary:** Issue a reset link, or a fresh invite for a pending operator.
- **Auth/Permission:** `operators.reset_password`.

**Path parameter:** `operator_id` — operator UUID.

**Payload:** none.

**Response `200`:** the [access-link shape](#access-link-shape) directly, not
wrapped:

```json
{
  "token": "rT8x...",
  "kind": "reset",
  "url": "https://scp.sabipipu.com/reset-password?token=rT8x...",
  "email": "tola.bakare@sabipipu.com",
  "expires_at": "2026-11-12T08:30:00+00:00"
}
```

For a `pending` operator the returned kind is `invite` and the link points at
`/accept-invite`. Issuing a reset ends every JWT already held by the target
operator; they must sign in again after choosing a new password.

**Errors:**

- `400` `"This operator's access is revoked. Restore it first."`
- `404` `"Operator not found."`
- `403` without `operators.reset_password`.

---

## POST `/scp/resend-operator-invite/{operator_id}/`

- **Summary:** Reissue an outstanding invite link.
- **Auth/Permission:** `operators.invite`.

**Path parameter:** `operator_id` — operator UUID.

**Payload:** none.

**Response `200`:**

```json
{
  "message": "Invite resent to tola.bakare@sabipipu.com."
}
```

**Errors:**

- `400` `"Only pending invites can be resent."`
- `404` `"Operator not found."`
- `403` without `operators.invite`.

---

## POST `/scp/revoke-operator/{operator_id}/`

- **Summary:** Revoke an operator's access, ending their sessions and links.
- **Auth/Permission:** `operators.revoke`.

**Path parameter:** `operator_id` — operator UUID.

**Payload:** none.

**Response `200`:** the updated [operator shape](#operator-shape) with
`status: "revoked"`.

**Errors:**

- `400` `"You cannot revoke your own account."`
- `400` `"This operator's access is already revoked."`
- `404` `"Operator not found."`
- `403` without `operators.revoke`.

---

## POST `/scp/restore-operator/{operator_id}/`

- **Summary:** Restore a revoked operator.
- **Auth/Permission:** `operators.revoke`.

**Path parameter:** `operator_id` — operator UUID.

**Payload:** none.

**Response `200`:** the updated [operator shape](#operator-shape). The status
becomes `active` when the operator has a password, otherwise `pending`.
Sessions ended by the revocation are not restored; the operator must sign in
again.

**Errors:**

- `400` `"This operator's access is not revoked."`
- `404` `"Operator not found."`
- `403` without `operators.revoke`.

---

## DELETE `/scp/delete-operator/{operator_id}/`

- **Summary:** Delete an operator account.
- **Auth/Permission:** `operators.delete`.

**Path parameter:** `operator_id` — operator UUID.

**Payload:** none.

**Response `200`:**

```json
{
  "message": "Operator deleted successfully."
}
```

Audit entries survive because `actor_name` is stored as a string.

**Errors:**

- `400` `"You cannot delete your own account."`
- `404` `"Operator not found."`
- `403` without `operators.delete`.

---

# Monetization

## GET `/scp/list-plans/`

- **Summary:** Return every plan with its feature matrix and live subscriber
  count.
- **Auth/Permission:** `monetization.view`.

**Payload:** none.

**Response `200`:** plain array of plans.

```json
[
  {
    "id": "3e31f7e0-6e3a-4e91-9a3d-3b7e5a8c2d11",
    "tier": "small",
    "name": "Small team",
    "price_label": "₦45,000 / month",
    "price_amount": 45000,
    "currency": "NGN",
    "billing_cycle": "monthly",
    "max_users": 25,
    "storage_limit_gb": 10.0,
    "is_active": true,
    "subscriber_count": 46,
    "updated_at": "2026-10-17T15:00:00+00:00",
    "features": [
      {
        "key": "people",
        "name": "People",
        "description": "How many members a workspace can have.",
        "enabled": true,
        "limit": "Up to 25"
      },
      {
        "key": "calls",
        "name": "Voice and video calls",
        "description": "Calling inside chat.",
        "enabled": false,
        "limit": null
      }
    ]
  }
]
```

Every plan contains the same 15 feature keys in the same order:
`people`, `tasks`, `chat`, `projects`, `files`, `routines`, `reports`,
`organogram`, `guest_checkin`, `gamification`, `calls`, `sso`,
`audit_export`, `support`, `branding`.

**Errors:** `403` without `monetization.view`.

---

## PUT `/scp/update-plan/{plan_id}/`

- **Summary:** Edit a plan and its feature matrix.
- **Auth/Permission:** `monetization.edit_plans`.

**Path parameter:** `plan_id` — plan UUID.

**Payload:** the full editable plan object.

```json
{
  "name": "Small team",
  "price_label": "₦45,000 / month",
  "price_amount": 45000,
  "billing_cycle": "monthly",
  "max_users": 25,
  "storage_limit_gb": 10,
  "is_active": true,
  "features": [
    {
      "key": "people",
      "name": "People",
      "description": "How many members a workspace can have.",
      "enabled": true,
      "limit": "Up to 25"
    },
    {
      "key": "tasks",
      "name": "Tasks and approvals",
      "description": "Assign, submit, approve, return.",
      "enabled": true,
      "limit": null
    }
  ]
}
```

`features` must contain exactly the 15 catalogue keys. `id`, `tier` and
`currency` are not editable. `null` for `max_users` or `storage_limit_gb`
means unlimited.

**Response `200`:** the updated plan, in the same shape as a
`GET /scp/list-plans/` item.

**Errors:**

- `404` `"Plan not found."`
- `400` `"A plan must include exactly the 15 catalogue features."`
- `400` `"Each feature key may only appear once."`
- `403` without `monetization.edit_plans`.

Plan changes write a `plan.update` audit entry. Tenant MRR is computed from
the current plan price, so a price edit affects existing tenants immediately
in this implementation.

---

# Help Center

SCP reads and replies to tickets; ticket creation is intentionally not part of
this API. The main TMS app, an inbound email hook or chat integration must
create `scp_tickets` rows with their first `scp_ticket_messages` row and a
unique `reference`.

## GET `/scp/list-tickets/`

- **Summary:** List support tickets. Message bodies are omitted from the list.
- **Auth/Permission:** `help.view`.

**Query parameters:**

| Name | Type | Default | Notes |
| --- | --- | --- | --- |
| `search` | string | — | Subject, reference, organization, requester name/email |
| `status` | `open` / `pending` / `resolved` | — | |
| `priority` | `low` / `medium` / `high` | — | |
| `channel` | `email` / `chat` | — | |
| `date_from` | `yyyy-MM-dd` | — | Inclusive `created_at` lower bound |
| `date_to` | `yyyy-MM-dd` | — | Inclusive `created_at` upper bound |
| `sort_by` | `created_at` / `updated_at` / `priority` | `updated_at` | |
| `sort_dir` | `asc` / `desc` | `desc` | |
| `page` | int | `1` | |
| `page_size` | int | `10` | Max 100 |

**Payload:** none.

**Response `200`:**

```json
{
  "items": [
    {
      "id": "d3f1a3e8-6ee2-4aa5-9a2a-2c9f9e8d7b11",
      "reference": "SP-4130",
      "subject": "Cannot invite new staff after upgrade",
      "status": "open",
      "priority": "medium",
      "channel": "chat",
      "organization_id": "9e9e4a5c-1f22-4dd2-b3a3-82b6f2e9a111",
      "organization_name": "Tarkwa Group 5",
      "requester_name": "Ngozi Okonkwo",
      "requester_email": "ngozi@tarkwa.com",
      "assigned_to": null,
      "created_at": "2026-11-10T09:00:00+00:00",
      "updated_at": "2026-11-10T09:00:00+00:00",
      "messages": []
    }
  ],
  "total": 24,
  "page": 1,
  "page_size": 10,
  "total_pages": 3
}
```

The list deliberately sends `messages: []`. Open a ticket with
`GET /scp/get-ticket/{ticket_id}/` to load the thread.

**Errors:** `400` when `date_from` is after `date_to`; `422` for an
unsupported sort field; `403` without `help.view`.

---

## GET `/scp/get-ticket/{ticket_id}/`

- **Summary:** Return one ticket with its full message thread, oldest first.
- **Auth/Permission:** `help.view`.

**Path parameter:** `ticket_id` — ticket UUID.

**Payload:** none.

**Response `200`:**

```json
{
  "id": "d3f1a3e8-6ee2-4aa5-9a2a-2c9f9e8d7b11",
  "reference": "SP-4130",
  "subject": "Cannot invite new staff after upgrade",
  "status": "open",
  "priority": "medium",
  "channel": "chat",
  "organization_id": "9e9e4a5c-1f22-4dd2-b3a3-82b6f2e9a111",
  "organization_name": "Tarkwa Group 5",
  "requester_name": "Ngozi Okonkwo",
  "requester_email": "ngozi@tarkwa.com",
  "assigned_to": null,
  "created_at": "2026-11-10T09:00:00+00:00",
  "updated_at": "2026-11-10T09:00:00+00:00",
  "messages": [
    {
      "id": "1e2d3c4b-5a69-4788-9a0b-1c2d3e4f5a11",
      "author_name": "Ngozi Okonkwo",
      "from": "requester",
      "body": "We upgraded this morning but the invite button is still disabled.",
      "created_at": "2026-11-10T09:00:00+00:00"
    }
  ]
}
```

**Errors:** `404` `"Ticket not found."`; `403` without `help.view`.

---

## POST `/scp/reply-ticket/{ticket_id}/`

- **Summary:** Reply to the customer, assign the ticket and set it pending.
- **Auth/Permission:** `help.reply`.

**Path parameter:** `ticket_id` — ticket UUID.

**Payload:**

```json
{
  "body": "We are looking at your workspace now and will update you shortly."
}
```

**Response `200`:** the updated ticket with the new operator message appended,
`assigned_to` set to the acting operator, `status: "pending"` and a bumped
`updated_at`.

```json
{
  "id": "d3f1a3e8-6ee2-4aa5-9a2a-2c9f9e8d7b11",
  "reference": "SP-4130",
  "subject": "Cannot invite new staff after upgrade",
  "status": "pending",
  "priority": "medium",
  "channel": "chat",
  "organization_id": "9e9e4a5c-1f22-4dd2-b3a3-82b6f2e9a111",
  "organization_name": "Tarkwa Group 5",
  "requester_name": "Ngozi Okonkwo",
  "requester_email": "ngozi@tarkwa.com",
  "assigned_to": "Chinedu Okafor",
  "created_at": "2026-11-10T09:00:00+00:00",
  "updated_at": "2026-11-11T08:35:00+00:00",
  "messages": [
    {
      "id": "1e2d3c4b-5a69-4788-9a0b-1c2d3e4f5a11",
      "author_name": "Ngozi Okonkwo",
      "from": "requester",
      "body": "We upgraded this morning but the invite button is still disabled.",
      "created_at": "2026-11-10T09:00:00+00:00"
    },
    {
      "id": "2f3e4d5c-6b7a-4899-8b1c-2d3e4f5a6b11",
      "author_name": "Chinedu Okafor",
      "from": "operator",
      "body": "We are looking at your workspace now and will update you shortly.",
      "created_at": "2026-11-11T08:35:00+00:00"
    }
  ]
}
```

The requester is emailed a copy of the reply.

**Errors:** `422` when `body` is missing, blank or longer than 10,000
characters; `404` `"Ticket not found."`; `403` without `help.reply`.

---

## PATCH `/scp/update-ticket-status/{ticket_id}/`

- **Summary:** Set a ticket's status.
- **Auth/Permission:** `help.resolve`.

**Path parameter:** `ticket_id` — ticket UUID.

**Payload:**

```json
{
  "status": "resolved"
}
```

**Response `200`:** the updated ticket with its full message thread. The audit
action is `ticket.resolved`, `ticket.open` or `ticket.pending`.

**Errors:** `404` `"Ticket not found."`; `403` without `help.resolve`.

---

# Audit Logs

## Audit-log shape

```json
{
  "id": "e9d3b4c2-6a71-4ca8-a7a2-8f16f0f0f111",
  "category": "admin_action",
  "severity": "critical",
  "action": "organization.suspend",
  "summary": "Suspended Adunni Logistics — payment failed for two cycles",
  "actor_name": "Micheal Peter",
  "actor_role": "super_admin",
  "target": "Adunni Logistics",
  "ip_address": "102.89.14.7",
  "created_at": "2026-11-10T16:11:00+00:00"
}
```

Audit logs are append-only. The API never updates or deletes them.

## GET `/scp/list-audit-logs/`

- **Summary:** List audit entries.
- **Auth/Permission:** `audit.view`.

**Query parameters:**

| Name | Type | Default | Notes |
| --- | --- | --- | --- |
| `search` | string | — | Summary, action, actor name or target |
| `category` | `system` / `admin_action` | — | |
| `severity` | `info` / `warning` / `critical` | — | |
| `date_from` | `yyyy-MM-dd` | — | Inclusive `created_at` lower bound |
| `date_to` | `yyyy-MM-dd` | — | Inclusive `created_at` upper bound |
| `sort_dir` | `asc` / `desc` | `desc` | |
| `page` | int | `1` | |
| `page_size` | int | `25` | Max 100 |

**Payload:** none.

**Response `200`:**

```json
{
  "items": [
    {
      "id": "e9d3b4c2-6a71-4ca8-a7a2-8f16f0f0f111",
      "category": "admin_action",
      "severity": "critical",
      "action": "organization.suspend",
      "summary": "Suspended Adunni Logistics — payment failed for two cycles",
      "actor_name": "Micheal Peter",
      "actor_role": "super_admin",
      "target": "Adunni Logistics",
      "ip_address": "102.89.14.7",
      "created_at": "2026-11-10T16:11:00+00:00"
    }
  ],
  "total": 912,
  "page": 1,
  "page_size": 25,
  "total_pages": 37
}
```

**Errors:** `400` when `date_from` is after `date_to`; `403` without
`audit.view`.

---

## GET `/scp/export-audit-logs/`

- **Summary:** Download every matching audit entry as CSV.
- **Auth/Permission:** `audit.export`.

**Query parameters:** the same filters as `GET /scp/list-audit-logs/`, but no
`page` or `page_size`.

**Response `200`:**

- `Content-Type: text/csv`
- `Content-Disposition: attachment; filename="scp-audit-logs.csv"`

Sample body:

```csv
id,created_at,category,severity,action,summary,actor_name,actor_role,target,ip_address
e9d3b4c2-6a71-4ca8-a7a2-8f16f0f0f111,2026-11-10T16:11:00+00:00,admin_action,critical,organization.suspend,Suspended Adunni Logistics — payment failed for two cycles,Micheal Peter,super_admin,Adunni Logistics,102.89.14.7
```

**Errors:** `403` without `audit.export`.

---

# Audit event catalogue

Every mutating endpoint writes exactly one entry.

| `action` | Category | Severity | When |
| --- | --- | --- | --- |
| `operator.login` | `admin_action` | `info` | Successful sign-in |
| `operator.invite` | `admin_action` | `warning` | Invite sent |
| `operator.invite_resend` | `admin_action` | `info` | Invite re-sent |
| `operator.invite_accepted` | `system` | `info` | Invitee set their password |
| `operator.password_reset` | `admin_action` | `warning` | Reset link issued |
| `operator.password_set` | `system` | `info` | Reset link used |
| `operator.role_change` | `admin_action` | `critical` | Role changed |
| `operator.permissions_change` | `admin_action` | `critical` | Permissions changed |
| `operator.revoke` | `admin_action` | `critical` | Access blocked |
| `operator.restore` | `admin_action` | `warning` | Access restored |
| `operator.delete` | `admin_action` | `critical` | Account deleted |
| `organization.created` | `system` | `info` | A workspace was created and is awaiting approval |
| `organization.approve` | `admin_action` | `warning` | A sign-up was approved |
| `organization.reject` | `admin_action` | `warning` | A sign-up was declined |
| `organization.plan_change` | `admin_action` | `warning` | Tier or cycle changed |
| `organization.free_access_grant` | `admin_action` | `critical` | Free access given |
| `organization.free_access_end` | `admin_action` | `warning` | Free access ended by an operator |
| `organization.free_access_expired` | `system` | `info` | `free_until` passed |
| `organization.suspend` | `admin_action` | `critical` | Tenant suspended |
| `organization.reactivate` | `admin_action` | `warning` | Tenant reactivated |
| `organization.delete` | `admin_action` | `critical` | Tenant deleted |
| `plan.update` | `admin_action` | `critical` | Tier edited |
| `ticket.reply` | `admin_action` | `info` | Operator replied |
| `ticket.resolved` / `ticket.open` / `ticket.pending` | `admin_action` | `info` | Status set |

`billing.failed` and `storage.threshold` remain future system feeds; they are
not generated by the SCP API today.

# Seed data

The console URL and token lifetimes are configured with:

- `SCP_FRONTEND_URL` — base URL used in invite/reset links
- `SCP_INVITE_TOKEN_EXPIRE_DAYS` — default `7`
- `SCP_RESET_TOKEN_EXPIRE_HOURS` — default `24`
- `SCP_YEARLY_DISCOUNT_PERCENT` — default `15`
- `SCP_DELETED_ORG_RETENTION_DAYS` — default `30`

Plans and features are seeded with:

```bash
make db-upgrade
make scp-seed
```

The command is idempotent and never overwrites plans or features already
edited in the console. It also creates the first super admin from
`SCP_BOOTSTRAP_EMAIL` / `SCP_BOOTSTRAP_PASSWORD` when no operator exists.
The bootstrap password must be at least 8 characters. Leave those variables
blank to skip the bootstrap.

The daily Celery beat task `scp.tasks.expire_free_access` clears expired free
access grants and writes one `organization.free_access_expired` audit entry per
tenant. The daily `scp.tasks.purge_deleted_organizations` task hard-deletes
soft-deleted organizations after `SCP_DELETED_ORG_RETENTION_DAYS`.
