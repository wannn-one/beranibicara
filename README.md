# Berani Bicara App 🚀

**Status: V1 Complete ✅ (Android Tested)**

Aplikasi mobile lintas platform yang dibangun dengan Flutter untuk membantu pencegahan dan penanganan kasus perundungan (bullying) di lingkungan sekolah terkhusus SDN Kaliasin 1 Surabaya. Proyek ini bertujuan untuk memberdayakan siswa agar berani bicara dan menyediakan kanal yang aman bagi mereka untuk melapor kepada tim TPPK sekolah.

> **📱 Platform Support**: V1 telah diuji dan berjalan dengan baik di **Android**. iOS support tersedia secara teoritis (Flutter cross-platform) namun belum diuji karena keterbatasan development environment (Windows-based development).

## ✨ Fitur Utama V1

### 🔐 Sistem Autentikasi & Manajemen Pengguna
* **Autentikasi Multi-Method:** Email/Password dan Google Sign-In
* **Sistem Peran Pengguna:** Tiga peran dengan hak akses berbeda (Siswa, Guru, Admin TPPK)
* **Pelengkapan Profil:** Onboarding lengkap dengan pemilihan kelas untuk siswa
* **Manajemen Password:** Reset password, ubah password, dan verifikasi email

### 👨‍🎓 Fitur Siswa
* **Dashboard Siswa:** Tampilan ringkasan laporan dan akses cepat ke fitur utama
* **Pelaporan Insiden:** Form lengkap untuk melaporkan kasus bullying dengan opsi anonim/semi-anonim
* **Upload Bukti:** Kemampuan mengunggah foto/video sebagai bukti laporan
* **Pelacakan Laporan:** Monitor status dan progress laporan yang telah dibuat
* **Mading Kelas:** Buat dan lihat cerita/pengalaman positif di kelas
* **Konten Edukasi:** Akses materi sosialisasi anti-bullying dari tim TPPK

### 👨‍🏫 Fitur Guru (Wali Kelas)
* **Dashboard Guru:** Overview laporan dari siswa di kelas yang diampu
* **Manajemen Siswa:** Lihat daftar siswa di kelas
* **Review Laporan:** Akses dan tindak lanjut laporan dari siswa kelas
* **Mading Kelas:** Moderasi dan kelola konten mading kelas

### 👨‍💼 Fitur Admin (TPPK)
* **Dashboard Admin:** Statistik lengkap dan overview semua laporan
* **Kelola Laporan:** Review, proses, dan berikan tanggapan terhadap semua laporan
* **Kelola Pengguna:** Manajemen akun siswa, guru, dan admin
* **Kelola Konten:** Buat dan kelola materi edukasi/sosialisasi
* **Mading Kelas:** Supervisi konten mading dari semua kelas
* **Notifikasi Real-time:** Sistem notifikasi push untuk laporan baru

### 🔔 Fitur Sistem
* **Notifikasi Push:** Firebase Cloud Messaging untuk update real-time
* **Storage Aman:** Upload dan penyimpanan file bukti dengan keamanan tinggi
* **Row Level Security:** Keamanan data tingkat baris di database
* **Responsive Design:** UI yang optimal untuk berbagai ukuran layar

## 📱 Screenshots & Demo

> **Coming Soon**: Screenshots dan video demo akan ditambahkan untuk menunjukkan fitur-fitur utama aplikasi.

### Planned Screenshots:
- [ ] Login & Registration Flow
- [ ] Student Dashboard & Report Creation
- [ ] Teacher Dashboard & Report Management  
- [ ] Admin Dashboard & Analytics
- [ ] Mading Kelas Interface
- [ ] Push Notification Examples

## 🛠️ Teknologi yang Digunakan

### Frontend
* **Framework:** Flutter 3.35.0+
* **Language:** Dart
* **UI Components:** Material Design dengan custom fonts (League Spartan, Lily Script One)
* **State Management:** Built-in Flutter state management

### Backend & Database
* **Backend-as-a-Service:** Supabase
* **Database:** PostgreSQL dengan Row Level Security (RLS)
* **Authentication:** Supabase GoTrue + Google Sign-In
* **Storage:** Supabase Storage untuk file upload
* **Real-time:** Supabase Realtime untuk notifikasi
* **Edge Functions:** Deno/TypeScript untuk webhook dan notifikasi

### Dependencies Utama
```yaml
# Core
flutter: sdk
supabase_flutter: ^2.5.0
google_sign_in: ^6.2.1

# UI & UX
font_awesome_flutter: ^10.7.0
fl_chart: ^0.68.0
cached_network_image: ^3.3.1
pinput: ^4.0.0

# Utilities
flutter_dotenv: ^5.1.0
url_launcher: ^6.3.0
intl: ^0.19.0
image_picker: ^1.1.2
path_provider: ^2.1.3

# Firebase & Notifications
firebase_core: ^2.24.2
firebase_messaging: ^14.7.10

# Network & Permissions
dio: ^5.4.3+1
permission_handler: ^11.3.1
device_info_plus: ^10.1.0
```

### Keamanan & Compliance
* **Row Level Security (RLS):** Keamanan tingkat baris untuk semua tabel
* **JWT Authentication:** Token-based authentication dengan refresh token
* **Data Encryption:** Enkripsi data sensitif di database
* **File Upload Security:** Validasi dan sanitasi file upload
* **Anonymous Reporting:** Sistem pelaporan anonim yang aman

## 🚀 Memulai (Getting Started)

### Prerequisites
* Flutter SDK 3.35.0 atau lebih baru
* Dart SDK
* Android Studio / VS Code dengan Flutter plugin
* Git
* **Android Development**: Android SDK, device/emulator untuk testing
* **iOS Development**: macOS, Xcode, iOS device/simulator (belum diuji)

### Instalasi Lokal

1. **Clone Repository**
   ```bash
   git clone https://github.com/wannn-one/beranibicara.git
   cd beranibicara
   ```

2. **Install Dependencies**
   ```bash
   flutter pub get
   ```

3. **Setup Supabase Backend**
   
   a. Buat proyek baru di [Supabase](https://supabase.com/)
   
   b. Jalankan script database lengkap:
   ```bash
   # Jalankan file init_complete.sql di SQL Editor Supabase Dashboard
   # File ini sudah berisi semua tabel, RLS policies, functions, dan seed data kelas
   ```
   
   c. Setup Storage Buckets di Supabase Dashboard:
   - Buat bucket `evidence` untuk file bukti laporan
   - Buat bucket `profile-pictures` untuk foto profil
   - Buat bucket `socialization-content` untuk konten edukasi
   - Buat bucket `cerita-images` untuk gambar cerita kelas

4. **Konfigurasi Environment Variables**
   
   Buat file `.env` di root directory:
   ```env
   SUPABASE_URL=https://your-project.supabase.co
   SUPABASE_ANON_KEY=your-anon-key
   GOOGLE_CLIENT_ID=your-google-client-id.apps.googleusercontent.com
   ```

5. **Setup Firebase (untuk Push Notifications)**
   
   a. Buat proyek di [Firebase Console](https://console.firebase.google.com/)
   
   b. **Android Setup**: Download `google-services.json` dan letakkan di `android/app/`
   
   c. **iOS Setup** (opsional untuk masa depan): Download `GoogleService-Info.plist` dan letakkan di `ios/Runner/`

6. **Setup Google Sign-In**
   
   a. Buat OAuth 2.0 Client IDs di [Google Cloud Console](https://console.cloud.google.com/)
   
   b. Tambahkan SHA-1 fingerprint untuk Android
   
   c. Update `GOOGLE_CLIENT_ID` di file `.env`

7. **Jalankan Aplikasi**
   ```bash
   # Debug mode (Android - tested)
   flutter run
   
   # Release mode (Android - tested)
   flutter run --release
   
   # Platform specific
   flutter run -d android    # ✅ Tested & Working
   flutter run -d ios        # ⚠️ Untested (requires macOS)
   ```

### Setup Development Environment (Opsional)

Untuk development dengan Supabase local:

1. **Install Supabase CLI**
   ```bash
   npm install -g supabase
   ```

2. **Start Local Supabase**
   ```bash
   supabase start
   ```

3. **Update .env untuk local development**
   ```env
   SUPABASE_URL=http://127.0.0.1:54321
   SUPABASE_ANON_KEY=your-local-anon-key
   ```

## 📱 Platform Support & Testing Status

### ✅ **Android (Fully Tested)**
- **Development Environment**: Windows 11 + Android Studio
- **Testing Devices**: Android Emulator & Physical Device
- **Status**: Semua fitur telah diuji dan berfungsi dengan baik
- **Build**: APK dan AAB telah berhasil di-generate

### ⚠️ **iOS (Theoretical Support)**
- **Development Environment**: Membutuhkan macOS + Xcode
- **Testing Status**: Belum diuji karena keterbatasan environment
- **Code Compatibility**: Flutter code sudah cross-platform ready
- **Firebase Setup**: Memerlukan `GoogleService-Info.plist` (belum dikonfigurasi)
- **Potential Issues**: Memerlukan setup Firebase iOS dan adjustment untuk iOS-specific features

### 🔄 **Future iOS Development**
Untuk development iOS di masa depan:
1. Akses ke macOS development environment
2. Testing di iOS Simulator dan physical device
3. App Store deployment preparation
4. iOS-specific UI/UX adjustments

## 📁 Struktur Proyek

```
beranibicara/
├── lib/
│   ├── main.dart                 # Entry point aplikasi
│   ├── screens/                  # UI Screens
│   │   ├── auth/                # Authentication screens
│   │   ├── student/             # Student-specific screens
│   │   ├── teacher/             # Teacher-specific screens
│   │   ├── admin/               # Admin-specific screens
│   │   ├── splash.dart          # Splash screen
│   │   └── welcome.dart         # Welcome screen
│   ├── services/                # Business logic & services
│   │   ├── fcm_service.dart     # Firebase Cloud Messaging
│   │   ├── firebase_background_handler.dart
│   │   └── image_download_service.dart
│   └── widgets/                 # Reusable UI components
├── database/                    # SQL migration files
│   ├── 01_init.sql             # Initial database schema
│   ├── 02_user_policies_trigger.sql
│   ├── ...                     # Sequential migration files
│   └── 23_storage_policies.sql
├── supabase/                   # Supabase configuration
│   ├── config.toml             # Local development config
│   └── functions/              # Edge functions
├── assets/                     # Static assets
│   ├── fonts/                  # Custom fonts
│   └── images/                 # App images & logos
├── android/                    # Android-specific files
├── ios/                        # iOS-specific files
└── pubspec.yaml               # Flutter dependencies
```

### Key Directories

- **`lib/screens/`**: Semua UI screens diorganisir berdasarkan peran pengguna
- **`lib/services/`**: Business logic, API calls, dan service classes
- **`database/`**: SQL migration files untuk setup database Supabase
- **`supabase/functions/`**: Edge functions untuk webhook dan notifikasi
- **`assets/`**: Font custom dan gambar aplikasi

## 🎯 Status Proyek

**✅ V1 Complete - Oktober 2024**

Proyek V1 telah selesai dengan semua fitur inti yang direncanakan:
- ✅ Sistem autentikasi lengkap
- ✅ Dashboard untuk semua peran pengguna
- ✅ Sistem pelaporan dengan upload bukti
- ✅ Notifikasi real-time
- ✅ Mading kelas dan konten edukasi
- ✅ Row Level Security dan keamanan data

## 🤝 Contributing

Kami menyambut kontribusi dari komunitas! Berikut cara berkontribusi:

1. **Fork** repository ini
2. **Create** feature branch (`git checkout -b feature/AmazingFeature`)
3. **Commit** perubahan Anda (`git commit -m 'Add some AmazingFeature'`)
4. **Push** ke branch (`git push origin feature/AmazingFeature`)
5. **Open** Pull Request

### Development Guidelines
- Ikuti [Flutter Style Guide](https://dart.dev/guides/language/effective-dart/style)
- Tulis unit tests untuk fitur baru
- Update dokumentasi jika diperlukan
- Pastikan semua tests pass sebelum submit PR

## 📝 License

Proyek ini dilisensikan di bawah MIT License - lihat file [LICENSE](LICENSE) untuk detail.

## 🙏 Acknowledgments

- **SDN Kaliasin 1 Surabaya** - Partner sekolah untuk implementasi
- **Tim TPPK** - Konsultasi dan feedback fitur
- **Flutter Community** - Framework dan packages yang luar biasa
- **Supabase** - Backend-as-a-Service yang powerful

## 📞 Contact & Support

- **Developer**: [Ikhwanul Abiyu](mailto:ikhwanulabiyu@gmail.com)
- **Project Repository**: [GitHub](https://github.com/wannn-one/beranibicara)
- **Issues**: [GitHub Issues](https://github.com/wannn-one/beranibicara/issues)

## 🔮 Roadmap V2

Fitur TPPK yang direncanakan untuk versi mendatang:

### 📊 **Analytics & Monitoring**
- [ ] **Peta Risiko & Monitoring** - Mapping area rawan kekerasan berbasis data
- [ ] **Analisis Tren Kasus** - Dashboard analitik mendalam dengan machine learning
- [ ] **Evaluasi Kinerja TPPK** - Sistem penilaian efektivitas program
- [ ] **Laporan Kinerja Bulanan/Tahunan** - Generator report otomatis

### 🏥 **Layanan Dukungan**
- [ ] **Profil & Data TPPK** - Halaman informasi lengkap tim TPPK
- [ ] **Jadwal Konseling** - Sistem penjadwalan layanan psikologis
- [ ] **Hotline Darurat** - Integrasi dengan layanan eksternal
- [ ] **Chat Support** real-time dengan konselor

### 📋 **Administrasi & Dokumentasi**
- [ ] **Dokumentasi & Arsip Kasus** - Sistem arsip komprehensif
- [ ] **Template Dokumen Resmi** - Generator dokumen standar TPPK
- [ ] **Backup Otomatis** - Sistem backup terjadwal

### 🔗 **Integrasi & Ekspansi**
- [ ] **Integrasi dengan LMS Sekolah** (SIAKAD) - Sinkronisasi data siswa
- [ ] **Parent Portal** - Portal khusus orang tua siswa
- [ ] **Multi-language Support** (Bahasa Indonesia & English)
- [ ] **Offline Mode** - Akses tanpa internet
- [ ] **Gamification** - Sistem reward untuk pelaporan positif

---
*Dibuat dengan ❤️ untuk lingkungan belajar yang lebih aman dan lebih baik.*

**"Berani Bicara, Berani Berubah"** 🗣️✨