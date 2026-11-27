# Church API Documentation

Source: `tms/church/routers.py`

**Prefix:** `/church`

Church data is available in a `specials` workspace with subtype `church`.
All endpoints require `Authorization: Bearer <JWT>` and active workspace
membership. Church admins are workspace owners/admins; unit leaders can also
manage their own unit's notices, duties and chat link.

The first `GET /church/get-church/` creates the default funds (`Tithes`,
`Offerings`, `Building fund`, `Welfare`). All church collections are stored in
normalized tables; no JSON documents are used.

## GET `/church/get-church/{workspace_id}/`

```json
{
  "name": "Victory Chapel",
  "services": [],
  "funds": [
    {
      "id": "11111111-1111-4111-8111-111111111111",
      "name": "Tithes",
      "kind": "tithe",
      "target": null,
      "description": null,
      "deadline": null,
      "builtin": true
    }
  ],
  "giving": [],
  "pledges": [],
  "units": [],
  "prayers": [],
  "first_timers": [],
  "can_manage": true
}
```

Private prayers are omitted unless the caller is an admin or the author.

## POST `/church/action/{workspace_id}/`

Every action returns the full `ChurchRead` payload above.

### Services

| Action | Payload |
| --- | --- |
| `save_service` | `service`: `{id?, title, date, time?, venue?, minister?, theme?, scripture?}` |
| `delete_service` | `id` |
| `set_roster` | `id`, `roster`: `[{role, person_id?, name?}]` |
| `record_attendance` | `id`, `attendance`: `{men, women, children, online, first_timers}` |

### Giving and funds

| Action | Payload |
| --- | --- |
| `record_giving` | `giving`: `{fund_id, amount, method, date, member_id?, name?, service_id?, note?}` |
| `delete_giving` | `id` |
| `save_fund` | `id?`, `name`, `kind`, `target?`, `description?`, `deadline?` |
| `delete_fund` | `id` (built-in `tithe`/`offering` funds cannot be deleted) |
| `add_pledge` | `fund_id`, `member_ids`, `name?`, `amount`, `due?` |
| `pay_pledge` | `id`, `amount` |

### Units

| Action | Payload |
| --- | --- |
| `save_unit` | `id?`, `name`, `icon?`, `description?`, `meets?` |
| `delete_unit` | `id` |
| `unit_members` | `id`, `leader_id?`, `member_ids` |
| `unit_notice` | `id`, `text`, `urgent?` |
| `remove_unit_notice` | `id`, `notice_id` |
| `set_unit_chat` | `id`, `chat_id?` |
| `add_duty` | `id`, `date`, `duty`, `person_id?` |
| `remove_duty` | `id`, `duty_id` |

### Prayer and follow-up

| Action | Payload |
| --- | --- |
| `add_prayer` | `text`, `private?`, `anonymous?`, `name?` (any member) |
| `pray` | `id` (toggles the caller's prayer support; any member) |
| `answer_prayer` | `id`, `testimony?` |
| `add_first_timer` | `first_timer`: `{name, phone?, email?, came_with?, first_visit, interest?}` |
| `first_timer_stage` | `id`, `stage` (`new`, `contacted`, `visited`, `class`, `member`) |
| `first_timer_assign` | `id`, `follow_up_id?` |
| `first_timer_note` | `id`, `text` |

### Example

```json
{
  "action": "record_giving",
  "giving": {
    "fund_id": "11111111-1111-4111-8111-111111111111",
    "amount": 50000,
    "method": "transfer",
    "date": "2026-11-19",
    "name": "Anonymous"
  }
}
```
