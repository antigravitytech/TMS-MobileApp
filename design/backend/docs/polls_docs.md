# Poll API Documentation

Source: `tms/polls/routers.py`

**Prefix:** `/poll`

Polls can stand alone in a workspace or be posted into a chat conversation.
All endpoints require `Authorization: Bearer <JWT>` and active workspace
membership. Chat-linked polls are visible through
`GET /chat/list-messages/{conversation_id}/` as messages of type `poll`.

## GET `/poll/list-polls/{workspace_id}/`

Paginated. Query: `page`, `page_size`, optional `conversation_id`.

```json
{
  "items": [
    {
      "id": "11111111-1111-4111-8111-111111111111",
      "question": "Tea or coffee?",
      "options": [
        {"id": "22222222-2222-4222-8222-222222222222", "label": "Tea", "votes": 3},
        {"id": "33333333-3333-4333-8333-333333333333", "label": "Coffee", "votes": 1}
      ],
      "multiple": false,
      "created_by": {"id": "...", "email": "...", "first_name": "...", "last_name": "...", "photo": null},
      "created_at": "2026-11-19T13:00:00Z",
      "closes_on": null,
      "closed": false,
      "conversation": null,
      "my_votes": ["22222222-2222-4222-8222-222222222222"],
      "voters": 4,
      "audience": 12,
      "is_owner": true,
      "responses": []
    }
  ],
  "total": 1,
  "page": 1,
  "page_size": 50,
  "total_pages": 1
}
```

`responses` is only populated for the creator or a workspace manager.

## GET `/poll/get-poll/{poll_id}/`

Returns one poll in the same shape.

## POST `/poll/create-poll/{workspace_id}/`

```json
{
  "question": "Tea or coffee?",
  "options": ["Tea", "Coffee"],
  "multiple": false,
  "conversation_id": null,
  "closes_on": null
}
```

When `conversation_id` is set, the caller must be a conversation member and a
chat message of type `poll` is created automatically.

## POST `/poll/vote-poll/{poll_id}/`

```json
{"option_ids": ["22222222-2222-4222-8222-222222222222"]}
```

Replaces the caller's previous votes. A single-choice poll rejects more than
one option.

## POST `/poll/close-poll/{poll_id}/`

Closes the poll. Only the creator or a workspace manager can close it.

## DELETE `/poll/delete-poll/{poll_id}/`

Soft-deletes the poll. Only the creator or a workspace manager can delete it.
