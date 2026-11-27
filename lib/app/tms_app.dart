import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/config/environment.dart';
import '../modules/authentication/application/account_session.dart';
import '../modules/workspace/application/workspace_preview.dart';
import '../router/router_config.dart';
import '../theme/tms_theme.dart';

class TmsApp extends StatelessWidget {
  const TmsApp({super.key, this.assetLoader = const RootBundleAssetLoader()});

  final AssetLoader assetLoader;

  static const _english = Locale('en');
  static const _supportedLocales = [_english];

  @override
  Widget build(BuildContext context) => EasyLocalization(
    supportedLocales: _supportedLocales,
    fallbackLocale: _english,
    useFallbackTranslations: true,
    path: 'assets/translations',
    assetLoader: assetLoader,
    child: const _LocalizedApp(),
  );
}

class _LocalizedApp extends ConsumerWidget {
  const _LocalizedApp();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(routerConfigProvider);
    final mode = ref.watch(environmentProvider).isLive
        ? switch (ref.watch(
            accountSessionProvider.select((account) => account?.theme),
          )) {
            'light' => ThemeMode.light,
            'dark' => ThemeMode.dark,
            _ => ThemeMode.system,
          }
        : ref.watch(workspacePreviewProvider.select((state) => state.theme));

    return MaterialApp.router(
      debugShowCheckedModeBanner: false,
      themeMode: mode,
      onGenerateTitle: (context) => context.tr('app.title'),
      routerConfig: router.config(),
      locale: context.locale,
      localizationsDelegates: context.localizationDelegates,
      supportedLocales: context.supportedLocales,
      theme: TmsTheme.light,
      darkTheme: TmsTheme.dark,
    );
  }
}
