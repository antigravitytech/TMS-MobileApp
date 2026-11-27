# Backend integration

What each feature reads and writes when the app runs with `DATA_SOURCE=live`, and how mock mode stays offline. The API contract is in `design/backend/docs/`; the web sample (`web_sample/web/src/features/`) shows the same flows in React.

Every integrated feature follows the same layers: screen → Riverpod controller → repository. The repository provider returns the mock or live implementation from `environmentProvider`, so screens and controllers don't change between modes. Live repositories send requests through `NetworkCallsRepository`, which attaches the token and maps errors to `AccountFailure`. A 401 signs the user out through `AccountSession.expire`. Newer controllers wrap requests in `guardSession(ref, …)` from `account_session.dart`.

## Birthdays

**Code:** [`lib/modules/birthdays/`](../lib/modules/birthdays/)

| Layer | File | Role |
|---|---|---|
| Models | `domain/birthday.dart` | `BirthdayPerson` (colleagues, only `MM-DD`), `BirthdayEntry` (calendar entries for people without an account), `BirthdayCalendar`, and the card styles' API `theme` and `sticker` values. |
| Repository | `data/birthdays_repository.dart` with `mock_birthdays_repository.dart` and `live_birthdays_repository.dart` | `BirthdaysRepository` and `birthdaysRepositoryProvider`. |
| Controller | `application/birthdays_controller.dart` | `birthdaysProvider` loads the calendar and leaves the signed-in user out of the colleague list. It sends cards and marks entries, updating the screen in place. `birthdayWorkspaceProvider` gives the workspace: the active live workspace, or the preview. |
| Screen | `presentation/birthdays_screen.dart` with `widgets/birthday_overview.dart` and `widgets/birthday_card_sheet.dart` | Month strip, today's cards, Coming up, and the card sheet, with loading, error ("Try again") and empty states. |

### Mock mode

`MockBirthdaysRepository` returns the prototype's people, dated relative to today. Sent cards and "wished" marks are kept in `WorkspacePreview.birthdayCards`, so other preview screens see them. It makes no network requests.

### Live mode

| Screen action | Endpoint |
|---|---|
| Month strip, Today, Coming up | `GET /birthday/get-calendar/{workspace_id}/` (members and entries) |
| "You!" card and its card count | `GET /birthday/get-feed/{workspace_id}/` (`mine_is_today`, `wishes_received`) |
| Send a card | `POST /birthday/send-wish/{user_id}/` `{ "message", "theme", "sticker" }` |
| Mark as wished | `POST /birthday/celebrate-entry/{entry_id}/` |

- **Card styles:** the sheet's five styles map to confetti/party, cake/cake, bloom/heart, fireworks/sparkles and sparkle/bouquet.
- **Errors:** a broken response is an `AccountFailure` and shows the error state. Live data never falls back to mock data, and provider retry is off.
- **Routing:** `birthdays` is on the live router allowlist.

### Tests

[`test/modules/birthdays/birthdays_test.dart`](../test/modules/birthdays/birthdays_test.dart) covers:

- **Mock:** loading and updating make no network requests.
- **Live loading:** calendar and feed requests, with the caller filtered out.
- **Live actions:** the send-wish body (trimmed message, theme, sticker) and the celebrate call.
- **Live errors:** a broken response shows the error state.

### Not yet integrated

- Your own birthday settings (`GET /birthday/get-my-birthday/`, `PUT /birthday/set-my-birthday/`) and adding, editing or deleting calendar entries (`save-entry`, `delete-entry`). The mobile design has no screens for these.
- Tapping a `birthday_today` notification only marks it read. It doesn't open Birthdays yet.

## Tasks

**Code:** [`lib/modules/tasks/`](../lib/modules/tasks/)

| Layer | File | Role |
|---|---|---|
| Models | `domain/task.dart` | `TaskItem` with typed status, priority, type and the server's permissions. Also people, comments, activity, files, list results, New task options and drafts. |
| Repository | `data/tasks_repository.dart` with `mock_tasks_repository.dart` and `live_tasks_repository.dart` | `TasksRepository` and `tasksRepositoryProvider`. |
| Controllers | `application/tasks_controller.dart` | `tasksListProvider(scope)`, `openedTaskProvider` (opened task plus start, submit and complete), `taskActivityProvider`, `taskCommentsProvider`, `taskFilesProvider`, `taskOptionsProvider` and `createTaskProvider`. |
| Screens | `presentation/tasks_screen.dart`, `task_detail_screen.dart`, `task_forms.dart` and their widgets | Tasks list, task detail and New task. |

**Minimal loading:**

- **Opening a task:** tapping one passes the `TaskItem` to the detail screen. Opening it makes no request; there is no `get-task` call.
- **Tabs:** Activity, Comments and Files each load only when that tab is shown.
- **Actions:** start, submit and complete replace the opened task with the copy the server returns, so nothing is fetched again. The task lists are refreshed in the background.
- **New task:** its options (members, projects, teams) load once per session.

### Mock mode

`MockTasksRepository` adapts the prototype's `WorkspacePreview.tasks`, which Home, Approvals and chat also read, so those screens stay in step. Actions and comments are written back to the preview. In mock mode the opened task follows the preview's selected task, so tasks opened from Home or chat still work. It makes no network requests.

### Live mode

| Screen action | Endpoint |
|---|---|
| Tabs (My tasks, My requests, Team, All) | `GET /task/list-tasks/{workspace_id}/?scope=…&sort_by=due&sort_dir=asc&page_size=100` |
| Tab counts | `GET /task/get-summary/{workspace_id}/` (`tabs`) |
| Activity tab | `GET /task/list-activity/{task_id}/?order=newest` |
| Comments tab / send | `GET /task/list-comments/{task_id}/?order=oldest`, `POST /task/add-comment/{task_id}/` `{ "kind": "general", "body" }` |
| Files tab | `GET /task/list-attachments/{task_id}/` |
| Start / Submit for review / Mark complete | `POST /task/start-task/…`, `POST /task/submit-task/…` `{ "note" }`, `POST /task/complete-task/…` |
| New task options | `GET /workspace/list-members/{workspace_id}/?status=active`, `GET /project/list-projects/…`, `GET /team/list-teams/…` |
| Create | `POST /task/create-task/{workspace_id}/` (one assignee). Recurring tasks are sent as `repeat_frequency: weekdays`, `due_time: 17:00`, matching the design's "every weekday by 5:00 pm". |

**List behaviour:**

- The status chips, the priority and project filters and the sort all apply to the loaded tab, so changing them makes no request.
- Tasks are grouped by their due date: overdue, today, upcoming and done.

**Detail actions:** the main button follows the server's `permissions`: Start task, then Submit for review or Mark complete. Otherwise it shows the state, for example "Waiting for {assigner}".

**Errors:** a failure shows an error state with "Try again", or a toast. Live data never falls back to mock data, and provider retry is off.

**Routing:** `tasks`, `task` and `newTask` are on the live router allowlist.

### Tests

[`test/modules/tasks/tasks_repository_test.dart`](../test/modules/tasks/tasks_repository_test.dart) covers:

- **Mock:** the preview is adapted and actions write back to it.
- **Live lists:** the list query and tab counts.
- **Live detail:** opening a task makes no request, and each tab makes only its own request.
- **Live actions:** the comment body and submitting with the server copy.
- **New task:** options and the create payload.
- **Errors:** a broken list response shows an error, never mock data.

### Not yet integrated

- Reopening a task and changing its due date (`reopen-task`, `change-due-date`) aren't in the mobile design yet. Approve and return are covered under Approvals.
- These aren't in the mobile design yet: editing, deleting, duplicating, moving or reassigning a task; checklist; watchers; links; access requests; saved views; uploading attachments; inline images; more than one assignee; choosing a recurring schedule; milestones.
- The task's chat button and the "⋯ → Open conversation" action still open the mock conversation. In live mode they should call `POST /chat/start-task-conversation/{task_id}/`.
- Lists load up to 100 tasks per tab; there's no paging beyond that yet.
- In mock mode the prototype's fixed due labels ("Wed, 25 Nov") are now read as real dates, so a past one shows as overdue.

## Home (business dashboard)

**Code:** [`lib/modules/home/`](../lib/modules/home/). The live dashboard is `presentation/live_home_screen.dart` plus `widgets/live_business_home.dart`, with `data/live_home_repository.dart` and `application/live_home.dart`.

`HomeScreen` shows the mock dashboard in mock mode and `LiveHomeScreen` in live mode. Unlike the newer modules, this branch is still a check on `environmentProvider` in the widget (see "Not yet integrated").

### Live mode

`LiveHomeRepository.load` requests every section in parallel. A failed section is listed in `failed` and the rest of the dashboard still shows. A 401 signs the user out.

| Section | Endpoint |
|---|---|
| Workspace name, my context | `GET /workspace/get-workspace/{id}/`, `GET /people/my-context/{id}/` |
| Due today / overdue / to review chips | `GET /task/get-summary/{id}/` |
| Due today list | `GET /task/list-tasks/{id}/?scope=mine&due=today&sort_by=due` |
| Coming up | `GET /task/list-tasks/{id}/?scope=mine&due=week&sort_by=due` |
| Awaiting your review | `GET /task/list-approvals/{id}/?sort=oldest&page_size=10` |
| Birthday banner | `GET /birthday/get-feed/{id}/` |
| Daily report | `GET /routine/list-my-routines/{id}/`, `GET /routine/get-routine/{routine_id}/`, `POST /routine/submit-log/{routine_id}/` |
| Team today | `GET /routine/list-summaries/{id}/?days=1` |
| Chat tab badge | `GET /chat/get-unread-summary/{id}/` |
| Bell badge | `GET /notification/get-unread-count/{id}/` |

Home refreshes every 60 s while it's on screen and the app is in the foreground. Pull to refresh also reloads it.

**Shared actions:** Home doesn't keep its own copies of these actions.

| Action | Goes through | What else happens |
|---|---|---|
| Approve or return a review card | `TasksRepository.approve` / `returnTask` | The Approvals queue and task lists refresh. |
| Send a card from the birthday banner | `BirthdaysRepository.sendWish` | Uses the API's default card: no message, `confetti`, `cake`. |

**Navigation:**

- **Due today and Coming up cards:** open the task detail with the row Home already loaded, through `taskItemFromJson`. No request is made.
- **Section links:** "View all" opens Tasks, and "Open queue" opens Approvals.
- **Bottom tabs:** My tasks and Approvals open those screens. Chat opens Chat, and More opens Account.

### Tests

- [`test/modules/home/live_dashboard_test.dart`](../test/modules/home/live_dashboard_test.dart):
  - every section is requested with the workspace scope;
  - a failed section leaves the rest of the dashboard showing;
  - a 401 signs the user out;
  - the conversation list is no longer requested.
- [`test/modules/home/live_home_actions_test.dart`](../test/modules/home/live_home_actions_test.dart): review decisions and birthday cards go through the Tasks and Birthdays endpoints, and a dashboard task opens without a request.

### Not yet integrated

- Moving the mock/live switch into a repository, as the other modules do. Today `HomeScreen` checks `environmentProvider` itself, and the live dashboard reads raw JSON through `LiveHomeData`.
- **Mock-only parts:**
  - the search bar and "Summaries" link wait for the Search and Reports modules;
  - the team summary card in live mode is a plain "{submitted} of {total}" line, not the design's avatar card.
- **Other workspace kinds:** the live home for non-business workspaces (`live_space_dashboard.dart`) isn't in this business-role pass.

## Approvals

**Code:** [`lib/modules/approvals/`](../lib/modules/approvals/), using the Tasks repository (`TasksRepository.approvals`, `submissionNote`, `approve` and `returnTask`).

| Layer | File | Role |
|---|---|---|
| Model | `tasks/domain/task.dart` | `ReviewQueue`: submitted tasks plus the average review time and this week's approved and returned counts. `TaskItem` also carries `submittedAt`, `round` and `fileCount`. |
| Controller | `application/approvals_controller.dart` | `approvalsProvider` loads the queue. `approve` and `returnTask` remove the card and update the counters locally. `reviewNoteProvider(task)` loads one card's submission note. |
| Screen | `presentation/approvals_screen.dart` with `widgets/review_card.dart` and `widgets/review_actions.dart` | Stats row, sort and filter chips, the swipeable card, and the Return sheet. |

**Minimal loading:**

- **Queue and stats:** loaded once.
- **Decisions:** approving or returning removes the card and updates the counters locally; the queue isn't fetched again.
- **Submission note:** `TaskRead` doesn't carry the note, so `get-task` is called only for the card on screen.
- **Open task:** passes the task to the detail screen, so it opens without a request.
- **Filters:** the people and project choices come from the tasks in the queue, and sorting is done on the loaded queue.

### Mock mode

The queue is `WorkspacePreview.reviewQueue`, adapted to `TaskItem`. The counters start from the prototype's 2 approved and 5 returned, and an average of 5.3h. Decisions go through `WorkspacePreview.review`, so Home sees them. It makes no network requests.

### Live mode

| Screen action | Endpoint |
|---|---|
| Queue | `GET /task/list-approvals/{workspace_id}/?sort=oldest&page_size=100` |
| Stats (avg review, approved, returned) | `GET /task/get-summary/{workspace_id}/` (`review`) |
| Card note | `GET /task/get-task/{task_id}/` (`latest_submission_note`) |
| Approve (swipe right or button) | `POST /task/approve-task/{task_id}/` `{ "comment": "" }` |
| Return (swipe left or button, then the sheet) | `POST /task/return-task/{task_id}/` `{ "note" }`. The note is the chosen reason chips plus the typed text. The API requires a note, so the button stays disabled until there is one. |

**Errors:**

- If a decision fails, the card animates back and a toast shows the error, so the decision can be tried again.
- A queue that fails to load shows an error with "Try again".

**Routing:** `approvals` is on the live router allowlist.

### Tests

[`test/modules/approvals/approvals_test.dart`](../test/modules/approvals/approvals_test.dart) covers:

- **Mock:** the queue comes from the preview and a decision updates it.
- **Live queue:** the queue query, stats mapping, and the note request for one card only.
- **Live decisions:** approve and return payloads, with no refetch afterwards.
- **Failure:** a failed decision keeps the card.

### Not yet integrated

- A closing comment when approving, moving the due date when returning, and filtering by approver on the server. The mobile design doesn't have these.
- The queue loads up to 100 tasks, with no paging beyond that yet.

## Projects

**Code:** [`lib/modules/projects/`](../lib/modules/projects/)

| Layer | File | Role |
|---|---|---|
| Models | `domain/project.dart` | `ProjectItem` has health, owner, optional plan mode, progress, accepted rate and the next milestone. `ProjectMilestone` works out the working days late. |
| Repository | `data/projects_repository.dart` with `mock_projects_repository.dart` and `live_projects_repository.dart` | `ProjectsRepository` and `projectsRepositoryProvider`. |
| Controller | `application/projects_controller.dart` | `projectsProvider` loads the list. `create` appends the new project and refreshes New task's project picker. |
| Screen | `presentation/projects_screen.dart` with `widgets/project_card.dart` and `widgets/project_widgets.dart` | Health filter chips, expandable project cards and the New project sheet. |

**Minimal loading:**

- **List:** one request fills every card: health, owner, next milestone, progress and acceptance.
- **New project:** added to the list without a reload.
- **Plan mode:** not fetched per card. The mode tag shows only when it's known (mock data). In live mode it's hidden, because only `get-plan` returns it and that call creates a plan when a project has none.

### Mock mode

`MockProjectsRepository` returns the design's four projects, with milestones dated around today, so lateness and forecasts read as in the design. New projects last for the session. It makes no network requests.

### Live mode

| Screen action | Endpoint |
|---|---|
| Project cards and filter counts | `GET /project/list-projects/{workspace_id}/?page_size=100` |
| New project | `POST /project/create-project/{workspace_id}/` `{ "name" }` (the server fills in the other fields) |

**Card mapping:**

| Card element | Source |
|---|---|
| Health tag | `health` |
| Owner avatar | `owner` |
| Tasks done | `stats.progress` |
| Accepted | `stats.first_time_right_rate` |

**Promise line:** taken from `next_milestone`.

- **Late milestone:** "Next promise · {name} · {n} working days late". Working days are counted Monday to Friday.
- **On time:** "Next promise · {name} · {due}".
- **Expanded card:** shows "Promised {due}". A forecast date is added only when one is known (mock).

**Errors:** a failure shows an error with "Try again", or a toast when creating. Live data never falls back to mock data.

**Routing:** `projects` is on the live router allowlist.

### Tests

[`test/modules/projects/projects_test.dart`](../test/modules/projects/projects_test.dart) covers:

- **Lateness:** working days late skip weekends.
- **Mock:** listing and creating make no network requests.
- **Live list:** one request maps every card field.
- **Live create:** the new project joins the list without a reload.
- **Errors:** a broken response shows an error, never mock data.

### Not yet integrated

- **Card buttons:** Tasks, Files and Chat open the general screens. Filtering Tasks by project (`list-tasks?project_id=`), a project's files, and its chat aren't wired yet.
- **Not in the mobile design:** project detail, plan, members, milestones, editing, deleting, templates and leave, and the extra create fields (team, owner, dates, visibility).
- **Live-only gaps:** there's no "On track" filter chip (the design shows only Off track and At risk), and the plan mode tag doesn't show.
- **Paging:** the list loads up to 100 projects.

## Teams

**Code:** [`lib/modules/teams/`](../lib/modules/teams/)

| Layer | File | Role |
|---|---|---|
| Models | `domain/team.dart` | `TeamItem` (name, lead, colour, member count, weekly progress), `TeamMember` (lead flag, open tasks) and `TeamDirectory`. |
| Repository | `data/teams_repository.dart` with `mock_teams_repository.dart` and `live_teams_repository.dart` | `TeamsRepository` and `teamsRepositoryProvider`. |
| Providers | `application/teams_controller.dart` | `teamsProvider` and `teamMembersProvider(team)`. |
| Screen | `presentation/teams_screen.dart` with `widgets/team_card.dart` | Expandable team cards with members. |

**Minimal loading:**

- **Teams:** one request loads every team card.
- **Members:** a team's members load only when its card is expanded. The screen keeps every opened team's members, so collapsing and reopening a card doesn't fetch again.

### Mock mode

`MockTeamsRepository` returns the design's Tech Team and Compliance. The preview user leads Tech Team and shows their job title. It makes no network requests.

### Live mode

| Screen action | Endpoint |
|---|---|
| Team cards and the "N teams in {workspace}" caption | `GET /team/list-teams/{workspace_id}/?page_size=100` |
| Expanded members, with "N open" | `GET /team/list-members/{team_id}/?page_size=100` (`role`, `in_progress_tasks`) |
| Tap a member | `ChatRepository.start` → `POST /chat/start-dm/{workspace_id}/`, then opens the conversation |

- **Card mapping:**
  - "This week · N% complete" is `stats.weekly_progress`.
  - The icon colour is the team's `color`.
  - The lead is listed first.
- **Mock members:** tapping a prototype person reopens their sample thread.

**Errors:** the list shows an error with "Try again". A failed member list shows "Try again" inside the card.

**Routing:** `teams` is on the live router allowlist.

### Tests

[`test/modules/teams/teams_test.dart`](../test/modules/teams/teams_test.dart) covers:

- **Mock:** teams and members load with no network requests.
- **Live:** a single list request maps every card field, and members load per opened team with the lead first and open counts.

### Not yet integrated

- **Lead's job title:** `list-members` doesn't include it, so live leads read "Team lead" only.
- **Not in the mobile design:** creating, editing or deleting teams, adding or removing members, lanes, and the other team stats (on-time, first-time-right, rework).
- **Paging:** teams and members load up to 100 each.

## Attendance

**Code:** [`lib/modules/attendance/`](../lib/modules/attendance/). It uses `lib/core/services/location_service.dart` for the device position.

| Layer | File | Role |
|---|---|---|
| Models | `domain/attendance.dart` | `DayStatus`, `AttendanceToday` (status, record, place, schedule window, holiday), `AttendanceRecord`, `AttendanceStats`, `BoardEntry`, `Weather`, and `AttendanceRefused`, which carries the server's reason. |
| Repository | `data/attendance_repository.dart` with `mock_attendance_repository.dart` and `live_attendance_repository.dart` | `AttendanceRepository` and `attendanceRepositoryProvider`. |
| Controllers | `application/attendance_controller.dart` | `attendanceTodayProvider` (clock in and out), `attendanceMonthProvider`, `attendanceHistoryProvider`, `attendanceBoardProvider` and `attendanceWeatherProvider`. |
| Screen | `presentation/attendance_screen.dart` with `widgets/attendance_clock.dart`, `attendance_widgets.dart` and `attendance_lists.dart` | Today, History and Team tabs. |

**Location:**

- `LocationService` (package `geolocator`) asks for when-in-use permission at clock-in and waits up to 12 seconds for a fix.
- If location is off or refused, it sends `lat`/`lng` as `null`. The server then decides, and only refuses when the workspace has a location check.
- The location permissions are declared in `AndroidManifest.xml` (fine and coarse) and in `Info.plist` (`NSLocationWhenInUseUsageDescription`).

**Minimal loading:**

- **Today tab:** loads today and the month, plus the weather when the workplace has a location.
- **History and Team:** each loads only when its tab is opened.
- **Clock in or out:** today is replaced with the server's response. The month, history and board refresh in the background.

### Mock mode

`MockAttendanceRepository` covers today, the month's punctuality and calendar, history, the team board and the weather (29°, partly cloudy).

- **Dates:** everything is dated within the current month.
- **Clocking:** uses `WorkspacePreview.setAttendance`, after the design's short "Checking location" pause.
- **Network:** it makes no network requests.

### Live mode

| Screen action | Endpoint |
|---|---|
| Today card (status, record, place, holiday, arrival window) | `GET /attendance/get-today/{workspace_id}/` |
| Weather tag | `GET /attendance/get-weather/{workspace_id}/?lat=&lng=` using the first location's centre. Hidden when there's no location or the provider is unavailable (503). |
| Clock in / out | `POST /attendance/clock-in/…` / `clock-out/…` `{ "lat", "lng", "accuracy_m" }` |
| Your month (punctuality ring, counts, calendar, usual arrival/leaving, time logged, late arrivals of limit) | `GET /attendance/get-stats/{workspace_id}/?period=month` |
| History | `GET /attendance/list-records/{workspace_id}/?page_size=30`, plus the month's absent days from `get-stats` |
| Team | `GET /attendance/list-board/{workspace_id}/` (a plain array) |

**Refusals:** a 403 or 409 on clock-in or clock-out throws `AttendanceRefused` with the server's `detail`. The toast shows it word for word, as the integration guide says (for example "You're 1.2 km from Head office…"). Other failures show the translated network error.

**Routing:** `attendance` is on the live router allowlist.

### Tests

[`test/modules/attendance/attendance_test.dart`](../test/modules/attendance/attendance_test.dart) covers:

- **Mock:** clock in and out without the network.
- **Live mapping:** today, weather, stats, history and board responses.
- **Clock-in:** sends the device position.
- **Refusals:** a refusal surfaces the server's sentence.
- **Weather:** hidden when unavailable.

### Not yet integrated

- **Not in the mobile design:** the Settings tab (hours, locations, Wi-Fi, holidays, exemptions), the clock-in note, history filters and CSV export, and picking another person or date on the board.
- **Time zone:** times are shown in the device's time zone. The guide says to use the workspace time zone when it differs.
- **Board polling:** the board doesn't poll (the guide suggests every 30 s); it refreshes when the tab is reopened or after clocking.
- **Paging:** History loads the latest 30 records.

## Reports & Performance

**Code:** [`lib/modules/reports/`](../lib/modules/reports/)

| Layer | File | Role |
|---|---|---|
| Models | `domain/report.dart` | `DailyReport`, `ReportField` (whose `role` matches done, plan or blockers from the label, as the server does), `TeamReports`/`TeamReport`, `ReportPeriod`, `Performance`/`PerfMetric`. |
| Repository | `data/reports_repository.dart` with `mock_reports_repository.dart` and `live_reports_repository.dart` | `ReportsRepository` and `reportsRepositoryProvider`. |
| Controllers | `application/reports_controller.dart` | `dailyReportProvider` (send), `teamReportsProvider` and `performanceProvider((team, period))`. |
| Screens | `presentation/reports_screen.dart` (`widgets/report_form.dart`, `team_summaries.dart`) and `performance_screen.dart` (`widgets/performance_widgets.dart`, `performance_charts.dart`) | Reports (Log today, Team summaries) and Performance (Me, My team). |

**Report form:**

- **Layout:** the routine's fields fill the design's slots. "Done" fields come first, then "next/plan" with the "Tomorrow's focus" hint. The "blockers" field sits behind the "I'm blocked" toggle, and any other field follows.
- **Field types:** choice and rating fields use chips.
- **Send:** stays disabled until every required field shown has an answer.

**Minimal loading:**

- **Log today:** `list-my-routines` finds today's report, then a single `get-routine` loads its questions. Sending marks the report sent locally, with no reload.
- **Team summaries:** load only when that tab is opened.
- **Performance:** one overview call per scope and period, cached while the screen is open.

### Mock mode

`MockReportsRepository` keeps every value the design shows:

- the prefilled report;
- "For Ibrahim Musa";
- the project chips and "+10 points";
- Tunde, David, Amaka and Sarah, with Nudge;
- the Me and Team metric cards;
- the level card, thermometer, weekly bars and "Needs attention".

Sending uses `WorkspacePreview.sendReport`, so Home sees it. It makes no network requests.

### Live mode

| Screen action | Endpoint |
|---|---|
| Log today | `GET /routine/list-my-routines/{workspace_id}/` (the first `report` routine: title, `due_time`, current occurrence, `can_log`, whether it's logged), then `GET /routine/get-routine/{routine_id}/` for its fields |
| Send report | `POST /routine/submit-log/{routine_id}/` `{ "occurrence_date", "answers" }` (keyed by field id; number and rating are sent as numbers) |
| Team summaries | `GET /routine/team-status/{workspace_id}/?occurrence_date=today` (names, sent, late and the "N of M sent" header) and `GET /routine/list-summaries/{workspace_id}/?days=1` (done and blockers), joined by user id |
| Performance | `GET /report/get-overview/{workspace_id}/?scope=me\|team&preset=This Week\|This Month\|Last Month\|This Quarter` |

**Performance mapping:**

| Screen element | Source |
|---|---|
| Period range | `period` |
| Me tab cards | `completed`, `on_time_rate`, `recurring_compliance` (Daily reports), `first_time_right_rate` |
| My team tab cards | `completed`, `on_time_rate`, `first_time_right_rate`, `average_rounds` |
| Card caption | `delta` (▲/▼, "pts" for percentages). Fewer rework rounds counts as better. |
| Thermometer | `saved_days` |
| Bars | `weekly` |
| Needs attention | `attention` |

**Routing:** `reports` and `performance` are on the live router allowlist.

### Tests

[`test/modules/reports/reports_test.dart`](../test/modules/reports/reports_test.dart) covers:

- **Field roles:** matched from the label.
- **Mock:** the report, team and performance load with no network requests, and sending marks the report sent.
- **Live report:** the routine and its fields load in two requests, and submit-log sends the answers.
- **Live team:** status and summaries join correctly.
- **Live performance:** the overview query and mapping.

### Not yet integrated

- **Mock only:**
  - **Nudge:** there's no reminder endpoint, so it only appears in mock mode.
  - **Project chips:** reports have no project field in the API.
  - **"+N points":** comes from gamification.
  - **Level card:** comes from gamification (`gamification_docs.md`).
- **Me tab:** the design's "on-time streak" and "punctuality" aren't overview metrics. Live shows the overview's own metrics instead; punctuality is in Attendance.
- **Team cards:** there's no per-person "N% this month · streak" line in live (it would need `get-person` for each person).
- **Export for appraisal:** still opens Profile. `GET /report/export-appraisal/` returns a CSV that needs a file save or share service.
- **Not in the mobile design:** reviewing or reacting to reports (`review-log`, `react-summary`), catch-up days and attachments.

## Files

**Code:** [`lib/modules/files/`](../lib/modules/files/). It uses `MediaService.pickFiles` for picking files and `TasksRepository.byId` to open a file's task.

| Layer | File | Role |
|---|---|---|
| Models | `domain/file_item.dart` | `FileItem` (name, kind, size, uploader, task, project, date, download URL), `FileKind` and `PickedFile`. |
| Repository | `data/files_repository.dart` with `mock_files_repository.dart` and `live_files_repository.dart` | `FilesRepository`, `filesRepositoryProvider` and `fileKindOf`. |
| Controller | `application/files_controller.dart` | `filesProvider` loads the library. `upload` adds the new files at the top. |
| Screen | `presentation/files_screen.dart` with `widgets/file_list_widgets.dart` | Type chips, the project and owner chips, file rows and upload. |

**Minimal loading:**

- **Library:** one request fills the list.
- **Filters:** the type, project and owner chips filter the loaded files. The project and owner choices come from those files.
- **Uploads:** join the list without a reload.
- **Opening a task:** the file row only knows the task's id, title and reference. That isn't enough for an accurate detail screen, so tapping a row calls `get-task` once, then opens the task.

### Mock mode

`MockFilesRepository` returns the design's seven files on Customer Portal Revamp tasks, dated around today. Uploads last for the session. It makes no network requests.

### Live mode

| Screen action | Endpoint |
|---|---|
| File list | `GET /file/list-files/{workspace_id}/?page_size=100` |
| Upload (Photos or Browse, then choose one of my open tasks) | `POST /file/upload-file/{workspace_id}/` (multipart `task_id` and `file`, one request per file) |
| Tap a file | `GET /task/get-task/{task_id}/`, then the task detail |

**Row mapping:**

| Row element | Source |
|---|---|
| Badge | the extension; colour by `kind` |
| Subtitle | task title |
| Details line | `uploaded_by.first_name` · `created_at` · `file_size` |
| Project filter | `project` (or `team`) |

**Routing:** `files` is on the live router allowlist.

### Tests

[`test/modules/files/files_test.dart`](../test/modules/files/files_test.dart) covers:

- **Kinds:** a file's kind from its name.
- **Mock:** the list and upload make no network requests.
- **Live list:** one request maps every row field.
- **Live upload:** sends multipart with the task id and file name.
- **Tapped file:** loads its task by id.

### Not yet integrated

- **Download:** the download icon is decorative. Opening or saving `download_url` needs the download flow in `download_integration.md` and a save or open service.
- **Server-side filters:** filters run on the client; `kind`, `project_id` and `uploader_id` filtering and search aren't used.
- **Not in the mobile design:** file stats, inline image uploads (`/file/upload/`), and the upload policy check.
- **Paging:** the list loads up to 100 files.

## Journal

**Code:** [`lib/modules/journal/`](../lib/modules/journal/)

| Layer | File | Role |
|---|---|---|
| Models | `domain/note.dart` | `JournalNote`, `NoteDraft` and `noteColors`, which lists the design's six colours by API name. |
| Repository | `data/journal_repository.dart` with `mock_journal_repository.dart` and `live_journal_repository.dart` | `JournalRepository` and `journalRepositoryProvider`. |
| Controller | `application/journal_controller.dart` | `journalProvider` loads the notes; `create` and `togglePin` change them. The list stays pinned first, then most recently changed, as the server orders it. |
| Screen | `presentation/journal_screen.dart` | Filter chips, note cards, pinning and the compose sheet. |

**Minimal loading:**

- **List:** one request loads the notes.
- **Filters:** All, Pinned, Reminders and Recent (changed in the last 7 days) filter the loaded notes.
- **Create and pin:** each replaces or adds the server's copy, with no reload.

### Mock mode

`MockJournalRepository` returns the design's four notes, with Tunde's birthday reminder set for tomorrow. New notes and pins last for the session. It makes no network requests.

### Live mode

| Screen action | Endpoint |
|---|---|
| Notes | `GET /note/list-notes/{workspace_id}/?state=active&page_size=100` |
| Save note | `POST /note/create-note/{workspace_id}/` `{ "title", "body", "color", "remind_at"? }` |
| Pin / unpin | `POST /note/pin-note/{note_id}/` `{ "pinned" }` |

- **Colours:** the six design colours map to `violet`, `lime`, `rose`, `sky`, `amber` and `slate`. The API's `teal` shows as `slate`.
- **Reminders:**
  - "Remind me" sends `remind_at` for 9:00 on the chosen day, or an hour from now if that time has passed, since the server needs a future time.
  - Reminders with `reminder_state: done` don't show.
- **Routing:** `journal` is on the live router allowlist.

### Tests

[`test/modules/journal/journal_test.dart`](../test/modules/journal/journal_test.dart) covers:

- **Mock:** create and pin make no network requests, and pinned notes stay first.
- **Live list:** the list query and the colour and reminder mapping.
- **Live create:** the payload, with `remind_at` in UTC.
- **Live pin:** replaces the note in the list.

### Not yet integrated

- **Not in the mobile design:**
  - editing, archiving, trashing, restoring and deleting notes;
  - the summary counts;
  - the reminder alarm (`list-due-reminders` polling, dismiss and snooze) and the alarm sound (`ring`/`voice`);
  - changing or clearing a reminder.
- **Search:** the journal's search icon opens global Search instead of searching notes (`list-notes?search=`).
- **Paging:** the list loads up to 100 notes.

## Visitors

**Code:** [`lib/modules/visitors/`](../lib/modules/visitors/)

| Layer | File | Role |
|---|---|---|
| Models | `domain/visit_pass.dart` | `VisitPass` (code, guest, purpose, date, status, arrival time, `canAnswer`), `GuestAnswer` (admit, hold, decline), `GuestInvite`, and `VisitorRefused`, which carries the server's reason. |
| Repository | `data/visitors_repository.dart` with `mock_visitors_repository.dart` and `live_visitors_repository.dart` | `VisitorsRepository` and `visitorsRepositoryProvider`. |
| Controller | `application/visitors_controller.dart` | `visitorsProvider` loads my guests and polls every 8 s in live mode. `invite` and `answer` put the server's copy into the list. |
| Screen | `presentation/visitors_screen.dart` with `widgets/visitor_cards.dart` | "Waiting for you" (answer cards, then a confirmation once answered), "Expected", the invite sheet and the code/QR sheet. |

**Minimal loading:**

- **Guests:** one list request, refreshed on the guide's 8-second interval while the screen is open.
- **Default desk:** looked up only the first time someone invites, then kept.
- **Invite and answer:** put the returned pass into the list, with no reload.

### Mock mode

`MockVisitorsRepository` has Folake waiting at reception (arrived 2 minutes ago) and Bayo expected today at 14:00. Invites and answers last for the session. It makes no network requests and doesn't poll.

### Live mode

| Screen action | Endpoint |
|---|---|
| Waiting for you / Expected | `GET /visitor/list-passes/{workspace_id}/?scope=mine` (a plain array). "Waiting" means `can_answer` and status `waiting` or `hold_over`. "Expected" means status `expected`, soonest first. |
| Come in / Wait 10 min / Not today | `POST /visitor/pass-action/{workspace_id}/{pass_id}/` `{ "action": "admit" }`, `{ "action": "hold", "minutes": 10 }` or `{ "action": "decline" }` |
| Invite a guest | `GET /visitor/list-desks/{workspace_id}/` once to find the default desk, then `POST /visitor/create-pass/{workspace_id}/` `{ guest_name, party_size: 1, purpose, desk_id, valid_on, arrived: false }`. The sheet shows the returned `code` and its QR. |

- **Invite time:** passes only store a date, so the invite's time goes at the start of the purpose ("11:00 · Vendor demo"). The desk sees it there.
- **Refusals:** a 403, 404 or 409 from an invite or answer throws `VisitorRefused`. The toast shows the server's sentence word for word, as the guide says.
- **Routing:** `visitors` is on the live router allowlist.

### Tests

[`test/modules/visitors/visitors_test.dart`](../test/modules/visitors/visitors_test.dart) covers:

- **Mock:** invite and answer make no network requests.
- **Live:** the list query, the default desk looked up once, the create-pass body, the hold-for-10-minutes payload, and a refusal surfacing the server's reason.

### Not yet integrated

- **Not in the mobile design:**
  - the Front Desk (all passes, find by code, walk-ins, send in, mark gone);
  - setting up desks;
  - choosing a desk or host, party size, guest phone;
  - cancelling a pass;
  - hold times other than 10 minutes.
- **Share link:** the public pass page link (`/pass/{code}`) and sharing it.
- **Legacy check-in:** the guest check-in screens (`/guest-checkin/…`).

## Profile & Settings

**Code:** [`lib/modules/profile/`](../lib/modules/profile/) and [`lib/modules/settings/`](../lib/modules/settings/)

| Layer | File | Role |
|---|---|---|
| Models | `profile/domain/profile.dart` | `ProfileSummary`, `Presence` (the four design statuses with their API values), `Badge` and `badgeFromKey`. |
| Repository | `profile/data/profile_repository.dart` with mock and live parts | `profileRepositoryProvider`: `summary()` and `setPresence()`. |
| Repository | `settings/data/settings_repository.dart` with mock and live parts | `settingsRepositoryProvider`: notification switches and `saveAppearance()`. `DeviceNotices` stores the switches that only affect this phone. |
| Controllers | `profile/application/profile_controller.dart`, `settings/application/settings_controller.dart` | `profileProvider`; `settingsNoticesProvider`, which shows a change at once and reverts it if the save fails; `settingsActionsProvider` for the profile, theme, language and sign-out. |
| Screens | `profile/presentation/profile_screen.dart` (+ `widgets/profile_header.dart`), `settings/presentation/settings_screen.dart` | Same layout as before, now driven by the controllers. |

**Reused, not duplicated:**

- **Profile edit:** `ProfileSetupRepository.saveProfile`.
- **Email and password changes:** `showAccountAction` with `AccountAction.requestEmailChange` and `changePassword`.
- **Sign-out:** `AccountSession.signOut`.
- **Account data:** name, email and birthday come from the signed-in `Account`, so Settings makes no request for them.

**Minimal loading:**

- **Profile:** four parallel requests, once per visit. A status change updates the page in place.
- **Settings:** one request (notification preferences). Profile, theme and language saves update the session `Account` from the server's reply.

### Mock mode

- **Profile:** `MockProfileRepository` returns the design's person: Ibrahim Musa as manager, 4 direct reports, 640 points, level 2, a 4-day streak (best 11) and 3 of 5 badges. Status is kept in `WorkspacePreview`.
- **Settings:**
  - Notification switches are saved on the device.
  - Theme and language change locally.
  - Password & email shows the "available when connected" note.
- No network requests are made.

### Live mode

| Screen action | Endpoint |
|---|---|
| Profile (person, manager, reports, team) | `GET /people/get-person/{workspace_id}/{me}/` |
| Role chips | `GET /people/my-context/{workspace_id}/` (`role`, `is_line_manager`, `is_project_manager`, `is_team_lead`) |
| Points, level, streak, badges | `GET /gamification/get-profile/{workspace_id}/{me}/` |
| My status | `GET /people/list-statuses/{workspace_id}/` (my row) |
| Set status | `PUT /people/set-status/{workspace_id}/` `{ "presence" }` |
| Edit profile | `PATCH /auth/update-profile-json/` `{ first_name, last_name, job_title }` |
| Theme / language | `PATCH /auth/update-profile-json/` `{ "theme" }` / `{ "language" }` |
| Notification switches | `GET` / `PUT /notification/{get,update}-preferences/{workspace_id}/` |
| Change email | `POST /auth/request-email-change/` |
| Change password | `POST /auth/update-password/`, then sign out, since the server revokes every token |

- **Status mapping:**
  - Available is `available`, In a meeting is `meeting`, Focusing is `dnd`, and Out of office is `leave`.
  - On read, `busy` shows as In a meeting, and `away` or `offline` show as Out of office.
- **Badges:** server keys are matched to the five design badges.
- **Notification switches:**
  - Reviews & mentions maps to `submitted`, `returned`, `approved` and `mention`.
  - Daily report reminder maps to `reminder`.
  - Each event's `email` setting is kept as it was.
  - Push notifications, Quiet hours and Sounds & vibration are device settings and are stored on the phone.
- **Theme:** "System" has no server value, so it stays on the phone.
- **Manager row:** opens the chat inbox. The mock opens the reference conversation.
- **Routing:** `profile` and `settings` are on the live router allowlist.

### Tests

- [`test/modules/profile/profile_test.dart`](../test/modules/profile/profile_test.dart):
  - mock status changes;
  - badge key mapping;
  - the live summary combining all four responses;
  - the set-status payload.
- [`test/modules/settings/settings_test.dart`](../test/modules/settings/settings_test.dart):
  - device switches;
  - the server switch payload, which keeps email choices;
  - a failed switch reverting;
  - theme saving, with System kept local.
- `test/widget_test.dart`: Profile and Settings render the mock account.

### Not yet integrated

- **No API:**
  - best streak;
  - the 15-week streak history grid (hidden in live mode);
  - a "system" theme.
- **Not in the mobile design:**
  - status note and end time (`custom` and `until`);
  - department and phone editing;
  - photo upload from Settings (it remains in profile setup);
  - email digest settings.
- **Chat:** the manager row opens the inbox, not a direct conversation with the manager.
- **Face ID:** the switch is local only; there's no biometric service yet.
- **Sign in again:** the language and theme saved to the account aren't applied on the next sign-in.

## Search

**Code:** [`lib/modules/search/`](../lib/modules/search/)

| Layer | File | Role |
|---|---|---|
| Models | `domain/search.dart` | `SearchResults` with `SearchTask` (a `TaskItem`), `SearchProject` (a `ProjectItem`) and `SearchPerson`. In mock mode, each can carry reference copy for its detail line. |
| Repository | `data/search_repository.dart` with mock and live parts | `searchRepositoryProvider`: `search(query)`, `featured()` and `suggestedRecent`. |
| Controller | `application/search_controller.dart` | `searchResultsProvider(query)`; `searchFeaturedProvider` for "Jump to"; `recentSearchesProvider`, which keeps the last 5 searches on the phone. |
| Screen | `presentation/search_screen.dart` (+ `widgets/search_results.dart`, `widgets/search_open.dart`) | Same layout. Quick actions filter as you type. Server results load 300 ms after typing stops. |

**Minimal loading:**

- **When it searches:** one parallel set of 3 requests per settled query. Queries under 2 characters send nothing.
- **While loading:** earlier results stay on screen until the new ones arrive.
- **Task results:** a found task opens straight into Task detail, since the list item is the full task. No `get-task` request is made.
- **Quick actions:** local commands. They route to their screens and make no request.
- **Reused parsers:** `taskItemFromJson` and `projectItemFromJson`. The second is newly exposed from the Projects live repository.

### Mock mode

`MockSearchRepository` gives the design's results:

- **Tasks:** TK-190 and TK-142, from the mock Tasks repository so they open properly.
- **Projects:** Customer Portal Revamp and Mobile App Launch. These also appear under "Jump to".
- **People:** Tunde and Ibrahim.
- **Recent chips:** start as webhook, Tunde and TK-190.

It makes no network requests.

### Live mode

| Group | Endpoint |
|---|---|
| Tasks | `GET /task/list-tasks/{workspace_id}/?search={q}&page_size=5` |
| Projects | `GET /project/list-projects/{workspace_id}/?search={q}&page_size=5` |
| People | `GET /people/list-people/{workspace_id}/?search={q}&page_size=5` |
| Message a person | `POST /chat/start-dm/{workspace_id}/` (through `ChatRepository.start`), then Conversation |

- **People:**
  - Only `active` members appear. Pending invites and signup requests are left out because they can't be messaged.
  - The detail line is job title · team.
- **Detail lines:**
  - Tasks show reference · status.
  - Projects show health · progress.
- **Before typing:**
  - "Jump to" is empty, because there is no "recent projects" endpoint.
  - Recent chips start empty and fill as you open results.
- **Errors:** a failure shows its typed message below the results.
- **Routing:** `search` is on the live router allowlist.

### Tests

- [`test/modules/search/search_test.dart`](../test/modules/search/search_test.dart):
  - mock matching, featured projects and recent persistence;
  - the live fan-out paths and query parameters, parsing, and pending people filtered out;
  - no requests for short queries.
- `test/widget_test.dart`: typing "webhook" shows TK-142 after the debounce.

### Not yet integrated

- **Messages:** results from `GET /chat/search-messages/` aren't shown. The docs mark this optional, and the design has no Messages group.
- **Project results:** these open the Projects list, not a project detail, because there is no project detail screen.
- **In-flight requests:** a superseded request isn't cancelled at the network level; its result is simply dropped.
- **"Jump to":** has no live content.

## More (business)

**Code:**
- [`lib/modules/workspace/presentation/more_screen.dart`](../lib/modules/workspace/presentation/more_screen.dart)
- `widgets/more_live.dart`

The More page keeps the same layout in both modes. Only where its data comes from changes.

| Row | Mock | Live |
|---|---|---|
| Me (name · job · status) | `WorkspacePreview` and the mock profile status | Signed-in `Account`, with no request, plus `myPresenceProvider`: one `GET /people/list-statuses/{workspace_id}/` |
| Workspace + Switch | Preview name and the local workspace picker | `activeLiveWorkspaceProvider`. Switch lists the approved workspaces from `accountWorkspacesProvider` (already loaded) and selects one with `liveWorkspaceSelectionProvider`, then opens Home. |
| Notifications badge | Preview unread count | `notificationUnreadProvider`, `GET /notification/get-unread-count/{workspace_id}/`. Hidden at 0. |
| Sign out | `AccountSession.signOut` → Welcome | Same; Welcome opens even if the server call fails |

- **Presence:** `ProfileRepository.presence()` is new. It loads my status alone. Setting a status on Profile refreshes it.
- **Routing:**
  - `more` is on the live router allowlist.
  - The live Home tab bar's More tab now opens More instead of the Account screen.

### Tests

- **`profile_test.dart`:** the live presence read makes one request.
- **`widget_test.dart`:** More shows the mock name, status and workspace.

### Not yet integrated

- **Pending workspaces:** the Account screen (pending and rejected workspaces, email verification) is no longer reachable from the live More tab. The live switcher lists approved workspaces only.
- **Tools grid:** routes to screens that are already integrated. The tools aren't filtered by role (`my-context`).
- **Status dot:** the online dot on the avatar applies only to non-business workspaces, as before.

## Chat

**Code:** [`lib/modules/chat/`](../lib/modules/chat/)

| Layer | File | Role |
|---|---|---|
| Models | `domain/chat_models.dart` | Conversation rows, contacts, chat requests and messages. Live rows carry the server conversation `id` and the last message time. |
| Repository | `data/chat_repository.dart` with `mock_chat_repository.dart` and `live_chat_repository.dart` | `ChatRepository` and `chatRepositoryProvider`. |
| Inbox | `data/chat_directory.dart` | `chatDirectoryProvider` loads the inbox and refreshes it while live. |
| Conversation | `application/chat_thread.dart` | `chatThreadProvider(conversationId)` loads, polls, sends, marks read and toggles reactions. |
| Prototype threads | `application/chat_session.dart` | Local state for the prototype's sample threads. Rows without an `id` keep using it. |
| Screens | `presentation/chat_screens.dart`, `presentation/conversation_screen.dart`, `presentation/widgets/live_thread.dart` | The inbox and conversation. A row with a server `id` opens the live thread, so the screen branches on data, not on the environment. |

### Mock mode

`MockChatRepository` reads `assets/fixtures/workspace_chats.json` for the active local workspace. People search filters the fixture contacts. New chats and replies stay in `ChatSessionController`, so mock mode makes no network requests and doesn't poll.

### Live mode

| Screen action | Endpoint |
|---|---|
| Inbox | `GET /chat/list-conversations/{workspace_id}/?page_size=100` |
| Chat request card | `GET /chat/list-chat-requests/?page_size=1` |
| Accept / Decline | `POST /chat/accept-chat-request/{conversation_id}/`, `POST /chat/decline-chat-request/{conversation_id}/` |
| Compose search (2+ characters, after a short typing pause) | `GET /chat/search-people/{workspace_id}/?q=…&page_size=20` |
| New direct message | `POST /chat/start-dm/{workspace_id}/` `{ "user_id" }` |
| New group | `POST /chat/create-conversation/{workspace_id}/` `{ "kind": "group", "title"?, "member_ids" }` |
| Conversation feed | `GET /chat/list-messages/{conversation_id}/?order=desc&page=1&page_size=50`, reversed for display |
| Send | `POST /chat/send-message/{conversation_id}/` as multipart `body` |
| Read state | `POST /chat/mark-read/{conversation_id}/` `{ "message_id" }` with the newest message |
| ❤️ on long press | `POST /chat/toggle-reaction/{message_id}/` `{ "emoji": "❤️" }` |

**Inbox sections**, following `chat_integration.md`:

- **Pinned:** the first `is_pinned` conversation.
- **Task conversations:** `kind == task`.
- **Recent:** `dm` and `group`.
- **Groups tab:** `channel`.

**Row details:**

- **Badge:** `@` when `mention_count > 0`, otherwise the unread count.
- **Time:** the last message's time, shown as relative time.

**Polling:** there is no realtime channel yet. Live mode refreshes the inbox every 15 s and an open conversation every 5 s, the same intervals as the web sample's `CHAT_POLL`. Polled messages are merged by id. After sending or reading, the inbox is refreshed so badges update.

**Realtime-only features:** the API has no typing, presence or calls yet, so live threads hide the typing indicator, online dots and call button.

**Errors:** failures show a toast or a "Try again" state with the translated network error. Live data never falls back to mock data. Provider-level retry is off because the network layer already retries.

**Routing:** `chat` and `conversation` are on the live router allowlist in `lib/router/router_config.dart`. Live Home's Chat tab opens the Chat screen.

### Tests

[`test/modules/chat/chat_repository_test.dart`](../test/modules/chat/chat_repository_test.dart) covers:

- **Mock:** the inbox and search make no network requests.
- **Live inbox:** conversations land in the right section with the right badge.
- **Live actions:** search, start a direct message, create a group and accept a request each send the right request body.
- **Live thread:** messages come back oldest first, the newest is marked read, sending uses multipart and the ❤️ reaction toggles.

### Not yet integrated

- Attachments and voice notes (the composer buttons do nothing in either mode), threads, editing, deleting, pinning messages, mute and pin state, the Files, Tasks and Pinned tabs, chat groups, and conversations with people outside the workspace. The mobile design doesn't include these yet.
- Loading older messages when scrolling up; live threads load the latest 50.
- The Chat screen's bottom navigation is still the mock bar. Live Home shows the unread chat count from `get-unread-summary`.
