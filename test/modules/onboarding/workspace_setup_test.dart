import 'package:auto_route/auto_route.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sabi_pipu_tms/app/tms_app.dart';
import 'package:sabi_pipu_tms/router/router_config.dart';
import 'package:sabi_pipu_tms/router/tms_routes.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../support/english_catalog.dart';

void main() {
  late EnglishCatalog catalog;
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(() async {
    catalog = await EnglishCatalog.preload();
    SharedPreferences.setMockInitialValues({});
    await EasyLocalization.ensureInitialized();
  });

  testWidgets(
    'build advances through three steps and the invite screen opens the workspace',
    (tester) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final container = ProviderContainer();
      addTearDown(container.dispose);
      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: TmsApp(assetLoader: catalog),
        ),
      );
      await tester.pump();
      final router = container.read(routerConfigProvider);
      await router.replaceAll([NamedRoute(TmsRoute.building.name)]);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 900));
      expect(find.text('Loading starter templates'), findsOneWidget);
      expect(find.text('Open my space'), findsNothing);
      await tester.pump(const Duration(milliseconds: 2700));
      await tester.pumpAndSettle();
      expect(find.text('Bring the family in'), findsOneWidget);
      await tester.ensureVisible(find.text('QR code'));
      await tester.tap(find.text('QR code').hitTestable());
      await tester.pumpAndSettle();
      expect(find.byType(BottomSheet), findsOneWidget);
      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();
      await tester.tap(find.text('Open my space'));
      await tester.pumpAndSettle();
      expect(router.current.name, TmsRoute.home.name);
    },
  );

  testWidgets(
    'workspace setup opens personal and special choices and returns',
    (tester) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      SharedPreferences.setMockInitialValues({});
      final container = ProviderContainer();
      addTearDown(container.dispose);
      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: TmsApp(assetLoader: catalog),
        ),
      );
      await tester.pump();
      await container.read(routerConfigProvider).replaceAll([
        NamedRoute(TmsRoute.setup.name),
      ]);
      await tester.pumpAndSettle();

      Future<void> tap(String text) async {
        await tester.tap(find.text(text).last);
        await tester.pumpAndSettle();
      }

      expect(find.text('Business'), findsOneWidget);
      expect(find.text('Individual & Family'), findsOneWidget);
      expect(find.text('Specials'), findsOneWidget);
      await tap('Individual & Family');
      await tester.enterText(find.byType(TextFormField), 'The Okafors');
      tester.testTextInput.hide();
      await tester.pumpAndSettle();
      await tap('Continue');
      expect(find.text('Just you,\nor your home?'), findsOneWidget);
      expect(find.text('2 of 5'), findsOneWidget);
      expect(find.text('Time & billing'), findsOneWidget);
      expect(find.text('Chores & points'), findsOneWidget);
      expect(
        tester.getSize(find.widgetWithText(FilledButton, 'Continue')),
        const Size(350, 52),
      );

      await tap('Individual');
      await tap('Continue');
      expect(find.text('Your work'), findsOneWidget);
      await tap('Trader');
      await tap('No');
      expect(find.textContaining('your own tasks and plans'), findsOneWidget);
      await tester.ensureVisible(find.byType(TextFormField));
      await tester.enterText(find.byType(TextFormField), 'Studio Ada');
      await tester.pumpAndSettle();
      expect(find.textContaining('sabipipu.app/studio-ada'), findsOneWidget);
      await tester.tap(find.byTooltip('Back'));
      await tester.pumpAndSettle();

      await tap('Family');
      await tap('Continue');
      expect(find.text('Set up your family'), findsOneWidget);
      expect(
        tester.getSize(find.byTooltip('Change crest')),
        const Size(84, 84),
      );
      await tester.tap(find.byTooltip('Change crest'));
      await tester.pumpAndSettle();
      await tap('Add member');
      await tester.enterText(find.byType(TextFormField).last, 'Tobi');
      await tester.pumpAndSettle();
      await tap('Save');
      expect(find.text('Tobi'), findsOneWidget);
      expect(find.text('Family tablet · PIN'), findsOneWidget);
      await tester.tap(find.widgetWithText(OutlinedButton, 'Child'));
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(ListTile, 'Relative'));
      await tester.pumpAndSettle();
      expect(find.widgetWithText(OutlinedButton, 'Relative'), findsOneWidget);
      await tester.tap(find.byTooltip('Remove'));
      await tester.pumpAndSettle();
      expect(find.text('Tobi'), findsNothing);
      await tester.tap(find.byTooltip('Back'));
      await tester.pumpAndSettle();
      await tester.tap(find.byTooltip('Back'));
      await tester.pumpAndSettle();
      await tap('Specials');
      await tester.enterText(
        find.byType(TextFormField),
        'Unilag Class of 2015',
      );
      tester.testTextInput.hide();
      await tester.pumpAndSettle();
      await tap('Continue');
      expect(find.text('What kind?'), findsOneWidget);
      expect(find.text('2 of 5'), findsOneWidget);
      expect(find.text('Estate or residents'), findsOneWidget);
      expect(find.byType(TextFormField), findsNothing);
      for (final (kind, feature) in const [
        ('Church or ministry', 'Giving & pledges'),
        ('Alumni association', 'Dues tracker'),
        ('Estate or residents', 'Gate passes'),
        ('Event', 'Guest list & RSVP'),
        ('Club or society', 'Attendance'),
        ('Committee', 'Action items'),
      ]) {
        await tap(kind);
        await tap('Continue');
        expect(find.text('3 of 5'), findsOneWidget);
        expect(find.text(feature), findsOneWidget);
        expect(find.text('Unilag Class of 2015'), findsOneWidget);
        if (kind != 'Committee') {
          await tester.tap(find.byTooltip('Back'));
          await tester.pumpAndSettle();
        }
      }
      expect(find.text('Milestone · optional'), findsOneWidget);
      await tester.enterText(
        find.byType(TextFormField).last,
        'Committee term closes',
      );
      await tester.pumpAndSettle();
      await tap('Choose a date');
      expect(find.byType(DatePickerDialog), findsOneWidget);
      await tap('OK');
      expect(find.text('DAYS TO GO'), findsOneWidget);
      expect(find.text('Committee term closes'), findsNWidgets(2));
      await tester.tap(find.byTooltip('Clear date'));
      await tester.pumpAndSettle();
      expect(find.text('Countdown preview'), findsOneWidget);
      expect(
        tester.getSize(find.widgetWithText(FilledButton, 'Build my space')),
        const Size(350, 52),
      );
      expect(tester.takeException(), isNull);
    },
  );
}
