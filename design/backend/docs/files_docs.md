# File Library API Documentation

Source: `tms/files/routers.py`

**Prefix:** `/file`

The file library is a read/upload view over task attachments. Attachments
belong to a task; the library adds workspace-wide search, filters, preview
metadata and project/team views. Standalone uploads created for inline
description images exist before a task is attached and are excluded from the
library until bound.

All endpoints require `Authorization: Bearer <JWT>` except
`GET /file/view/{file_id}/`, which is public so it can be used in `<img>`
tags. Workspace-scoped endpoints require an active membership. Only files on
tasks the member can see are returned by the library endpoints.

## File kinds

| Kind | Matched content |
| --- | --- |
| `image` | `image/*` and common image extensions |
| `pdf` | `application/pdf` / `.pdf` |
| `video` | `video/*` and common video extensions |
| `document` | Everything else |

---

## GET `/file/list-files/{workspace_id}/`

- **Query:**
  - `project_id`, `team_id`, `task_id`, `uploader_id`
  - `content_type` — case-insensitive MIME substring
  - `kind` — `image`, `pdf`, `video` or `document`
  - `search` — file name or task title
  - `page`, `page_size`

### Sample response item

```json
{
  "id": "aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa",
  "file_name": "webhook-retry-tests.pdf",
  "file_url": "https://example.com/signed/url?Authorization=preview-token",
  "download_url": "https://example.com/signed/url?Authorization=download-token&b2ContentDisposition=attachment%3B%20filename%3D%22webhook-retry-tests.pdf%22",
  "file_size": 245760,
  "content_type": "application/pdf",
  "kind": "pdf",
  "expires_at": "2026-10-31T10:00:00Z",
  "uploaded_by": {
    "id": "44444444-4444-4444-8444-444444444444",
    "email": "tunde@example.com",
    "first_name": "Tunde",
    "last_name": "Bakare",
    "photo": null
  },
  "task": {
    "id": "11111111-1111-4111-8111-111111111111",
    "title": "Payment webhook retry handler",
    "reference": "TK-142"
  },
  "project": {
    "id": "22222222-2222-4222-8222-222222222222",
    "name": "Customer Portal Revamp"
  },
  "team": {
    "id": "33333333-3333-4333-8333-333333333333",
    "name": "Tech Team"
  },
  "created_at": "2026-10-24T08:20:00Z"
}
```

Project Files and Team Files tabs use the same endpoint with `project_id` or
`team_id`.

---

## GET `/file/file-stats/{workspace_id}/`

```json
{
  "total": 14,
  "by_kind": { "pdf": 6, "image": 5, "document": 3 },
  "total_size": 18432000
}
```

---

## POST `/file/upload-file/{workspace_id}/`

- **Content type:** `multipart/form-data`
- **Form fields:**
  - `task_id` — target task UUID in this workspace (required; files belong to tasks)
  - `file` — file upload

The task is validated against the URL workspace before the upload is stored.

Returns the same file shape as `list-files`. Signed URLs expire; the
`renew-file-urls` Celery beat task re-signs them before expiry.

`file_url` is for inline previews. `download_url` is a separately signed B2
URL whose token is minted with
`b2ContentDisposition=attachment; filename="..."` so the browser saves the
file with its original name. Both URLs share the same expiry. See
`docs/download_integration.md` for frontend usage and the bucket CORS rule
needed by background `fetch()` requests.

---

## GET `/file/upload-policy/`

Returns the limits enforced by `POST /file/upload/{workspace_id}/` so the UI
can reject invalid files before uploading. Requires authentication.

```json
{
  "max_file_size_mb": 10,
  "max_file_size_bytes": 10485760,
  "allowed_content_types": [
    "image/png",
    "image/jpeg",
    "image/gif",
    "image/webp"
  ],
  "allowed_extensions": ["gif", "jpeg", "jpg", "png", "webp"],
  "orphan_ttl_hours": 72
}
```

---

## POST `/file/upload/{workspace_id}/`

Upload an inline image before its task exists. The caller must be an active
workspace member; no task id is required.

- **Content type:** `multipart/form-data`
- **Form fields:**
  - `file` — one PNG, JPEG, GIF or WEBP image
- **Status:** `201 Created`
- **Limits:** `MAX_UPLOAD_FILE_SIZE_MB` (10 MB default), magic-byte checked
- **Rejected:** SVG, HTML, executables, fake image payloads and unsupported
  extensions/content types

```json
{
  "file_id": "aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa",
  "url": "https://api.example.com/file/view/aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa/",
  "file_name": "screenshot.png",
  "file_size": 184320,
  "content_type": "image/png"
}
```

Store `url` in the task description markdown:

```markdown
See the failing state:

![Screenshot](https://api.example.com/file/view/aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa/)
```

Pass `file_ids` on task create or update, or on recurring-rule update, to
bind the upload. The file is attached to every task created in the same
create request. Recurring-rule edits mark uploads as claimed without adding
a task attachment, because generated occurrences reuse the description
markdown. Uploads that are never bound are deleted after
`ORPHAN_UPLOAD_TTL_HOURS` (72 hours by default).

The `url` is stable and can be saved permanently. It redirects to a freshly
signed B2 URL, so it does not expire with `FILE_URL_EXPIRE_SECONDS`.

---

## GET `/file/view/{file_id}/`

Public image-rendering endpoint used by the stable URL above. It does not
require an `Authorization` header because `<img src>` cannot send one.

- Returns `302` to a fresh signed B2 URL
- Returns `404` when the upload is missing or deleted
- The UUID is the capability: anyone with the link can fetch the image
