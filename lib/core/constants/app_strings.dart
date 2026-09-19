/// App-wide string constants
class AppStrings {
  AppStrings._(); // Private constructor

  // App Info
  static const String appName = 'Berani Bicara';
  static const String appTagline = 'Speak Up, We Listen';

  // Auth Strings
  static const String login = 'Log In';
  static const String register = 'Sign Up';
  static const String logout = 'Logout';
  static const String email = 'Email';
  static const String password = 'Password';
  static const String fullName = 'Full Name';
  static const String confirmPassword = 'Confirm Password';
  static const String forgotPassword = 'Forgot Password?';
  static const String dontHaveAccount = "Don't have an account?";
  static const String alreadyHaveAccount = 'Already have an account?';
  static const String continueWithGoogle = 'Continue with Google';
  static const String or = 'OR';

  // NISN Verification
  static const String nisn = 'NISN';
  static const String nisnRequired = 'NISN (wajib untuk siswa)';
  static const String nisnOptional = 'NISN (Optional for Students)';
  static const String nisnHint = 'Enter your 10-digit NISN';
  static const String agreeToLegal =
      'Saya setuju dengan Ketentuan Penggunaan dan Kebijakan Privasi';
  static const String termsOfUse = 'Ketentuan Penggunaan';
  static const String privacyPolicy = 'Kebijakan Privasi';
  static const String acceptLegalToContinue =
      'Centang persetujuan kebijakan untuk melanjutkan';
  static const String nisnVerifying = 'Verifying NISN...';
  static const String nisnValid = 'NISN verified!';
  static const String nisnInvalid = 'NISN not registered';
  static const String nisnAlreadyUsed = 'NISN already used';
  static const String skipNisn = 'Skip (for Teachers)';

  // Role Selection
  static const String selectRole = 'Register as:';
  static const String roleSiswa = 'Student';
  static const String roleGuru = 'Teacher';
  static const String roleTPPK = 'TPPK';
  static const String roleAdmin = 'Admin';

  // Complete Profile
  static const String completeProfile = 'Complete Your Profile';
  static const String selectClass = 'Select Your Class';
  static const String selectTingkat = 'Select Grade';
  static const String selectJurusan = 'Select Major';
  static const String save = 'Save';
  static const String saveAndContinue = 'Save & Continue';

  // Dashboard
  static const String dashboard = 'Dashboard';
  static const String welcome = 'Welcome';
  static const String myReports = 'My Reports';
  static const String createReport = 'Create Report';
  static const String createNewReport = 'Create New Report';
  static const String noReports = 'No reports yet';

  // Reports
  static const String reportTitle = 'Report Title';
  static const String reportDescription = 'Description';
  static const String reportStatus = 'Status';
  static const String reportAnonymous = 'Report Anonymously';
  static const String uploadEvidence = 'Upload Evidence';
  static const String evidenceOptional = 'Evidence (Optional)';
  static const String maxFiles = 'Maximum 3 files';
  static const String maxFileSize = 'Maximum 10MB per file';
  
  // Report Status
  static const String statusNew = 'New';
  static const String statusProcessing = 'Processing';
  static const String statusCompleted = 'Completed';
  static const String statusRejected = 'Rejected';
  static const String statusSpam = 'Spam';

  // Socialization
  static const String socialization = 'Socialization';
  static const String socializationList = 'Articles & Announcements';
  static const String createSocialization = 'Create Article';
  static const String publishedAt = 'Published';
  static const String draft = 'Draft';

  // Cerita Kelas
  static const String ceritaKelas = 'Class Stories';
  static const String createCerita = 'Share Your Story';
  static const String publicStory = 'Public Story';
  static const String classOnlyStory = 'Class Only';

  // Common Actions
  static const String submit = 'Submit';
  static const String cancel = 'Cancel';
  static const String delete = 'Delete';
  static const String edit = 'Edit';
  static const String view = 'View';
  static const String update = 'Update';
  static const String confirm = 'Confirm';
  static const String close = 'Close';
  static const String ok = 'OK';
  static const String yes = 'Yes';
  static const String no = 'No';
  static const String back = 'Back';
  static const String next = 'Next';
  static const String retry = 'Retry';
  static const String refresh = 'Refresh';

  // Error Messages
  static const String errorGeneric = 'An error occurred';
  static const String errorNetwork = 'Network error. Please check your connection.';
  static const String errorServer = 'Server error. Please try again later.';
  static const String errorAuth = 'Authentication failed';
  static const String errorInvalidEmail = 'Invalid email address';
  static const String errorInvalidPassword = 'Password must be at least 6 characters';
  static const String errorPasswordMismatch = 'Passwords do not match';
  static const String errorFieldRequired = 'This field is required';
  static const String errorAllFieldsRequired = 'All fields are required';
  static const String errorFileSize = 'File size exceeds maximum limit';
  static const String errorFileType = 'Invalid file type';

  // Success Messages
  static const String successRegistration = 'Registration successful! Please check your email for verification.';
  static const String successLogin = 'Login successful';
  static const String successLogout = 'Logged out successfully';
  static const String successReportCreated = 'Report created successfully';
  static const String successProfileUpdated = 'Profile updated successfully';

  // Loading Messages
  static const String loading = 'Loading...';
  static const String pleaseWait = 'Please wait...';
  static const String processing = 'Processing...';

  // Warnings
  static const String warning = 'Warning';
  static const String warningUnsavedChanges = 'You have unsaved changes. Continue?';
  static const String warningDeleteReport = 'Are you sure you want to delete this report?';
}
