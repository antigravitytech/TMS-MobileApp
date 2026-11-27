// Temporary: renders Individual screens to PNG for visual review.
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
import 'package:sabi_pipu_tms/modules/workspace/application/local_workspaces.dart';
import 'package:sabi_pipu_tms/modules/workspace/data/local_workspace_store.dart';
import 'package:sabi_pipu_tms/modules/workspace/data/workspace_demo.dart';
import 'package:sabi_pipu_tms/modules/workspace/domain/local_workspace.dart';
import 'package:sabi_pipu_tms/modules/workspace/domain/workspace_kind.dart';
import 'package:sabi_pipu_tms/router/router_config.dart';
import 'package:sabi_pipu_tms/theme/tms_theme.dart';

import 'support/english_catalog.dart';

const out = String.fromEnvironment('OUT');
final kind = WorkspaceKind.values.byName(
  const String.fromEnvironment('KIND', defaultValue: 'individual'),
);

/// Screens to capture: name and the app path to open.
const shots = String.fromEnvironment(
  'SHOTS',
  defaultValue:
      'home=/home,gigs=/workspace/plan?section=gigs,'
      'time=/workspace/plan?section=time,'
      'invoices=/workspace/plan?section=invoices,'
      'clients=/workspace/plan?section=clients,'
      'proposals=/workspace/plan?section=proposals,more=/more,chat=/chat',
);

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

  testWidgets('capture individual screens', skip: out.isEmpty, (tester) async {
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
        WorkspaceDirectory(
          activeId: kind.name,
          workspaces: [demoWorkspace(kind, DateTime.now())],
        ),
      );
      container = ProviderContainer();
      await container.read(localWorkspacesProvider.future);
    });
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
    Future<void> settle([int n = 20]) async {
      for (var i = 0; i < n; i++) {
        await tester.pump(const Duration(milliseconds: 100));
      }
    }

    Future<void> shoot(String name) => tester.runAsync(() async {
      final boundary =
          key.currentContext!.findRenderObject()! as RenderRepaintBoundary;
      final image = await boundary.toImage(pixelRatio: 2);
      final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
      File('$out/$name.png').writeAsBytesSync(bytes!.buffer.asUint8List());
    });

    await settle(5);
    for (final entry in shots.split(',')) {
      final cut = entry.indexOf('=');
      final name = entry.substring(0, cut), path = entry.substring(cut + 1);
      router.replacePath(path).ignore();
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 900)),
      );
      await settle();
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 500)),
      );
      await settle(5);
      await shoot('${kind.name}-$name');
      final scroll = find.byType(Scrollable);
      if (scroll.evaluate().isNotEmpty) {
        await tester.drag(scroll.first, const Offset(0, -700));
        await settle(10);
        await shoot('${kind.name}-$name-2');
      }
    }
    const tapTab = String.fromEnvironment('TAP');
    for (final label in tapTab.split(',').where((t) => t.isNotEmpty)) {
      final byText = find.text(label);
      final chip =
          (byText.evaluate().isEmpty ? find.byTooltip(label) : byText).first;
      await tester.ensureVisible(chip);
      await settle(3);
      await tester.tap(chip);
      await settle();
      await shoot('${kind.name}-tap-$label');
      final scroll = find.byType(Scrollable);
      if (scroll.evaluate().length > 1) {
        await tester.drag(scroll.at(1), const Offset(0, -650));
        await settle(10);
        await shoot('${kind.name}-tap-$label-2');
      }
    }
    container.dispose();
  });
}
