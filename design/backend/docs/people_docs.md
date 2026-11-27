# People API Documentation

Source: `tms/people/routers.py` and `tms/workspaces/routers.py`

**Prefixes:** `/people`, `/workspace`

These endpoints power the Admin **Users** directory, **Organogram**, invite
screens, profile headers and the signed-in “detecting your roles” view.

All `/people` endpoints require `Authorization: Bearer <JWT>` and an active
workspace membership unless marked public. Workspace profile data is visible
to active members; editing and deactivation require an owner/admin.

For the screen-by-screen frontend flow (CSV upload, signup links and
approval), see
[people_onboarding_integration.md](people_onboarding_integration.md).

## Reporting lines

`reports_to_id` is stored on `WorkspaceMembership`, not on `Users`: one
person can report to a different manager in each workspace. Reporting lines
are validated so a user cannot report to themselves and cycles are rejected.

The line manager is the approver for the member's **non-project** tasks. If
no manager is configured, the legacy assigner/team-lead routing remains the
fallback until the workspace is fully mapped.

## Directory statuses

| Status | Meaning |
| --- | --- |
| `active` | Active workspace member |
| `suspended` | Deactivated member; history is retained |
| `pending` | Pending invite or pending signup request (shown with the invitee name/email) |

A pending invite is returned with `id` set to the membership id and
`membership_id` set to the same value. Accepted members use the user id.

Pending rows also expose:

- `is_signup_request` — `true` when the row is a self-signup request created
  through a workspace signup link. For these rows `id` is the user id and
  `membership_id` is the pending membership id. Email invites return
  `is_signup_request: false`.
- `is_verified` — whether the person has verified their email address.
  Admins must wait for verification before approving a signup request.

---

## GET `/people/list-people/{workspace_id}/`

- **Auth:** Active workspace member.
- **Description:** Unified directory of members, pending email invites and
  pending signup requests. Filter pending rows with `is_signup_request` to
  separate self-signup requests from email invites.
- **Query:**
  - `search` — name, email, invited name or job title
  - `status` — `active`, `suspended`, `pending`
  - `access` — `admin` or `general`
  - `team_id` — UUID
  - `unmapped=true` — active non-admin members without a manager
  - `page`, `page_size`

### Sample response item

```json
{
  "id": "44444444-4444-4444-8444-444444444444",
  "membership_id": "77777777-7777-4777-8777-777777777777",
  "email": "tunde@example.com",
  "first_name": "Tunde",
  "last_name": "Bakare",
  "photo": null,
  "job_title": "Backend Engineer",
  "department": "Engineering",
  "phone": "+234 803 555 0142",
  "role": "member",
  "status": "active",
  "is_admin": false,
  "is_guest": false,
  "is_signup_request": false,
  "is_verified": true,
  "team": {
    "id": "33333333-3333-4333-8333-333333333333",
    "name": "Tech Team",
    "color": "#6658c0",
    "lane": "Backend"
  },
  "reports_to": {
    "id": "55555555-5555-4555-8555-555555555555",
    "email": "chioma@example.com",
    "first_name": "Chioma",
    "last_name": "Okafor",
    "photo": null
  },
  "direct_report_count": 0,
  "last_active_at": "2026-10-24T09:12:00Z",
  "points": 120,
  "streak": 4
}
```

---

## GET `/people/get-person/{workspace_id}/{user_id}/`

- **Auth:** Active workspace member.
- **Description:** Person profile with teams, projects, direct reports,
  gamification points and badges.

### Sample response

```json
{
  "id": "44444444-4444-4444-8444-444444444444",
  "membership_id": "77777777-7777-4777-8777-777777777777",
  "email": "tunde@example.com",
  "first_name": "Tunde",
  "last_name": "Bakare",
  "job_title": "Backend Engineer",
  "department": "Engineering",
  "role": "member",
  "status": "active",
  "reports_to": null,
  "direct_report_count": 2,
  "teams": [
    {
      "id": "33333333-3333-4333-8333-333333333333",
      "name": "Tech Team",
      "color": "#6658c0",
      "lane": "Backend"
    }
  ],
  "projects": [
    {
      "id": "11111111-1111-4111-8111-111111111111",
      "name": "Customer Portal Revamp",
      "color": "#6658c0"
    }
  ],
  "direct_reports": [
    {
      "id": "66666666-6666-4666-8666-666666666666",
      "email": "amaka@example.com",
      "first_name": "Amaka",
      "last_name": "Eze",
      "photo": null
    }
  ],
  "badges": [
    {
      "key": "first_time_right_5",
      "name": "First-time right ×5",
      "description": "First-time right ×5",
      "icon": "target",
      "earned": true,
      "awarded_at": "2026-10-20T10:00:00Z"
    }
  ]
}
```

---

## PUT `/people/update-person/{workspace_id}/{user_id}/`

- **Auth:** Owner/admin.
- **Description:** Update profile fields, team, manager, role or guest flag.

```json
{
  "first_name": "Tunde",
  "last_name": "Bakare",
  "job_title": "Senior Backend Engineer",
  "department": "Platform",
  "phone": "+234 803 555 0142",
  "team_id": "33333333-3333-4333-8333-333333333333",
  "reports_to_id": "55555555-5555-4555-8555-555555555555",
  "role": "member",
  "is_guest": false
}
```

Returns the full person profile. Changing the manager recalculates approvers
for the member's open non-project tasks.

---

## GET `/people/get-organogram/{workspace_id}/`

- **Auth:** Active workspace member.
- **Description:** Reporting-line tree. Members without a valid manager are
  returned as roots.

### Sample response

```json
[
  {
    "person": {
      "id": "55555555-5555-4555-8555-555555555555",
      "email": "chioma@example.com",
      "first_name": "Chioma",
      "last_name": "Okafor",
      "job_title": "Tech Lead",
      "role": "member",
      "status": "active"
    },
    "children": [
      {
        "person": {
          "id": "44444444-4444-4444-8444-444444444444",
          "email": "tunde@example.com",
          "first_name": "Tunde",
          "last_name": "Bakare",
          "job_title": "Backend Engineer",
          "role": "member",
          "status": "active"
        },
        "children": []
      }
    ]
  }
]
```

---

## POST `/people/deactivate-person/{workspace_id}/{user_id}/`

- **Auth:** Owner/admin.
- **Description:** Suspend a member and hand over their open tasks, direct
  reports, owned projects and team-lead roles.

```json
{
  "handover_to_id": "66666666-6666-4666-8666-666666666666",
  "reason": "Leaving the company"
}
```

Returns `{ "message": "Member deactivated successfully." }`.

The workspace owner cannot be deactivated and a member cannot deactivate
themselves.

---

## POST `/people/reactivate-person/{workspace_id}/{user_id}/`

- **Auth:** Owner/admin.
- **Description:** Reactivate a suspended member and optionally set their role.
- Only suspended memberships can be reactivated; the workspace owner cannot.
- Only an owner can grant the owner role.

```json
{ "role": "member" }
```

---

## POST `/people/bulk-invite/{workspace_id}/`

- **Auth:** Owner/admin.
- **Description:** Invite many people in one request. Invalid or duplicate
  rows are returned in `skipped` instead of failing the whole request.
  Under single-organization mode, a row whose email already belongs to
  another organization is also returned in `skipped` with that reason.
  For file uploads use `POST /people/bulk-upload/{workspace_id}/` below.

```json
{
  "team_id": "33333333-3333-4333-8333-333333333333",
  "reports_to_id": "55555555-5555-4555-8555-555555555555",
  "items": [
    {
      "email": "david@example.com",
      "first_name": "David",
      "last_name": "Mensah",
      "job_title": "QA Engineer",
      "role": "member"
    },
    {
      "email": "sarah@example.com",
      "first_name": "Sarah",
      "role": "member"
    }
  ]
}
```

### Sample response

```json
{
  "invited": [
    { "id": "aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa", "email": "david@example.com" }
  ],
  "skipped": [
    { "email": "sarah@example.com", "reason": "An active invite already exists for this email." }
  ]
}
```

---

## POST `/people/bulk-upload/{workspace_id}/`

- **Auth:** Owner/admin.
- **Content type:** `multipart/form-data` — `file` (`.csv` only).
- **Description:** Upload a CSV of people and create one pending invite per
  valid row. Each row follows the normal invite pipeline, including the
  7-day token, invitation email and single-organization checks.
- **Limits:** 200 data rows and 2 MB per file.
- **Headers:** the file must contain exactly these columns (case-insensitive,
  surrounding whitespace ignored):

| Column | Required | Rules |
| --- | --- | --- |
| `Email` | Yes | Valid email; normalized to lower case; unique within the file. |
| `First Name` | No | Stored as the invitee name. |
| `Last Name` | No | Stored as the invitee name. |
| `Job Title` | No | Stored on the pending membership. |
| `Role` | No | `member` (default) or `admin`. `owner` is allowed only when the uploader is an owner. |
| `Team` | No | Team name or slug in this workspace. Unknown teams skip the row. |
| `Reports To` | No | Email of an active workspace member. Unknown managers skip the row. |

Missing or unknown columns make the whole request fail with `400`. Row-level
problems do not fail the upload: the row is returned in `skipped` and the
remaining rows are still processed.

### Sample CSV

```csv
Email,First Name,Last Name,Job Title,Role,Team,Reports To
ada@example.com,Ada,Okafor,Designer,member,Design,lead@example.com
sam@example.com,Sam,Bello,QA Engineer,member,Engineering,lead@example.com
ada@example.com,Ada,Okafor,Designer,member,Design,lead@example.com
```

### Sample response

```json
{
  "total_rows": 3,
  "invited": [
    {
      "row": 2,
      "id": "aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa",
      "email": "ada@example.com"
    }
  ],
  "skipped": [
    {
      "row": 3,
      "email": "sam@example.com",
      "reason": "Team 'Engineering' was not found in this workspace."
    },
    {
      "row": 4,
      "email": "ada@example.com",
      "reason": "Duplicate email in this file."
    }
  ]
}
```

`total_rows` counts non-empty data rows. `row` is the 1-based CSV row number,
so the first data row is `2`.

---

## GET `/people/get-bulk-upload-template/{workspace_id}/`

- **Auth:** Owner/admin.
- **Response:** `text/csv` attachment named `people-upload-template.csv`
  containing the header row:
  `Email,First Name,Last Name,Job Title,Role,Team,Reports To`.

---

## GET `/people/export-people/{workspace_id}/`

- **Auth:** Owner/admin.
- **Response:** `text/csv` attachment (`people.csv`). Columns:
  `Name,Email,Access,Job title,Team,Reports to,Status,Last active`.

---

## GET `/people/my-context/{workspace_id}/`

- **Auth:** Active workspace member.
- **Description:** Derived roles and counts used by navigation and the
  “detecting your roles” screen.

### Sample response

```json
{
  "workspace_id": "22222222-2222-4222-8222-222222222222",
  "workspace_name": "Acme Group",
  "workspace_kind": "business",
  "role": "member",
  "is_guest": false,
  "is_manager": false,
  "is_line_manager": true,
  "is_project_manager": true,
  "is_team_lead": false,
  "is_assigner": true,
  "direct_report_count": 3,
  "review_count": 2,
  "open_task_count": 6
}
```

---

## GET `/people/get-invite-link/{workspace_id}/{invite_id}/`

- **Auth:** Owner/admin.
- **Description:** Return a copyable pending invite link. Expired invites
  return `400`; use the resend endpoint for a new link.

```json
{
  "invite_id": "99999999-9999-4999-8999-999999999999",
  "email": "newbie@example.com",
  "token": "secure-invite-token",
  "invite_url": "https://app.example.com/invite?token=secure-invite-token",
  "expires_at": "2026-10-31T10:00:00Z"
}
```

---

## POST `/people/resend-invite/{workspace_id}/{invite_id}/`

- **Auth:** Owner/admin.
- **Description:** Regenerate the token/expiry, resend the invite email and
  return the new link. Pending and expired invites can be resent.

---

## Workspace and invite endpoints used by the people screens

### PUT `/workspace/update-settings/{workspace_id}/`

- **Auth:** Owner/admin.
- **Description:** Update organization settings.

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

### POST `/workspace/invite-member/{workspace_id}/`

The invite body now accepts profile metadata in addition to email/role:

```json
{
  "email": "newbie@example.com",
  "role": "member",
  "first_name": "New",
  "last_name": "Bie",
  "job_title": "Designer",
  "team_id": "33333333-3333-4333-8333-333333333333",
  "reports_to_id": "55555555-5555-4555-8555-555555555555",
  "project_id": "11111111-1111-4111-8111-111111111111",
  "is_guest": false
}
```

### GET `/workspace/get-invite-public/{token}/`

- **Auth:** Public.
- **Description:** Invite details for the acceptance screen.

```json
{
  "workspace_id": "22222222-2222-4222-8222-222222222222",
  "workspace_name": "Acme Group",
  "email": "newbie@example.com",
  "invited_by_name": "Chioma Okafor",
  "role": "member",
  "team_name": "Tech Team",
  "reports_to_name": "Chioma Okafor",
  "project_name": "Customer Portal Revamp",
  "expires_at": "2026-10-31T10:00:00Z"
}
```

### POST `/workspace/accept-invite-public/{token}/`

- **Auth:** Public.
- **Description:** Accept an invite and create the account in one call. The
  invite token proves ownership of the email, so the created user is marked
  verified.

```json
{
  "first_name": "New",
  "last_name": "Bie",
  "password": "strong-pass-123",
  "phone": "+234 803 555 0142",
  "job_title": "Designer"
}
```

Returns the accepted invite shape with `status: "active"`.

---

## Presence

Every directory row also returns:

- `presence` — `available`, `busy`, `meeting`, `away`, `dnd`, `leave` or `offline`
- `presence_custom` — optional short note (max 80 chars)
- `presence_until` — optional timestamp

### GET `/people/list-statuses/{workspace_id}/`

Returns an array for every active member:

```json
[
  {
    "user_id": "11111111-1111-4111-8111-111111111111",
    "presence": "available",
    "custom": null,
    "until": null
  }
]
```

### PUT `/people/set-status/{workspace_id}/`

```json
{"presence": "dnd", "custom": "Deep work", "until": "2026-11-19T17:00:00Z"}
```

Only the caller's own status can be set. Returns the caller's presence row.

`GET /people/my-context/{workspace_id}/` also returns `workspace_subtype` so
the navigation can label specials workspaces.
