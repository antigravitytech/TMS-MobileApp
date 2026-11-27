import 'package:auto_route/auto_route.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:sabi_pipu_tms/app/tms_app.dart';
import 'package:sabi_pipu_tms/modules/authentication/presentation/sign_in_screen.dart';
import 'package:sabi_pipu_tms/modules/authentication/presentation/widgets/sign_in_ready.dart';
import 'package:sabi_pipu_tms/modules/authentication/presentation/welcome_screen.dart';
import 'package:sabi_pipu_tms/router/router_config.dart';
import 'package:sabi_pipu_tms/router/tms_routes.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('startup, preview sign-in and profile setup on device', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    await EasyLocalization.ensureInitialized();
    final container = ProviderContainer.test();
    await tester.pumpWidget(
      UncontrolledProviderScope(container: container, child: const TmsApp()),
    );

    for (
      var attempt = 0;
      attempt < 80 && find.byType(WelcomeScreen).evaluate().isEmpty;
      attempt++
    ) {
      await tester.pump(const Duration(milliseconds: 100));
    }
    expect(find.byType(WelcomeScreen), findsOneWidget);
    await tester.pump(const Duration(milliseconds: 750));
    await tester.tap(find.text('Sign in').last);
    await tester.pumpAndSettle(
      const Duration(milliseconds: 100),
      EnginePhase.sendSemanticsUpdate,
      const Duration(seconds: 15),
    );
    expect(find.byType(SignInScreen), findsOneWidget);

    final signIn = find.widgetWithText(FilledButton, 'Sign in');
    await tester.ensureVisible(signIn);
    await tester.tap(signIn);
    await tester.pump(const Duration(milliseconds: 1300));
    await tester.pumpAndSettle(
      const Duration(milliseconds: 100),
      EnginePhase.sendSemanticsUpdate,
      const Duration(seconds: 15),
    );
    expect(find.byType(SignInReady), findsOneWidget);

    await container.read(routerConfigProvider).replaceAll([
      NamedRoute(TmsRoute.profileSetup.name),
    ]);
    await tester.pumpAndSettle(
      const Duration(milliseconds: 100),
      EnginePhase.sendSemanticsUpdate,
      const Duration(seconds: 15),
    );
    final first = find.byType(TextFormField).first;
    await tester.ensureVisible(first);
    await tester.enterText(first, 'Ada');
    final next = find.widgetWithText(FilledButton, 'Continue');
    await tester.ensureVisible(next);
    await tester.tap(next);
    await tester.pumpAndSettle(
      const Duration(milliseconds: 100),
      EnginePhase.sendSemanticsUpdate,
      const Duration(seconds: 15),
    );
    expect(find.text('“Ada’s birthday · 23 November”'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
