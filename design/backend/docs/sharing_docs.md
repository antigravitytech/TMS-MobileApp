# Resource Sharing API Documentation

Source: `tms/sharing/routers.py`

**Prefix:** `/share`

Project and task sharing stores link access and invited collaborators in
normalized tables (`resource_shares`, `resource_share_entries`,
`resource_share_permissions`).

All endpoints require `Authorization: Bearer <JWT>`. The caller must be an
active member of the resource's workspace, and only the resource owner or a
workspace owner/admin can update sharing.

## Enumerations

| Field | Values |
| --- | --- |
| `resource_type` | `project`, `task` |
| `level` | `none`, `view`, `comment`, `edit` |
| `role` | `member`, `client` |
| `status` | `active`, `pending` |
| `client_can` | `progress`, `timeline`, `files`, `invoices`, `comment` |

## GET `/share/get-access/{resource_type}/{resource_id}/`

```json
{
  "resource_type": "project",
  "resource_id": "11111111-1111-4111-8111-111111111111",
  "resource_name": "Website build",
  "owner": {
    "id": "22222222-2222-4222-8222-222222222222",
    "email": "owner@acme.com",
    "first_name": "Ada",
    "last_name": "Okafor",
    "photo": null
  },
  "link_level": "view",
  "link_token": "share-link-token",
  "people": [
    {
      "id": "33333333-3333-4333-8333-333333333333",
      "email": "client@example.com",
      "user": null,
      "level": "view",
      "status": "pending",
      "role": "client",
      "client_can": ["progress", "files"],
      "invited_at": "2026-11-19T13:00:00Z",
      "expires_on": null
    }
  ]
}
```

The first call creates the share row and its `link_token`.

## POST `/share/update-access/{resource_type}/{resource_id}/`

One action per request:

| Action | Payload |
| --- | --- |
| `invite` | `emails`, `level`, `expires_on`, `role`, `client_can` |
| `set_client` | `entry_id`, `client_can` |
| `set_level` | `entry_id`, `level` |
| `remove` | `entry_id` |
| `resend` | `entry_id` |
| `set_link` | `level` |

```json
{
  "action": "invite",
  "emails": ["client@example.com"],
  "level": "view",
  "role": "client",
  "client_can": ["progress", "files"]
}
```

Existing users are linked immediately (`status=active`) and receive an
in-app `task_access_granted` notification; unknown emails stay `pending`
until they join. Returns the full access payload.

## GET `/share/list-collaborators/{workspace_id}/`

Returns active workspace members plus every share invite, grouped by email:

```json
[
  {
    "email": "client@example.com",
    "user": null,
    "status": "pending",
    "role": "client",
    "client_can": ["progress", "files"],
    "access": [
      {
        "entry_id": "33333333-3333-4333-8333-333333333333",
        "resource_type": "project",
        "resource_id": "11111111-1111-4111-8111-111111111111",
        "resource_name": "Shared resource",
        "level": "view"
      }
    ]
  }
]
```
