// Temporary: renders Family screens to PNG for visual review.
import 'dart:convert';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sabi_pipu_tms/modules/chores/presentation/chores_screen.dart';
import 'package:sabi_pipu_tms/modules/shopping/presentation/shopping_screen.dart';
import 'package:sabi_pipu_tms/modules/family/presentation/kid_home_screen.dart';
import 'package:sabi_pipu_tms/modules/school/presentation/school_screen.dart';
import 'package:sabi_pipu_tms/modules/rewards/presentation/rewards_screen.dart';
import 'package:sabi_pipu_tms/modules/bills/presentation/bills_screen.dart';
import 'package:sabi_pipu_tms/modules/family/presentation/household_screen.dart';
import 'package:sabi_pipu_tms/modules/workspace/presentation/more_screen.dart';
import 'package:sabi_pipu_tms/modules/family/presentation/family_home_screen.dart';
import 'package:sabi_pipu_tms/modules/chat/presentation/chat_screens.dart';
import 'package:sabi_pipu_tms/modules/workspace/application/local_workspaces.dart';
import 'package:sabi_pipu_tms/modules/family/data/family_reference.dart';
import 'package:sabi_pipu_tms/modules/workspace/data/local_workspace_store.dart';
import 'package:sabi_pipu_tms/modules/workspace/domain/local_workspace.dart';
import 'package:sabi_pipu_tms/theme/tms_theme.dart';
import 'package:sabi_pipu_tms/router/router_config.dart';
import 'package:sabi_pipu_tms/router/tms_routes.dart';
import 'package:sabi_pipu_tms/modules/workspace/domain/workspace_kind.dart';
import 'package:auto_route/auto_route.dart';

import 'support/english_catalog.dart';

const out = String.fromEnvironment('OUT');

Future<void> loadFonts() async {
  final manifest =
      json.decode(await rootBundle.loadString('FontManifest.json')) as List;
  for (final family in manifest.cast<Map<String, dynamic>>()) {
    final loader = FontLoader(family['family'] as String);
    for (final font in (family['fonts'] as List).cast<Map>()) {
      loader.addFont(rootBundle.load(font['asset'] as String));
    }
    await loader.load();
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  final key = GlobalKey();

  Future<void> shoot(WidgetTester tester, String name) async {
    await tester.runAsync(() async {
      final boundary =
          key.currentContext!.findRenderObject()! as RenderRepaintBoundary;
      final image = await boundary.toImage(pixelRatio: 2);
      final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
      File('$out/$name.png').writeAsBytesSync(bytes!.buffer.asUint8List());
    });
  }

  testWidgets('capture family screens', skip: out.isEmpty, (tester) async {
    tester.view.physicalSize = const Size(780, 1688);
    tester.view.devicePixelRatio = 2;
    tester.view.padding = const FakeViewPadding(top: 60, bottom: 30);
    SharedPreferences.setMockInitialValues({});
    late EnglishCatalog catalog;
    late ProviderContainer container;
    await tester.runAsync(() async {
      await loadFonts();
      await EasyLocalization.ensureInitialized();
      catalog = await EnglishCatalog.preload();
      await LocalWorkspaceStore(await SharedPreferences.getInstance()).save(
        WorkspaceDirectory(activeId: 'family', workspaces: [familyReference()]),
      );
      container = ProviderContainer();
      await container.read(localWorkspacesProvider.future);
    });
    final space = container.read(localWorkspacesProvider).requireValue.active!;

    Future<void> show(Widget screen) async {
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
              builder: (c) => RepaintBoundary(
                key: key,
                child: MaterialApp(
                  debugShowCheckedModeBanner: false,
                  theme: TmsTheme.dark,
                  locale: c.locale,
                  supportedLocales: c.supportedLocales,
                  localizationsDelegates: c.localizationDelegates,
                  home: screen,
                ),
              ),
            ),
          ),
        ),
      );
      for (var i = 0; i < 20; i++) {
        await tester.pump(const Duration(milliseconds: 100));
      }
    }

    await show(ChoresScreen(key: UniqueKey(), workspace: space));
    await shoot(tester, '1-chores');
    await tester.tap(find.byTooltip('Add chore'));
    await tester.pumpAndSettle();
    await shoot(tester, '2-chores-add-sheet');

    await show(ShoppingScreen(key: UniqueKey(), workspace: space));
    await shoot(tester, '3-shopping');
    await tester.tap(find.text('In the cart').first);
    await tester.pumpAndSettle();
    await shoot(tester, '4-shopping-empty');
    await show(KidHomeScreen(key: UniqueKey()));
    await shoot(tester, '5-kid-home');
    await tester.drag(find.byType(ListView).first, const Offset(0, -500));
    for (var i = 0; i < 10; i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }
    await shoot(tester, '6-kid-home-scrolled');
    await show(SchoolScreen(key: UniqueKey(), workspace: space));
    await shoot(tester, '7-school');
    await tester.drag(find.byType(ListView).first, const Offset(0, -600));
    for (var i = 0; i < 10; i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }
    await shoot(tester, '8-school-scrolled');
    await show(
      FamilyHomeScreen(key: UniqueKey(), workspace: space, companyName: ''),
    );
    for (final (i, dy) in [(0, 0.0), (1, -700.0), (2, -700.0), (3, -700.0)]) {
      if (dy != 0) {
        await tester.drag(find.byType(Scrollable).first, Offset(0, dy));
        for (var j = 0; j < 10; j++) {
          await tester.pump(const Duration(milliseconds: 100));
        }
      }
      await shoot(tester, '13-home-$i');
    }
    await show(RewardsScreen(key: UniqueKey(), workspace: space));
    await shoot(tester, '14-rewards');
    await tester.tap(find.text('Rewards').last);
    for (var j = 0; j < 10; j++) {
      await tester.pump(const Duration(milliseconds: 100));
    }
    await shoot(tester, '15-rewards-shop');
    await show(BillsScreen(key: UniqueKey(), workspace: space));
    await shoot(tester, '16-bills');
    await tester.tap(find.text('Pay').first);
    for (var j = 0; j < 10; j++) {
      await tester.pump(const Duration(milliseconds: 100));
    }
    await shoot(tester, '17-bills-pay');
    Navigator.of(tester.element(find.text('Record a payment'))).pop();
    for (var j = 0; j < 10; j++) {
      await tester.pump(const Duration(milliseconds: 100));
    }
    await show(HouseholdScreen(key: UniqueKey()));
    await shoot(tester, '18-household');
    await show(MoreScreen(key: UniqueKey()));
    await shoot(tester, '19-more');
    await show(ChatScreen(key: UniqueKey()));
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 300)),
    );
    await tester.pump(const Duration(milliseconds: 500));
    await shoot(tester, '9-chat');
    await show(ConversationScreen(key: UniqueKey()));
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 300)),
    );
    for (var i = 0; i < 30; i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }
    await shoot(tester, '10-thread');
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
            builder: (c) => RepaintBoundary(
              key: key,
              child: MaterialApp.router(
                debugShowCheckedModeBanner: false,
                theme: TmsTheme.dark,
                locale: c.locale,
                supportedLocales: c.supportedLocales,
                localizationsDelegates: c.localizationDelegates,
                routerConfig: router.config(),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pump(const Duration(milliseconds: 200));
    router.push(
      NamedRoute(
        TmsRoute.personalize.name,
        args: (
          kind: WorkspaceKind.values.byName(
            const String.fromEnvironment('SETUP', defaultValue: 'family'),
          ),
          name: '',
        ),
      ),
    );
    for (var i = 0; i < 20; i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }
    await shoot(tester, '11-setup-family');
    await tester.drag(find.byType(Scrollable).last, const Offset(0, -700));
    for (var i = 0; i < 10; i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }
    await shoot(tester, '12-setup-family-scrolled');
    container.dispose();
  });
}
