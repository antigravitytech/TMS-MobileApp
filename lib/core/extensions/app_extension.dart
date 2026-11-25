import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

// extension XLoader on StateStatus {
//   bool get isLoading => this == StateStatus.loading || this == StateStatus.initial;
//   bool get isError => this == StateStatus.error;
//   bool get isSuccess => this == StateStatus.success;
//   bool get isInitial => this == StateStatus.initial;
//   bool get isLoadMore => this == StateStatus.loadMore;
// }

extension DateTimeExtension on DateTime {
  String toFormattedString([String format = 'yyyy-MM-dd']) =>
      DateFormat(format).format(this);

  String get computeGreeting {
    if (hour < 12) {
      return 'Good Morning';
    } else if (hour < 16) {
      return 'Good Afternoon';
    } else {
      return 'Good Evening';
    }
  }

  String dateWithDateSuffix([String format = 'MMMM, yyyy']) {
    final day = this.day;
    final suffix = (day >= 11 && day <= 13)
        ? 'th'
        : switch (day % 10) {
            1 => 'st',
            2 => 'nd',
            3 => 'rd',
            _ => 'th',
          };

    return '$day$suffix ${DateFormat(format).format(this)}';
  }
}

extension XTime on TimeOfDay {
  String to12HourFormat({bool showMinute = true}) {
    final hour12 = hour % 12 == 0 ? 12 : hour % 12;
    final minuteStr = minute.toString().padLeft(2, '0');
    final ampm = hour < 12 ? 'AM' : 'PM';

    if (showMinute) {
      return '$hour12:$minuteStr $ampm';
    } else {
      return '$hour12 $ampm';
    }
  }

  String to24HourFormat({bool addSeconds = false}) {
    final hour24 = hour.toString().padLeft(2, '0');
    final minuteStr = minute.toString().padLeft(2, '0');
    return addSeconds ? '$hour24:$minuteStr:00' : '$hour24:$minuteStr';
  }

  DateTime toDateTime() {
    final date = DateTime.now();
    return DateTime(date.year, date.month, date.day, hour, minute);
  }
}

extension XColor on Color {
  String toHex() {
    return '#${(toARGB32() & 0xFFFFFF).toRadixString(16).padLeft(6, '0').toUpperCase()}';
  }
}
