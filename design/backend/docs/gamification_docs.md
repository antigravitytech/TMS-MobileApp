# Gamification API Documentation

Source: `tms/gamification/routers.py`

**Prefix:** `/gamification`

Gamification tracks points, streaks, badges and the workspace leaderboard.
Awarding is automatic when a task is approved and is controlled by workspace
toggles:

```json
{
  "points": true,
  "badges": true,
  "board": true
}
```

Update the toggles with `PUT /gamification/update-settings/{workspace_id}/`.

## Award rules

- Each approved task awards **+20 points** to the assignee.
- Consecutive daily approvals increase the streak; a gap resets it to 1.
- Default badges: first-time-right ×5, 7-day streak, early bird, zero overdue
  month and 100 tasks.

All endpoints require `Authorization: Bearer <JWT>` and an active workspace
membership.

---

## GET `/gamification/get-profile/{workspace_id}/{user_id}/`

### Sample response

```json
{
  "user": {
    "id": "44444444-4444-4444-8444-444444444444",
    "email": "tunde@example.com",
    "first_name": "Tunde",
    "last_name": "Bakare",
    "photo": null
  },
  "points": 1240,
  "streak": 12,
  "level": 3,
  "points_to_next_level": 260,
  "badges": [
    {
      "key": "first_time_right_5",
      "name": "First-time right ×5",
      "description": "First-time right ×5",
      "icon": "target",
      "earned": true,
      "awarded_at": "2026-10-20T10:00:00Z"
    }
  ]
}
```

`level` is `points // 500 + 1`; `points_to_next_level` is the remaining
points before the next level.

---

## GET `/gamification/leaderboard/{workspace_id}/`

- **Query:** `limit` (default 5, max 50).

```json
[
  {
    "user": {
      "id": "44444444-4444-4444-8444-444444444444",
      "email": "tunde@example.com",
      "first_name": "Tunde",
      "last_name": "Bakare",
      "photo": null
    },
    "points": 1240,
    "streak": 12,
    "rank": 1
  }
]
```

---

## PUT `/gamification/update-settings/{workspace_id}/`

- **Auth:** Owner/admin.

```json
{
  "points": true,
  "badges": false,
  "board": true
}
```

Returns the stored settings object.

## Points ledger

Every award writes a `PointEntry` row referencing the task and the reason.
The ledger is append-only and is used for audit/export; it is intentionally
not exposed as a mutable endpoint.
