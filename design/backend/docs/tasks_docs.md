# Task API Documentation

Source: `tms/tasks/routers.py`

**Prefix:** `/task`

All endpoints require `Authorization: Bearer <JWT>` and an active
workspace membership.

## Enums

| Enum | Values |
| --- | --- |
| `type` | `project`, `standalone`, `team`, `recurring` |
| `status` | `not_started`, `in_progress`, `submitted`, `returned`, `completed` |
| `priority` | `low`, `medium`, `high`, `critical` |
| `visibility` | `public`, `confidential` |
| `comment.kind` | `update`, `challenge`, `scope_change`, `quality_note`, `general` |

`recurring` creates a recurring rule and the current occurrence. See
“Recurring tasks and times” below.

## Multi-assignee creation

The creation dialog accepts multiple assignees. Each assignee receives an
**independent task** with its own status, submission round, approval,
activity, comments, checklist, attachments and notifications.

A single request with N assignees creates N task rows. There is no parent
task group. If any assignee is invalid, the whole request is rejected and no
tasks are created.

## Access

| Action | Rule |
| --- | --- |
| View a public task | Any active workspace member |
| View a public task in a confidential project | Project access rules |
| View a confidential task | Assigner, assignee, approvers, explicit viewers or watchers |
| Edit / delete | Assigner, workspace owner/admin, project PM/alternate PM, team lead |
| Reassign | Editors, only `not_started` or `returned` |
| Start / submit | Assignee only |
| Return / approve | Effective approver only |
| Complete | Assignee, personal tasks only |
| Change due date | Approver, assigner or editor |

Workspace admins are **not** automatically added to confidential tasks; they
must be selected in `visible_to`.

## Approval routing

- **Project tasks:** follow `Project.approval_policy`
  - `pm` — project owner only
  - `pm_alt` — project owner, alternate PM as backup
  - `any` — project owner or alternate PM, first to act
- **Team tasks:** team lead. If the lead is the assignee, the assigner
  approves. If the assigner is also the assignee, the task is personal.
- **Standalone tasks:** assigner. If the assigner is also the assignee, the
  task is personal.

An assignee is never their own approver. If a project task would be assigned
to its only approver, creation is rejected with `422`.

## Due reminders

A Celery beat job (`tasks.tasks.send_task_due_reminders`) runs hourly. When a
workspace reaches the hour of its `working_hours_start` (default `09:00`
local), the job emails each user one consolidated summary of tasks due the
next local day.

- Recipients are the task **assignee** and **assigner**, restricted to active,
  verified workspace members.
- Only tasks still in `not_started`, `in_progress` or `returned` are included.
  `submitted`, `completed` and soft-deleted tasks are excluded.
- Assigned tasks and tasks the user assigned are listed in separate sections.
  A self-assigned task appears only once.
- Each user receives at most one reminder per workspace per local day. The
  `task_reminder_logs` table enforces this idempotency.
- Delivery is a plain email (no in-app notification row). Users can opt out
  through the `reminder` notification preference; the email default is on.
  The global unsubscribe link is still respected.

## Pagination

Every list endpoint returns:

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

## POST `/task/create-task/{workspace_id}/`

- **Status:** `201 Created`
- **Description:** Create one independent task per assignee.
- **Payload:**

```json
{
  "title": "Payment webhook retry handler",
  "description": "Retry failed webhook deliveries.",
  "type": "team",
  "team_id": "33333333-3333-4333-8333-333333333333",
  "assignee_ids": [
    "44444444-4444-4444-8444-444444444444",
    "55555555-5555-4555-8555-555555555555"
  ],
  "priority": "high",
  "visibility": "public",
  "visible_to": [],
  "start_date": "2026-10-23",
  "due_date": "2026-10-26"
}
```

- `assignee_ids` is required, deduplicated, 1–50 users.
- Project tasks require `project_id`; every assignee must be a project
  member. Optional `milestone_id` must belong to that project.
- Team tasks require `team_id`; every assignee must be a team member.
- Standalone tasks must omit `project_id`, `team_id` and `milestone_id`.
- Due date defaults to start date + 3 days.
- Optional `file_ids` binds standalone uploads from `POST /file/upload/` to
  every task created in the request.
- Returns a JSON array with one task per assignee.

**Sample response:**

```json
[
  {
    "id": "11111111-1111-4111-8111-111111111111",
    "reference": "TK-142",
    "workspace_id": "22222222-2222-4222-8222-222222222222",
    "title": "Payment webhook retry handler",
    "type": "team",
    "status": "not_started",
    "priority": "high",
    "visibility": "public",
    "project": null,
    "team": {
      "id": "33333333-3333-4333-8333-333333333333",
      "name": "Tech Team",
      "color": "#6658c0"
    },
    "milestone": null,
    "assignee": {
      "id": "44444444-4444-4444-8444-444444444444",
      "email": "tunde@example.com",
      "first_name": "Tunde",
      "last_name": "Bakare",
      "photo": null
    },
    "assigner": {
      "id": "66666666-6666-4666-8666-666666666666",
      "email": "chioma@example.com",
      "first_name": "Chioma",
      "last_name": "Okafor",
      "photo": null
    },
    "approver": {
      "id": "66666666-6666-4666-8666-666666666666",
      "email": "chioma@example.com",
      "first_name": "Chioma",
      "last_name": "Okafor",
      "photo": null
    },
    "alternate_approver": null,
    "start_date": "2026-10-23",
    "due_date": "2026-10-26",
    "original_due_date": "2026-10-26",
    "is_overdue": false,
    "overdue_days": 0,
    "submitted_at": null,
    "waiting_hours": 0.0,
    "completed_at": null,
    "submission_round": 0,
    "return_count": 0,
    "first_time_right": false,
    "comment_count": 0,
    "attachment_count": 0,
    "checklist_total": 0,
    "checklist_done": 0,
    "last_activity_at": "2026-10-23T10:00:00Z",
    "permissions": {
      "can_edit": true,
      "can_delete": true,
      "can_reassign": true,
      "can_start": false,
      "can_submit": false,
      "can_approve": false,
      "can_return": false,
      "can_complete": false,
      "can_change_due_date": true,
      "can_comment": true,
      "can_upload": true,
      "can_toggle_checklist": true,
      "can_manage_watchers": true
    },
    "created_at": "2026-10-23T10:00:00Z",
    "updated_at": "2026-10-23T10:00:00Z"
  }
]
```

---

## GET `/task/resolve-approver/{workspace_id}/`

- **Auth:** Active workspace member.
- **Query:** `assignee_id` (required), `project_id` (optional), `team_id` (optional).
- **Description:** Preview the approver routing used by task creation. `kind`
  is `project`, `line_manager`, `team_lead`, `assigner`, `personal` or
  `no_approver`.

```json
{
  "kind": "line_manager",
  "approver": {
    "id": "55555555-5555-4555-8555-555555555555",
    "email": "manager@example.com",
    "first_name": "Mia",
    "last_name": "Manager",
    "photo": null
  },
  "alternate_approver": null
}
```

## GET `/task/list-tasks/{workspace_id}/`

- **Description:** List visible tasks with scope, filters and pagination.

### Query parameters

| Parameter | Values |
| --- | --- |
| `scope` | `mine`, `requests`, `team`, `all` |
| `status` | repeatable: `not_started`, `in_progress`, `submitted`, `returned`, `completed` |
| `type` | repeatable: `project`, `standalone`, `team`, `recurring` |
| `priority` | repeatable: `low`, `medium`, `high`, `critical` |
| `project_id`, `team_id`, `milestone_id` | UUID |
| `assignee_id`, `assigner_id` | UUID |
| `visibility` | `public`, `confidential` |
| `due` | `overdue`, `today`, `week`, `later` |
| `due_from`, `due_to` | ISO date |
| `search` | title/description |
| `sort_by` | `due`, `created`, `updated`, `last_activity`, `priority`, `status`, `title` |
| `sort_dir` | `asc`, `desc` |
| `page`, `page_size` | pagination |

`scope=team` includes tasks assigned to anyone who shares an active team with
the current user in the same workspace.

`sort_by=priority` orders `low`, `medium`, `high`, `critical` and
`sort_by=status` orders the workflow sequence (`not_started`, `in_progress`,
`submitted`, `returned`, `completed`) when `sort_dir=asc`; `desc` reverses
that order.

**Sample response:** `PaginatedResponse[TaskRead]` using the task shape above.

---

## GET `/task/get-task/{task_id}/`

- **Description:** Full task detail, including description, viewers, watchers,
  checklist, latest submission/return notes and recent activity.

**Sample response:**

```json
{
  "id": "11111111-1111-4111-8111-111111111111",
  "reference": "TK-142",
  "title": "Payment webhook retry handler",
  "description": "Retry failed deliveries.",
  "visible_to": [],
  "watchers": [
    {
      "id": "44444444-4444-4444-8444-444444444444",
      "email": "tunde@example.com",
      "first_name": "Tunde",
      "last_name": "Bakare",
      "photo": null
    }
  ],
  "checklist": [
    {
      "id": "77777777-7777-4777-8777-777777777777",
      "task_id": "11111111-1111-4111-8111-111111111111",
      "text": "Dead-letter queue",
      "is_done": true,
      "position": 0,
      "created_at": "2026-10-23T10:00:00Z",
      "updated_at": "2026-10-23T10:00:00Z"
    }
  ],
  "latest_submission_note": "Retry logic and tests are in place.",
  "latest_return_note": null,
  "recent_activity": [],
  "permissions": {}
}
```

The response also includes every `TaskRead` field.

---

## PUT `/task/update-task/{task_id}/`

- **Description:** Partial update.
- **Editable:** `title`, `description`, `priority`, `assignee_id`,
  `milestone_id`, `visibility`, `visible_to`, `start_date`, plus `type`,
  `project_id` and `team_id` to move the task. Move fields can be combined
  with other edits in the same request.
- Pass `file_ids` when the new description references uploads from
  `POST /file/upload/`; binding is idempotent.
- **Not editable here:** `due_date`. Use `change-due-date` for the target
  date.
- Assignee changes are allowed only for `not_started` or `returned` tasks.
- Submitted tasks cannot be moved; return or approve them first.
- Changing visibility to `public` clears explicit viewers.
- Returns `TaskDetailRead`.

```json
{
  "title": "Payment webhook retry handler v2",
  "priority": "critical",
  "visibility": "confidential",
  "visible_to": [
    "88888888-8888-4888-8888-888888888888"
  ],
  "start_date": "2026-10-24"
}
```

---

## DELETE `/task/delete-task/{task_id}/`

- **Description:** Soft-delete a task. Submitted tasks must be returned or
  approved first.
- **Response:**

```json
{ "message": "Task deleted successfully." }
```

---

## Workflow endpoints

All workflow endpoints return `TaskDetailRead`.

| Endpoint | Actor | Payload |
| --- | --- | --- |
| `POST /task/start-task/{task_id}/` | Assignee | none |
| `POST /task/submit-task/{task_id}/` | Assignee | `{"note": "..."}` |
| `POST /task/return-task/{task_id}/` | Approver | `{"note": "...", "due_date": null, "reason": null}` |
| `POST /task/approve-task/{task_id}/` | Approver | `{"comment": "..."}` |
| `POST /task/complete-task/{task_id}/` | Assignee, personal task | none |
| `POST /task/reopen-task/{task_id}/` | Approver or editor | none |
| `POST /task/change-due-date/{task_id}/` | Approver, assigner or editor | `{"due_date": "2026-11-01", "reason": "..."}` |

Rules:

- submit handles both first submission and resubmission; `submission_round`
  increments every time.
- Personal tasks (no approver) cannot be submitted; use `complete-task`
  instead. Attempting to submit one returns `409`.
- return requires a note. If `due_date` is supplied, `reason` is required.
- approve accepts an optional closing comment.
- change-due-date requires a reason and cannot be used on completed tasks.
- reopening a task recalculates its approver from the current project PM/team
  lead and rejects reopening a project task when the assignee would be the
  only approver.
- invalid transitions return `409`.
- all actions append a `TaskActivity` row.

**Sample submit payload:**

```json
{ "note": "Retry with exponential backoff and a dead-letter queue." }
```

**Sample return payload:**

```json
{
  "note": "Declined cards must not retry forever.",
  "due_date": "2026-10-30",
  "reason": "Scope change after review"
}
```

---

## GET `/task/list-approvals/{workspace_id}/`

- **Description:** Submitted tasks where the current user is the primary or
  alternate approver.
- **Query:** `assignee_id`, `project_id`, `team_id`, `search`,
  `sort=oldest|newest|round`, `page`, `page_size`.
- Returns `PaginatedResponse[TaskRead]`.

---

## GET `/task/get-summary/{workspace_id}/`

- **Description:** Counts for My Day and Review.

```json
{
  "my_tasks": {
    "open": 4,
    "overdue": 1,
    "due_today": 2,
    "due_this_week": 3,
    "returned_to_me": 1
  },
  "review": {
    "waiting": 2,
    "avg_review_hours": 6.4,
    "approved_this_week": 5,
    "returned_this_week": 1
  },
  "tabs": {
    "mine": 6,
    "requests": 8,
    "team": 15,
    "all": 24
  },
  "by_status": {
    "not_started": 3,
    "in_progress": 2,
    "submitted": 1,
    "returned": 1,
    "completed": 17
  }
}
```

---

## GET `/task/list-activity/{task_id}/`

- **Query:** `order=newest|oldest`, `page`, `page_size`.
- **Sample item:**

```json
{
  "id": "99999999-9999-4999-8999-999999999999",
  "task_id": "11111111-1111-4111-8111-111111111111",
  "actor": {
    "id": "66666666-6666-4666-8666-666666666666",
    "email": "chioma@example.com",
    "first_name": "Chioma",
    "last_name": "Okafor",
    "photo": null
  },
  "kind": "due_date_changed",
  "note": "Scope change after review",
  "metadata": { "from": "2026-10-26", "to": "2026-10-30" },
  "created_at": "2026-10-23T10:00:00Z",
  "updated_at": "2026-10-23T10:00:00Z"
}
```

---

## Comments

| Endpoint | Description |
| --- | --- |
| `GET /task/list-comments/{task_id}/` | Paginated comments; `order=newest|oldest` |
| `POST /task/add-comment/{task_id}/` | Add a comment |
| `DELETE /task/delete-comment/{task_id}/{comment_id}/` | Author or editor |

**Add comment payload:**

```json
{ "kind": "quality_note", "body": "Please add a test for declined cards." }
```

Comment creation notifies every watcher except the author.

---

## Checklist

| Endpoint | Description |
| --- | --- |
| `POST /task/add-checklist-item/{task_id}/` | `{"text": "...", "position": 0}` |
| `PUT /task/update-checklist-item/{task_id}/{item_id}/` | `{"text": "...", "is_done": true, "position": 1}` |
| `DELETE /task/delete-checklist-item/{task_id}/{item_id}/` | Soft-delete |

Checklist updates are available to anyone who can view the task.

---

## Attachments

| Endpoint | Description |
| --- | --- |
| `POST /task/upload-attachment/{task_id}/` | Multipart field `file` |
| `GET /task/list-attachments/{task_id}/` | Paginated |
| `DELETE /task/delete-attachment/{task_id}/{attachment_id}/` | Uploader or editor |

Uploads use the existing B2 storage and return a signed URL. Expiring
attachment URLs are refreshed by the `renew-file-urls` beat task.

### Inline images in descriptions

Descriptions store markdown. Upload an image first through
`POST /file/upload/{workspace_id}/`, then put its stable `url` in the
description and send the returned `file_id` in `file_ids` on task create,
task update or recurring-rule update. This works before a task exists, unlike
the task attachment routes. Unbound uploads are cleaned up after the
configured orphan TTL.

See `docs/inline_image_upload_integration.md` for the full frontend flow.

**Sample attachment response:**

```json
{
  "id": "aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa",
  "task_id": "11111111-1111-4111-8111-111111111111",
  "uploaded_by": {
    "id": "44444444-4444-4444-8444-444444444444",
    "email": "tunde@example.com",
    "first_name": "Tunde",
    "last_name": "Bakare",
    "photo": null
  },
  "file_name": "webhook-tests.pdf",
  "file_url": "https://example.com/signed/url?Authorization=preview-token",
  "download_url": "https://example.com/signed/url?Authorization=download-token&b2ContentDisposition=attachment%3B%20filename%3D%22webhook-tests.pdf%22",
  "file_size": 245760,
  "content_type": "application/pdf",
  "expires_at": "2026-10-24T10:00:00Z",
  "created_at": "2026-10-23T10:00:00Z",
  "updated_at": "2026-10-23T10:00:00Z"
}
```

---

## Watchers

| Endpoint | Description |
| --- | --- |
| `GET /task/list-watchers/{task_id}/` | Paginated watchers |
| `POST /task/add-watcher/{task_id}/` | `{"user_id": "..."}` |
| `DELETE /task/remove-watcher/{task_id}/{user_id}/` | Self-unwatch or editor |

Assignees, assigners, approvers and alternate approvers are auto-watchers.
Watchers of a confidential task can view it. Watchers of a confidential
project task must be project members.

---

## POST `/task/create-task-with-files/{workspace_id}/`

- **Content type:** `multipart/form-data`
- **Form fields:**
  - `payload` — JSON string with the same shape as `POST /task/create-task/`
  - `files` — repeatable file uploads
- **Description:** Create the task(s), then attach every uploaded file to each
  created task. Useful for the Composer's attachment preview.

## Recurring tasks and times

`POST /task/create-task/{workspace_id}/` accepts `type: "recurring"` with
`repeat_frequency` (`daily`, `weekdays`, `weekly`, `monthly`), optional
`repeat_weekday`, `repeat_time`, `start_time` and `due_time`. The request
creates a `RecurringTaskRule` plus the current occurrence. Future occurrences
are generated idempotently by the `routines.tasks.generate_recurring_tasks`
Celery beat task.

`TaskRead` / `TaskDetailRead` include `start_time`, `due_time`,
`recurring_rule_id`, `routine_id` and `occurrence_date`. Generation starts on
the rule's `start_date`; `weekdays` rules use the workspace working days and
dates are evaluated in the workspace timezone.

### Recurring rule management

| Endpoint | Auth | Description |
| --- | --- | --- |
| `GET /task/list-recurring-rules/{workspace_id}/` | Member (own) / manager (all) | Paginated rules; `active`, `page`, `page_size` |
| `GET /task/get-recurring-rule/{rule_id}/` | Assigner or manager | One rule |
| `PATCH /task/update-recurring-rule/{rule_id}/` | Assigner or manager | `{ "active": false }` pauses generation; may also edit title, description, priority, frequency, weekday, due_time, start_date, due_date, and send `file_ids` to claim inline uploads used in the description |
| `DELETE /task/delete-recurring-rule/{rule_id}/` | Assigner or manager | Stops generation and soft-deletes the rule |

## Additional task endpoints

| Endpoint | Auth | Description |
| --- | --- | --- |
| `POST /task/move-task/{task_id}/` | Editor | Move between standalone/team/project |
| `POST /task/duplicate-task/{task_id}/` | Editor | Copy core fields and checklist |
| `POST /task/bulk-update/{workspace_id}/` | Editor per task | Reassign/priority/project/team |
| `GET /task/list-links/{task_id}/` | Viewer | Linked tasks |
| `POST /task/add-link/{task_id}/` | Editor | `{ "linked_task_id": "...", "kind": "related" }` |
| `DELETE /task/remove-link/{task_id}/{link_id}/` | Editor | Remove a link |
| `POST /task/toggle-comment-like/{task_id}/{comment_id}/` | Viewer | Like/unlike a comment |
| `POST /task/request-access/{task_id}/` | Workspace member | Request confidential access |
| `GET /task/list-access-requests/{task_id}/` | Editor | List access requests |
| `POST /task/review-access-request/{request_id}/` | Editor | `{ "approve": true }` |
| `GET /task/list-saved-views/{workspace_id}/` | Self | List saved views |
| `POST /task/create-saved-view/{workspace_id}/` | Self | `{ "label", "route", "params" }` |
| `DELETE /task/delete-saved-view/{view_id}/` | Owner | Delete a saved view |

Bulk updates require view access to every task and are atomic. Reassignment is
only allowed for `not_started` or `returned` tasks. Moving tasks to a project
or team recalculates approvers and clears milestones that belong to the old
project.

Comments accept optional `mentioned_user_ids`; mentioned members are
notified even if they are not watchers. Comment responses include
`like_count`, `liked_by_me` and `mentioned_users`.

`TaskDetailRead` includes `links` and `access_requests`.

## Error responses

| Status | Meaning |
| --- | --- |
| `403` | Not a workspace member, no task access, or action not allowed |
| `404` | Task, comment, checklist item, attachment or watcher not found |
| `409` | Invalid status transition or task cannot be modified yet |
| `422` | Validation error, invalid assignee membership, missing team lead, etc. |
