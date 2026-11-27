import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../specials/presentation/widgets/special_stages.dart';
import '../../workspace/application/local_workspaces.dart';

export '../../specials/presentation/widgets/special_stages.dart'
    show SpecialStage;
import '../../workspace/domain/local_workspace.dart';
import '../../workspace/domain/workspace_entry.dart';
import '../../workspace/domain/workspace_kind.dart';

enum ChurchTab {
  overview,
  services,
  giving,
  units,
  prayer,
  firstTimers,
  notices,
}

/// First-timer follow-up stages, in order.
const firstTimerStages = ['new', 'called', 'visited', 'class', 'member'];

/// Attendance groups on the record sheet, and gift methods.
const attendanceGroups = ['men', 'women', 'children', 'online'];
const giftMethods = ['transfer', 'cash', 'pos'];

extension ChurchRecord on WorkspaceRecord {
  int field(String key) => int.tryParse(fields[key] ?? '') ?? 0;
  bool flag(String key) => fields[key] == 'true';
}

/// Everything the Church home shows, derived from the workspace records.
class ChurchView {
  ChurchView(this.space, DateTime now)
    : services = space.items(WorkspaceSection.services).toList()
        ..sort((a, b) => a.date!.compareTo(b.date!)),
      funds = space.items(WorkspaceSection.giving).toList(),
      units = space.items(WorkspaceSection.units).toList(),
      prayers = space.items(WorkspaceSection.prayers).toList()
        ..sort((a, b) => (b.date ?? now).compareTo(a.date ?? now)),
      firstTimers = space.items(WorkspaceSection.firstTimers).toList(),
      notices = space.items(WorkspaceSection.notices).toList()
        ..sort((a, b) => (b.date ?? now).compareTo(a.date ?? now)),
      today = DateTime(now.year, now.month, now.day);
  final LocalWorkspace space;
  final List<WorkspaceRecord> services, funds, units, prayers, firstTimers;
  final List<WorkspaceRecord> notices;
  final DateTime today;

  int get members =>
      space
          .items(WorkspaceSection.congregation)
          .map((r) => r.field('size'))
          .where((n) => n > 0)
          .firstOrNull ??
      space.items(WorkspaceSection.congregation).length;

  /// The next service flagged as the season's highlight, else the next one.
  WorkspaceRecord? get highlight =>
      upcoming.where((s) => s.flag('highlight')).firstOrNull ??
      upcoming.firstOrNull;

  List<WorkspaceRecord> get upcoming =>
      services.where((s) => !s.date!.isBefore(today)).toList();

  /// Today's (or the next) service, which attendance is recorded for.
  WorkspaceRecord? get nextService => upcoming.firstOrNull;

  /// The last five services with a recorded attendance, oldest first.
  List<WorkspaceRecord> get trend => services
      .where((s) => s.field('attendance') > 0)
      .toList()
      .reversed
      .take(5)
      .toList()
      .reversed
      .toList();

  int get lastSunday =>
      trend
          .where((s) => s.flag('sunday') || s.date!.weekday == DateTime.sunday)
          .lastOrNull
          ?.field('attendance') ??
      0;

  int givingOf(String kind) => funds
      .where((f) => f.fields['kind'] == kind)
      .fold(0, (s, f) => s + f.paid);
  int get givingTotal => funds.fold(0, (s, f) => s + f.paid);

  /// Funds with a target, for the progress cards.
  List<WorkspaceRecord> get targetFunds =>
      funds.where((f) => f.amount > 0).toList();

  /// The latest gifts across every fund, newest first.
  List<(WorkspaceRecord, WorkspaceEntry)> get recentGifts {
    final gifts = [
      for (final f in funds)
        for (final e in f.entries.where((e) => e.kind == EntryKind.payment))
          (f, e),
    ]..sort((a, b) => b.$2.date.compareTo(a.$2.date));
    return gifts.take(4).toList();
  }

  int get openPrayers =>
      prayers.where((p) => p.status != WorkspaceStatus.done).length;
  int get answeredPrayers =>
      prayers.where((p) => p.status == WorkspaceStatus.done).length;
  int get notCalled => firstTimers.where((f) => f.stage == 0).length;
}

final churchViewProvider = Provider.autoDispose.family<ChurchView?, String>((
  ref,
  id,
) {
  final space = ref
      .watch(localWorkspacesProvider)
      .value
      ?.workspaces
      .where((w) => w.id == id)
      .firstOrNull;
  return space == null ? null : ChurchView(space, DateTime.now());
});

class ChurchState {
  const ChurchState({
    this.tab = ChurchTab.overview,
    this.pastorsOnly = false,
    this.hideName = false,
  });
  final ChurchTab tab;
  final bool pastorsOnly, hideName;
  ChurchState copyWith({ChurchTab? tab, bool? pastorsOnly, bool? hideName}) =>
      ChurchState(
        tab: tab ?? this.tab,
        pastorsOnly: pastorsOnly ?? this.pastorsOnly,
        hideName: hideName ?? this.hideName,
      );
}

final churchControllerProvider = NotifierProvider.autoDispose
    .family<ChurchController, ChurchState, (String, ChurchTab)>(
      ChurchController.new,
    );

class ChurchController extends Notifier<ChurchState> {
  ChurchController(this.args);

  /// Workspace id and the tab the screen opened on.
  final (String, ChurchTab) args;
  String get _id => args.$1;

  @override
  ChurchState build() => ChurchState(tab: args.$2);

  LocalWorkspaces get _directory => ref.read(localWorkspacesProvider.notifier);

  void tab(ChurchTab value) => state = state.copyWith(tab: value);
  void togglePastorsOnly() =>
      state = state.copyWith(pastorsOnly: !state.pastorsOnly);
  void toggleHideName() => state = state.copyWith(hideName: !state.hideName);

  Future<bool> _try(Future<void> Function() action) async {
    try {
      await action();
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<bool> _update(
    WorkspaceRecord r,
    WorkspaceRecord Function(WorkspaceRecord) change,
  ) => _try(() => _directory.updateRecord(_id, r.id, change));

  /// Saves a head count per group and the total on [service].
  Future<bool> saveAttendance(
    WorkspaceRecord service,
    Map<String, int> counts,
  ) => _update(
    service,
    (r) => r.copyWith(
      fields: {
        ...r.fields,
        for (final MapEntry(:key, :value) in counts.entries) key: '$value',
        'attendance': '${counts.values.fold(0, (a, b) => a + b)}',
      },
    ),
  );

  /// Records a gift on [fund]; an empty [giver] stays anonymous.
  Future<bool> recordGift(
    WorkspaceRecord fund, {
    required int kobo,
    required String method,
    required String giver,
  }) => _try(
    () => _directory.addEntry(
      _id,
      fund.id,
      WorkspaceEntry(
        kind: EntryKind.payment,
        date: DateTime.now(),
        name: giver,
        method: method,
        amount: kobo,
      ),
    ),
  );

  /// Shares a prayer request. Returns false when nothing was saved.
  Future<bool> sharePrayer(String text, String me) {
    final body = text.trim();
    if (body.isEmpty) return Future.value(false);
    return _try(
      () => _directory.saveRecord(
        _id,
        WorkspaceRecord(
          id: '',
          section: WorkspaceSection.prayers,
          title: body,
          person: state.hideName ? '' : me,
          date: DateTime.now(),
          points: 0,
          fields: {
            'praying': '0',
            'private': '${state.pastorsOnly}',
            'anonymous': '${state.hideName}',
          },
        ),
      ),
    );
  }

  /// Joins or leaves praying for a request. Returns the new state, or null.
  Future<bool?> togglePraying(WorkspaceRecord p) async {
    final on = !p.flag('iPray');
    final ok = await _update(
      p,
      (r) => r.copyWith(
        fields: {
          ...r.fields,
          'iPray': '$on',
          'praying': '${(r.field('praying') + (on ? 1 : -1)).clamp(0, 9999)}',
        },
      ),
    );
    return ok ? on : null;
  }

  Future<bool> markAnswered(WorkspaceRecord p) =>
      _update(p, (r) => r.copyWith(status: WorkspaceStatus.done));

  /// Moves a first-timer to the next stage; unassigned ones go to [me].
  Future<bool> advance(WorkspaceRecord f, String me) => _update(f, (r) {
    final next = (r.stage + 1).clamp(0, firstTimerStages.length - 1);
    return r.copyWith(
      status: next == firstTimerStages.length - 1
          ? WorkspaceStatus.done
          : WorkspaceStatus.pending,
      fields: {
        ...r.fields,
        'stage': '$next',
        if ((r.fields['followsUp'] ?? '').isEmpty) 'followsUp': me,
      },
    );
  });

  /// Adds a first-timer from the welcome card.
  Future<bool> addFirstTimer(String name) {
    final who = name.trim();
    if (who.isEmpty) return Future.value(false);
    return _try(
      () => _directory.saveRecord(
        _id,
        WorkspaceRecord(
          id: '',
          section: WorkspaceSection.firstTimers,
          title: who,
          date: DateTime.now(),
          points: 0,
          status: WorkspaceStatus.pending,
          fields: const {'stage': '0', 'followsUp': ''},
        ),
      ),
    );
  }
}
