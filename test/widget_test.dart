import 'package:auto_route/auto_route.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sabi_pipu_tms/app/tms_app.dart';
import 'package:sabi_pipu_tms/core/network/api_response.dart';
import 'package:sabi_pipu_tms/l10n/network_failure_localization.dart';
import 'package:sabi_pipu_tms/modules/onboarding/presentation/welcome_screen.dart';
import 'package:sabi_pipu_tms/modules/workspace/application/local_workspaces.dart';
import 'package:sabi_pipu_tms/modules/workspace/application/workspace_preview.dart';
import 'package:sabi_pipu_tms/modules/workspace/domain/workspace_kind.dart';
import 'package:sabi_pipu_tms/router/router_config.dart';
import 'package:sabi_pipu_tms/router/tms_routes.dart';
import 'package:shared_preferences/shared_preferences.dart';

part 'native_route_checks.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late _TestLocaleLoader localeLoader;
  setUpAll(() async {
    SharedPreferences.setMockInitialValues({});
    await EasyLocalization.ensureInitialized();
    final english = await const RootBundleAssetLoader().load(
      'assets/translations',
      const Locale('en'),
    );
    localeLoader = _TestLocaleLoader(english!);
  });

  _registerRouteTests(() => localeLoader);

  testWidgets('a native review swipe updates the workspace approval queue', (
    tester,
  ) async {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: TmsApp(assetLoader: localeLoader),
      ),
    );
    await tester.pump();
    await container.read(routerConfigProvider).replaceAll([
      NamedRoute(TmsRoute.approvals.name),
    ]);
    await tester.pumpAndSettle();
    final initial = container.read(workspacePreviewProvider).reviewQueue.first;
    await tester.drag(find.text(initial.title), const Offset(210, 0));
    await tester.pumpAndSettle();
    expect(
      container.read(workspacePreviewProvider).approved,
      contains(initial.id),
    );
    expect(find.text('Approved · ${initial.title}'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Family schoolwork can be submitted, returned and approved', (
    tester,
  ) async {
    final container = await _openWorkspaceApp(
      tester,
      localeLoader,
      TmsRoute.more,
    );
    await _tapText(tester, 'Switch');
    await _tapText(tester, 'Family');
    expect(find.text('Today at home'), findsOneWidget);
    expect(find.text('Approvals'), findsNothing);

    await _tapText(tester, 'School');
    await _tapText(tester, 'Add school item');
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Title'),
      'Maths worksheet',
    );
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Assigned to'),
      'Taylor',
    );
    await _tapText(tester, 'Save');
    await _tapText(tester, 'Maths worksheet');
    await _tapText(tester, 'Submit for review');
    await _tapText(tester, 'Home');

    expect(find.text('1 item needs review'), findsOneWidget);
    await _tapText(tester, 'Review work');
    await _tapText(tester, 'Maths worksheet');
    await _tapText(tester, 'Send back');
    final provider = container.read(localWorkspacesProvider).requireValue;
    expect(
      provider.active!.items(WorkspaceSection.school).single.status,
      WorkspaceStatus.returned,
    );
    await _tapText(tester, 'All');
    await _tapText(tester, 'Maths worksheet');
    await _tapText(tester, 'Submit for review');
    await _tapText(tester, 'Maths worksheet');
    await _tapText(tester, 'Approve');
    await _tapText(tester, 'Home');
    expect(find.text('1 point'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'Individual invoices total their line items and record payments',
    (tester) async {
      await _openWorkspaceApp(tester, localeLoader, TmsRoute.more);
      await _tapText(tester, 'Switch');
      await _tapText(tester, 'Individual');
      await _tapText(tester, 'Invoices');
      await _tapText(tester, 'New invoice');
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Invoice number'),
        'INV-100',
      );
      await _tapText(tester, 'Add line item');
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Description'),
        'Design review',
      );
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Quantity'),
        '2',
      );
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Unit rate (NGN)'),
        '1500',
      );
      await _tapText(tester, 'Save');
      await _tapText(tester, 'Save');
      expect(find.text('Outstanding'), findsOneWidget);
      expect(find.text('₦3,000'), findsWidgets);
      await _tapText(tester, 'INV-100');
      await _tapText(tester, 'Record payment');
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Amount (NGN)'),
        '1000',
      );
      await _tapText(tester, 'Record payment');
      expect(find.text('₦2,000'), findsWidgets);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('Special event RSVPs update seating and the overview', (
    tester,
  ) async {
    await _openWorkspaceApp(tester, localeLoader, TmsRoute.more);
    await _tapText(tester, 'Switch');
    await _tapText(tester, 'Wedding & event');
    await _tapText(tester, 'Guest list');
    await _tapText(tester, 'Add guest');
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Name'),
      'Jordan',
    );
    await tester.enterText(find.widgetWithText(TextFormField, 'Table'), 'A');
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Party size'),
      '2',
    );
    final status = find.byType(DropdownButtonFormField<WorkspaceStatus>);
    await tester.ensureVisible(status);
    await tester.tap(status);
    await tester.pumpAndSettle();
    await _tapText(tester, 'Coming');
    await _tapText(tester, 'Save');
    await _tapText(tester, 'Seating');
    expect(find.text('Table A'), findsOneWidget);
    expect(find.text('Jordan'), findsOneWidget);
    expect(find.text('2 seats'), findsOneWidget);
    await _tapText(tester, 'Home');
    expect(find.text('2 confirmed seats'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('each Specials type has its own tools on a compact screen', (
    tester,
  ) async {
    final container = await _openWorkspaceApp(
      tester,
      localeLoader,
      TmsRoute.home,
    );
    tester.view.physicalSize = const Size(960, 1920);
    tester.platformDispatcher.textScaleFactorTestValue = 1.3;
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);

    final workspaces = container.read(localWorkspacesProvider.notifier);
    const sections = {
      WorkspaceKind.event: 'Guest list',
      WorkspaceKind.church: 'Services',
      WorkspaceKind.alumni: 'Dues & pledges',
      WorkspaceKind.estate: 'Levies',
      WorkspaceKind.committee: 'Meetings',
      WorkspaceKind.club: 'Sessions',
    };

    for (final kind in WorkspaceKind.specials) {
      await workspaces.select(kind.name);
      await tester.pumpAndSettle();
      await _tapText(tester, sections[kind]!);
      expect(find.text('Nothing here yet'), findsOneWidget, reason: kind.name);
      expect(tester.takeException(), isNull, reason: kind.name);
      await _tapText(tester, 'Home');
    }
    await workspaces.select(WorkspaceKind.business.name);
    await tester.pumpAndSettle();
    expect(find.text('Good morning, Chioma'), findsOneWidget);
    expect(find.text('Approvals'), findsOneWidget);
  });

  testWidgets(
    'locale changes update the UI and missing copy falls back to English',
    (tester) async {
      const english = Locale('en');
      const french = Locale('fr');
      await tester.pumpWidget(
        EasyLocalization(
          supportedLocales: const [english, french],
          startLocale: french,
          fallbackLocale: english,
          useFallbackTranslations: true,
          saveLocale: false,
          path: 'assets/translations',
          assetLoader: localeLoader,
          child: Builder(
            builder: (context) => MaterialApp(
              locale: context.locale,
              supportedLocales: context.supportedLocales,
              localizationsDelegates: context.localizationDelegates,
              home: Builder(
                builder: (context) => Scaffold(
                  body: Column(
                    children: [
                      Text(context.tr('common.today')),
                      Text(context.plural('tasks.days_overdue', 2)),
                      Text(
                        NetworkFailureType.unauthorized.localizedMessage(
                          context,
                        ),
                      ),
                      TextButton(
                        onPressed: () => context.setLocale(english),
                        child: const Text('EN'),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Aujourd’hui'), findsOneWidget);
      expect(find.text('2 days overdue'), findsOneWidget);
      expect(
        find.text('Your session has expired. Please sign in again.'),
        findsOneWidget,
      );

      await tester.tap(find.text('EN'));
      await tester.pumpAndSettle();
      expect(find.text('Today'), findsOneWidget);
      expect(find.text('Aujourd’hui'), findsNothing);
    },
  );
}

Future<ProviderContainer> _openWorkspaceApp(
  WidgetTester tester,
  AssetLoader loader,
  TmsRoute route,
) async {
  SharedPreferences.setMockInitialValues({});
  tester.view.physicalSize = const Size(1170, 2532);
  tester.view.devicePixelRatio = 3;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);

  final container = ProviderContainer();
  addTearDown(container.dispose);
  await tester.pumpWidget(
    UncontrolledProviderScope(
      container: container,
      child: TmsApp(assetLoader: loader),
    ),
  );
  await tester.pump();
  await container.read(routerConfigProvider).replaceAll([
    NamedRoute(route.name),
  ]);
  await tester.pumpAndSettle();
  return container;
}

Future<void> _tapText(WidgetTester tester, String label) async {
  final matches = find.text(label);
  if (matches.evaluate().isEmpty) {
    await tester.scrollUntilVisible(
      matches,
      200,
      scrollable: find
          .descendant(
            of: find.byType(ListView).first,
            matching: find.byType(Scrollable),
          )
          .first,
    );
  }
  final target = matches.last;
  await tester.ensureVisible(target);
  await tester.pumpAndSettle();
  await tester.tap(target);
  await tester.pumpAndSettle();
}

class _TestLocaleLoader extends AssetLoader {
  const _TestLocaleLoader(this.english);

  final Map<String, dynamic> english;

  @override
  Future<Map<String, dynamic>?> load(String path, Locale locale) async {
    if (locale.languageCode == 'fr') {
      return {
        'common': {'today': 'Aujourd’hui'},
      };
    }
    return english;
  }
}
