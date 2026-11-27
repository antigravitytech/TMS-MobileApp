# Project API Documentation

Source: `tms/projects/routers.py`

Project plan, template and leave endpoints are documented separately in
[project_plans_docs.md](project_plans_docs.md).

**Prefix:** `/project`

All endpoints require `Authorization: Bearer <JWT>`. Bodies are JSON.

## Enums

| Enum | Values |
| --- | --- |
| `health` | `on_track`, `at_risk`, `off_track` |
| `visibility` | `public`, `confidential` |
| `approval_policy` | `pm`, `pm_alt`, `any` |

## Access

| Action | Owner/admin | Project PM / alternate PM | Workspace member |
| --- | --- | --- | --- |
| View a public project | Yes | Yes | Yes |
| View a confidential project | Yes | Yes | Only if a project member |
| Create a project | Yes | Yes | Yes |
| Update project, members and milestones | Yes | Yes | No |
| Delete a project | Yes | PM only | No |

- Every endpoint requires an **active workspace membership**.
- Confidential projects are hidden from the project list and return `403`
  when fetched by a workspace member who is not a project member.
- The project owner and alternate owner are always project members.
- A project can belong to a team in the same workspace, or to no team.
- The project owner must be an active workspace member.
- Removing a workspace member who owns a project is blocked with `409`;
  reassign the project first. Removing an alternate owner clears the
  reference automatically.

## Pagination

List endpoints return:

```json
{
  "items": [],
  "total": 0,
  "page": 1,
  "page_size": 20,
  "total_pages": 0
}
```

## Task-derived figures

Project, milestone and member task figures are computed from non-deleted
tasks. Definitions:

- `stats.total_tasks` — all project tasks.
- `stats.open_tasks` — tasks whose status is not `completed`.
- `stats.submitted_tasks` — tasks currently `submitted`.
- `stats.returned_tasks` — tasks currently `returned`.
- `stats.completed_tasks` — tasks `completed`.
- `stats.overdue_tasks` — non-completed tasks whose due date is before today.
- `stats.progress` — completed / total × 100.
- `stats.on_time_rate` — completed on or before the due date / completed × 100.
- `stats.first_time_right_rate` — completed with zero returns / completed × 100.
- `members[].assigned_tasks` — project tasks assigned to the member.
- `members[].completed_tasks` — completed project tasks assigned to the member.
- `members[].on_time_rate` — on-time completed tasks / completed × 100.
- `milestones[].task_count` — tasks assigned to the milestone.
- `milestones[].completed_tasks` — completed milestone tasks.
- `milestones[].progress` — completed / task_count × 100.

`workspace_role` on a project member is the user's workspace role
(`owner`, `admin` or `member`).

`next_milestone` is real and is computed as the earliest milestone whose
`due_date >= today`.

---

## GET `/project/list-projects/{workspace_id}/`

- **Auth:** Active workspace member; confidential projects are filtered.
- **Query:**
  - `health` — `on_track | at_risk | off_track`
  - `team_id` — UUID
  - `owner_id` — UUID
  - `visibility` — `public | confidential`
  - `search` — name/description
  - `mine=true` — only projects the caller owns, alternates or belongs to
  - `page` (default 1), `page_size` (default 20, max 100)

### Sample Response Item

```json
{
  "id": "11111111-1111-4111-8111-111111111111",
  "workspace_id": "22222222-2222-4222-8222-222222222222",
  "team": {
    "id": "33333333-3333-4333-8333-333333333333",
    "name": "Tech Team",
    "color": "#6658c0"
  },
  "name": "Customer Portal Revamp",
  "slug": "customer-portal-revamp",
  "description": "Rebuild the customer portal",
  "color": "#6658c0",
  "owner": {
    "id": "44444444-4444-4444-8444-444444444444",
    "email": "chioma@example.com",
    "first_name": "Chioma",
    "last_name": "Okafor",
    "photo": null
  },
  "alternate_owner": null,
  "approval_policy": "pm_alt",
  "health": "on_track",
  "visibility": "public",
  "start_date": "2026-10-21",
  "target_date": "2026-11-20",
  "member_count": 3,
  "member_preview": [],
  "next_milestone": {
    "id": "55555555-5555-4555-8555-555555555555",
    "name": "Discovery",
    "due_date": "2026-10-28"
  },
  "stats": {
    "total_tasks": 0,
    "open_tasks": 0,
    "submitted_tasks": 0,
    "returned_tasks": 0,
    "completed_tasks": 0,
    "overdue_tasks": 0,
    "progress": 0.0,
    "on_time_rate": 0.0,
    "first_time_right_rate": 0.0
  },
  "created_at": "2026-10-21T10:00:00Z",
  "updated_at": "2026-10-21T10:00:00Z"
}
```

---

## POST `/project/create-project/{workspace_id}/`

- **Status Code:** `201 Created`
- **Auth:** Any active workspace member; the creator becomes PM by default.
- **Description:** Create a project and its owner/alternate/member
  memberships.

### Sample Payload

```json
{
  "name": "Customer Portal Revamp",
  "description": "Rebuild the customer portal",
  "team_id": "33333333-3333-4333-8333-333333333333",
  "owner_id": "44444444-4444-4444-8444-444444444444",
  "alternate_owner_id": "55555555-5555-4555-8555-555555555555",
  "member_ids": [
    "66666666-6666-4666-8666-666666666666"
  ],
  "health": "on_track",
  "visibility": "public",
  "approval_policy": "pm_alt",
  "color": "#6658c0",
  "start_date": "2026-10-21",
  "target_date": "2026-11-20",
  "invite_emails": ["newcollaborator@example.com"]
}
```

All fields except `name` are optional. Server defaults:

| Field | Default |
| --- | --- |
| `owner_id` | current user |
| `health` | `on_track` |
| `visibility` | `public` |
| `approval_policy` | `pm_alt` |
| `start_date` | today |
| `target_date` | `start_date + 30 days` |
| `color` | `#6658c0` |

- `owner_id` and `alternate_owner_id` must be active workspace members and
  must differ.
- `team_id` must belong to the same workspace.
- `target_date` cannot be before `start_date`.
- The owner and alternate owner are automatically added as project members.
- `invite_emails` optionally sends workspace/project invites to people who
  are not yet members. Each accepted invite also creates the project
  membership. Invites are only sent when the caller can invite members.
- No milestones are created automatically.

### Sample Response

Returns the project detail shape described in
`GET /project/get-project/{project_id}/`.

---

## GET `/project/get-project/{project_id}/`

- **Auth:** Project access rules.
- **Description:** Return the project with its members and milestones.

### Sample Response

```json
{
  "id": "11111111-1111-4111-8111-111111111111",
  "workspace_id": "22222222-2222-4222-8222-222222222222",
  "team": null,
  "name": "Customer Portal Revamp",
  "slug": "customer-portal-revamp",
  "description": "Rebuild the customer portal",
  "color": "#6658c0",
  "owner": {
    "id": "44444444-4444-4444-8444-444444444444",
    "email": "chioma@example.com",
    "first_name": "Chioma",
    "last_name": "Okafor",
    "photo": null
  },
  "alternate_owner": null,
  "approval_policy": "pm_alt",
  "health": "on_track",
  "visibility": "public",
  "start_date": "2026-10-21",
  "target_date": "2026-11-20",
  "member_count": 2,
  "member_preview": [],
  "next_milestone": null,
  "stats": {
    "total_tasks": 0,
    "open_tasks": 0,
    "submitted_tasks": 0,
    "returned_tasks": 0,
    "completed_tasks": 0,
    "overdue_tasks": 0,
    "progress": 0.0,
    "on_time_rate": 0.0,
    "first_time_right_rate": 0.0
  },
  "members": [
    {
      "id": "77777777-7777-4777-8777-777777777777",
      "project_id": "11111111-1111-4111-8111-111111111111",
      "user": {
        "id": "44444444-4444-4444-8444-444444444444",
        "email": "chioma@example.com",
        "first_name": "Chioma",
        "last_name": "Okafor",
        "photo": null
      },
      "workspace_role": "owner",
      "assigned_tasks": 0,
      "completed_tasks": 0,
      "on_time_rate": 0.0,
      "created_at": "2026-10-21T10:00:00Z",
      "updated_at": "2026-10-21T10:00:00Z"
    }
  ],
  "milestones": [
    {
      "id": "55555555-5555-4555-8555-555555555555",
      "created_at": "2026-10-21T10:00:00Z",
      "updated_at": "2026-10-21T10:00:00Z",
      "name": "Discovery",
      "due_date": "2026-10-28",
      "position": 0,
      "task_count": 0,
      "completed_tasks": 0,
      "progress": 0.0
    }
  ],
  "created_at": "2026-10-21T10:00:00Z",
  "updated_at": "2026-10-21T10:00:00Z"
}
```

---

## PUT `/project/update-project/{project_id}/`

- **Auth:** Workspace owner/admin, project PM or alternate PM.
- **Description:** Partial update of project details.

### Sample Payload

```json
{
  "name": "Customer Portal v2",
  "description": null,
  "team_id": null,
  "owner_id": "44444444-4444-4444-8444-444444444444",
  "alternate_owner_id": null,
  "health": "at_risk",
  "visibility": "confidential",
  "approval_policy": "pm",
  "color": "#445566",
  "start_date": "2026-10-25",
  "target_date": "2026-12-01"
}
```

- Omitted fields are unchanged.
- `"team_id": null` detaches the project from its team.
- `"alternate_owner_id": null` clears the alternate PM.
- `"description": null` clears the description.
- New owners/alternates are automatically added as members.
- `target_date` cannot be before `start_date`.

Returns the project detail shape.

---

## DELETE `/project/delete-project/{project_id}/`

- **Auth:** Workspace owner/admin or the project PM.
- **Description:** Soft-delete the project. Memberships and milestones are
  retained but become inaccessible. Tasks in the project are soft-deleted
  with it.

### Sample Response

```json
{ "message": "Project deleted successfully." }
```

---

## GET `/project/list-members/{project_id}/`

- **Auth:** Project access rules.
- **Query:** `search` (user name/email), `page`, `page_size`.

### Sample Response Item

```json
{
  "id": "77777777-7777-4777-8777-777777777777",
  "project_id": "11111111-1111-4111-8111-111111111111",
  "user": {
    "id": "66666666-6666-4666-8666-666666666666",
    "email": "tunde@example.com",
    "first_name": "Tunde",
    "last_name": "Bakare",
    "photo": null
  },
  "workspace_role": "member",
  "assigned_tasks": 0,
  "completed_tasks": 0,
  "on_time_rate": 0.0,
  "created_at": "2026-10-21T10:00:00Z",
  "updated_at": "2026-10-21T10:00:00Z"
}
```

---

## POST `/project/add-member/{project_id}/`

- **Status Code:** `201 Created`
- **Auth:** Workspace owner/admin, project PM or alternate PM.
- **Description:** Add an active workspace member to the project. Returns
  `409` for an existing member and `422` for a user who is not an active
  workspace member.

### Sample Payload

```json
{ "user_id": "66666666-6666-4666-8666-666666666666" }
```

### Sample Response

Returns the project membership shape shown in `list-members`.

---

## DELETE `/project/remove-member/{project_id}/{membership_id}/`

- **Auth:** Workspace owner/admin, project PM or alternate PM.
- **Description:** Remove a project member. The PM and alternate PM cannot be
  removed; reassign them first. Removing a member with open assigned tasks
  returns `409`. Their task watcher/viewer rows for the project are
  soft-deleted.

### Sample Response

```json
{ "message": "Project member removed successfully." }
```

---

## GET `/project/list-milestones/{project_id}/`

- **Auth:** Project access rules.
- **Query:** `page` (default 1), `page_size` (default 20, max 100).
- **Description:** List project milestones ordered by `position`, then
  `due_date`.

### Sample Response Item

```json
{
  "id": "55555555-5555-4555-8555-555555555555",
  "created_at": "2026-10-21T10:00:00Z",
  "updated_at": "2026-10-21T10:00:00Z",
  "name": "Discovery",
  "due_date": "2026-10-28",
  "position": 0,
  "task_count": 0,
  "completed_tasks": 0,
  "progress": 0.0
}
```

---

## POST `/project/create-milestone/{project_id}/`

- **Status Code:** `201 Created`
- **Auth:** Workspace owner/admin, project PM or alternate PM.
- **Description:** Create a milestone. `position` is optional and defaults to
  the next position.

### Sample Payload

```json
{
  "name": "Discovery",
  "due_date": "2026-10-28",
  "position": 0
}
```

### Sample Response

Returns the milestone shape shown in `list-milestones`.

---

## PUT `/project/update-milestone/{project_id}/{milestone_id}/`

- **Auth:** Workspace owner/admin, project PM or alternate PM.
- **Description:** Partial update of a milestone name, due date or position.

### Sample Payload

```json
{
  "name": "Discovery v2",
  "due_date": "2026-11-02",
  "position": 1
}
```

### Sample Response

Returns the milestone shape shown in `list-milestones`.

---

## DELETE `/project/delete-milestone/{project_id}/{milestone_id}/`

- **Auth:** Workspace owner/admin, project PM or alternate PM.
- **Description:** Soft-delete a milestone. Tasks that referenced it keep
  their other data and have `milestone_id` cleared.

### Sample Response

```json
{ "message": "Milestone deleted successfully." }
```
