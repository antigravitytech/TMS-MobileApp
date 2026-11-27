import 'package:url_launcher/url_launcher.dart';

class BrowserService {
  static Future<bool> open(Uri url) =>
      launchUrl(url, mode: LaunchMode.externalApplication);
}
