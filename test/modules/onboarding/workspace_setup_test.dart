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
      expect(find.text('Just you, or your home?'), findsOneWidget);
      await tap('Family');
      expect(find.byType(TextFormField), findsNothing);
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
      expect(find.text('Estate or residents’ association'), findsOneWidget);
      await tap('Church or ministry');
      expect(find.byType(TextFormField), findsNothing);
      expect(tester.takeException(), isNull);
    },
  );
}
