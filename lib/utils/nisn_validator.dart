class NISNValidator {
  // Regex untuk validasi format NISN
  // NISN_REGEX[0] = NISN has 10 digits
  // NISN_REGEX[1] = 3 digits of Birth Year in YYY format (eg: 2002 => 002)
  // NISN_REGEX[2] = 3 digits of Grouping
  // NISN_REGEX[3] = 4 digits of Index
  static final RegExp _nisnRegex = RegExp(r'^(\d{3})(\d{3})(\d{4})$');
  
  // Total length of NISN
  static const int _nisnLength = 10;
  
  // Validity periode of NISN
  // Counted from 7 years (as child) + 6 years (as elementaryer) + 
  // 3 years (as mid schooler) + 3 years (high schooler) +
  // 3 years (margin of error, eg: grade retained, starting elementary from age of 8)
  static const int _nisnAgeValidity = 22;

  /// Validasi NISN berdasarkan format dan tahun lahir
  /// 
  /// [nisn] - NISN yang akan divalidasi (10 digit)
  /// Returns true jika NISN valid
  static bool isValid(String nisn) {
    if (nisn.isEmpty || nisn.length != _nisnLength) {
      return false;
    }

    // Hanya angka
    if (!RegExp(r'^\d+$').hasMatch(nisn)) {
      return false;
    }

    // Cek format dengan regex
    final match = _nisnRegex.firstMatch(nisn);
    if (match == null) {
      return false;
    }

    // Extract tahun lahir (3 digit pertama)
    final birthYearStr = match.group(1)!;
    
    // Validasi periode/tahun lahir
    return _isValidPeriod(birthYearStr);
  }

  /// Validasi periode/tahun lahir dari NISN
  /// 
  /// [year] - 3 digit tahun lahir dari NISN
  /// Returns true jika tahun lahir valid
  static bool _isValidPeriod(String year) {
    final thisYear = DateTime.now().year;
    final endYear = thisYear - _nisnAgeValidity;
    
    // Convert 3 digit year to full year
    int birthYear = int.parse(year) + 2000;
    
    // Handle century rollover (e.g., 002 could be 2002 or 1002)
    if (birthYear > thisYear) {
      birthYear = birthYear - 1000;
    }

    // Check if birth year is within valid range
    return birthYear >= endYear;
  }

  /// Validasi format NISN saja (tanpa cek tahun lahir)
  /// 
  /// [nisn] - NISN yang akan divalidasi
  /// Returns true jika format valid (10 digit angka)
  static bool isValidFormat(String nisn) {
    if (nisn.isEmpty) return false;
    
    // Hanya angka dan panjang 10 digit
    return RegExp(r'^\d{10}$').hasMatch(nisn);
  }

  /// Extract tahun lahir dari NISN
  /// 
  /// [nisn] - NISN yang valid
  /// Returns tahun lahir dalam format 4 digit (e.g., 2002)
  static int? extractBirthYear(String nisn) {
    if (!isValidFormat(nisn)) return null;
    
    final match = _nisnRegex.firstMatch(nisn);
    if (match == null) return null;
    
    final birthYearStr = match.group(1)!;
    int birthYear = int.parse(birthYearStr) + 2000;
    
    // Handle century rollover
    if (birthYear > DateTime.now().year) {
      birthYear = birthYear - 1000;
    }
    
    return birthYear;
  }

  /// Extract informasi dari NISN
  /// 
  /// [nisn] - NISN yang valid
  /// Returns Map dengan informasi NISN atau null jika invalid
  static Map<String, dynamic>? extractInfo(String nisn) {
    if (!isValid(nisn)) return null;
    
    final match = _nisnRegex.firstMatch(nisn);
    if (match == null) return null;
    
    final birthYear = extractBirthYear(nisn);
    final grouping = match.group(2)!;
    final index = match.group(3)!;
    
    return {
      'nisn': nisn,
      'birth_year': birthYear,
      'birth_year_short': match.group(1)!,
      'grouping': grouping,
      'index': index,
      'is_valid': true,
    };
  }

  /// Generate contoh NISN valid untuk testing
  /// 
  /// Returns NISN dengan tahun lahir yang valid
  static String generateSampleNISN() {
    final currentYear = DateTime.now().year;
    final validBirthYear = currentYear - 15; // 15 tahun yang lalu
    final birthYearShort = (validBirthYear % 1000).toString().padLeft(3, '0');
    
    // Generate random grouping dan index
    final grouping = (DateTime.now().millisecond % 1000).toString().padLeft(3, '0');
    final index = (DateTime.now().microsecond % 10000).toString().padLeft(4, '0');
    
    return '$birthYearShort$grouping$index';
  }
}

/// Extension untuk String untuk memudahkan validasi NISN
extension NISNValidation on String {
  /// Cek apakah string ini adalah NISN yang valid
  bool get isNISN => NISNValidator.isValid(this);
  
  /// Cek apakah string ini adalah format NISN yang valid
  bool get isNISNFormat => NISNValidator.isValidFormat(this);
  
  /// Extract informasi dari NISN
  Map<String, dynamic>? get nisnInfo => NISNValidator.extractInfo(this);
}
