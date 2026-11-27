# Reporting API Documentation

Source: `tms/reports/routers.py`

**Prefix:** `/report`

Reporting endpoints power the Dashboard, Team performance, Profile overview,
project/team activity feeds and appraisal exports.

All endpoints require `Authorization: Bearer <JWT>` and an active workspace
membership. `scope=org` requires an owner/admin.

## Periods

`preset` accepts:

- `Today`
- `This Week`
- `Last Week`
- `This Month`
- `Last Month`
- `This Quarter`
- `Custom` (with `date_from` and `date_to`)

The response resolves the period and the previous comparison period.

## Metrics

| Key | Meaning |
| --- | --- |
| `completed` | Tasks completed in the period |
| `on_time_rate` | Completed on/before the current target date |
| `first_time_right_rate` | Completed with zero returns |
| `average_rounds` | Average submission round for completed tasks |
| `overdue` | Open tasks past their target date |
| `saved_days` | Average days early vs the original target (negative = late) |
| `recurring_compliance` | Routine logs submitted on time / all routine logs |

---

## GET `/report/get-overview/{workspace_id}/`

- **Auth:** Active member. `scope=org` requires owner/admin.
- **Query:**
  - `scope` — `me`, `team`, `org` (default `me`)
  - `person_id` — optional person override
  - `team_id` — optional team for `scope=team`
  - `preset` — period preset (default `This Month`)
  - `date_from`, `date_to` — required for `Custom`

### Sample response

```json
{
  "scope": "org",
  "person": null,
  "period": {
    "preset": "This Month",
    "date_from": "2026-10-01",
    "date_to": "2026-10-24",
    "previous_from": "2026-09-01",
    "previous_to": "2026-09-30"
  },
  "metrics": [
    {
      "key": "completed",
      "label": "Tasks completed",
      "value": 18,
      "delta": 3,
      "unit": ""
    },
    {
      "key": "on_time_rate",
      "label": "On-time rate",
      "value": 88.9,
      "delta": 2.1,
      "unit": "%"
    }
  ],
  "gauges": [],
  "weekly": [
    { "label": "01 Sep", "completed": 4, "returned": 1 }
  ],
  "task_types": [
    { "label": "Project", "key": "project", "value": 12, "percentage": 60.0 }
  ],
  "people": [
    {
      "user": {
        "id": "44444444-4444-4444-8444-444444444444",
        "email": "tunde@example.com",
        "first_name": "Tunde",
        "last_name": "Bakare",
        "photo": null
      },
      "job_title": "Backend Engineer",
      "team_name": "Tech Team",
      "completed": 6,
      "on_time_rate": 100.0,
      "first_time_right_rate": 83.3,
      "average_rounds": 1.2,
      "overdue": 0,
      "points": 120,
      "streak": 4
    }
  ],
  "leaderboard": [],
  "attention": [
    {
      "task_id": "11111111-1111-4111-8111-111111111111",
      "title": "Payment webhook retry handler",
      "reference": "TK-142",
      "status": "returned",
      "reason": "returned_multiple",
      "meta": "2 returns"
    }
  ],
  "appraisal_tasks": [
    {
      "task_id": "11111111-1111-4111-8111-111111111111",
      "title": "Payment webhook retry handler",
      "project_name": "Customer Portal Revamp",
      "original_due_date": "2026-10-20",
      "completed_date": "2026-10-18",
      "variance_days": 2,
      "rounds": 2
    }
  ]
}
```

`weekly` contains eight weeks ending at the period end. `task_types` counts
tasks created in the period. `attention` covers overdue tasks, tasks with two
or more returns and due-date changes in the period.

---

## GET `/report/get-person/{workspace_id}/{user_id}/`

- **Auth:** Active member (self, teammate, line manager or manager).
- **Query:** `preset`, `date_from`, `date_to`.
- **Description:** Person profile report with metrics, 90-day streak
  heatmap, badges, direct reports and completed-task rows. The heatmap counts
  approvals the person received, not approvals they performed.

```json
{
  "person": {
    "id": "44444444-4444-4444-8444-444444444444",
    "email": "tunde@example.com",
    "first_name": "Tunde",
    "last_name": "Bakare",
    "photo": null
  },
  "job_title": "Backend Engineer",
  "department": "Engineering",
  "team_name": "Tech Team",
  "reports_to": null,
  "direct_reports": [],
  "period": { "preset": "This Month", "date_from": "2026-10-01", "date_to": "2026-10-24" },
  "metrics": [],
  "streak_heatmap": [
    { "date": "2026-10-20", "count": 2 }
  ],
  "badges": [
    {
      "key": "streak_7",
      "name": "7-day streak",
      "description": "7-day streak",
      "icon": "fire",
      "earned": true,
      "awarded_at": "2026-10-20T10:00:00Z"
    }
  ],
  "tasks": []
}
```

---

## GET `/report/list-activity/{workspace_id}/`

- **Auth:** Active member; only activity on visible tasks is returned.
- **Query:**
  - `project_id`, `team_id`, `actor_id`
  - `kind` — task activity kind (`created`, `started`, `submitted`,
    `resubmitted`, `returned`, `approved`, `moved`, `linked`, …)
  - `date_from`, `date_to`
  - `page`, `page_size`

### Sample response item

```json
{
  "id": "99999999-9999-4999-8999-999999999999",
  "task_id": "11111111-1111-4111-8111-111111111111",
  "task_title": "Payment webhook retry handler",
  "task_reference": "TK-142",
  "project_id": "aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa",
  "project_name": "Customer Portal Revamp",
  "team_id": "33333333-3333-4333-8333-333333333333",
  "team_name": "Tech Team",
  "actor": {
    "id": "55555555-5555-4555-8555-555555555555",
    "email": "chioma@example.com",
    "first_name": "Chioma",
    "last_name": "Okafor",
    "photo": null
  },
  "kind": "approved",
  "note": "Clean and well tested.",
  "metadata": null,
  "created_at": "2026-10-24T10:15:00Z"
}
```

The same feed powers My Day team pulse, project recent activity, team pulse
and profile activity.

---

## GET `/report/export-appraisal/{workspace_id}/`

- **Auth:** Active member; `person_id` optional.
- **Query:** `person_id`, `preset`, `date_from`, `date_to`.
- **Response:** `text/csv` attachment (`appraisal.csv`).

Columns: `Name,Completed,On time %,First-time-right %,Average rounds,Overdue`.

PDF export is rendered by the client print dialog from the same data.
