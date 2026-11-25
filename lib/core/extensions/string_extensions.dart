import 'dart:developer';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

extension StringExtensions on String {
  String? get capitalizeFirst {
    if (isEmpty) return null;
    return '${this[0].toUpperCase()}${substring(1)}';
  }

  void logInfo({String? name}) =>
      kDebugMode ? log(this, name: name ?? '') : null;

  /// Returns value if it is not empty or 'null', else returns null
  String? get valueOrNull {
    if (isEmpty || this == 'null') return null;
    return this;
  }

  String toTitleCase() => split(' ').map((e) => e.capitalizeFirst).join(' ');
}

extension XDateFormatters on String {
  ///Converts a date string to inputed format [default is yyyy-MM-dd]
  ///
  ///Returns [DateTime.now] if the string cannot be parsed as [DateTime] object
  String changeDateFormat([String format = "yyyy-MM-dd"]) {
    bool isSupportedDate = DateTime.tryParse(this) != null;

    if (!isSupportedDate) {
      final formatedDate = DateFormat(format).format(DateTime.now());
      return formatedDate;
    }

    DateTime dateTime = DateTime.parse(this).toLocal();
    return DateFormat(format).format(dateTime);
  }

  DateTime toDateTime() {
    bool isSupportedDate = DateTime.tryParse(this) != null;
    if (!isSupportedDate) return DateTime.now();
    return DateTime.parse(this);
  }

  /// Parses a 24-hour time string back into a [TimeOfDay].
  ///
  /// Handles formats produced by [to24HourFormat] as well as backend ISO
  /// time strings, e.g. "08:00", "08:00:00", "08:00:00Z".
  /// Returns [TimeOfDay.now] if the string cannot be parsed.
  TimeOfDay get from24HourFormat {
    try {
      // Strip trailing 'Z' (UTC marker) and split on ':'
      final parts = replaceAll('Z', '').split(':');
      if (parts.length < 2) return TimeOfDay.now();
      final hour = int.parse(parts[0]);
      final minute = int.parse(parts[1]);
      return TimeOfDay(hour: hour, minute: minute);
    } catch (_) {
      return TimeOfDay.now();
    }
  }

  /// Returns a [DateTime] object from a time string.
  ///
  /// Handles formats produced by [to24HourFormat] as well as backend ISO
  /// time strings, e.g. "08:00", "08:00:00", "08:00:00Z".
  /// Returns [DateTime.now] if the string cannot be parsed.
  DateTime get timeToDateTime {
    try {
      final parts = split(':');
      final hour = int.parse(parts[0]);
      final minute = int.parse(parts[1]);
      final now = DateTime.now();
      return DateTime(now.year, now.month, now.day, hour, minute);
    } catch (_) {
      return DateTime.now();
    }
  }
}

extension NullableStringExtensions on String? {
  String orDash() => this?.trim().isNotEmpty == true ? this! : '—';
}
