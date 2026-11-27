import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../specials/application/special_actions.dart';
import '../../workspace/application/local_workspaces.dart';
import '../../workspace/domain/event_seating.dart';
import '../../workspace/domain/local_workspace.dart';
import '../../workspace/domain/workspace_kind.dart';

enum EventTab { overview, guests, seating, vendors, programme }

/// RSVP filters and the order they show in, with their statuses.
const rsvpOrder = [
  WorkspaceStatus.confirmed,
  WorkspaceStatus.maybe,
  WorkspaceStatus.pending,
  WorkspaceStatus.notInvited,
  WorkspaceStatus.declined,
];

/// Vendor board columns.
const vendorStages = ['enquiry', 'quoted', 'booked', 'paid'];

extension EventRecord on WorkspaceRecord {
  bool get isMeta => fields['meta'] == 'true';
  bool get checkedIn => fields['checkedIn'] == 'true';
  double get px => double.tryParse(fields['px'] ?? '') ?? 50;
  double get py => double.tryParse(fields['py'] ?? '') ?? 50;

  /// A vendor's board column: paid in full wins over its stage.
  String get vendorStage => amount > 0 && paid >= amount
      ? 'paid'
      : fields['stage'] ?? (amount > 0 ? 'quoted' : 'enquiry');
}

/// Everything the Event home shows, derived from the workspace records.
class EventView {
  EventView(this.space, DateTime now)
    : today = DateTime(now.year, now.month, now.day),
      guests = space.items(WorkspaceSection.guests).toList(),
      tables = space.items(WorkspaceSection.seating).toList(),
      vendors = space.items(WorkspaceSection.vendors).toList(),
      programme = space.items(WorkspaceSection.programme).toList()
        ..sort((a, b) => (a.date ?? now).compareTo(b.date ?? now)),
      info = space
          .items(WorkspaceSection.notices)
          .where((r) => r.isMeta)
          .firstOrNull;
  final LocalWorkspace space;
  final DateTime today;
  final List<WorkspaceRecord> guests, tables, vendors, programme;

  /// Hosts, the event's name and style.
  final WorkspaceRecord? info;

  int partyOf(WorkspaceStatus s) => guests
      .where((g) => g.status == s)
      .fold(0, (n, g) => n + (g.duration < 1 ? 1 : g.duration));
  int count(WorkspaceStatus s) => guests.where((g) => g.status == s).length;
  int get seatsConfirmed => partyOf(WorkspaceStatus.confirmed);
  int get awaiting =>
      count(WorkspaceStatus.pending) + count(WorkspaceStatus.maybe);
  int get checkedIn => guests
      .where((g) => g.checkedIn)
      .fold(0, (n, g) => n + (g.duration < 1 ? 1 : g.duration));

  int get committed => vendors.fold(0, (s, v) => s + v.amount);
  int get paid => vendors.fold(0, (s, v) => s + v.paid.clamp(0, v.amount));

  /// Vendor balances due in the next two weeks, soonest first.
  List<WorkspaceRecord> get dueSoon =>
      vendors
          .where(
            (v) =>
                v.outstanding > 0 &&
                v.date != null &&
                !v.date!.isBefore(today) &&
                v.date!.difference(today).inDays <= 14,
          )
          .toList()
        ..sort((a, b) => a.date!.compareTo(b.date!));

  int seatedAt(String table) => space.seatsTaken(table);
  int get seated => tables.fold(0, (s, t) => s + seatedAt(t.title));
  int get capacity => tables.fold(0, (s, t) => s + t.duration);

  /// Attending or maybe guests without a table.
  List<WorkspaceRecord> get unseated =>
      space.arrivingGuests.where((g) => g.group.isEmpty).toList();
}

final eventViewProvider = Provider.autoDispose.family<EventView?, String>((
  ref,
  id,
) {
  final space = ref
      .watch(localWorkspacesProvider)
      .value
      ?.workspaces
      .where((w) => w.id == id)
      .firstOrNull;
  return space == null ? null : EventView(space, DateTime.now());
});

class EventState {
  const EventState({
    this.tab = EventTab.overview,
    this.filter,
    this.door = false,
    this.pick,
    this.peek,
    this.running = false,
    this.now = 0,
  });
  final EventTab tab;

  /// RSVP status shown, or null for everyone.
  final WorkspaceStatus? filter;

  /// Door mode lists attending guests for check-in.
  final bool door;

  /// Guest picked for seating, and the table being looked at.
  final String? pick, peek;

  /// Whether the run of show is live, and its current item.
  final bool running;
  final int now;

  EventState copyWith({
    EventTab? tab,
    WorkspaceStatus? Function()? filter,
    bool? door,
    String? Function()? pick,
    String? Function()? peek,
    bool? running,
    int? now,
  }) => EventState(
    tab: tab ?? this.tab,
    filter: filter == null ? this.filter : filter(),
    door: door ?? this.door,
    pick: pick == null ? this.pick : pick(),
    peek: peek == null ? this.peek : peek(),
    running: running ?? this.running,
    now: now ?? this.now,
  );
}

final eventControllerProvider = NotifierProvider.autoDispose
    .family<EventController, EventState, (String, EventTab)>(
      EventController.new,
    );

/// Holds Event UI state and changes guests, tables and vendors.
class EventController extends Notifier<EventState> {
  EventController(this.args);

  /// Workspace id and the tab the screen opened on.
  final (String, EventTab) args;
  String get _id => args.$1;

  @override
  EventState build() => EventState(tab: args.$2);

  SpecialActions get _actions => ref.read(specialActionsProvider(_id));
  LocalWorkspaces get _directory => ref.read(localWorkspacesProvider.notifier);

  void tab(EventTab value) => state = state.copyWith(tab: value);
  void filter(WorkspaceStatus? value) =>
      state = state.copyWith(filter: () => value);
  void door(bool value) =>
      state = state.copyWith(door: value, filter: value ? () => null : null);
  void pickGuest(String? id) =>
      state = state.copyWith(pick: () => state.pick == id ? null : id);
  void peekTable(String? table) => state = state.copyWith(peek: () => table);
  void run(bool value) => state = state.copyWith(running: value, now: 0);
  void next(int items) =>
      state = state.copyWith(now: (state.now + 1).clamp(0, items - 1));

  Future<bool> _try(Future<void> Function() action) async {
    try {
      await action();
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<bool> toggleCheckIn(WorkspaceRecord guest) => _actions.update(
    guest,
    (r) => r.copyWith(fields: {...r.fields, 'checkedIn': '${!r.checkedIn}'}),
  );

  /// Seats the picked guest at [table]. Returns false if it's full.
  Future<bool> seatPicked(String table) async {
    final guest = state.pick;
    if (guest == null) return false;
    final ok = await _try(() => _directory.seatGuest(_id, guest, table));
    if (ok) state = state.copyWith(pick: () => null, peek: () => table);
    return ok;
  }

  Future<bool> autoSeat() => _try(() => _directory.autoSeatGuests(_id));

  /// Pays a quarter of a vendor's cost, or what's left if less.
  Future<int?> payVendor(WorkspaceRecord vendor) async {
    final quarter = (vendor.amount / 4).round();
    final kobo = quarter < vendor.outstanding ? quarter : vendor.outstanding;
    if (kobo <= 0) return null;
    final ok = await _actions.recordPayment(
      vendor,
      kobo: kobo,
      method: 'transfer',
      giver: vendor.title,
    );
    return ok ? kobo : null;
  }
}
