# File Downloads — Frontend Integration

Chat attachment, task attachment and workspace file-library responses now
include a `download_url` next to `file_url`. Use `file_url` for previews and
`download_url` for download buttons.

This applies to chat attachments, task attachments and the workspace file
library. Inline images uploaded before a task exists keep their existing
stable `/file/view/{file_id}/` URL; see
`docs/inline_image_upload_integration.md`.

## What changed

| Surface | Endpoints | Field |
| --- | --- | --- |
| Chat messages | `GET /chat/list-messages/{conversation_id}/`, `POST /chat/send-message/{conversation_id}/`, thread replies | `attachments[].download_url` |
| Chat Files tab | `GET /chat/list-conversation-files/{conversation_id}/` | `items[].download_url` |
| Task attachments | `POST /task/upload-attachment/{task_id}/`, `GET /task/list-attachments/{task_id}/` | `download_url` |
| File library | `GET /file/list-files/{workspace_id}/`, `POST /file/upload-file/{workspace_id}/` | `download_url` |

`download_url` is additive. Existing fields and behaviour are unchanged.

| Field | Use |
| --- | --- |
| `file_url` | Inline preview: `<img>`, `<video>`, PDF viewer |
| `download_url` | Save to disk with the original filename |
| `expires_at` | Both URLs share this expiry |

## URL shape

```text
https://f00X.backblazeb2.com/file/<bucket>/<object-key>
  ?Authorization=<download-token>
  &b2ContentDisposition=attachment%3B%20filename%3D%22report.pdf%22
```

These are **native Backblaze B2 download URLs, not S3 pre-signed URLs**.
There is no `X-Amz-Signature`. The `Authorization` value is a prefix-scoped
B2 download token. B2 binds that token to the `b2ContentDisposition` value
used when the token was minted, so `download_url` uses a **separate token**
from `file_url`; it is not the preview token with a parameter appended.

The backend mints and encodes the download disposition for you. Do not append
another `b2ContentDisposition`, and do not replace the URL with the stored
object key.

## Using the URL

```ts
interface FileAttachment {
  id: string;
  file_name: string;
  file_url: string | null;
  download_url: string | null;
  file_size: number;
  content_type: string | null;
  kind?: string;
  expires_at: string | null;
}
```

A normal link is enough:

```tsx
<a href={attachment.download_url ?? undefined} rel="noopener">
  Download
</a>
```

Or, for a button:

```ts
function downloadFile(file: FileAttachment) {
  if (!file.download_url) return;
  const link = document.createElement("a");
  link.href = file.download_url;
  link.rel = "noopener";
  link.click();
}
```

B2 responds with `Content-Disposition: attachment`, so the browser saves the
file instead of opening a new tab.

Do **not** rely on the HTML `download` attribute: browsers ignore it for
cross-origin URLs. The disposition header is what triggers the download.

Prefer a direct link or redirect. If you fetch the URL in the background to
build a blob, the bucket must allow CORS from your origin (see below).

## CORS

Image previews work without CORS because `<img>` subresource loads are not
CORS-gated. Direct download links and navigations also work without CORS.

A `fetch()`/`XMLHttpRequest` to the B2 URL is cross-origin and needs a
bucket-level CORS rule. The API's `CORS_ALLOW_ORIGINS` setting does **not**
apply to B2.

```json
[
  {
    "corsRuleName": "frontendDownloads",
    "allowedOrigins": ["https://app.sabipipu.com"],
    "allowedOperations": ["b2_download_file_by_name"],
    "allowedHeaders": ["range"],
    "exposeHeaders": ["content-disposition", "content-length", "content-type"],
    "maxAgeSeconds": 3600
  }
]
```

- Add staging and local-development origins explicitly; `allowedOrigins`
  entries must match the exact scheme/host/port.
- The backend's B2 application key may not be allowed to update bucket
  settings. Apply the rule with the B2 console or CLI.
- Do not send an `Authorization` header from the browser. The download token
  is already in the URL; preflight requests using account credentials are
  rejected by B2.
- `allowedHeaders: ["range"]` is only needed if the frontend sends `Range`
  requests. Expose `content-disposition` if JavaScript needs the filename.

## Expiry and renewal

`download_url` has the same lifetime as `file_url`
(`FILE_URL_EXPIRE_SECONDS`, one week by default). The `renew-file-urls` Celery
beat task re-signs stored URLs every six hours when they are within 24 hours
of expiry.

- Do not persist `download_url` in browser storage or a client-side database.
- On `401`, refetch the message, task attachments or file list to get a fresh
  URL.
- Both URL fields are `null` for legacy rows without a stored file URL.
  `download_url` can briefly be `null` on an older row while the
  `renew-file-urls` task backfills it; disable the download action in either
  case.
- If a download still fails after a refetch, surface a generic "file
  unavailable" message rather than retrying the same expired URL.

## Response examples

Chat message attachment:

```json
{
  "id": "aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa",
  "message_id": "bbbbbbbb-bbbb-4bbb-8bbb-bbbbbbbbbbbb",
  "file_name": "screenshot.png",
  "file_url": "https://f001.backblazeb2.com/file/tms/chat/photo.png?Authorization=preview-token",
  "download_url": "https://f001.backblazeb2.com/file/tms/chat/photo.png?Authorization=download-token&b2ContentDisposition=attachment%3B%20filename%3D%22screenshot.png%22",
  "file_size": 184320,
  "content_type": "image/png",
  "kind": "image",
  "expires_at": "2026-11-20T10:00:00Z"
}
```

Task attachment and file-library items use the same two URL fields; the file
library also returns `task`, `project`, `team` and `kind`.

## Filenames

`download_url` carries a sanitised, ASCII-safe filename based on `file_name`,
with the original extension preserved when possible. Keep displaying
`file_name` in the UI; the saved filename may be transliterated for non-ASCII
names.

## Error handling

| Status | Meaning | UI behaviour |
| --- | --- | --- |
| `401` | B2 download token missing, malformed or expired | Refetch the owning message/task/file list |
| `403` | Token does not authorize the object | Refetch; if it persists, report it |
| `404` | Object was deleted or the bucket/key is wrong | Show "file unavailable" |
| Network error | Offline, DNS, or missing bucket CORS rule for `fetch()` | Retry once, then show the error |

## Checklist

- [ ] Use `file_url` for previews, `download_url` for downloads.
- [ ] Do not construct or modify B2 URLs in the frontend.
- [ ] Do not use the HTML `download` attribute as the sole download trigger.
- [ ] Refetch on 401 instead of reusing an expired URL.
- [ ] Add the bucket CORS rule only if you need programmatic `fetch()`.
