part of 'widget_test.dart';

void _registerRouteTests(AssetLoader Function() catalog) {
  testWidgets('splash holds the final mark before its automatic wipe', (
    tester,
  ) async {
    await tester.runAsync(
      () => (FontLoader(
        'Inter',
      )..addFont(rootBundle.load('assets/fonts/Inter.ttf'))).load(),
    );
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(
      ProviderScope(child: TmsApp(assetLoader: catalog())),
    );
    await tester.pump();
    await tester.pump();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 3600));
    final mark = find.byType(SplashBrandMark);
    expect(tester.getSize(mark), const Size(104, 104));
    expect(tester.getTopLeft(mark).dx, 143);
    expect(tester.getTopLeft(mark).dy, closeTo(294, 1));
    expect(find.byType(WelcomeScreen), findsNothing);
    await tester.pump(const Duration(milliseconds: 100));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 350));
    expect(find.byType(WelcomeScreen), findsOneWidget);
    expect(find.byType(SplashScreen), findsOneWidget);
    await tester.pump(const Duration(milliseconds: 351));
    await tester.pump();
    expect(find.byType(SplashScreen), findsNothing);
  });

  testWidgets('splash opens the native welcome and demo sign-in reaches Home', (
    tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(child: TmsApp(assetLoader: catalog())),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));
    expect(find.byType(SplashScreen), findsOneWidget);
    await tester.tap(find.byType(SplashScreen));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 710));
    expect(find.byType(WelcomeScreen), findsOneWidget);
    await tester.tap(find.text('Sign in'));
    await tester.pumpAndSettle();
    await tester.drag(find.byType(ListView), const Offset(0, -450));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Company'));
    await tester.pumpAndSettle();
    expect(find.text('Good morning, Chioma'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'every design screen renders as a registered native route on a phone',
    (tester) async {
      tester.view.physicalSize = const Size(1080, 2220);
      tester.view.devicePixelRatio = 3;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final container = ProviderContainer();
      addTearDown(container.dispose);
      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: TmsApp(assetLoader: catalog()),
        ),
      );
      await tester.pump();
      final failures = <String>[];
      for (final route in TmsRoute.values.skip(1)) {
        final router = container.read(routerConfigProvider);
        await router.replaceAll([
          NamedRoute(route.name),
        ], updateExistingRoutes: false);
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 500));
        await tester.pump();
        expect(router.current.name, route.name);
        expect(
          find.byType(AppRouter.screens[route]!.runtimeType),
          findsOneWidget,
          reason: route.path,
        );
        final problem = tester.takeException();
        if (problem != null) failures.add("${route.path}: $problem");
      }
      expect(failures, isEmpty);
    },
  );

  testWidgets('welcome content slides upward after opening', (tester) async {
    SharedPreferences.setMockInitialValues({});
    final container = ProviderContainer();
    addTearDown(container.dispose);
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: TmsApp(assetLoader: catalog()),
      ),
    );
    await tester.pump();
    await container.read(routerConfigProvider).replaceAll([
      NamedRoute(TmsRoute.welcome.name),
    ]);
    await tester.pump();
    final headline = find.text("Your team's rhythm,");
    final button = find.text('Get started');
    expect(headline, findsOneWidget);
    final startHeadline = tester.getTopLeft(headline).dy;
    final startButton = tester.getTopLeft(button).dy;
    await tester.pump(const Duration(milliseconds: 1100));
    expect(tester.getTopLeft(headline).dy, lessThan(startHeadline - 10));
    expect(tester.getTopLeft(button).dy, lessThan(startButton - 10));
  });
}
