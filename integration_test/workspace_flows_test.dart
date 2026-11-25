import 'dart:io';
import 'dart:typed_data';
import 'package:file_picker/file_picker.dart';

import 'package:auto_route/auto_route.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:sabi_pipu_tms/app/tms_app.dart';
import 'package:sabi_pipu_tms/modules/onboarding/presentation/welcome_screen.dart';
import 'package:sabi_pipu_tms/modules/workspace/application/local_workspaces.dart';
import 'package:sabi_pipu_tms/modules/workspace/domain/workspace_kind.dart';
import 'package:sabi_pipu_tms/router/router_config.dart';
import 'package:sabi_pipu_tms/router/tms_routes.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  testWidgets(
    'Personal billing, household review and event arrivals on device',
    (tester) async {
      SharedPreferences.setMockInitialValues({});
      await EasyLocalization.ensureInitialized();
      final container = ProviderContainer();
      addTearDown(container.dispose);
      final router = container.read(routerConfigProvider);
      await tester.pumpWidget(
        UncontrolledProviderScope(container: container, child: const TmsApp()),
      );
      for (
        var attempt = 0;
        attempt < 50 &&
            find.byType(SplashScreen).evaluate().isEmpty &&
            find.byType(WelcomeScreen).evaluate().isEmpty;
        attempt++
      ) {
        await tester.pump(const Duration(milliseconds: 100));
      }
      await router.replaceAll([NamedRoute(TmsRoute.signIn.name)]);
      await tester.pumpAndSettle();

      var converted = false;
      Future<void> capture(String name) async {
        if (!const bool.fromEnvironment('WORKSPACE_SCREENSHOTS')) return;
        if (Platform.isAndroid && !converted) {
          await binding.convertFlutterSurfaceToImage();
          converted = true;
        }
        await tester.pumpAndSettle();
        await binding.takeScreenshot(name);
      }

      Future<void> tap(String label) async {
        final matches = find.text(label);
        if (matches.evaluate().isEmpty) {
          await tester.scrollUntilVisible(
            matches,
            240,
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

      Future<void> switchTo(String label) async {
        await tap('More');
        await tap('Switch');
        await tap(label);
      }

      await tap('Individual');
      await capture('individual-home');
      await tap('Invoices');
      await tap('INV-014');
      await tap('Preview document');
      final picker = FilePickerPlatform.instance;
      final downloads = _TestDownloads();
      FilePickerPlatform.instance = downloads;
      addTearDown(() => FilePickerPlatform.instance = picker);
      for (final (label, signature) in [
        ('Save PDF', [37, 80, 68, 70]),
        ('Save image', [137, 80, 78, 71]),
      ]) {
        downloads.bytes = null;
        await tap(label);
        for (var i = 0; i < 50 && downloads.bytes == null; i++) {
          await tester.pump(const Duration(milliseconds: 100));
        }
        expect(downloads.bytes?.take(4), signature, reason: label);
      }
      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();
      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();
      await tap('Proposals');
      await tap('Launch campaign');
      await tap('Edit');
      expect(find.byTooltip('Bold'), findsOneWidget);
      await tap('Save');
      await switchTo('Family');
      await capture('family-home');
      await tap('Review work');
      await tap('Reading journal');
      await tap('Approve');
      await tap('Home');
      expect(find.text('15 points'), findsOneWidget);

      await switchTo('Wedding & event');
      await tap('Guest list');
      await tap('Check-in mode');
      await tester.tap(find.byTooltip('Check guest in'));
      await tester.pumpAndSettle();
      expect(
        container
            .read(localWorkspacesProvider)
            .requireValue
            .active!
            .items(WorkspaceSection.guests)
            .first
            .flagged,
        isTrue,
      );
      await tap('Seating');
      expect(find.text('Table Garden'), findsOneWidget);
      await capture('event-seating');
      await tap('Floor plan');
      expect(find.text('Stage'), findsOneWidget);
      await switchTo('Church');
      await tap('Units');
      await tap('Welcome team');
      await tap('Prepare welcome packs');
      expect(
        container
            .read(localWorkspacesProvider)
            .requireValue
            .active!
            .items(WorkspaceSection.units)
            .single
            .todos['Prepare welcome packs'],
        isTrue,
      );
      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();
      await switchTo('Alumni');
      await tap('Polls');
      await tap('Saturday');
      expect(
        container
            .read(localWorkspacesProvider)
            .requireValue
            .active!
            .items(WorkspaceSection.poll)
            .single
            .vote,
        0,
      );
      await switchTo('Estate');
      await tap('Gate passes');
      await tap('Delivery to House 12');
      await tap('Check visitor in');
      await switchTo('Committee');
      await tap('Decisions');
      await tap('Approve');
      await switchTo('Club');
      await tap('Attendance');
      await tap('Taylor');
      expect(find.text('Saturday training'), findsWidgets);
      expect(tester.takeException(), isNull);
    },
  );
}

class _TestDownloads extends FilePickerPlatform {
  Uint8List? bytes;
  @override
  Future<Uri?> saveFile({
    required String fileName,
    required Uint8List bytes,
    required String mimeType,
    String? dialogTitle,
    String? initialDirectory,
    Function(FilePickerStatus)? onFileSaving,
    WindowsOptions windowsOptions = const WindowsOptions(),
    LinuxOptions linuxOptions = const LinuxOptions(),
    WebOptions webOptions = const WebOptions(),
  }) async {
    this.bytes = bytes;
    return null;
  }
}
