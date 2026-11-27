# School API Documentation

Source: `tms/school/routers.py`

**Prefix:** `/school`

School diary endpoints are available in `family` workspaces. All endpoints
require `Authorization: Bearer <JWT>` and active workspace membership.

## Enumerations

| Field | Values |
| --- | --- |
| `kind` | `assignment`, `test`, `pta`, `event`, `form`, `fees`, `supplies`, `report` |
| `status` | `todo`, `done`, `checked`, `redo` |
| `action` | `done`, `check`, `redo`, `reopen`, `delete` |

## Permissions

- `can_edit` — creator, or a workspace owner/admin.
- `can_check` — the assigned checker, or an owner/admin.
- `can_mark_done` — the linked child, the creator, or an owner/admin.

## GET `/school/list-items/{workspace_id}/`

Returns an array:

```json
{
  "id": "11111111-1111-4111-8111-111111111111",
  "kind": "assignment",
  "title": "Maths homework",
  "child": null,
  "subject": "Maths",
  "due": "2026-11-20",
  "time": null,
  "place": null,
  "amount": null,
  "checker": null,
  "status": "todo",
  "note": "Chapter 4",
  "feedback": null,
  "done_at": null,
  "checked_at": null,
  "created_by": null,
  "can_mark_done": true,
  "can_check": true,
  "can_edit": true
}
```

## POST `/school/save-item/{workspace_id}/`

```json
{
  "id": null,
  "kind": "assignment",
  "title": "Maths homework",
  "child_id": null,
  "subject": "Maths",
  "due": "2026-11-20",
  "time": null,
  "place": null,
  "amount": null,
  "checker_id": null,
  "note": "Chapter 4"
}
```

`child_id` and `checker_id` must be active workspace members. Sending an
existing `id` updates the item. The assigned checker receives a notification.

## POST `/school/item-action/{workspace_id}/`

```json
{"id": "11111111-1111-4111-8111-111111111111", "action": "done", "note": null}
```

| Action | Effect |
| --- | --- |
| `done` | Sets `status=done` and `done_at` |
| `check` | Sets `status=checked`, `checked_at` and optional `feedback` |
| `redo` | Sets `status=redo` and optional `feedback` |
| `reopen` | Returns the item to `todo` |
| `delete` | Soft-deletes the item (creator/admin only) |

Returns the updated item. `check`, `redo` and `delete` require the appropriate
permission described above.
