import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sabi_pipu_tms/modules/individual/application/clients_controller.dart';
import 'package:sabi_pipu_tms/modules/individual/application/gigs_controller.dart';
import 'package:sabi_pipu_tms/modules/individual/application/individual_home.dart';
import 'package:sabi_pipu_tms/modules/individual/application/time_controller.dart';
import 'package:sabi_pipu_tms/modules/workspace/application/local_workspaces.dart';
import 'package:sabi_pipu_tms/modules/workspace/data/local_workspace_store.dart';
import 'package:sabi_pipu_tms/modules/workspace/data/workspace_demo.dart';
import 'package:sabi_pipu_tms/modules/workspace/domain/local_workspace.dart';
import 'package:sabi_pipu_tms/modules/workspace/domain/workspace_kind.dart';
import 'package:sabi_pipu_tms/router/router_config.dart';
import 'package:sabi_pipu_tms/theme/tms_theme.dart';

import '../../support/english_catalog.dart';

Future<ProviderContainer> _individual() async {
  SharedPreferences.setMockInitialValues({});
  await LocalWorkspaceStore(await SharedPreferences.getInstance()).save(
    WorkspaceDirectory(
      activeId: 'individual',
      workspaces: [demoWorkspace(WorkspaceKind.individual, DateTime.now())],
    ),
  );
  final container = ProviderContainer();
  await container.read(localWorkspacesProvider.future);
  return container;
}

T _keep<T>(ProviderContainer c, ProviderListenable<T> p) {
  final sub = c.listen(p, (_, _) {});
  addTearDown(sub.close);
  return sub.read();
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('quick add reads day, priority, project and person tokens', () {
    final d = parseTask('Send moodboard fri !high #brand @tolu');
    expect(d.title, 'Send moodboard');
    expect(
      (d.due, d.priority, d.project, d.person),
      (5, 'high', 'brand', 'tolu'),
    );
    final friday = taskDueDate(d, DateTime(2026, 11, 26));
    expect(friday, DateTime(2026, 11, 27));
    expect(parseTask('Call mum').hasTokens, isFalse);
  });

  test('home cards add up the prototype business', () async {
    final c = await _individual();
    addTearDown(c.dispose);
    final s = _keep(c, individualSummaryProvider('individual'))!;
    expect((s.activeClients, s.clients), (2, 4));
    expect((s.received, s.billed, s.owing), (91000000, 202000000, 3));
    expect(s.openProposals, 2);
    expect(s.watch?.title, 'Brand Refresh');
    expect(s.upcoming.single.title, 'Renew domain and email hosting');
    _keep(c, individualHomeProvider('individual'));
    final home = c.read(individualHomeProvider('individual').notifier);
    home.edit('Invoice Nexora tomorrow #retainer');
    expect(await home.add(), 'Invoice Nexora');
    expect(c.read(individualSummaryProvider('individual'))!.upcoming.length, 2);
  });

  test('gigs tick milestones and proposals move through stages', () async {
    final c = await _individual();
    addTearDown(c.dispose);
    final gig = _keep(c, gigsProvider('individual')).single;
    expect(gig.milestoneState(1), MilestoneState.late);
    await c
        .read(gigsControllerProvider('individual'))
        .toggleMilestone(gig, 'Moodboard');
    final after = c.read(gigsProvider('individual')).single;
    expect(after.tasksDone, closeTo(2 / 3, .01));

    final args = ('individual', true);
    _keep(c, clientsControllerProvider(args));
    final proposals = _keep(
      c,
      clientRecordsProvider(('individual', WorkspaceSection.proposals)),
    );
    final todo = proposals.firstWhere((p) => p.stage == 'todo');
    await c
        .read(clientsControllerProvider(args).notifier)
        .setStage(todo, 'sent');
    final sent = c
        .read(clientRecordsProvider(('individual', WorkspaceSection.proposals)))
        .firstWhere((p) => p.id == todo.id);
    expect((sent.stage, sent.status), ('sent', WorkspaceStatus.inProgress));
  });

  test('time totals the week and flips billable entries', () async {
    final c = await _individual();
    addTearDown(c.dispose);
    final t = _keep(c, timeSummaryProvider('individual'))!;
    expect(
      (t.minutes, t.billableMinutes, t.billableValue),
      (480, 390, 9750000),
    );
    final admin = t.entries.firstWhere((e) => !e.flagged);
    await c.read(timeActionsProvider('individual')).toggleBillable(admin);
    expect(c.read(timeSummaryProvider('individual'))!.billableMinutes, 480);
  });

  testWidgets('the bottom bar switches between section screens', (
    tester,
  ) async {
    late ProviderContainer container;
    late EnglishCatalog catalog;
    await tester.runAsync(() async {
      await EasyLocalization.ensureInitialized();
      catalog = await EnglishCatalog.preload();
      container = await _individual();
    });
    addTearDown(container.dispose);
    final router = AppRouter();
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: EasyLocalization(
          supportedLocales: const [Locale('en')],
          fallbackLocale: const Locale('en'),
          path: 'assets/translations',
          saveLocale: false,
          assetLoader: catalog,
          child: Builder(
            builder: (c) => MaterialApp.router(
              theme: TmsTheme.dark,
              locale: c.locale,
              supportedLocales: c.supportedLocales,
              localizationsDelegates: c.localizationDelegates,
              routerConfig: router.config(),
            ),
          ),
        ),
      ),
    );
    await tester.pump();
    router.replacePath('/workspace/plan?section=gigs').ignore();
    for (var i = 0; i < 10; i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }
    expect(find.text('Start a gig'), findsOneWidget);
    await tester.tap(find.text('Time').last);
    for (var i = 0; i < 10; i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }
    expect(find.text('Tap play to start tracking'), findsOneWidget);
  });
}
