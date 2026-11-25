import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/widgets.dart';

import '../core/network/api_response.dart';

extension NetworkFailureLocalization on NetworkFailureType {
  String get translationKey => 'network.errors.$name';

  String localizedMessage(BuildContext context) => context.tr(translationKey);
}
