enum WorkspaceView {
  checklist,
  review,
  people,
  money,
  time,
  schedule,
  board,
  poll,
  notice,
  seating,
}

enum WorkspaceSection {
  gigs(WorkspaceView.checklist),
  clients(WorkspaceView.people),
  invoices(WorkspaceView.money),
  time(WorkspaceView.time),
  proposals(WorkspaceView.checklist),
  tasks(WorkspaceView.checklist),
  chores(WorkspaceView.review),
  shopping(WorkspaceView.checklist),
  bills(WorkspaceView.money),
  school(WorkspaceView.review),
  errands(WorkspaceView.checklist),
  plans(WorkspaceView.schedule),
  household(WorkspaceView.people),
  visitors(WorkspaceView.people),
  rewards(WorkspaceView.board),
  services(WorkspaceView.schedule),
  giving(WorkspaceView.money),
  units(WorkspaceView.board),
  congregation(WorkspaceView.people),
  prayers(WorkspaceView.checklist),
  firstTimers(WorkspaceView.people),
  notices(WorkspaceView.notice),
  dues(WorkspaceView.money),
  committees(WorkspaceView.board),
  poll(WorkspaceView.poll),
  directory(WorkspaceView.people),
  levies(WorkspaceView.money),
  passes(WorkspaceView.schedule),
  issues(WorkspaceView.checklist),
  guests(WorkspaceView.people),
  seating(WorkspaceView.seating),
  vendors(WorkspaceView.money),
  programme(WorkspaceView.schedule),
  prep(WorkspaceView.checklist),
  meetings(WorkspaceView.schedule),
  actions(WorkspaceView.checklist),
  minutes(WorkspaceView.notice),
  decisions(WorkspaceView.poll),
  sessions(WorkspaceView.schedule),
  fees(WorkspaceView.money),
  attendance(WorkspaceView.people);

  const WorkspaceSection(this.view);
  final WorkspaceView view;
}

enum WorkspaceKind {
  business([]),
  individual([
    WorkspaceSection.gigs,
    WorkspaceSection.clients,
    WorkspaceSection.invoices,
    WorkspaceSection.time,
    WorkspaceSection.proposals,
    WorkspaceSection.tasks,
  ]),
  family([
    WorkspaceSection.chores,
    WorkspaceSection.school,
    WorkspaceSection.shopping,
    WorkspaceSection.bills,
    WorkspaceSection.errands,
    WorkspaceSection.plans,
    WorkspaceSection.household,
    WorkspaceSection.visitors,
    WorkspaceSection.rewards,
  ]),
  event([
    WorkspaceSection.guests,
    WorkspaceSection.seating,
    WorkspaceSection.vendors,
    WorkspaceSection.programme,
    WorkspaceSection.prep,
    WorkspaceSection.notices,
  ]),
  church([
    WorkspaceSection.services,
    WorkspaceSection.giving,
    WorkspaceSection.units,
    WorkspaceSection.prayers,
    WorkspaceSection.firstTimers,
    WorkspaceSection.congregation,
    WorkspaceSection.notices,
  ]),
  alumni([
    WorkspaceSection.dues,
    WorkspaceSection.committees,
    WorkspaceSection.poll,
    WorkspaceSection.notices,
    WorkspaceSection.directory,
  ]),
  estate([
    WorkspaceSection.levies,
    WorkspaceSection.passes,
    WorkspaceSection.issues,
    WorkspaceSection.notices,
    WorkspaceSection.poll,
  ]),
  committee([
    WorkspaceSection.meetings,
    WorkspaceSection.actions,
    WorkspaceSection.minutes,
    WorkspaceSection.decisions,
  ]),
  club([
    WorkspaceSection.sessions,
    WorkspaceSection.fees,
    WorkspaceSection.attendance,
    WorkspaceSection.notices,
  ]);

  const WorkspaceKind(this.sections);
  final List<WorkspaceSection> sections;

  static const specials = [event, church, alumni, estate, committee, club];
}

enum WorkspaceStatus {
  todo,
  inProgress,
  submitted,
  returned,
  done,
  pending,
  confirmed,
  declined,
  maybe,
  notInvited,
  contacted,
  visited,
  membershipClass,
}

enum SchoolItemKind { homework, test, meeting, form, fee }
