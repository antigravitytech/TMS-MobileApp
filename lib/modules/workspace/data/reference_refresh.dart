import '../../alumni/data/alumni_reference.dart';
import '../../church/data/church_reference.dart';
import '../../club/data/club_reference.dart';
import '../../committee/data/committee_reference.dart';
import '../../estate/data/estate_reference.dart';
import '../../event/data/event_reference.dart';
import '../../individual/data/individual_reference.dart';
import '../domain/local_workspace.dart';
import '../domain/workspace_kind.dart';
import '../../family/data/family_reference.dart';

/// One-time refreshes of saved demo data, each behind its preference flag.
/// Records people added themselves are always kept.
const referenceRefreshes =
    <(String, WorkspaceDirectory Function(WorkspaceDirectory, DateTime))>[
      ('family_reference.v1', _seedFamily),
      ('family_members.v1', _addFamilyMembers),
      ('family_reference.v3', _refreshFamily),
      ('individual_reference.v1', _refreshIndividual),
      ('church_reference.v2', _refreshChurch),
      ('alumni_reference.v1', _refreshAlumni),
      ('estate_reference.v1', _refreshEstate),
      ('event_reference.v2', _refreshEvent),
      ('committee_reference.v2', _refreshCommittee),
      ('club_reference.v1', _refreshClub),
    ];

/// Fills an empty saved Family workspace with the reference household.
WorkspaceDirectory _seedFamily(WorkspaceDirectory directory, DateTime _) =>
    directory.copyWith(
      workspaces: [
        for (final space in directory.workspaces)
          if (space.id == 'family' && space.records.isEmpty)
            familyReference()
          else
            space,
      ],
    );

/// Adds the reference household members to an older Family workspace.
WorkspaceDirectory _addFamilyMembers(
  WorkspaceDirectory directory,
  DateTime _,
) => directory.copyWith(
  workspaces: [
    for (final space in directory.workspaces)
      if (space.id == 'family' &&
          space.records.any((r) => r.id.startsWith('family-ref-')) &&
          space.items(WorkspaceSection.household).isEmpty)
        space.copyWith(
          records: [
            ...space.records,
            ...familyReference().items(WorkspaceSection.household),
          ],
        )
      else
        space,
  ],
);

/// Re-seeds the Family chores, bills, rewards and shopping list.
WorkspaceDirectory _refreshFamily(WorkspaceDirectory directory, DateTime _) {
  const refreshed = {
    WorkspaceSection.chores,
    WorkspaceSection.bills,
    WorkspaceSection.rewards,
    WorkspaceSection.shopping,
    WorkspaceSection.visitors,
  };
  bool seeded(WorkspaceRecord r) =>
      r.id.startsWith('family-ref-') && refreshed.contains(r.section);
  return directory.copyWith(
    workspaces: [
      for (final space in directory.workspaces)
        if (space.id == 'family' &&
            space.records.any((r) => r.id.startsWith('family-ref-')))
          space.copyWith(
            records: [
              ...space.records.where((r) => !seeded(r)),
              ...familyReference().records.where(seeded),
            ],
          )
        else
          space,
    ],
  );
}

/// Swaps the old Individual demo records for the prototype's data.
WorkspaceDirectory _refreshIndividual(
  WorkspaceDirectory directory,
  DateTime now,
) {
  bool old(WorkspaceRecord r) => r.id.startsWith('demo-individual-');
  return directory.copyWith(
    workspaces: [
      for (final space in directory.workspaces)
        if (space.id == 'individual' && space.records.any(old))
          space.copyWith(
            records: [
              ...space.records.where((r) => !old(r)),
              ...individualReference(now),
            ],
          )
        else
          space,
    ],
  );
}

/// Swaps a Specials demo's old records for its prototype data.
WorkspaceDirectory _refreshDemo(
  WorkspaceDirectory directory, {
  required String id,
  required String name,
  required List<WorkspaceRecord> records,
}) {
  bool old(WorkspaceRecord r) => r.id.startsWith('demo-$id-');
  return directory.copyWith(
    workspaces: [
      for (final space in directory.workspaces)
        if (space.id == id && space.records.any(old))
          space.copyWith(
            name: space.name.isEmpty ? name : space.name,
            records: [...space.records.where((r) => !old(r)), ...records],
          )
        else
          space,
    ],
  );
}

WorkspaceDirectory _refreshChurch(WorkspaceDirectory d, DateTime now) =>
    _refreshDemo(
      d,
      id: 'church',
      name: churchReferenceName,
      records: churchReference(now),
    );

WorkspaceDirectory _refreshAlumni(WorkspaceDirectory d, DateTime now) =>
    _refreshDemo(
      d,
      id: 'alumni',
      name: alumniReferenceName,
      records: alumniReference(now),
    );

WorkspaceDirectory _refreshEstate(WorkspaceDirectory d, DateTime now) =>
    _refreshDemo(
      d,
      id: 'estate',
      name: estateReferenceName,
      records: estateReference(now),
    );

WorkspaceDirectory _refreshCommittee(WorkspaceDirectory d, DateTime now) =>
    _refreshDemo(
      d,
      id: 'committee',
      name: committeeReferenceName,
      records: committeeReference(now),
    );

WorkspaceDirectory _refreshClub(WorkspaceDirectory d, DateTime now) =>
    _refreshDemo(
      d,
      id: 'club',
      name: clubReferenceName,
      records: clubReference(now),
    );

/// Re-seeds the Event demo and moves the wedding to its date and venue.
WorkspaceDirectory _refreshEvent(WorkspaceDirectory d, DateTime now) {
  final refreshed = _refreshDemo(
    d,
    id: 'event',
    name: eventReferenceName,
    records: eventReference(now),
  );
  if (identical(refreshed.workspaces, d.workspaces)) return refreshed;
  final day = DateTime(now.year, now.month, now.day + eventReferenceDays, 14);
  return refreshed.copyWith(
    workspaces: [
      for (final space in refreshed.workspaces)
        if (space.id == 'event' &&
            space.records.any((r) => r.id.startsWith(eventRefPrefix)))
          space.copyWith(
            eventDate: day,
            eventVenue: eventReferenceVenue,
            eventCapacity: eventReferenceCapacity,
            eventBudget: eventReferenceBudget,
          )
        else
          space,
    ],
  );
}
