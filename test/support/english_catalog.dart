import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/widgets.dart';

/// Loads the real catalog before the test enters its fake animation clock.
class EnglishCatalog extends AssetLoader {
  const EnglishCatalog(this.messages);
  final Map<String, dynamic> messages;
  static Future<EnglishCatalog> preload() async => EnglishCatalog(
    (await const RootBundleAssetLoader().load(
      'assets/translations',
      const Locale('en'),
    ))!,
  );
  @override
  Future<Map<String, dynamic>> load(String path, Locale locale) async =>
      messages;
}
