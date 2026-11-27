import 'package:auto_route/auto_route.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sabi_pipu_tms/app/tms_app.dart';
import 'package:sabi_pipu_tms/modules/onboarding/application/profile_setup_notifier.dart';
import 'package:sabi_pipu_tms/router/router_config.dart';
import 'package:sabi_pipu_tms/modules/workspace/application/local_workspaces.dart';
import 'package:sabi_pipu_tms/router/tms_routes.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../support/english_catalog.dart';

void main() {
  late EnglishCatalog catalog;
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(() async {
    catalog = await EnglishCatalog.preload();
    final font = FontLoader('Inter')
      ..addFont(rootBundle.load('assets/fonts/Inter.ttf'));
    await font.load();
  });

  testWidgets(
    'profile setup follows the reference layout and keeps edits between steps',
    (tester) async {
      SharedPreferences.setMockInitialValues({});
      await EasyLocalization.ensureInitialized();
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = const Size(390, 844);
      const insets = FakeViewPadding(top: 26, bottom: 22);
      tester.view.padding = insets;
      addTearDown(tester.view.resetPadding);
      addTearDown(tester.view.resetDevicePixelRatio);
      addTearDown(tester.view.resetPhysicalSize);

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
        NamedRoute(TmsRoute.profileSetup.name),
      ]);
      await tester.pumpAndSettle();

      final progress = find.byType(LinearProgressIndicator);
      expect(tester.getSize(progress).height, 6);
      expect(
        tester.getCenter(progress).dy,
        tester.getCenter(find.byTooltip('Back')).dy,
      );
      expect(
        tester.getTopLeft(find.text('ABOUT YOU')).dy,
        greaterThan(tester.getBottomLeft(progress).dy),
      );
      expect(find.text('Let your team\nknow who you are'), findsOneWidget);
      expect(
        tester.getTopLeft(find.text('First name')).dy,
        lessThan(tester.getTopLeft(find.byType(TextFormField).first).dy),
      );
      expect(
        tester.getCenter(find.byTooltip('Avatar colour 1')).dy,
        tester.getCenter(find.byTooltip('Avatar colour 6')).dy,
      );

      final member = find.widgetWithText(ChoiceChip, 'Member');
      final project = find.widgetWithText(ChoiceChip, 'Project manager');
      expect(tester.widget<ChoiceChip>(member).selected, isTrue);
      expect(tester.widget<ChoiceChip>(project).selected, isFalse);
      expect(
        tester.getTopLeft(project).dy,
        greaterThan(tester.getTopLeft(member).dy),
      );

      final next = find.widgetWithText(FilledButton, 'Continue');
      expect(tester.getSize(next).height, 52);
      expect(tester.getTopLeft(find.byTooltip('Back')).dy, 34);
      expect(
        tester
            .getBottomLeft(find.widgetWithText(TextButton, 'Skip for now'))
            .dy,
        844 - insets.bottom - 12,
      );
      await tester.enterText(find.byType(TextFormField).first, 'Ada');
      await tester.tap(next);
      await tester.pumpAndSettle();
      expect(find.text('3 of 4'), findsOneWidget);
      expect(find.text('1997'), findsOneWidget);
      expect(find.text('“Ada’s birthday · 23 November”'), findsOneWidget);
      final dateFields = find.byType(DropdownButton<int>);
      expect(tester.getSize(dateFields.first), const Size(110, 54));
      await tester.tap(dateFields.at(1));
      await tester.pumpAndSettle();
      await tester.tap(find.text('February').last);
      await tester.pumpAndSettle();
      expect(find.text('“Ada’s birthday · 23 February”'), findsOneWidget);
      await tester.tap(find.text('Nobody'));
      await tester.pumpAndSettle();
      expect(container.read(profileSetupProvider).birthdayVisible, isFalse);
      await tester.tap(find.text('My colleagues'));
      await tester.pumpAndSettle();
      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();
      expect(find.text('Ada'), findsOneWidget);
      await tester.tap(next);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Skip for now'));
      await tester.pumpAndSettle();
      expect(find.text('4 of 4'), findsOneWidget);
      expect(find.text('Finish setup'), findsOneWidget);

      final clockReminder = find.widgetWithText(
        SwitchListTile,
        'Clock-in reminder',
      );
      await tester.ensureVisible(clockReminder);
      await tester.tap(clockReminder);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Finish setup'));
      await tester.pumpAndSettle();
      final router = container.read(routerConfigProvider);
      expect(router.current.name, TmsRoute.businessReady.name);
      expect(find.text("You're all set, Ada"), findsOneWidget);
      expect(find.text('1 task due today'), findsOneWidget);
      expect(find.text('3 waiting for your review'), findsOneWidget);
      final openDay = find.widgetWithText(FilledButton, 'Go to my day');
      expect(tester.getSize(openDay), const Size(350, 52));
      expect(tester.getBottomLeft(openDay).dy, 844 - insets.bottom - 12);
      await tester.tap(openDay);
      await tester.pumpAndSettle();
      expect(router.current.name, TmsRoute.home.name);
      expect(find.text('Go to my day'), findsNothing);

      final preferences = await SharedPreferences.getInstance();
      expect(preferences.getString('onboarding.birthday'), '');
      expect(preferences.getBool('onboarding.birthday_visible'), isTrue);
      expect(preferences.getBool('onboarding.nudge.clock'), isTrue);
      expect(tester.takeException(), isNull);
    },
  );
  testWidgets('non-business workspaces bypass Business completion', (
    tester,
  ) async {
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
    await container.read(localWorkspacesProvider.notifier).select('family');
    final router = container.read(routerConfigProvider);
    await router.replaceAll([NamedRoute(TmsRoute.profileSetup.name)]);
    await tester.pumpAndSettle();
    for (var step = 0; step < 3; step++) {
      await tester.tap(find.text('Skip for now'));
      await tester.pumpAndSettle();
    }
    expect(router.current.name, TmsRoute.home.name);
    expect(find.text('Go to my day'), findsNothing);
  });
}
