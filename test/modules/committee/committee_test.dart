import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sabi_pipu_tms/modules/committee/application/committee_controller.dart';
import 'package:sabi_pipu_tms/modules/specials/application/special_actions.dart';
import 'package:sabi_pipu_tms/modules/specials/presentation/widgets/special_meetings.dart';
import 'package:sabi_pipu_tms/modules/specials/presentation/widgets/special_records.dart';
import 'package:sabi_pipu_tms/modules/workspace/application/local_workspaces.dart';
import 'package:sabi_pipu_tms/modules/workspace/data/local_workspace_store.dart';
import 'package:sabi_pipu_tms/modules/workspace/data/workspace_demo.dart';
import 'package:sabi_pipu_tms/modules/workspace/domain/local_workspace.dart';
import 'package:sabi_pipu_tms/modules/workspace/domain/workspace_kind.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late ProviderContainer c;
  const args = ('committee', CommitteeTab.overview);

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await LocalWorkspaceStore(await SharedPreferences.getInstance()).save(
      WorkspaceDirectory(
        activeId: 'committee',
        workspaces: [demoWorkspace(WorkspaceKind.committee, DateTime.now())],
      ),
    );
    c = ProviderContainer();
    await c.read(localWorkspacesProvider.future);
  });
  tearDown(() => c.dispose());

  T keep<T>(ProviderListenable<T> p) {
    final sub = c.listen(p, (_, _) {});
    addTearDown(sub.close);
    return sub.read();
  }

  CommitteeView view() => c.read(committeeViewProvider('committee'))!;
  CommitteeController actions() =>
      c.read(committeeControllerProvider(args).notifier);

  test('overview reads Harvest Planning Committee', () {
    final v = keep(committeeViewProvider('committee'))!;
    expect(v.space.name, 'Harvest Planning Committee');
    expect((v.members, v.upcoming.length, v.openActions), (12, 2, 3));
    expect(v.upcoming.first.tags, ['Agenda: budget', 'Venue']);
    expect(v.decision?.votes, [3, 1, 1]);
    expect(v.minutes.single.status, isNot(WorkspaceStatus.done));
  });

  test('replies, actions and minutes change', () async {
    keep(committeeViewProvider('committee'));
    keep(committeeControllerProvider(args));
    final meeting = view().upcoming.first;
    expect(
      await c
          .read(specialActionsProvider('committee'))
          .reply(meeting, 'coming'),
      isTrue,
    );
    expect(view().upcoming.first.fields['myReply'], 'coming');

    final quotes = view().actions.first;
    await c.read(specialActionsProvider('committee')).setStage(quotes, 2);
    expect(view().openActions, 2);

    final minutes = view().minutes.single;
    expect(
      await actions().saveMinutes(minutes, 'Dayo to book the hall.'),
      isTrue,
    );
    expect(view().minutes.single.status, WorkspaceStatus.done);
    expect(view().minutes.single.notes, 'Dayo to book the hall.');

    expect(
      await actions().actionsFromMinutes(
        'Budget approved.\nDayo to book the hall.\nChinwe to call caterers.',
        'From the minutes',
      ),
      2,
    );
    expect(view().openActions, 4);
    expect(
      view().actions.any((a) => a.title == 'Dayo to book the hall'),
      isTrue,
    );
  });
}
