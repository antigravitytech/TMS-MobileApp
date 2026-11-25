import 'package:intl/intl.dart';

extension XIntegerExtensions on int {
  /// 1000000 => 1,000,000
  /// 1000 => 1,000
  /// 1 => 1
  String get commaFormattedNumber => NumberFormat('#,##0').format(this);

  /// 1000000 => 1M
  /// 1000 => 1K
  /// 1 => 1
  /// 1200 => 1.2K
  String get compactDigit => NumberFormat.compact().format(this);

  String get numberToMonth {
    switch (this) {
      case 1:
        return 'January';
      case 2:
        return 'February';
      case 3:
        return 'March';
      case 4:
        return 'April';
      case 5:
        return 'May';
      case 6:
        return 'June';
      case 7:
        return 'July';
      case 8:
        return 'August';
      case 9:
        return 'September';
      case 10:
        return 'October';
      case 11:
        return 'November';
      case 12:
        return 'December';
      default:
        return '';
    }
  }
}

extension XDoubleExtensions on double {
  /// See [XIntegerExtensions.commaFormattedNumber]
  String get commaFormattedNumber => NumberFormat('#,##0').format(this);

  /// See [XIntegerExtensions.compactDigit]
  String get compactDigit => NumberFormat.compact().format(this);
}

extension XNumExtensions on num? {
  String formatAmount() {
    if (this == null) return '—';
    return NumberFormat('#,##0.##').format(this);
  }
}
