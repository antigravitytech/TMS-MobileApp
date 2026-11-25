import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

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

    return MaterialApp.router(
      debugShowCheckedModeBanner: false,
      themeMode: ref.watch(
        workspacePreviewProvider.select((state) => state.theme),
      ),
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
