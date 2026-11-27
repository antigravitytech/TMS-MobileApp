# Chat Frontend Integration Guide

Companion to [`chat_docs.md`](chat_docs.md). This is the practical map from
the Taskify Chat prototype (`designs/Taskify-Chat.html`) to the API: which
screen calls which endpoint, what to render, and how to keep state fresh.
External people search, chat requests and cross-workspace conversations are
covered in [`external_chat_integration.md`](external_chat_integration.md).

All routes are under the API base URL, require
`Authorization: Bearer <JWT>`, and use JSON unless noted otherwise. Every
list endpoint returns:

```json
{
  "items": [],
  "total": 0,
  "page": 1,
  "page_size": 20,
  "total_pages": 0
}
```

**Realtime note:** there is no WebSocket/typing/presence API yet. Use polling
(see the end of this guide) and hide the typing indicator and presence dot
until the realtime phase lands. Voice/video calls are intentionally absent.
Voice notes are normal audio attachments.

---

## Screen map

| Screen / component | Endpoints |
| --- | --- |
| App shell / nav badge | `GET /chat/get-unread-summary/{workspace_id}/`, `GET /notification/get-unread-count/{workspace_id}/` |
| Notifications bell/panel | `GET /notification/list-notifications/{workspace_id}/`, `POST /notification/mark-read/{notification_id}/`, `POST /notification/mark-all-read/{workspace_id}/` |
| Chats list | `GET /chat/list-conversations/{workspace_id}/` |
| Groups tree | `GET /chat/list-groups/{workspace_id}/`, `GET /chat/get-group/{group_id}/` |
| Conversation header | `GET /chat/get-conversation/{conversation_id}/` |
| Chat feed | `GET /chat/list-messages/{conversation_id}/` |
| Composer | `POST /chat/send-message/{conversation_id}/`, `PATCH /chat/edit-message/{message_id}/` |
| Message actions | `POST /chat/toggle-reaction/{message_id}/`, `PATCH /chat/pin-message/{message_id}/`, `POST /chat/mark-unread/{conversation_id}/`, `DELETE /chat/delete-message/{message_id}/`, `POST /chat/create-task/{conversation_id}/` |
| Thread panel | `GET /chat/list-thread-replies/{message_id}/`, `POST /chat/send-message/{conversation_id}/` |
| Files tab | `GET /chat/list-conversation-files/{conversation_id}/` |
| Tasks tab | `GET /chat/list-linked-tasks/{conversation_id}/` |
| Pinned tab | `GET /chat/list-pinned-messages/{conversation_id}/` |
| Details panel | `GET /chat/get-conversation/{conversation_id}/`, `GET /chat/get-group/{group_id}/`, `PUT /chat/update-group/{group_id}/`, `PUT /chat/update-conversation-state/{conversation_id}/`, `POST /chat/add-conversation-member/{conversation_id}/`, `DELETE /chat/remove-conversation-member/{conversation_id}/{user_id}/`, `POST /chat/start-dm/{workspace_id}/` |
| Create group modal | `POST /chat/create-group/{workspace_id}/` |
| Create channel modal | `POST /chat/create-channel/{group_id}/`, `GET /chat/get-group/{group_id}/` |
| New chat modal | `POST /chat/start-dm/{workspace_id}/`, `POST /chat/create-conversation/{workspace_id}/`, `GET /chat/search-people/{workspace_id}/?q=...` |
| External requests | `GET /chat/list-chat-requests/`, `POST /chat/accept-chat-request/{conversation_id}/`, `POST /chat/decline-chat-request/{conversation_id}/`, `GET /chat/list-external-conversations/` |
| Create task modal | `POST /chat/create-task/{conversation_id}/` |
| Task drawer / review dialogs | `GET /task/get-task/{task_id}/`, `POST /task/start-task/{task_id}/`, `POST /task/submit-task/{task_id}/`, `POST /task/return-task/{task_id}/`, `POST /task/approve-task/{task_id}/`, `POST /chat/start-task-conversation/{task_id}/` |
| Global search | `GET /chat/search-messages/{workspace_id}/` |
| In-conversation search | `GET /chat/list-messages/{conversation_id}/?search=...` |
| People suggestions | `GET /workspace/list-members/{workspace_id}/?search=...` |
| Task suggestions | `GET /task/list-tasks/{workspace_id}/?search=...&scope=all` |

---

## Core data shapes

### Conversation summary (list rows and headers)

```ts
type ConversationSummary = {
  id: string;                 // channel/dm/group/task conversation id
  workspace_id: string;
  kind: "channel" | "dm" | "group" | "task";
  title: string | null;       // channel name / group chat title / task title
  description: string | null;
  is_private: boolean;        // channels only
  group: { id: string; name: string; glyph: string | null; color: string } | null;
  task: {
    id: string;
    reference: string;        // "TK-142"
    title: string;
    status: string;
    priority: string;
    due_date: string;
    assignee: UserBrief | null;
  } | null;
  peer: ChatPerson | null;    // DM only: the other user
  member_count: number;
  member_preview: ChatPerson[];
  is_external: boolean;       // has participants outside this workspace
  request_status: "none" | "pending" | "accepted" | "declined";
  requested_by: ChatPerson | null;
  requested_at: string | null;
  responded_at: string | null;
  last_message: {
    id: string;
    type: "text" | "system" | "task" | "birthday";
    body: string | null;
    preview: string;          // ready-to-show row preview
    sender: ChatPerson | null;
    created_at: string;
  } | null;
  unread_count: number;
  mention_count: number;
  is_muted: boolean;
  mentions_only: boolean;
  is_pinned: boolean;
  last_read_at: string | null;
  last_read_message_id: string | null;
  created_at: string;
  updated_at: string;
};
```

`GET /chat/get-conversation/{conversation_id}/` returns the same object plus:

```ts
type ConversationDetail = ConversationSummary & {
  can_manage: boolean;        // show channel/group management actions
  my_role: "owner" | "member" | null;
  members: {
    id: string;               // membership id
    user: ChatPerson;
    role: string;
    created_at: string;
  }[];
};
```

### Person

```ts
type ChatPerson = {
  id: string;
  email: string;
  first_name: string | null;
  last_name: string | null;
  photo: string | null;
  job_title: string | null;
};
```

### Message

```ts
type ChatMessage = {
  id: string;
  conversation_id: string;
  type: "text" | "system" | "task" | "birthday";
  body: string | null;
  system_event: string | null;   // created, returned, task_approved, ...
  sender: ChatPerson | null;     // null for system messages
  task: TaskBrief | null;        // type "task"
  birthday: {                    // type "birthday"
    celebrant: ChatPerson;
    theme: string;
    sticker: string;
    day: string;                 // MM-DD, never a year
  } | null;
  attachments: ChatAttachment[];
  mentioned_users: ChatPerson[];
  linked_task_ids: string[];     // parsed #TK-123 references
  reply_to: MessagePreview | null;
  thread_root_id: string | null; // non-null => this is a thread reply
  thread: {
    reply_count: number;
    last_reply_at: string | null;
    participants: ChatPerson[];
    last_reply_preview: string | null;
  } | null;                      // roots only
  reactions: {
    emoji: string;
    count: number;
    reacted_by_me: boolean;
    users: ChatPerson[];         // first 5
  }[];
  is_pinned: boolean;
  edited_at: string | null;
  seen_by: ChatPerson[];         // caller's own messages only
  seen_by_count: number;
  created_at: string;
  updated_at: string;
};
```

`ChatAttachment.kind` is one of `image`, `video`, `audio`, `pdf`,
`document`. `file_url` is a signed B2 URL for inline previews.
`download_url` is a separately signed URL that forces a save with the
original filename. Both expire together; treat them as short lived and refetch
the message/conversation when a preview or download fails. See
`docs/download_integration.md`.

---

## 1. App shell and navigation badge

### Unread badge

`GET /chat/get-unread-summary/{workspace_id}/`

```json
{
  "total_unread": 4,
  "total_mentions": 1,
  "items": [
    { "conversation_id": "…", "unread": 2, "mentions": 1 }
  ]
}
```

- Show `total_unread` on the Chat nav item.
- Show `total_mentions` as the red/mention indicator.
- Muted conversations are excluded from the totals; `items` never includes
  them.
- Poll this every 10–15 seconds while the app is visible, and immediately
  after sending/reading a message.

### Notification bell

- `GET /notification/get-unread-count/{workspace_id}/` → `{ "unread": n }`
- `GET /notification/list-notifications/{workspace_id}/?category=chat`
  returns both chat kinds. Each item includes:

```json
{
  "kind": "chat_message",
  "message": "Tunde: Morning",
  "actor": { "…": "ChatPerson" },
  "conversation_id": "…",
  "conversation_kind": "dm",
  "conversation_title": "Direct message",
  "conversation_workspace_id": "…",
  "is_read": false
}
```

- Clicking a chat notification should open
  `GET /chat/get-conversation/{conversation_id}/`.
- `POST /notification/mark-read/{notification_id}/`
- `POST /notification/mark-all-read/{workspace_id}/`
- Toasts can be driven by polling the unread count/list. There is no push
  channel yet.

---

## 2. Chat list — "Chats" tab

**Endpoint:** `GET /chat/list-conversations/{workspace_id}/`

**Query params**

| Param | Values | Notes |
| --- | --- | --- |
| `filter` | `all` (default), `unread`, `mentions`, `tasks` | Server-side filter |
| `search` | text | Matches title, group name, task title, message body |
| `kind` | `channel`, `dm`, `group`, `task` | Optional kind filter |
| `page`, `page_size` | ints | Defaults 1 / 20, max 100 |

**Reproduce the design sections**

- **Pinned:** `is_pinned === true`
- **Task conversations:** `!is_pinned && kind === "task"`
- **Recent chats:** `!is_pinned && (kind === "dm" || kind === "group")`
- **Pinned channels** also belong in Pinned (`kind === "channel" && is_pinned`).
  Channels are usually shown in the Groups tab instead.

**Row mapping**

- DM: `peer.photo` / initials, `peer.first_name + last_name`. Show
  `peer.job_title` as the subtitle if space allows.
- Group chat: `title` (or fallback names from `member_preview`).
- Channel (pinned): `group.glyph` + `title`.
- Task conversation: clipboard icon; `task.reference` + `title`.
- Last line: `last_message.preview`. Prefix `You:` when
  `last_message.sender.id === currentUser.id` and the conversation is not a
  DM.
- Right meta: `last_message.created_at` (relative), `is_muted` bell-off,
  `is_pinned` pin.
- Badge: `mention_count > 0` → `@` badge; otherwise `unread_count > 0` →
  number. Muted rows can show a grey number.
- Active row: `id === selectedConversationId`.

**Opening a conversation**

1. `GET /chat/get-conversation/{id}/`
2. `GET /chat/list-messages/{id}/?order=desc&page=1&page_size=50`
3. Render messages in reverse order.
4. `POST /chat/mark-read/{id}/` with the newest message id once the feed is
   visible.
5. Refresh the conversations list and unread summary.

`last_read_message_id` from the conversation summary/detail is the message to
place the **New messages** divider *after*. If it is not in the loaded page,
show the divider above the oldest unread message and fetch more pages when
the user scrolls up.

**Row actions**

- Pin/unpin conversation:
  `PUT /chat/update-conversation-state/{id}/` `{ "is_pinned": true }`
- Mute / mentions-only: same endpoint with `is_muted` or `mentions_only`.
  They are mutually exclusive; sending `true` for one clears the other.
- Leave group: `POST /chat/leave-group/{group_id}/`
- Open details: `GET /chat/get-conversation/{id}/`

---

## 3. Chat list — "Groups" tab

### Group tree

`GET /chat/list-groups/{workspace_id}/?search=&page=1&page_size=20`

Group row fields:

- `glyph` and `color` → square avatar.
- `name`, `description`.
- `member_count`, `channel_count`.
- `unread_count`, `mention_count`.
- `my_role` (`owner`/`member`/`null`), `is_member`.
- `privacy` (`public`/`private`), `allow_member_channels`.
- `is_member === false` → show "Not joined".

For an expanded group, fetch its channels and members with:

`GET /chat/get-group/{group_id}/`

Response adds:

```ts
{
  members: [{ id, user, role, created_at }],
  channels: [ConversationSummary, ...]   // kind = "channel"
}
```

Channel rows use `title`, `is_private`, `unread_count`, `mention_count`,
`is_muted`, `is_pinned`, `last_message.preview`.

**Buttons and permissions**

- **Create group:** workspace owner/admin or a team lead. The chat API does
  not expose "am I a team lead?" in the group list; use the current
  workspace/member context if available, otherwise attempt the create and
  handle `403`.
- **Add channel:** show when `my_role === "owner"`, or
  `allow_member_channels === true` (the API also allows workspace
  owner/admin).
- **Group menu:** Join (`POST /chat/join-group/{group_id}/`) or Leave
  (`POST /chat/leave-group/{group_id}/`), Manage group
  (`PUT /chat/update-group/{group_id}/`), Add channel
  (`POST /chat/create-channel/{group_id}/`).
- The last owner cannot leave or be removed (`400`).

---

## 4. Conversation header

Use the selected `ConversationDetail`.

| Kind | Title | Subtitle |
| --- | --- | --- |
| `dm` | `peer` name | `peer.job_title`; presence is not available yet |
| `channel` | `# title` or `🔒 title` | `group.name · {Private · }N members` |
| `group` | `title` | `N members` |
| `task` | task title | `Task conversation · N people` |

- Search icon: toggles the in-conversation search input.
- Details icon: opens the details panel and calls
  `GET /chat/get-conversation/{id}/`.
- For `kind === "task"`, render the task bar from `task`:
  `reference`, `status`, `priority`, `due_date`, `assignee`. Clicking
  "Instructions" calls `GET /task/get-task/{task_id}/`.
- Call buttons from the design have no backend yet; hide or disable them.

---

## 5. Chat feed

**Endpoint:** `GET /chat/list-messages/{conversation_id}/`

**Query params**

| Param | Values | Notes |
| --- | --- | --- |
| `order` | `desc` (default), `asc` | `desc` returns newest page first |
| `search` | text | Matches body, attachment filename, task title |
| `page`, `page_size` | ints | Defaults 1 / 20, max 100 |

Thread replies are **not** returned by this endpoint. Use the thread panel.

**Pagination**

- Initial load: `order=desc&page=1&page_size=50`, then reverse for display.
- Load older: `page=2`, `page=3`, …; prepend the reversed page.
- New messages: poll `page=1&order=desc` and merge unseen ids by `id`
  (do not replace the feed if the user is scrolled up; show a "new
  messages" pill instead).

**Rendering rules**

- `type === "system"`: centered pill, optional icon from `system_event`;
  no avatar, no actions. Examples: `group_created`, `channel_created`,
  `member_added`, `member_removed`, `task_conversation_started`,
  `task_created`, `started`, `submitted`, `returned`, `approved`,
  `completed`, `due_date_changed`.
- `type === "task"`: task card using `task` (`reference`, `title`,
  `status`, `priority`, `due_date`, `assignee`). Open with
  `GET /task/get-task/{task_id}/`.
- Normal text: render the markdown subset (`**bold**`, `_italic_`,
  `` `code` ``, `~~strike~~`), `@name` mentions and `#TK-123` task refs.
  `mentioned_users` gives the mentioned IDs; `linked_task_ids` gives the
  task IDs parsed from the body.
- `reply_to`: quote block above the body. Clicking it should scroll to
  `reply_to.id` if loaded, otherwise fetch more history or ignore.
- `attachments`:
  - `image`: grid (1 image full width, otherwise 2 columns) using `file_url`;
    the download action uses `download_url`.
  - `video`: inline player via `file_url`.
  - `audio`: voice-note bubble with play/pause and duration if you have it.
  - `pdf`/`document`: file card with name, size and a `download_url` link.
- `reactions`: pill list; click calls the toggle endpoint. Show
  `reacted_by_me` styling.
- `thread`: "N replies · last reply …" link; participants are in
  `thread.participants`. Clicking opens the thread panel.
- Own messages: right aligned. Show `seen_by` / `seen_by_count` only for
  messages where `sender.id === currentUser.id`.
- `edited_at` → "(edited)".
- `is_pinned` → pin indicator.
- `thread_root_id !== null` should never appear in the main feed.
- Day separators and the **New messages** divider are client-side.
- Group consecutive messages from the same sender when the gap is under
  5 minutes and the message has no `reply_to`.

**Read state**

- `POST /chat/mark-read/{conversation_id}/` with
  `{ "message_id": "<newest visible message id>" }` (or `{}` to mark the
  latest).
- Call it when the feed is visible at the bottom, after sending, and after
  returning to the tab.
- `POST /chat/mark-unread/{conversation_id}/` with the target
  `{ "message_id": "…" }` from a message's ⋯ menu.
- Refetch the conversation summary after either call to update
  `unread_count`, `mention_count` and `last_read_message_id`.

---

## 6. Composer

**Endpoint:** `POST /chat/send-message/{conversation_id}/`
**Content type:** `multipart/form-data`

| Field | Type | Notes |
| --- | --- | --- |
| `body` | string | Max 10,000 chars; markdown source |
| `attachments` | file[] | Max 10 files; normal upload size limit |
| `mentioned_user_ids` | UUID[] | Repeat the field for each mention |
| `reply_to_id` | UUID | Quote a message |
| `thread_root_id` | UUID | Post a thread reply |
| `also_send_to_channel` | bool | With `thread_root_id`; channel threads only |
| `task_id` | UUID | Post a task card instead of text |

Example:

```ts
const form = new FormData();
if (text.trim()) form.append("body", text);
files.forEach((file) => form.append("attachments", file));
mentions.forEach((id) => form.append("mentioned_user_ids", id));
if (replyToId) form.append("reply_to_id", replyToId);
if (threadRootId) form.append("thread_root_id", threadRootId);
if (alsoSend) form.append("also_send_to_channel", "true");

const response = await fetch(`/chat/send-message/${conversationId}/`, {
  method: "POST",
  headers: { Authorization: `Bearer ${token}` },
  body: form,
});
// response: { message: ChatMessage, channel_message: ChatMessage | null }
```

**Editor state**

- Reply context: set `reply_to_id` and render the quoted preview above the
  composer.
- Edit mode: `PATCH /chat/edit-message/{message_id}/` `{ "body": "..." }`.
  Attachments cannot be changed by edit; ask the user to delete and resend.
- Cancel reply/edit: clear local state; no API call.
- Send is disabled when there is no body, no attachment and no task.
- After send:
  - append `response.message` (and `response.channel_message` when present)
    to the feed;
  - refresh the conversation list and unread summary;
  - clear the draft, reply and attachments.

**Mentions**

Use `GET /workspace/list-members/{workspace_id}/?search=...&page_size=20`
for the suggestion list. Only send IDs of people who can access the
conversation; the server silently drops invalid mentions.

**Task references**

Type `#TK-142` manually or offer
`GET /task/list-tasks/{workspace_id}/?search=...&scope=all&page_size=20`.
The server parses references in the body and stores `linked_task_ids`; the
client still needs to render the token as a link.

**Attachments**

- Accept up to 10 files per message.
- Images are previewed locally before send; everything else shows a file row.
- Audio files are the voice-note path. There is no recording API; record
  with `MediaRecorder`, then attach the resulting audio blob.
- `file_url` and `download_url` in the response may expire; refetch the
  message/conversation when a preview or download fails. Use `file_url` for
  previews and `download_url` for the save action.

---

## 7. Message actions

| UI action | Request | Notes |
| --- | --- | --- |
| 👍 / emoji reaction | `POST /chat/toggle-reaction/{message_id}/` `{ "emoji": "👍" }` | Toggles; response is the updated message |
| Reply | local state | Set `reply_to_id` on the next send |
| Reply in thread | local panel | Open thread, send with `thread_root_id` |
| Create task from message | `POST /chat/create-task/{conversation_id}/` `{ "message_id": "…" }` | Server uses body as title/description and sender as assignee |
| Pin / unpin | `PATCH /chat/pin-message/{message_id}/` `{ "pinned": true }` | Response is the updated message |
| Copy text | client | `navigator.clipboard.writeText(message.body)` |
| Mark unread from here | `POST /chat/mark-unread/{conversation_id}/` `{ "message_id": "…" }` | Then refresh list/unread |
| Edit | `PATCH /chat/edit-message/{message_id}/` `{ "body": "…" }` | Author only |
| Delete | `DELETE /chat/delete-message/{message_id}/` | Author, or channel/group manager |

Permission hints:

- Show Edit/Delete for `message.sender.id === currentUser.id`.
- Show Delete for a manager when `conversationDetail.can_manage === true`
  and the conversation is a channel or group chat.
- Thread replies cannot be pinned (`422`).

---

## 8. Thread panel

1. The root message's `thread` object gives `reply_count`, `last_reply_at`
   and participants. If `thread` is null there are no replies yet.
2. `GET /chat/list-thread-replies/{root_message_id}/?page=1&page_size=50`
   returns replies in ascending order.
3. Send:

```ts
form.append("thread_root_id", rootMessageId);
form.append("body", replyText);
// optional:
form.append("also_send_to_channel", "true");
```

4. When `also_send_to_channel` is true (channels only), the response includes
   `channel_message`; append it to the main feed quoting the root.
5. Refetch the thread and the root message (or at least its `thread` summary)
   after sending.
6. Reactions and edits on replies use the same message endpoints.

The thread composer in the design also has an "Also send to channel"
checkbox; only show it for `conversation.kind === "channel"`.

---

## 9. Tabs: Files, Tasks, Pinned

Lazy-load each tab when selected.

### Files

`GET /chat/list-conversation-files/{conversation_id}/`

Query: `kind` (`image`/`video`/`audio`/`pdf`/`document`), `search`, `page`,
`page_size`.

Each item is an attachment plus `sender` (the message author) and
`message_id`. `file_url` is for previews; `download_url` saves the file.
Both are signed and expiring. This tab includes files from thread replies too.

### Tasks

`GET /chat/list-linked-tasks/{conversation_id}/`

Returns `TaskRead` items. A task is linked when:

- it is the conversation's task (`kind === "task"`),
- a message is a task card (`message.task`),
- or a message body contains `#TK-123`.

Clicking an item opens `GET /task/get-task/{task_id}/`.

### Pinned

`GET /chat/list-pinned-messages/{conversation_id}/`

Returns hydrated `ChatMessage` items. "Jump to message" should load the
main feed and scroll to `message.id`; if it is not loaded yet, fetch older
pages until found.

---

## 10. Details panel

Open from the header. Fetch `GET /chat/get-conversation/{id}/` first.

**Hero / header**

- DM: peer photo/name/title.
- Group/channel: glyph + title + privacy/description.
- Quick actions: mute/unmute and pin/unpin via
  `PUT /chat/update-conversation-state/{id}/`.

**Group section (channels only)**

Call `GET /chat/get-group/{group_id}/` for full details.

- Show privacy, channel count, member count and description.
- If `can_manage` (or group `my_role === "owner"`), show:
  - "Members can create channels" toggle →
    `PUT /chat/update-group/{group_id}/`
    `{ "allow_member_channels": true|false }`
  - "Add channel" → create-channel modal.
  - Member role selector → `PATCH /chat/set-group-member-role/{group_id}/{membership_id}/`
    `{ "role": "owner" | "member" }`.
  - Remove member → `DELETE /chat/remove-group-member/{group_id}/{membership_id}/`.
  - Add people → `POST /chat/add-group-member/{group_id}/`
    `{ "user_ids": [...], "role": "member" }`.

**Linked tasks**

`GET /chat/list-linked-tasks/{conversation_id}/` → open task drawer.

**People**

Use `members[]` from the conversation detail.

- "Message" a person → `POST /chat/start-dm/{workspace_id}/`
  `{ "user_id": "…" }`.
- Add people:
  - group chat or private channel →
    `POST /chat/add-conversation-member/{conversation_id}/`
    `{ "user_ids": [...] }`
  - standard channel → add to the group with `add-group-member`.
- Remove:
  - group chat → `DELETE /chat/remove-conversation-member/{conversation_id}/{user_id}/`
  - private channel → same endpoint (manager or self)
  - standard channel → remove from the group instead.
- Group-member role changes use the group endpoint above; membership ids
  come from `GET /chat/get-group/{group_id}/`.

**Notifications**

`PUT /chat/update-conversation-state/{conversation_id}/`

```json
{ "is_muted": true, "mentions_only": false }
```

- "All messages" → both false.
- "Mentions and task updates only" → `mentions_only: true`.
- "Mute" → `is_muted: true`.
- "Pin conversation" → `is_pinned: true`.

**Files**

Reuse the Files tab endpoint in a compact list.

---

## 11. Modals and creation flows

### Create group

`POST /chat/create-group/{workspace_id}/`

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
    { "user_id": "…", "role": "owner" },
    { "user_id": "…", "role": "member" }
  ]
}
```

- Member picker: `GET /workspace/list-members/{workspace_id}/?search=`.
- At least one member besides the creator is required (`422`).
- Names are unique per workspace (`409`).
- The response is the full group detail including the auto-created
  `General` channel. Add it to the tree and open that channel.

### Create channel

`POST /chat/create-channel/{group_id}/`

```json
{
  "name": "Design review",
  "description": "Mockups and feedback",
  "is_private": true,
  "member_ids": ["…"]
}
```

- Private channels require at least one selected **group** member.
- Names are unique per group (`409`).
- Response is the channel conversation detail; add it to the group tree
  and open it.
- "Add channel" is available to group owners, workspace managers, and any
  group member when `allow_member_channels` is true.

### New chat

- One person: `POST /chat/start-dm/{workspace_id}/`
  `{ "user_id": "…" }` → existing or new DM.
- Multiple people: `POST /chat/create-conversation/{workspace_id}/`

```json
{
  "kind": "group",
  "title": "Launch room",
  "member_ids": ["…", "…"]
}
```

- `title` is optional; the server builds one from first names.
- External people are started with the same `start-dm`/`create-conversation`
  endpoints after an accepted request; see
  [`external_chat_integration.md`](external_chat_integration.md).
- Response is the conversation detail; open it.

### Create task from chat

`POST /chat/create-task/{conversation_id}/`

```json
{
  "message_id": null,
  "title": "Review checkout errors",
  "description": "Inline errors and focus management",
  "assignee_id": "…",
  "due_date": "2026-11-05",
  "priority": "high",
  "project_id": null,
  "team_id": null,
  "milestone_id": null
}
```

- For "create task from this message", send only `{ "message_id": "…" }`;
  the server defaults the title/description from the message and the
  assignee from its sender.
- If the channel's group has a project, it is used unless `project_id` or
  `team_id` is supplied.
- Response:

```json
{
  "task": { "…": "TaskRead" },
  "message": { "…": "ChatMessage" }
}
```

Append `message` to the feed and refresh the Tasks tab.

### Task drawer / approvals

Chat is a lens over the existing task API. The task drawer and review
dialogs use:

- `GET /task/get-task/{task_id}/`
- `POST /task/start-task/{task_id}/`
- `POST /task/submit-task/{task_id}/` `{ "note": "…" }`
- `POST /task/return-task/{task_id}/` `{ "note": "…", "due_date": null, "reason": null }`
- `POST /task/approve-task/{task_id}/` `{ "comment": "…" }`

If the task has a chat conversation (`POST /chat/start-task-conversation/{task_id}/`),
the server appends system messages automatically after these actions.
Refetch the task conversation feed to show them.

---

## 12. Search

### Global message search

`GET /chat/search-messages/{workspace_id}/?q=checkout&page=1&page_size=20`

Response items:

```json
{
  "message": { "…": "ChatMessage" },
  "conversation": {
    "id": "…",
    "kind": "channel",
    "title": "General",
    "group_name": "Customer Portal Revamp",
    "peer": null,
    "task_reference": null
  }
}
```

- Debounce the input (300 ms).
- Clicking a hit opens the conversation, loads messages, and scrolls to
  `message.id`; fetch older pages until the id is found if necessary.
- Search covers messages in every conversation the caller can read.

### In-conversation search

`GET /chat/list-messages/{conversation_id}/?search=checkout&page=1`

- This searches the main feed only; thread replies are not included.
- Show matching messages and a "no matches" state when `total === 0`.

### People / task suggestions

- People: `GET /workspace/list-members/{workspace_id}/?search=...`
- Internal + external people: `GET /chat/search-people/{workspace_id}/?q=...`
  (see [`external_chat_integration.md`](external_chat_integration.md))
- Tasks: `GET /task/list-tasks/{workspace_id}/?search=...&scope=all`

---

## 13. Polling strategy (no WebSocket yet)

| Data | Endpoint | Suggested interval |
| --- | --- | --- |
| Unread nav badge | `GET /chat/get-unread-summary/{workspace_id}/` | 10–15 s |
| Notification count | `GET /notification/get-unread-count/{workspace_id}/` | 15 s |
| Open conversation | `GET /chat/list-messages/{conversation_id}/?order=desc&page=1` | 5 s |
| Chats list | `GET /chat/list-conversations/{workspace_id}/` | 15 s, or on focus |
| Groups tree | `GET /chat/list-groups/{workspace_id}/` | 30 s, or on focus |

- Pause polling when `document.visibilityState === "hidden"`.
- After any mutation (send, react, pin, read, task action), refresh the
  affected conversation, list and unread summary immediately.
- Merge messages by `id` rather than replacing the feed, so scroll position
  and drafts survive polling.

---

## 14. Error handling

| Status | Meaning |
| --- | --- |
| `401` | Expired/invalid JWT; send the user to login |
| `403` | Not a workspace member, no group/channel access, or missing manager role |
| `404` | Conversation/message/group was deleted or never existed |
| `409` | Duplicate group/channel name |
| `422` | Validation error (empty body, too many files, bad private-channel members, etc.) |

- If a conversation returns `404` after being open, close it and remove it
  from the list.
- If a group/channel is deleted, refetch the Groups tree.
- The last group owner cannot leave, be removed or be demoted (`400`).

---

## 15. Minimal boot sequence

```ts
const [workspaceId, conversationId] = [/* from route */];

// App shell
await Promise.all([
  api.get(`/chat/get-unread-summary/${workspaceId}/`),
  api.get(`/notification/get-unread-count/${workspaceId}/`),
  api.get(`/chat/list-groups/${workspaceId}/`),
  api.get(`/chat/list-conversations/${workspaceId}/?filter=all`),
]);

// Open a conversation
const detail = await api.get(`/chat/get-conversation/${conversationId}/`);
const page = await api.get(
  `/chat/list-messages/${conversationId}/?order=desc&page=1&page_size=50`,
);
await api.post(`/chat/mark-read/${conversationId}/`, {
  message_id: page.items[0]?.id ?? null,
});
```
