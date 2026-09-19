import 'package:intl/intl.dart';
import 'package:beranibicara/core/constants/app_constants.dart';

final DateFormat _dateTimeFormat = DateFormat(AppConstants.dateTimeFormat);
final DateFormat _dateFormat = DateFormat(AppConstants.dateFormat);

/// Formats a UTC timestamp from Supabase in the device timezone (WIB = UTC+7).
String formatAppDateTime(DateTime dateTime) {
  return _dateTimeFormat.format(dateTime.toLocal());
}

String formatAppDate(DateTime dateTime) {
  return _dateFormat.format(dateTime.toLocal());
}
