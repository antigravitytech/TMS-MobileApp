import 'workspace_kind.dart';

/// Optional details collected by the corresponding workspace tool.
enum WorkspaceField {
  phone,
  email,
  relationship,
  meal,
  dietary,
  vendorCategory,
  contact,
  arrival,
  theme,
  scripture,
  worshipLeader,
  ushers,
  media,
  men,
  women,
  children,
  online,
  firstVisits,
  followsUp,
  interest,
  schoolName,
  reviewer,
  members,
  meetingTime,
  loggedBy,
  accessCode,
  session,
  position,
  city,
  segment,
  vendor,
  issued,
  spent,
  side;

  bool get numeric =>
      const {men, women, children, online, firstVisits}.contains(this);
}

extension WorkspaceSectionFields on WorkspaceSection {
  List<WorkspaceField> get detailFields => switch (this) {
    WorkspaceSection.clients => const [
      WorkspaceField.email,
      WorkspaceField.phone,
    ],
    WorkspaceSection.household => const [WorkspaceField.phone],
    WorkspaceSection.congregation => const [
      WorkspaceField.email,
      WorkspaceField.phone,
    ],
    WorkspaceSection.guests => const [
      WorkspaceField.side,
      WorkspaceField.relationship,
      WorkspaceField.phone,
      WorkspaceField.email,
      WorkspaceField.meal,
      WorkspaceField.dietary,
    ],
    WorkspaceSection.vendors => const [
      WorkspaceField.vendorCategory,
      WorkspaceField.contact,
      WorkspaceField.phone,
      WorkspaceField.email,
      WorkspaceField.arrival,
    ],
    WorkspaceSection.programme => const [
      WorkspaceField.segment,
      WorkspaceField.vendor,
    ],
    WorkspaceSection.services => const [
      WorkspaceField.theme,
      WorkspaceField.scripture,
      WorkspaceField.worshipLeader,
      WorkspaceField.ushers,
      WorkspaceField.media,
      WorkspaceField.men,
      WorkspaceField.women,
      WorkspaceField.children,
      WorkspaceField.online,
      WorkspaceField.firstVisits,
    ],
    WorkspaceSection.firstTimers => const [
      WorkspaceField.phone,
      WorkspaceField.email,
      WorkspaceField.relationship,
      WorkspaceField.followsUp,
      WorkspaceField.interest,
    ],
    WorkspaceSection.school => const [
      WorkspaceField.schoolName,
      WorkspaceField.reviewer,
    ],
    WorkspaceSection.visitors => const [WorkspaceField.loggedBy],
    WorkspaceSection.passes => const [WorkspaceField.accessCode],
    WorkspaceSection.committees || WorkspaceSection.units => const [
      WorkspaceField.members,
      WorkspaceField.meetingTime,
    ],
    WorkspaceSection.attendance => const [
      WorkspaceField.session,
      WorkspaceField.position,
    ],
    WorkspaceSection.directory => const [
      WorkspaceField.city,
      WorkspaceField.email,
      WorkspaceField.phone,
    ],
    _ => const [],
  };
}
