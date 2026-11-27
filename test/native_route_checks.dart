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
    final brand = find.text('Sabi');
    final brandTop = tester.getTopLeft(brand).dy;
    expect(brandTop, closeTo(16, 1));
    tester.view.padding = const FakeViewPadding(top: 26, bottom: 22);
    addTearDown(tester.view.resetPadding);
    await tester.pumpAndSettle();
    expect(
      tester.getTopLeft(brand).dy - brandTop,
      closeTo(26 / tester.view.devicePixelRatio, .1),
    );
    expect(find.text('Welcome back'), findsOneWidget);
    expect(
      tester.widget<EditableText>(find.byType(EditableText).last).obscureText,
      isTrue,
    );
    await tester.tap(find.byTooltip('Show password'));
    await tester.pumpAndSettle();
    expect(
      tester.widget<EditableText>(find.byType(EditableText).last).obscureText,
      isFalse,
    );
    await tester.tap(find.text('Forgot password?'));
    await tester.pumpAndSettle();
    expect(find.byType(BottomSheet), findsOneWidget);
    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    await tester.drag(find.byType(ListView), const Offset(0, -450));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Company'));
    await tester.pumpAndSettle();
    expect(find.text('Good morning, Chioma'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'Company Home keeps compact cards and renders the entire review queue',
    (tester) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      tester.view.padding = const FakeViewPadding(top: 26, bottom: 22);
      addTearDown(tester.view.resetPadding);
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
        NamedRoute(TmsRoute.home.name),
      ]);
      await tester.pumpAndSettle();

      final notification = find.byTooltip('Notifications');
      final homeTab = find.text('Home');
      final withInsetsTop = tester.getTopLeft(notification).dy;
      final withInsetsTab = tester.getTopLeft(homeTab).dy;
      tester.view.padding = const FakeViewPadding();
      await tester.pumpAndSettle();
      expect(tester.getTopLeft(notification).dy, closeTo(10, 1));
      expect(withInsetsTop - tester.getTopLeft(notification).dy, 26);
      expect(tester.getTopLeft(homeTab).dy - withInsetsTab, 22);

      final fab = find.byTooltip('Quick create');
      expect(tester.getSize(fab), const Size.square(60));
      await tester.tap(fab);
      await tester.pumpAndSettle();
      expect(find.byTooltip('Close quick create'), findsOneWidget);
      await tester.tap(find.byTooltip('Close quick create'));
      await tester.pumpAndSettle();

      final scroll = find.byType(ListView);
      await tester.scrollUntilVisible(
        find.text('Awaiting my review'),
        300,
        scrollable: find
            .descendant(of: scroll, matching: find.byType(Scrollable))
            .first,
      );
      await tester.pumpAndSettle();
      expect(find.text('Payment webhook retry handler'), findsOneWidget);
      await tester.ensureVisible(find.text('Onboarding flow usability test'));
      final approve = find.widgetWithText(TextButton, 'Approve').first;
      await tester.ensureVisible(approve);
      await tester.tap(approve);
      await tester.pumpAndSettle();
      expect(container.read(workspacePreviewProvider).reviewQueue.length, 2);
      expect(find.text('Onboarding flow usability test'), findsNothing);
      await tester.scrollUntilVisible(
        find.text('Sprint 14 retro notes'),
        300,
        scrollable: find
            .descendant(of: scroll, matching: find.byType(Scrollable))
            .first,
      );
      await tester.pumpAndSettle();
      expect(find.text('Coming up'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'Notifications group and filter cards and preserve mark-read state',
    (tester) async {
      await tester.runAsync(
        () => (FontLoader(
          'Inter',
        )..addFont(rootBundle.load('assets/fonts/Inter.ttf'))).load(),
      );
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1;
      tester.view.padding = const FakeViewPadding(top: 26, bottom: 22);
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      addTearDown(tester.view.resetPadding);
      final container = ProviderContainer();
      addTearDown(container.dispose);
      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: TmsApp(assetLoader: catalog()),
        ),
      );
      await tester.pump();
      final router = container.read(routerConfigProvider);
      await router.replaceAll([NamedRoute(TmsRoute.notifications.name)]);
      await tester.pumpAndSettle();

      expect(tester.getTopLeft(find.byTooltip('Back')).dy, closeTo(36, 2));
      expect(find.text('TODAY'), findsOneWidget);
      expect(find.text('YESTERDAY'), findsOneWidget);
      expect(find.text('6'), findsOneWidget);
      await tester.tap(find.text('Reviews'));
      await tester.pumpAndSettle();
      expect(find.textContaining('Tunde Bakare resubmitted'), findsOneWidget);
      expect(find.textContaining('Mama Bisi'), findsNothing);
      await tester.tap(find.text('Mentions'));
      await tester.pumpAndSettle();
      expect(find.text('TODAY'), findsNothing);
      final mention = find.textContaining('David Mensah mentioned');
      expect(mention, findsOneWidget);
      await tester.tap(mention);
      await tester.pumpAndSettle();
      expect(router.current.name, TmsRoute.conversation.name);
      expect(find.text('David Mensah'), findsOneWidget);
      expect(container.read(workspacePreviewProvider).readNotifications, {4});

      await router.replaceAll([NamedRoute(TmsRoute.notifications.name)]);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Unread only'));
      await tester.pumpAndSettle();
      expect(mention, findsNothing);
      await tester.tap(find.text('Mark all read'));
      await tester.pumpAndSettle();
      expect(find.text("You're all caught up"), findsOneWidget);
      expect(
        container.read(workspacePreviewProvider).readNotifications.length,
        6,
      );
    },
  );

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
