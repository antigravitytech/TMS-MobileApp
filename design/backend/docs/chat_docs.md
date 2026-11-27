# Chat API Documentation

Source: `tms/chat/routers.py`

**Prefix:** `/chat`

For the frontend screen-by-screen integration notes, see
[`chat_integration.md`](chat_integration.md).

All endpoints require `Authorization: Bearer <JWT>`. Internal endpoints
require an active membership of the workspace that owns the group or
conversation. External conversation endpoints (`list-chat-requests`,
`accept/decline-chat-request`, `list-external-conversations` and
`get-external-unread-summary`) let a participant act on a chat without being
a member of the workspace that stores it. `search-people/{workspace_id}`
requires membership of that workspace because it computes the internal /
external split for that workspace.

## Concepts

| Entity | Meaning |
| --- | --- |
| Chat group | A chat space that holds channels. Separate from `Team`; optionally linked to a project. |
| Conversation | A channel, direct message (`dm`), ad-hoc group chat (`group`) or task conversation (`task`). |
| Channel | A conversation (`kind=channel`) inside a group. Standard channels are visible to every group member; private channels have explicit members. |
| Message | A `text`, `system`, `task` or `birthday` message. Text may quote another message or belong to a thread. |
| Conversation state | Per-user read position, mute, mentions-only and pin flags. |
| External conversation | A DM or ad-hoc group chat (`is_external=true`) that includes at least one person who is not an active member of the conversation's workspace. |
| Chat request | The pending acceptance step for an external DM. The first message creates it; the recipient accepts or declines before messages become visible. |

## Access rules

| Action | Workspace owner/admin | Group owner | Group member | Public-group viewer |
| --- | --- | --- | --- | --- |
| See a private group | Yes | Yes | Yes | No |
| See a public group | Yes | Yes | Yes | Yes |
| Join a public group | Yes | Yes | — | Yes |
| Create a group | Yes | — | No | No |
| Manage group / channels | Yes | Yes | No | No |
| Create a channel | Yes | Yes | Only when `allow_member_channels` | No |
| See a standard channel | Yes | Yes | Yes | Yes |
| See a private channel | Yes | Only if added | Only if added | Only if added |
| Post in a channel | Yes | Yes | Yes | Yes (standard only) |
| Start a DM | Yes | — | Yes | Yes |

Workspace owner/admin and **team leads** can create chat groups. Workspace
managers can see every group/channel, but only accrue unread counts for
channels they belong to. DMs and task conversations are visible only to their
explicit members — workspace managers do not get access. Private channels are
managed by their explicit `owner` members; a group owner who was not added to
the private channel can neither see nor manage it.

External participants are explicit `ChatConversationMember` rows without a
workspace membership. They only see the conversations they were invited to;
workspace groups, channels, tasks, people and files remain inaccessible.
Incoming external requests do not appear in the workspace chat list or
workspace unread summary until accepted.

Conversations whose workspace is suspended return `403` to every participant,
and the external list/request endpoints omit them. Task-card fields (`task`)
and `linked_task_ids` created before a group becomes external are omitted from
the external participants' message payloads.

## Conversation kinds

| Kind | Created by | Members |
| --- | --- | --- |
| `channel` | `POST /chat/create-channel/{group_id}/` | All group members (standard) or selected group members (private) |
| `dm` | `POST /chat/start-dm/{workspace_id}/` | Both users; one DM per pair, including external pairs |
| `group` | `POST /chat/create-conversation/{workspace_id}/` | Creator + selected workspace members and accepted external contacts |
| `task` | `POST /chat/start-task-conversation/{task_id}/` | Task assignee, assigner, approver, alternate approver and creator |

External membership is limited to `dm` and `group` conversations. Workspace
chat groups and channels remain internal-only.

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

## Content types

`POST /chat/send-message/{conversation_id}/` is the only
`multipart/form-data` endpoint. All other bodies are JSON.

## Message payload

Most message responses include:

```json
{
  "id": "aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa",
  "conversation_id": "bbbbbbbb-bbbb-4bbb-8bbb-bbbbbbbbbbbb",
  "type": "text",
  "body": "Latest checkout screens are ready",
  "system_event": null,
  "birthday": null,
  "sender": {
    "id": "cccccccc-cccc-4ccc-8ccc-cccccccccccc",
    "email": "sarah@example.com",
    "first_name": "Sarah",
    "last_name": "Johnson",
    "photo": null,
    "job_title": "Product Designer"
  },
  "task": null,
  "attachments": [],
  "mentioned_users": [],
  "linked_task_ids": [],
  "reply_to": null,
  "thread_root_id": null,
  "thread": {
    "reply_count": 3,
    "last_reply_at": "2026-11-01T12:00:00Z",
    "participants": [],
    "last_reply_preview": "Yes, a Slack alert after the third failure."
  },
  "reactions": [
    {
      "emoji": "👍",
      "count": 1,
      "reacted_by_me": true,
      "users": []
    }
  ],
  "is_pinned": false,
  "edited_at": null,
  "seen_by": [],
  "seen_by_count": 0,
  "created_at": "2026-11-01T10:00:00Z",
  "updated_at": "2026-11-01T10:00:00Z"
}
```

- `thread` is only present on root messages.
- `seen_by`/`seen_by_count` are populated for the caller's own messages.
- `linked_task_ids` is parsed from `#TK-123` text using the workspace prefix.
- `attachments[].kind` is `image`, `video`, `audio`, `pdf` or `document`.
- `attachments[].file_url` is for inline previews;
  `attachments[].download_url` is a separately signed URL that saves the file
  with its original name. Both share `expires_at`. See
  `docs/download_integration.md`.
- `type=system` messages do not have a sender and cannot be edited/deleted.
- `type=task` messages include the `task` brief and render as a task card.
- `type=birthday` messages include the `birthday` card payload below. The
  sender's words stay in `body`; previews read `"🎂 Birthday card"`.

### Birthday message payload

```json
{
  "type": "birthday",
  "body": "Happy birthday! Hope today is a good one. 🎉",
  "birthday": {
    "celebrant": {
      "id": "44444444-4444-4444-8444-444444444444",
      "email": "chioma@acme.com",
      "first_name": "Chioma",
      "last_name": "Okafor",
      "photo": null
    },
    "theme": "confetti",
    "sticker": "cake",
    "day": "11-09"
  }
}
```

`theme` is one of `confetti`, `balloons`, `cake`, `fireworks`, `sparkle` or
`bloom`; `sticker` is one of `cake`, `party`, `balloon`, `gift`, `sparkles`,
`bouquet`, `fizz` or `heart`. `day` is `MM-DD` — never a year or an age.
Birthday messages are created by `POST /birthday/send-wish/{user_id}/`; they
are normal messages otherwise (sender, timestamp, reactions, read receipts
and unread counts).

---

# People

## GET `/chat/search-people/{workspace_id}/`

- **Description:** Search every verified user on the platform by name or
  email. Results are flagged as internal (an active member of `workspace_id`)
  or external. The caller is excluded.
- **Query:** `q` (required, at least 2 characters), `page`, `page_size`.

**Sample response item:**

```json
{
  "id": "77777777-7777-4777-8777-777777777777",
  "email": "zara@otherco.com",
  "first_name": "Zara",
  "last_name": "Khan",
  "photo": "https://cdn.example.com/avatars/zara.png",
  "job_title": "Partner Engineer",
  "is_external": true
}
```

- Tokens are matched independently, so `"Zara Khan"` matches a first and last
  name. Email matching is case-insensitive.
- Unverified and deleted users are never returned.
- The endpoint is rate-limited per caller (`429` with `Retry-After` after 120
  requests in a minute) because the directory is global.

---

# Groups

## GET `/chat/list-groups/{workspace_id}/`

- **Description:** List groups visible to the caller.
- **Query:** `search`, `page` (default 1), `page_size` (default 20, max 100).

**Sample response item:**

```json
{
  "id": "11111111-1111-4111-8111-111111111111",
  "workspace_id": "22222222-2222-4222-8222-222222222222",
  "name": "Tech Team",
  "slug": "tech-team",
  "description": "Everyone in engineering and design.",
  "color": "#66c0c0",
  "glyph": "TT",
  "privacy": "public",
  "allow_member_channels": true,
  "project_id": null,
  "created_by": {
    "id": "33333333-3333-4333-8333-333333333333",
    "email": "chioma@example.com",
    "first_name": "Chioma",
    "last_name": "Okafor",
    "photo": null,
    "job_title": "Tech Lead"
  },
  "my_role": "owner",
  "is_member": true,
  "member_count": 5,
  "channel_count": 2,
  "unread_count": 3,
  "mention_count": 1,
  "created_at": "2026-10-30T09:00:00Z",
  "updated_at": "2026-10-30T09:00:00Z"
}
```

---

## POST `/chat/create-group/{workspace_id}/`

- **Auth:** Workspace owner/admin or a team lead.
- **Description:** Create a group, its `General` channel and the creator's
  owner membership. At least one other member is required.

**Payload:**

```json
{
  "name": "Tech Team",
  "description": "Everyone in engineering and design.",
  "color": "#66c0c0",
  "glyph": "TT",
  "privacy": "public",
  "allow_member_channels": true,
  "project_id": null,
  "members": [
    { "user_id": "44444444-4444-4444-8444-444444444444", "role": "owner" },
    { "user_id": "55555555-5555-4555-8555-555555555555", "role": "member" }
  ]
}
```

**Response:** `201` with group detail (`members` and `channels` included).
The `General` channel contains a system message recording the creation.

---

## GET `/chat/get-group/{group_id}/`

- **Description:** Group detail with `members` and visible `channels`.

---

## PUT `/chat/update-group/{group_id}/`

- **Auth:** Workspace manager or group owner.
- **Payload:** any subset of `name`, `description`, `color`, `glyph`,
  `privacy`, `allow_member_channels`, `project_id`.

---

## DELETE `/chat/delete-group/{group_id}/`

- **Auth:** Workspace manager or group owner.
- **Description:** Soft-delete the group and all of its channels.
- **Response:** `{ "message": "Chat group deleted successfully." }`

---

## POST `/chat/join-group/{group_id}/`

- **Description:** Join a public group. Workspace managers may also join a
  private group. Returns the group detail.

---

## POST `/chat/leave-group/{group_id}/`

- **Description:** Leave a group. Private-channel memberships in the group
  are removed. The last owner cannot leave (`400`).

---

## POST `/chat/add-group-member/{group_id}/`

- **Auth:** Workspace manager or group owner.
- **Payload:**

```json
{
  "user_ids": ["44444444-4444-4444-8444-444444444444"],
  "role": "member"
}
```

- **Response:** updated group detail.

---

## PATCH `/chat/set-group-member-role/{group_id}/{membership_id}/`

- **Auth:** Workspace manager or group owner.
- **Payload:** `{ "role": "owner" }` or `{ "role": "member" }`
- **Rules:** the last owner cannot be demoted (`400`).

---

## DELETE `/chat/remove-group-member/{group_id}/{membership_id}/`

- **Auth:** Workspace manager or group owner.
- **Rules:** the last owner cannot be removed (`400`).

---

# Channels

## GET `/chat/list-channels/{group_id}/`

- **Description:** Paginated list of channels visible to the caller.
- **Query:** `search`, `page`, `page_size`.

Each item is a conversation summary with `kind=channel`, `is_private`,
`unread_count`, `mention_count`, `last_message` and the caller's state.

---

## POST `/chat/create-channel/{group_id}/`

- **Auth:** Workspace manager, group owner, or any group member when
  `allow_member_channels=true`.
- **Payload:**

```json
{
  "name": "Design review",
  "description": "Mockups and feedback",
  "is_private": true,
  "member_ids": ["44444444-4444-4444-8444-444444444444"]
}
```

- **Rules:**
  - Channel names are unique within a group (case-insensitive).
  - Private channels require at least one selected group member; the creator
    is added automatically.
- **Response:** `201` with conversation detail.

---

## PUT `/chat/update-channel/{channel_id}/`

- **Auth:** Workspace manager or group owner.
- **Payload:** `{ "name": "..." }`, `{ "description": "..." }`, or both.

---

## DELETE `/chat/delete-channel/{channel_id}/`

- **Auth:** Workspace manager or group owner.
- **Response:** `{ "message": "Channel deleted successfully." }`

---

# Conversations

## GET `/chat/list-conversations/{workspace_id}/`

- **Description:** List every conversation visible to the caller, sorted by
  the latest main-feed message. Incoming external requests are excluded until
  accepted; accepted external conversations appear for workspace members who
  participate in them.
- **Query:**
  - `kind` — `channel`, `dm`, `group`, `task`
  - `filter` — `all` (default), `unread`, `mentions`, `tasks`
  - `search` — title, group name, task title or message body
  - `page`, `page_size`

**Sample response item:**

```json
{
  "id": "bbbbbbbb-bbbb-4bbb-8bbb-bbbbbbbbbbbb",
  "workspace_id": "22222222-2222-4222-8222-222222222222",
  "kind": "dm",
  "title": null,
  "description": null,
  "is_private": false,
  "group": null,
  "task": null,
  "peer": {
    "id": "44444444-4444-4444-8444-444444444444",
    "email": "tunde@example.com",
    "first_name": "Tunde",
    "last_name": "Bakare",
    "photo": null,
    "job_title": "Backend Engineer"
  },
  "member_count": 2,
  "member_preview": [],
  "is_external": false,
  "request_status": "none",
  "requested_by": null,
  "requested_at": null,
  "responded_at": null,
  "last_message": {
    "id": "aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa",
    "type": "text",
    "body": "Morning",
    "preview": "Morning",
    "sender": null,
    "created_at": "2026-11-01T10:00:00Z"
  },
  "unread_count": 1,
  "mention_count": 0,
  "is_muted": false,
  "mentions_only": false,
  "is_pinned": false,
  "last_read_at": "2026-11-01T09:55:00Z",
  "last_read_message_id": "aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa",
  "created_at": "2026-11-01T09:00:00Z",
  "updated_at": "2026-11-01T10:00:00Z"
}
```

For `kind=channel`, `group` contains `{id, name, glyph, color}`.
For `kind=task`, `task` contains the task brief and `title` defaults to the
task title.

---

## POST `/chat/start-dm/{workspace_id}/`

- **Payload:** `{ "user_id": "44444444-4444-4444-8444-444444444444" }`
- **Description:** Start or reopen the one-to-one DM for the pair. Calling it
  again returns the same conversation. Self-DMs are rejected (`422`).
- **Workspace members:** the DM lives in this workspace and behaves exactly as
  before.
- **External users:** when the target has no membership in this workspace, the
  DM is stored in the caller's workspace with `is_external=true` and
  `request_status="none"`. An external pair always shares one DM, even when
  each side starts from a different workspace.
- **Suspended members:** a person with a non-active membership in the
  workspace is rejected (`422`); they are not treated as an external contact.
- If an external contact later becomes an active workspace member,
  `start-dm` uses the normal workspace DM; the older external conversation
  remains available in `list-external-conversations`.
- Reopening a **declined** external DM starts a fresh conversation with
  `request_status="none"` so either side can send a new request. Messages
  from the declined conversation stay hidden from the person who declined;
  the requester keeps read access to the old conversation through
  `list-external-conversations`.

**Response:** conversation detail. External responses include `is_external`,
`request_status`, `requested_by`, `requested_at` and `responded_at`.

---

## GET `/chat/list-chat-requests/`

- **Description:** Paginated inbox of the caller's pending incoming external
  chat requests. Outgoing requests are not listed here.
- **Query:** `page`, `page_size`.

**Sample response item:**

```json
{
  "conversation": {
    "id": "bbbbbbbb-bbbb-4bbb-8bbb-bbbbbbbbbbbb",
    "workspace_id": "22222222-2222-4222-8222-222222222222",
    "kind": "dm",
    "peer": {
      "id": "44444444-4444-4444-8444-444444444444",
      "email": "alice@acme.com",
      "first_name": "Alice",
      "last_name": "Sender",
      "photo": null,
      "job_title": "Designer"
    },
    "is_external": true,
    "request_status": "pending",
    "requested_by": { "...": "ChatPersonRead" },
    "requested_at": "2026-11-12T09:00:00Z",
    "last_message": null,
    "unread_count": 0,
    "mention_count": 0,
    "created_at": "2026-11-12T08:59:00Z",
    "updated_at": "2026-11-12T09:00:00Z"
  },
  "requester": {
    "id": "44444444-4444-4444-8444-444444444444",
    "email": "alice@acme.com",
    "first_name": "Alice",
    "last_name": "Sender",
    "photo": null,
    "job_title": "Designer"
  },
  "requested_at": "2026-11-12T09:00:00Z"
}
```

`conversation.last_message` is always `null` for a pending request: the
messages are not visible until acceptance.

---

## POST `/chat/accept-chat-request/{conversation_id}/`

- **Description:** Accept an external DM request. Only the recipient can
  accept; the requester receives a `chat_request_accepted` notification.
  Accepting is idempotent.
- **Response:** conversation detail with `request_status="accepted"`. The
  queued messages (including the first one) become visible immediately.

---

## POST `/chat/decline-chat-request/{conversation_id}/`

- **Description:** Decline an external DM request. Only the recipient can
  decline. The requester can still read the messages they sent; neither side
  can send until `start-dm` starts a fresh conversation. The declined messages
  are never revealed to the recipient without a new acceptance.
- **Response:** conversation detail with `request_status="declined"`.

---

## GET `/chat/list-external-conversations/`

- **Description:** Cross-workspace list of the caller's external DMs and
  ad-hoc group chats. This is the external participant's equivalent of
  `list-conversations/{workspace_id}/`.
- **Query:**
  - `kind` — `dm` or `group`
  - `filter` — `all` (default), `unread`, `mentions`
  - `search` — title or message body
  - `page`, `page_size`
- **Visibility:** accepted conversations appear for every member. Pending and
  declined DMs appear only for the person who sent the request. Incoming
  pending requests live in `list-chat-requests` instead.
- **Response:** each item is a `ChatConversationSummary`; `workspace_id` is
  the workspace that stores the conversation.

---

## GET `/chat/get-external-unread-summary/`

- **Description:** Unread and mention counters across the caller's external
  conversations. Muted conversations are excluded.
- **Response:** the standard `ChatUnreadSummary` envelope
  (`total_unread`, `total_mentions`, `items`).

---

## POST `/chat/create-conversation/{workspace_id}/`

- **Description:** Create an ad-hoc group chat.
- **Payload:**

```json
{
  "kind": "group",
  "title": "Launch room",
  "member_ids": [
    "44444444-4444-4444-8444-444444444444",
    "55555555-5555-4555-8555-555555555555"
  ]
}
```

- `title` is optional; it defaults to the members' first names.
- The creator becomes the chat owner and can rename/remove members.
- `member_ids` may include external people only after the caller has an
  **accepted** external DM with each of them. The conversation is then stored
  with `is_external=true`. Workspace chat groups and channels do not accept
  external members.

---

## POST `/chat/start-task-conversation/{task_id}/`

- **Description:** Create or return the conversation for a task. The caller
  must be able to view the task. Participants are the assignee, assigner,
  approver, alternate approver and creator.
- **Behaviour:** existing `TaskActivity` rows are copied in as system messages
  on first creation. Future start/submit/return/approve/complete events are
  appended automatically while the conversation exists. Once created, the
  conversation can only be opened by its participants (`403` otherwise); other
  task viewers cannot self-join.

---

## GET `/chat/get-conversation/{conversation_id}/`

- **Description:** Conversation detail with `members`, `can_manage`,
  `my_role`, state and the latest message.
- External fields: `is_external`, `request_status`, `requested_by`,
  `requested_at`, `responded_at`. For a pending request the recipient sees
  the requester and the request state, but `last_message` is `null` and the
  unread counters are zero.

---

## PUT `/chat/update-conversation/{conversation_id}/`

- **Description:** Rename an ad-hoc group chat.
- **Payload:** `{ "title": "Launch war room" }`

---

## POST `/chat/add-conversation-member/{conversation_id}/`

- **Description:** Add members to an ad-hoc group chat (any member) or a
  private channel (group owner/manager).
- **Payload:** `{ "user_ids": ["44444444-4444-4444-8444-444444444444"] }`
- **External members:** group chats accept external IDs only when the caller
  has an accepted external DM with that person. Private channels remain
  internal-only. Adding an external member sets `is_external=true`; removing
  the last external member clears it.

---

## DELETE `/chat/remove-conversation-member/{conversation_id}/{user_id}/`

- **Description:** Remove a member from a group chat (the owner or the member
  themselves) or a private channel (group owner/manager or the member
  themselves).

---

## POST `/chat/mark-read/{conversation_id}/`

- **Payload:** `{}` or `{ "message_id": "..." }`
- **Description:** Mark read up to a message (defaults to the latest message).
  Returns the updated conversation detail.

---

## POST `/chat/mark-unread/{conversation_id}/`

- **Payload:** `{ "message_id": "aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa" }`
- **Description:** Mark the conversation unread from that message.

---

## PUT `/chat/update-conversation-state/{conversation_id}/`

- **Payload:**

```json
{
  "is_muted": false,
  "mentions_only": true,
  "is_pinned": true
}
```

`is_muted` and `mentions_only` are mutually exclusive; the last value wins.

---

## GET `/chat/get-unread-summary/{workspace_id}/`

- **Description:** Workspace-wide counters for the navigation badge. Muted
  conversations are excluded.

```json
{
  "total_unread": 4,
  "total_mentions": 1,
  "items": [
    { "conversation_id": "bbbbbbbb-bbbb-4bbb-8bbb-bbbbbbbbbbbb", "unread": 2, "mentions": 1 }
  ]
}
```

---

# Messages

## GET `/chat/list-messages/{conversation_id}/`

- **Description:** Main-feed messages (thread replies excluded).
- **Query:** `search`, `order` (`asc` or `desc`, default `desc`), `page`,
  `page_size`.

`order=desc` returns the newest page first; reverse the items client-side
when rendering the feed.

---

## POST `/chat/send-message/{conversation_id}/`

- **Content type:** `multipart/form-data`
- **Fields:**

| Field | Type | Required | Notes |
| --- | --- | --- | --- |
| `body` | string | No | Up to 10,000 characters |
| `attachments` | file[] | No | Up to 10 files; normal upload size limit |
| `mentioned_user_ids` | UUID[] | No | Repeated form field; validated against conversation access |
| `reply_to_id` | UUID | No | Quote a message in the same conversation |
| `thread_root_id` | UUID | No | Reply in a thread; defaults `reply_to_id` to the root |
| `also_send_to_channel` | bool | No | With `thread_root_id`, also posts a main-feed copy quoting the root |
| `task_id` | UUID | No | Post a task card; the task must be visible to the caller |

- **Rules:** a message needs a body, an attachment or a task. Mentions are
  limited to people who can read the conversation. `#TK-123` references are
  parsed into `linked_task_ids` in internal conversations only.
- **External DM request:** the first message in an external DM sets
  `request_status=pending`, records `requested_by`, and sends the recipient a
  `chat_request` notification. The recipient cannot read or send messages
  until accepting. Additional messages written by the requester before
  acceptance stay hidden and do not create more notifications.
- **External restrictions:** `task_id` is rejected (`422`). Declined external
  DMs reject sending (`403`) until `start-dm` resets the request.

**Response:**

```json
{
  "message": { "...": "ChatMessageRead" },
  "channel_message": null
}
```

`channel_message` is populated when `also_send_to_channel=true`.

---

## PATCH `/chat/edit-message/{message_id}/`

- **Auth:** Message author.
- **Payload:** `{ "body": "Updated text" }`
- Sets `edited_at`, re-parses `#TK-123` task references and returns the
  message. Mentions cannot be changed by an edit; `mentioned_user_ids` keeps
  the IDs supplied when the message was sent.

---

## DELETE `/chat/delete-message/{message_id}/`

- **Auth:** Author, or a channel/group owner/manager for channel/group chats.
- **Description:** Soft-delete the message. Deleting a thread root also
  deletes its replies.
- **Response:** `{ "message": "Message deleted successfully." }`

---

## POST `/chat/toggle-reaction/{message_id}/`

- **Payload:** `{ "emoji": "👍" }`
- Adds the reaction when absent and removes it when present. Returns the
  updated message with aggregated `reactions`.

---

## PATCH `/chat/pin-message/{message_id}/`

- **Payload:** `{ "pinned": true }`
- **Description:** Pin/unpin a main-feed message. Returns the updated message.

---

## GET `/chat/list-pinned-messages/{conversation_id}/`

- **Description:** Paginated pinned messages.

---

## GET `/chat/list-thread-replies/{message_id}/`

- **Description:** Paginated replies for a thread. Passing a reply id resolves
  its root first.

---

## GET `/chat/list-conversation-files/{conversation_id}/`

- **Description:** Files shared in the conversation (Files tab).
- **Query:** `kind` (`image`, `video`, `audio`, `pdf`, `document`), `search`,
  `page`, `page_size`.

Each item is an attachment plus `sender` (the message author).

---

## GET `/chat/list-linked-tasks/{conversation_id}/`

- **Description:** Tasks referenced by task cards or `#TK-123` text. Only
  tasks visible to the caller are returned. Items use the standard
  `TaskRead` payload. External conversations always return an empty page.

---

## POST `/chat/create-task/{conversation_id}/`

- **Description:** Create a task and post its card in the conversation.
- **Payload:**

```json
{
  "message_id": null,
  "title": "Review checkout errors",
  "description": "Inline errors and focus management",
  "assignee_id": "44444444-4444-4444-8444-444444444444",
  "due_date": "2026-11-05",
  "priority": "high",
  "project_id": null,
  "team_id": null,
  "milestone_id": null
}
```

When `message_id` is supplied, the message body becomes the default title
(if `title` is omitted) and description (if `description` is omitted), and the
message sender becomes the default assignee. If the channel's group has a
project and neither `project_id` nor `team_id` is supplied, the task is
created in that project. Otherwise it is a standalone task.

External conversations reject this endpoint (`422`): tasks and task cards are
workspace objects and are never exposed across organizations. If an existing
internal group with task cards later gains an external member, the `task`
payload and `linked_task_ids` are omitted from the external participant's
messages.

**Response:**

```json
{
  "task": { "...": "TaskRead" },
  "message": { "...": "ChatMessageRead" }
}
```

---

## GET `/chat/search-messages/{workspace_id}/`

- **Description:** Search messages across every conversation the caller can
  read.
- **Query:** `q` (required), `page`, `page_size`.

**Sample response item:**

```json
{
  "message": { "...": "ChatMessageRead" },
  "conversation": {
    "id": "bbbbbbbb-bbbb-4bbb-8bbb-bbbbbbbbbbbb",
    "kind": "channel",
    "title": "General",
    "group_name": "Tech Team",
    "peer": null,
    "task_reference": null
  }
}
```

---

# Notifications

Chat activity creates in-app notifications when:

- The caller is mentioned (`chat_mention`; uses the `mention` preference).
- A new message arrives in a DM, group chat or task conversation
  (`chat_message`; uses the `chat` preference).
- An external DM's first message creates a `chat_request` notification on
  the recipient's standard bell. Accepting it creates a
  `chat_request_accepted` notification for the requester.
- `chat_message` notifications are skipped for muted conversations and for
  `mentions_only` conversations unless the member is mentioned.
- Messages written before an external request is accepted do not create
  `chat_message` notifications.
- Standard-channel chatter does not create per-message notifications; unread
  and mention badges cover it.
- Thread replies notify the root sender and prior thread participants rather
  than the entire channel.

External participants are not members of the conversation's workspace, so
their chat notifications are stored in their **primary workspace** (the first
workspace they own, otherwise their earliest active membership). A
notification's `workspace_id` is therefore not always the conversation's
workspace: use `conversation_workspace_id`, `conversation_id`,
`conversation_kind` and `conversation_title` from `NotificationRead` to open
the right chat.

`NotificationRead` includes `conversation_id`, `conversation_kind`,
`conversation_title` and `conversation_workspace_id`.

Sending a birthday card (`POST /birthday/send-wish/{user_id}/`) creates a
`chat_message` notification reading
`"{Sender name} sent you a birthday card 🎂"` and carrying the DM
conversation id, unless the recipient muted the conversation or chose
mentions-only.


---

## Poll messages

Messages may have `type: "poll"`. The `poll` field on a message contains:

```json
{
  "id": "11111111-1111-4111-8111-111111111111",
  "question": "Tea or coffee?",
  "options": [{"id": "...", "label": "Tea", "votes": 3}],
  "multiple": false,
  "closed": false,
  "my_votes": ["..."]
}
```

Create and vote through the [poll endpoints](polls_docs.md); when
`conversation_id` is supplied to `POST /poll/create-poll/`, a poll message is
posted automatically and `GET /chat/list-messages/{conversation_id}/` returns
it with this payload.
