# Inline Image Upload — Frontend Integration

This document covers the backend additions for pasting screenshots into task
descriptions. Descriptions remain markdown; an inline image is just
`![alt](url)`.

## What changed

| Endpoint | Purpose |
| --- | --- |
| `POST /file/upload/{workspace_id}/` | Upload one image before a task exists |
| `GET /file/upload-policy/` | Fetch size/type limits for UI prevalidation |
| `GET /file/view/{file_id}/` | Stable image URL; redirects to a fresh signed B2 URL |

Task create and update now accept an optional `file_ids` array to bind the
uploaded image to the task. Existing task attachment endpoints and
`POST /task/create-task-with-files/` are unchanged.

## Upload policy

Call this once (per session is enough) to validate files before uploading.
Requires `Authorization: Bearer <JWT>`.

```http
GET /file/upload-policy/
```

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

SVG is intentionally rejected. The backend also checks the actual file bytes,
so a `.png` that is not a real image will fail even if the declared type is
correct.

## Uploading an image

```http
POST /file/upload/{workspace_id}/
Authorization: Bearer <JWT>
Content-Type: multipart/form-data
```

Form field: `file` — exactly one image.

### Success — `201 Created`

```json
{
  "file_id": "aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa",
  "url": "https://api.example.com/file/view/aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa/",
  "file_name": "screenshot.png",
  "file_size": 184320,
  "content_type": "image/png"
}
```

Use `url` in the markdown. Do **not** replace it with the redirect target:
the `url` above is stable, while the signed B2 URL it redirects to expires.

```markdown
Here is the failing state:

![Screenshot](https://api.example.com/file/view/aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa/)
```

The image can be previewed immediately with the same `url`; no task is needed
yet.

### TypeScript shape

```ts
interface InlineUpload {
  file_id: string;
  url: string;
  file_name: string;
  file_size: number;
  content_type: string;
}

interface UploadPolicy {
  max_file_size_mb: number;
  max_file_size_bytes: number;
  allowed_content_types: string[];
  allowed_extensions: string[];
  orphan_ttl_hours: number;
}
```

## New task flow

1. User pastes or drops an image into the description editor.
2. Upload it immediately with `POST /file/upload/{workspace_id}/`.
3. Insert `![alt](url)` into the markdown at the cursor.
4. Keep `file_id` in a pending list for this draft.
5. On task save, send the pending ids:

```http
POST /task/create-task/{workspace_id}/
Authorization: Bearer <JWT>
Content-Type: application/json
```

```json
{
  "title": "Payment webhook retry handler",
  "description": "See ![Screenshot](https://api.example.com/file/view/aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa/)",
  "assignee_ids": ["44444444-4444-4444-8444-444444444444"],
  "file_ids": ["aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa"]
}
```

The image is attached to every task created by that request. For example,
creating tasks for three assignees produces three tasks, each with the image
in its attachment list.

`file_ids` is limited to 50 ids per request. Re-sending an id that is already
attached to the same task is a no-op.

## Editing an existing task

The same flow applies to `PUT /task/update-task/{task_id}/`:

```json
{
  "description": "Updated screenshot:\n\n![Screenshot](https://api.example.com/file/view/aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa/)",
  "file_ids": ["aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa"]
}
```

Send only the ids uploaded during this editing session. Files that were
already attached earlier do not need to be re-sent.

## Recurring task rules

`PATCH /task/update-recurring-rule/{rule_id}/` also accepts `file_ids` when
the new description references fresh inline uploads:

```json
{
  "description": "Daily check ![](https://api.example.com/file/view/aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa/)",
  "file_ids": ["aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa"]
}
```

The upload is marked as claimed so orphan cleanup keeps it, but no task
attachment is created: generated occurrences reuse the rule description and
its stable image URL rather than copying attachments.

## Stable view URL

```http
GET /file/view/{file_id}/
```

- Public: no `Authorization` header, because `<img src>` cannot send one.
- Returns `302 Found` to a freshly signed B2 URL.
- Returns `404` if the upload is missing or deleted.
- The UUID acts as a capability link: anyone with the URL can fetch the image.
  This is the same practical model as the existing signed attachment URLs,
  except the stable URL itself does not expire.

Do not proxy this through an authenticated fetch in the editor if you want
normal browser image rendering; use the URL directly.

## Orphan cleanup

Uploads that are never bound to a task or claimed for a recurring rule are
deleted after `orphan_ttl_hours` (72 hours by default). This covers abandoned
dialogs and failed task saves.

**Always send `file_ids` when saving the task or recurring rule.** If an
uploaded image is in the description but its id is never bound, the cleanup
job will eventually delete it.

## Error handling

| Status | Meaning |
| --- | --- |
| `400` | Unsupported type, fake image payload, executable content, or too large |
| `401` | Missing/expired access token |
| `403` | Caller is not an active workspace member, or is binding someone else's upload |
| `404` | Unknown/deleted file id on the view endpoint, or unknown workspace |
| `422` | A `file_ids` entry does not exist in this workspace |

Recommended UI behavior:

- Check `upload-policy` before opening the file picker or on paste.
- Show the backend `detail` message for `400` responses.
- Keep the uploaded markdown in the draft until task save succeeds; if the
  save fails, the upload can be retried or left for the TTL cleanup.

## Markdown rendering

The backend stores and returns descriptions as raw markdown. It does not
currently render task descriptions in notification emails or reports, so
there is no server-side HTML to match.

The frontend remains responsible for rendering and sanitizing markdown,
including limiting image URLs to safe schemes. Descriptions have no new
backend length limit and are stored in a `TEXT` column.
