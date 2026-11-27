# External Chat Frontend Integration Guide

Companion to [`chat_docs.md`](chat_docs.md). This guide covers messaging with
people outside the current workspace: finding them, sending the first message,
the chat-request acceptance flow, cross-workspace conversation lists and
notifications.

All routes use the API base URL and require
`Authorization: Bearer <JWT>`. List endpoints return the standard envelope:

```json
{
  "items": [],
  "total": 0,
  "page": 1,
  "page_size": 20,
  "total_pages": 0
}
```

**Realtime note:** there is still no WebSocket/typing/presence API. Poll the
request inbox, external conversation list and unread summary (see §8).

---

## 1. What "external" means

A person is **external** when they do not have an active
`WorkspaceMembership` in the workspace the caller is searching from.
`is_external` is computed per request:

```ts
type PeopleSearchItem = {
  id: string;
  email: string;
  first_name: string | null;
  last_name: string | null;
  photo: string | null;
  job_title: string | null;
  is_external: boolean; // true => outside this workspace
};
```

External chats are stored in the **initiator's** workspace. The external
participant is an explicit conversation member, not a workspace member, so
they only see the conversations they were invited to. Workspace tasks,
projects, people, channels and chat groups are never exposed.

Supported external conversations:

| Kind | External members |
| --- | --- |
| `dm` | Yes, one pair |
| `group` | Yes, ad-hoc group chats only |
| `channel` | No |
| `task` | No |

Workspace chat groups (`ChatGroup`) and their channels remain internal-only.

---

## 2. Screen map

| Screen / component | Endpoints |
| --- | --- |
| New chat / people picker | `GET /chat/search-people/{workspace_id}/?q=...` |
| Start a DM | `POST /chat/start-dm/{workspace_id}/` |
| Chat request inbox | `GET /chat/list-chat-requests/` |
| Request actions | `POST /chat/accept-chat-request/{conversation_id}/`, `POST /chat/decline-chat-request/{conversation_id}/` |
| External chat list | `GET /chat/list-external-conversations/` |
| External unread badge | `GET /chat/get-external-unread-summary/` |
| Chat feed / composer | `GET /chat/list-messages/{conversation_id}/`, `POST /chat/send-message/{conversation_id}/` |
| Conversation header / details | `GET /chat/get-conversation/{conversation_id}/` |
| Group member picker | `POST /chat/add-conversation-member/{conversation_id}/`, `POST /chat/create-conversation/{workspace_id}/` |
| Notifications bell | `GET /notification/list-notifications/{workspace_id}/`, `POST /notification/mark-read/{notification_id}/` |

Backend route names (for generated clients):
`chat:search-people`, `chat:start-dm`, `chat:list-chat-requests`,
`chat:accept-chat-request`, `chat:decline-chat-request`,
`chat:list-external-conversations`, `chat:external-unread-summary`,
`chat:list-messages`, `chat:send-message`, `chat:get-conversation`.

---

## 3. Find people

`GET /chat/search-people/{workspace_id}/?q=zara&page=1&page_size=20`

- `q` is required and must be at least 2 characters.
- Matches first name, last name and email; tokens are matched independently
  (`"Zara Khan"` works).
- The caller, deleted users and unverified accounts are excluded.
- Rate limit: 120 requests per minute per user (`429` with `Retry-After`).
- Group the results client-side by `is_external`: **My organization** and
  **External**.
- Show the avatar (`photo` or initials), full name, `job_title` and email.

```ts
type PeopleSearchResponse = PaginatedResponse<PeopleSearchItem>;
```

---

## 4. Start an external DM

`POST /chat/start-dm/{workspace_id}/`

```json
{ "user_id": "44444444-4444-4444-8444-444444444444" }
```

- For an active workspace member this is the existing internal DM flow.
- For an external user the server creates (or returns) the single DM shared
  by the pair, stored in the caller's workspace.
- Starting the DM **does not** notify the other person yet. The first message
  does.
- Calling `start-dm` again from either side returns the same conversation
  (unless the previous request was declined; see below).
- Reopening a declined external DM starts a **new** conversation with a new
  `id`; the messages from the declined chat are never shown to the person who
  declined. The requester can still read the old conversation from their
  external chat list.
- A suspended/inactive workspace member cannot be reached as an external
  contact (`422`).
- If the person later becomes an active workspace member, `start-dm` returns
  the normal workspace DM; the previous external conversation stays in the
  external chat list.

Open the returned conversation immediately and show the composer. The
conversation detail carries:

```ts
type ExternalConversationState = {
  is_external: boolean;
  request_status: "none" | "pending" | "accepted" | "declined";
  requested_by: ChatPerson | null;
  requested_at: string | null;
  responded_at: string | null;
};
```

---

## 5. First message → chat request

Send the first message normally:

`POST /chat/send-message/{conversation_id}/` (`multipart/form-data`)

When the conversation is an external DM and `request_status` is `none`, the
server atomically:

1. creates the message;
2. sets `request_status="pending"` and `requested_by` to the sender;
3. sends the recipient a `chat_request` notification:
   `"{Sender name} sent you a chat request"`.

Behaviour to render:

- The sender sees their own messages normally while pending.
- The recipient sees the request (conversation header, peer, sender name) but
  `last_message` is `null`, `unread_count` is `0`, and both
  `GET /chat/list-messages/` and `POST /chat/send-message/` return `403`.
- Additional sender messages before acceptance are queued and hidden. They do
  not create extra notifications.
- The recipient can still fetch the conversation detail to render the
  accept/decline prompt.

Suggested sender UI while pending: a small "Waiting for acceptance" banner in
the header.

---

## 6. Chat requests inbox

`GET /chat/list-chat-requests/?page=1&page_size=20`

Returns only **incoming pending** requests. Outgoing requests are not listed.

```ts
type ChatRequest = {
  conversation: ConversationSummary; // last_message is null, unread_count 0
  requester: ChatPerson;             // sender name/photo/email
  requested_at: string;
};
```

Render:

- requester avatar + name;
- `requester.job_title` or `requester.email` as the subtitle;
- time (`requested_at`);
- **Accept** and **Decline** buttons.

### Accept

`POST /chat/accept-chat-request/{conversation_id}/`

- Only the recipient can call it; the requester gets `403`.
- Idempotent: accepting an already accepted conversation returns the detail.
- The requester receives a `chat_request_accepted` notification.
- Immediately load the feed; all queued messages are now visible.

### Decline

`POST /chat/decline-chat-request/{conversation_id}/`

- Only the recipient can call it.
- The requester keeps read access to messages they already sent; the
  recipient cannot read or send.
- Neither side can send until `start-dm` is called again. That call creates a
  brand-new conversation, so the declined messages stay hidden from the
  recipient until they accept a fresh request.

Remove declined requests from the inbox. A declined outgoing DM can show a
"Declined" state in the chat list, or be hidden until the user starts it
again.

---

## 7. External chat list and unread badges

External participants are not members of the workspace that stores the
conversation, so they cannot use
`GET /chat/list-conversations/{workspace_id}/` for those chats. Use:

`GET /chat/list-external-conversations/`

Query:

| Param | Values | Notes |
| --- | --- | --- |
| `kind` | `dm`, `group` | Optional |
| `filter` | `all` (default), `unread`, `mentions` | Server-side |
| `search` | text | Title or message body |
| `page`, `page_size` | ints | Defaults 1 / 20, max 100 |

Visibility:

- accepted conversations appear for all members;
- pending/declined DMs appear only for the person who sent the request;
- incoming pending requests are only in the request inbox;
- each item is a `ConversationSummary` with `workspace_id` set to the
  workspace that stores the conversation.

Unread badge:

`GET /chat/get-external-unread-summary/`

```json
{
  "total_unread": 2,
  "total_mentions": 1,
  "items": [
    { "conversation_id": "…", "unread": 2, "mentions": 1 }
  ]
}
```

Add `total_unread` to the external / "Outside organization" chat section and
combine it with the existing workspace badge if the UI shows one global Chat
badge.

---

## 8. Notifications

Request and message notifications for external chats use the standard
notification bell. The notification is stored in the recipient's **primary
workspace** (first owned workspace, otherwise earliest active membership),
while the conversation belongs to another workspace.

`NotificationRead` now includes:

```ts
{
  conversation_id: string | null;
  conversation_kind: "channel" | "dm" | "group" | "task" | null;
  conversation_title: string | null;
  conversation_workspace_id: string | null; // use this for the chat context
}
```

Rendering:

| Notification kind | UI |
| --- | --- |
| `chat_request` | Accept / Decline prompt; open request inbox or conversation detail |
| `chat_request_accepted` | "Accepted" toast/row; open the conversation feed |
| `chat_message` | Normal chat row; open `conversation_id` |
| `chat_mention` | Mention row; open `conversation_id` |

Always open external conversations by `conversation_id`
(`GET /chat/get-conversation/{conversation_id}/`), not by
`notification.workspace_id`. Poll the notification endpoints for the
recipient's primary workspace as usual. The request inbox remains the
authoritative list even if the bell row was dismissed or missed.

---

## 9. External group chats

Once an external DM request is **accepted**, both people can add each other
to ad-hoc group chats.

### Create a group

`POST /chat/create-conversation/{workspace_id}/`

```json
{
  "kind": "group",
  "title": "Partner launch room",
  "member_ids": ["<workspace-member-id>", "<external-id>"]
}
```

- Workspace members are always allowed.
- External IDs are accepted only when the caller has an accepted external DM
  with each person (`422` otherwise).
- The response has `is_external=true`; external members receive the group in
  `GET /chat/list-external-conversations/`.

### Add someone to an existing group

`POST /chat/add-conversation-member/{conversation_id}/`

```json
{ "user_ids": ["<external-id>"] }
```

- Any group member may add people to an ad-hoc group chat.
- External IDs require an accepted DM **with the caller**.
- Private channels remain internal-only.
- Adding an external person sets `is_external=true`; removing the last
  external member clears it.

### Group picker rules

- Fetch workspace members with
  `GET /workspace/list-members/{workspace_id}/?search=...` when the caller is
  a workspace member.
- Fetch external contacts with `GET /chat/search-people/{workspace_id}/` and
  filter `is_external === true`.
- An external participant adding people can only add their accepted contacts
  (and people already in the group); the API returns `422` otherwise.
- Let the server be the source of truth: attempt the add and surface `422`
  as "You need an accepted chat request with this person first."

### Limitations in external chats

- Task cards and `#TK-123` references are disabled for new messages;
  `POST /chat/create-task/` and `send-message` with `task_id` return `422`.
- Task cards and `linked_task_ids` from before a group became external are
  omitted from the external participant's message payloads.
- `GET /chat/list-linked-tasks/` returns an empty page.
- Workspace chat groups and channels cannot include external members.
- Files, threads, reactions, pins, read state and mentions work normally.

---

## 10. Message and member shapes

Conversation summaries/details add:

```ts
type ConversationExternalFields = {
  is_external: boolean;
  request_status: "none" | "pending" | "accepted" | "declined";
  requested_by: ChatPerson | null;
  requested_at: string | null;
  responded_at: string | null;
};
```

`ConversationDetail` also includes `members[].user` with external people when
the conversation has them.

---

## 11. Polling

| Data | Endpoint | Suggested interval |
| --- | --- | --- |
| Pending requests | `GET /chat/list-chat-requests/` | 15–30 s |
| External chats | `GET /chat/list-external-conversations/` | 15 s |
| External badge | `GET /chat/get-external-unread-summary/` | 10–15 s |
| Notification bell | `GET /notification/get-unread-count/{workspace_id}/` | 15 s |
| Open conversation feed | `GET /chat/list-messages/{conversation_id}/?order=desc&page=1` | 5 s |

- Pause polling when the tab is hidden.
- After accept/decline/send, refresh the request inbox, external list, unread
  summary and the affected feed immediately.
- Merge messages by `id`; never replace the feed while the user is scrolled up.

---

## 12. Error handling

| Status | Meaning |
| --- | --- |
| `403` | Message history is pending acceptance; only the recipient can accept/decline; declined chat cannot send; the conversation's workspace is suspended |
| `404` | Conversation/request no longer exists |
| `422` | Invalid request; external group member is not an accepted contact; task card in an external chat; search query too short |
| `429` | Too many people-search requests; retry after `Retry-After` seconds |
| `401` | Session expired |

Suggested messages:

- Pending: **"Accept this chat request in your inbox to start messaging."**
- Declined: **"This chat request was declined. Start a new chat to try again."**
- No connection: **"You need an accepted chat request with this person before adding them to a group."**

---

## 13. Minimal flow

```ts
// 1. Find an external person
const people = await api.get(
  `/chat/search-people/${workspaceId}/?q=${encodeURIComponent(query)}`,
);
const external = people.items.filter((p) => p.is_external);

// 2. Open the DM
const conversation = await api.post(`/chat/start-dm/${workspaceId}/`, {
  user_id: external[0].id,
});

// 3. Send the first message
const form = new FormData();
form.append("body", "Hi! Can we talk about the integration?");
const sent = await api.post(
  `/chat/send-message/${conversation.id}/`,
  form,
);
// conversation.request_status is now "pending"

// 4. Recipient side: accept from the request inbox
const requests = await api.get("/chat/list-chat-requests/");
const request = requests.items[0];
await api.post(
  `/chat/accept-chat-request/${request.conversation.id}/`,
);

// 5. Both sides can now message and add each other to group chats.
await api.get("/chat/list-external-conversations/");
await api.get("/chat/get-external-unread-summary/");
```
