import 'package:intl/intl.dart';

class DateTimeUtils {
  // Timezone offset untuk WIB (UTC+7)
  static const int wibOffsetHours = 7;
  
  /// Konversi UTC timestamp dari database ke WIB
  static DateTime parseUtcToWib(String utcTimestamp) {
    // Parse sebagai UTC
    final utcDateTime = DateTime.parse(utcTimestamp).toUtc();
    
    // Konversi ke WIB (UTC+7)
    final wibDateTime = utcDateTime.add(Duration(hours: wibOffsetHours));
    
    return wibDateTime;
  }
  
  /// Format DateTime ke string dengan format Indonesia
  static String formatToIndonesian(DateTime dateTime, {String pattern = 'd MMM yyyy, HH:mm'}) {
    try {
      // Gunakan locale Indonesia yang sudah diinisialisasi
      final formatter = DateFormat(pattern, 'id_ID');
      return formatter.format(dateTime);
    } catch (e) {
      // Fallback ke locale default jika ada error
      final formatter = DateFormat(pattern);
      return formatter.format(dateTime);
    }
  }
  
  /// Format UTC timestamp dari database ke string Indonesia
  static String formatUtcToIndonesian(String utcTimestamp, {String pattern = 'd MMM yyyy, HH:mm'}) {
    final wibDateTime = parseUtcToWib(utcTimestamp);
    return formatToIndonesian(wibDateTime, pattern: pattern);
  }
  
  /// Format untuk tampilan "waktu lalu" (relative time)
  static String getTimeAgo(String utcTimestamp) {
    final wibDateTime = parseUtcToWib(utcTimestamp);
    final now = DateTime.now();
    final difference = now.difference(wibDateTime);
    
    if (difference.inDays > 0) {
      return '${difference.inDays} hari lalu';
    } else if (difference.inHours > 0) {
      return '${difference.inHours} jam lalu';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes} menit lalu';
    } else {
      return 'Baru saja';
    }
  }
  
  /// Mendapatkan DateTime WIB saat ini untuk insert ke database
  static String getCurrentUtcForDatabase() {
    final now = DateTime.now();
    // Kurangi 7 jam untuk mendapatkan UTC dari WIB
    final utc = now.subtract(Duration(hours: wibOffsetHours));
    return utc.toIso8601String();
  }
}
