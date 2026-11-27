# Project Plans, Templates and Leave API Documentation

Source: `tms/projects/routers.py`, `tms/projects/plan_service.py`

**Prefix:** `/project`

Project plans are normalized node graphs (`project_plans` +
`project_plan_nodes`) rather than JSON documents. Nested collections such as
task dependencies, comments, evidence, baselines and budget entries are child
rows with a `parent_id`; their order is preserved with `position`.

All endpoints require `Authorization: Bearer <JWT>` and active workspace
membership. A plan may be edited by the project owner, alternate owner, or a
workspace owner/admin.

## Plan object

The plan payload follows the v4 UI contract:

```json
{
  "project_id": "11111111-1111-4111-8111-111111111111",
  "version": 2,
  "mode": "Simple",
  "outcome": "Launch the site",
  "brief": "A short brief",
  "accept_owner": "user-id",
  "start": "2026-11-19",
  "template": null,
  "draft": false,
  "closed": false,
  "closed_at": null,
  "closeout": null,
  "migrated": false,
  "demo": false,
  "review_days": 7,
  "override": null,
  "deliverables": [],
  "tasks": [],
  "milestones": [],
  "baselines": [],
  "risks": [],
  "changes": [],
  "gates": [],
  "decisions": [],
  "budget": {"cap": 0, "remaining": 0, "entries": []},
  "cost_baseline": null,
  "benefits": [],
  "activity": [],
  "automations": [],
  "documents": []
}
```

`mode` is `Simple`, `Intermediate` or `Advanced`.

## GET `/project/get-plan/{project_id}/`

Returns the plan. If the project has no plan yet, a `Simple` plan is created
from the project and its current tasks.

## PUT `/project/update-plan/{project_id}/`

```json
{
  "base_version": 2,
  "plan": {
    "mode": "Simple",
    "outcome": "Launch the site",
    "deliverables": [],
    "tasks": [],
    "milestones": [],
    "risks": [],
    "changes": [],
    "gates": [],
    "decisions": [],
    "budget": {"cap": 0, "entries": []},
    "benefits": [],
    "activity": [],
    "automations": [],
    "documents": []
  }
}
```

The whole graph is replaced transactionally and `version` increments by one.
A stale `base_version` returns **409**; reload `GET /project/get-plan/` and
retry. The first save after plan creation accepts `base_version: 1`.

### Task rows

```json
{
  "id": "client-task-id",
  "title": "Write the copy",
  "deliverable": "design",
  "owner": "user-id",
  "duration": 3,
  "effort": 12,
  "start": "2026-11-20",
  "state": "todo",
  "deps": [{"id": "another-task-id", "type": "FS", "lag": 0}],
  "blocker": null,
  "checklist": [{"text": "Draft", "done": false}],
  "comments": [],
  "history": []
}
```

`state` is `todo`, `doing`, `blocked`, `done` or `cancelled`.

## GET `/project/list-plans/{workspace_id}/`

Returns an array of plans for the portfolio view.

## GET `/project/list-leave/{workspace_id}/`

Read-only resource leave windows:

```json
[
  {
    "id": "22222222-2222-4222-8222-222222222222",
    "user": "33333333-3333-4333-8333-333333333333",
    "start": "2026-11-24",
    "end": "2026-11-28",
    "reason": "Annual leave"
  }
]
```

## Templates

### GET `/project/list-templates/{workspace_id}/`

```json
[
  {
    "id": "44444444-4444-4444-8444-444444444444",
    "key": "website",
    "name": "Website build",
    "purpose": "Launch a site",
    "mode": "Simple",
    "icon": null,
    "budget": null,
    "roles": ["Designer", "Developer"],
    "deliverables": [{"name": "Design", "phase": "Design"}],
    "risks": [{"title": "Late content", "next": "Chase weekly"}],
    "automations": ["Weekly status"],
    "custom": true,
    "created_by": "55555555-5555-4555-8555-555555555555"
  }
]
```

### POST `/project/save-template/{workspace_id}/`

Owner/admin only. Send the same shape; `id` updates an existing template,
omitting it creates one. A new template whose `key` is already used in the
workspace returns **409**; send the existing `id` to update it instead.

### DELETE `/project/delete-template/{template_id}/`

Owner/admin only. Soft-deletes the template.
