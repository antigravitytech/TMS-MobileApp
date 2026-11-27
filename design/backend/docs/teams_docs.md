# Team API Documentation

Source: `tms/teams/routers.py`

**Prefix:** `/team`

All endpoints require `Authorization: Bearer <JWT>`. Bodies are JSON.

## Roles

Team memberships have exactly two roles:

| Role | Meaning |
| --- | --- |
| `lead` | The team lead. Every team has exactly one lead, derived from the membership with this role. |
| `member` | A regular team member. |

The team lead is **not** stored on the team: it is the `TeamMembership` whose
`role` is `lead`. `set-lead` promotes the new lead and demotes the previous
one to `member`. Removing the `lead` membership is rejected until another
lead is assigned.

## Access

| Action | Owner/admin | Team lead | Workspace member |
| --- | --- | --- | --- |
| View teams and members | Yes | Yes | Yes |
| Create a team | Yes | No | No |
| Update team details | Yes | Yes | No |
| Add/remove team members | Yes | Yes | No |
| Set the lead | Yes | No | No |
| Delete the team | Yes | No | No |

A user must be an **active workspace member** to view a team or be added to
one. Removing a workspace member who is a team lead is blocked with `409`.

A team's projects are simply the projects whose `team_id` points at that
team; list them with:

```text
GET /project/list-projects/{workspace_id}/?team_id={team_id}
```

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

---

## GET `/team/list-teams/{workspace_id}/`

- **Auth:** Active workspace member.
- **Query:** `search` (name/description), `page` (default 1), `page_size`
  (default 20, max 100).
- **Description:** List teams in a workspace.

### Sample Response Item

```json
{
  "id": "11111111-1111-4111-8111-111111111111",
  "workspace_id": "22222222-2222-4222-8222-222222222222",
  "name": "Tech Team",
  "slug": "tech-team",
  "description": "Product engineering",
  "color": "#6658c0",
  "lead": {
    "id": "33333333-3333-4333-8333-333333333333",
    "email": "chioma@example.com",
    "first_name": "Chioma",
    "last_name": "Okafor",
    "photo": null
  },
  "member_count": 3,
  "member_preview": [
    {
      "id": "33333333-3333-4333-8333-333333333333",
      "email": "chioma@example.com",
      "first_name": "Chioma",
      "last_name": "Okafor",
      "photo": null
    }
  ],
  "stats": {
    "weekly_progress": 0.0,
    "completed_this_month": 0,
    "on_time_rate": 0.0,
    "first_time_right_rate": 0.0,
    "avg_rework_rounds": 0.0
  },
  "lanes": [],
  "created_at": "2026-10-21T10:00:00Z",
  "updated_at": "2026-10-21T10:00:00Z"
}
```

`stats` is computed from non-deleted tasks assigned to active team members:

- `weekly_progress` — tasks completed in the last 7 days / all team-assigned
  tasks × 100.
- `completed_this_month` — completed tasks whose completion is in the current
  calendar month.
- `on_time_rate` — completed on or before the due date / completed × 100.
- `first_time_right_rate` — completed with zero returns / completed × 100.
- `avg_rework_rounds` — average submission round of completed tasks.

---

## POST `/team/create-team/{workspace_id}/`

- **Status Code:** `201 Created`
- **Auth:** Workspace owner/admin.
- **Description:** Create a team. The lead is added with role `lead`; all
  `member_ids` are added with role `member`.

### Sample Payload

```json
{
  "name": "Tech Team",
  "description": "Product engineering",
  "color": "#6658c0",
  "lead_id": "33333333-3333-4333-8333-333333333333",
  "member_ids": [
    "44444444-4444-4444-8444-444444444444",
    "55555555-5555-4555-8555-555555555555"
  ]
}
```

- `lead_id` is optional and defaults to the current user.
- The lead is automatically added if it is not in `member_ids`.
- Duplicate IDs are ignored.

### Sample Response

Returns the team detail shape described in `GET /team/get-team/{team_id}/`.

---

## GET `/team/get-team/{team_id}/`

- **Auth:** Active workspace member.
- **Description:** Return the team with all members.

### Sample Response

```json
{
  "id": "11111111-1111-4111-8111-111111111111",
  "workspace_id": "22222222-2222-4222-8222-222222222222",
  "name": "Tech Team",
  "slug": "tech-team",
  "description": "Product engineering",
  "color": "#6658c0",
  "lead": {
    "id": "33333333-3333-4333-8333-333333333333",
    "email": "chioma@example.com",
    "first_name": "Chioma",
    "last_name": "Okafor",
    "photo": null
  },
  "member_count": 2,
  "member_preview": [],
  "stats": {
    "weekly_progress": 0.0,
    "completed_this_month": 0,
    "on_time_rate": 0.0,
    "first_time_right_rate": 0.0,
    "avg_rework_rounds": 0.0
  },
  "members": [
    {
      "id": "66666666-6666-4666-8666-666666666666",
      "team_id": "11111111-1111-4111-8111-111111111111",
      "user": {
        "id": "33333333-3333-4333-8333-333333333333",
        "email": "chioma@example.com",
        "first_name": "Chioma",
        "last_name": "Okafor",
        "photo": null
      },
      "role": "lead",
      "workspace_role": "owner",
      "in_progress_tasks": 0,
      "created_at": "2026-10-21T10:00:00Z",
      "updated_at": "2026-10-21T10:00:00Z"
    }
  ],
  "created_at": "2026-10-21T10:00:00Z",
  "updated_at": "2026-10-21T10:00:00Z"
}
```

`workspace_role` is the user's workspace role (`owner`, `admin` or
`member`). `in_progress_tasks` is the number of tasks assigned to the member
with status `in_progress` in the team's workspace.

---

## PUT `/team/update-team/{team_id}/`

- **Auth:** Workspace owner/admin or the team lead.
- **Description:** Update name, description and color. Lead changes use
  `set-lead`; roles are not stored on the team.

### Sample Payload

```json
{
  "name": "Platform Team",
  "description": "Platform engineering",
  "color": "#445566"
}
```

All fields are optional. Send `"description": null` to clear it.

---

## DELETE `/team/delete-team/{team_id}/`

- **Auth:** Workspace owner/admin.
- **Description:** Soft-delete the team and detach its projects
  (`project.team_id` becomes `null`). Projects are not deleted. Teams with
  open tasks return `409`; reassign or complete those tasks first.

### Sample Response

```json
{ "message": "Team deleted successfully." }
```

---

## PATCH `/team/set-lead/{team_id}/`

- **Auth:** Workspace owner/admin.
- **Description:** Promote the user to `lead` and demote the previous lead to
  `member`. If the user is not already in the team, they are added.

### Sample Payload

```json
{ "user_id": "44444444-4444-4444-8444-444444444444" }
```

### Sample Response

Returns the team detail shape, with `lead` set to the new lead and updated
`members[].role` values.

---

## GET `/team/list-members/{team_id}/`

- **Auth:** Active workspace member.
- **Query:** `search` (user name/email), `page`, `page_size`.
- **Description:** List team memberships.

### Sample Response Item

```json
{
  "id": "66666666-6666-4666-8666-666666666666",
  "team_id": "11111111-1111-4111-8111-111111111111",
  "user": {
    "id": "44444444-4444-4444-8444-444444444444",
    "email": "tunde@example.com",
    "first_name": "Tunde",
    "last_name": "Bakare",
    "photo": null
  },
  "role": "member",
  "workspace_role": "member",
  "in_progress_tasks": 0,
  "created_at": "2026-10-21T10:00:00Z",
  "updated_at": "2026-10-21T10:00:00Z"
}
```

---

## POST `/team/add-member/{team_id}/`

- **Status Code:** `201 Created`
- **Auth:** Workspace owner/admin or the team lead.
- **Description:** Add an active workspace member to the team with role
  `member`. Returns `409` if they are already in the team and `422` if they
  are not an active workspace member.

### Sample Payload

```json
{ "user_id": "44444444-4444-4444-8444-444444444444" }
```

### Sample Response

Returns the team membership shape shown in `list-members`.

---

## DELETE `/team/remove-member/{team_id}/{membership_id}/`

- **Auth:** Workspace owner/admin or the team lead.
- **Description:** Remove a team member. Removing the `lead` membership
  returns `400`; reassign the lead first. Removing a member with open assigned
  team tasks returns `409`.

### Sample Response

```json
{ "message": "Team member removed successfully." }
```

---

## Team lanes

Lanes are the configurable team roles shown as lanes on the team page
(“Frontend”, “Backend”, “QA”, …). They are separate from the `lead`/`member`
permission role. A team can be created with `lanes: ["Backend", "Frontend"]`.

```json
{
  "name": "Platform",
  "lead_id": "33333333-3333-4333-8333-333333333333",
  "member_ids": ["44444444-4444-4444-8444-444444444444"],
  "lanes": ["Backend", "Frontend"]
}
```

| Endpoint | Auth | Description |
| --- | --- | --- |
| `GET /team/list-lanes/{team_id}/` | Active member | List lanes with member counts |
| `POST /team/create-lane/{team_id}/` | Owner/admin or team lead | Create a lane |
| `PUT /team/update-lane/{team_id}/{lane_id}/` | Owner/admin or team lead | Rename/recolor/reorder |
| `DELETE /team/delete-lane/{team_id}/{lane_id}/` | Owner/admin or team lead | Delete and clear member assignments |
| `PATCH /team/set-member-lane/{team_id}/{membership_id}/` | Owner/admin or team lead | Assign/clear a lane |

### Sample lane

```json
{
  "id": "aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa",
  "team_id": "11111111-1111-4111-8111-111111111111",
  "name": "Backend",
  "color": "#6658c0",
  "position": 0,
  "member_count": 3,
  "created_at": "2026-10-21T10:00:00Z",
  "updated_at": "2026-10-21T10:00:00Z"
}
```

`GET /team/get-team/{team_id}/` includes `lanes`, and each `members[]` item
includes its `lane` (or `null`). `POST /team/add-member/{team_id}/` accepts
an optional `lane_id`.
