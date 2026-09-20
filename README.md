# Berani Bicara

Aplikasi Flutter (Android & iOS) untuk pencegahan dan penanganan perundungan di sekolah, dengan klien perdana **SDN Kaliasin 1 Surabaya**. Siswa dapat melapor secara aman; guru (wali kelas), Tim Penanganan dan Pencegahan Kekerasan (TPPK), dan admin mengelola laporan, sosialisasi, dan cerita kelas.

Versi aplikasi: **2.0.0+7** (`pubspec.yaml`).

## Fitur

- **Auth:** email/password, Google Sign-In, reset password, verifikasi NISN (siswa), syarat & privasi
- **Peran:** siswa, guru (wali kelas), TPPK, admin — dashboard dan hak akses berbeda
- **Laporan:** buat/edit (status Baru), lampiran bukti, anonim, status, chat balasan TPPK, log penanganan
- **Sosialisasi:** materi edukasi dari TPPK
- **Cerita kelas:** untuk wali kelas dan siswa di kelasnya
- **Notifikasi:** in-app dan push (setup terpisah, tidak didokumentasikan di sini)
- **Admin:** pengguna, kelas, statistik, pengaturan (versi, tautan legal, cache)

## Teknologi

| Bagian | Stack |
| --- | --- |
| App | Flutter, Dart, Provider, go_router |
| Backend | Supabase (Auth, PostgreSQL + RLS, Storage, Realtime) |
| Push | Firebase Cloud Messaging |
| Cache lokal | Hive |

Struktur kode: **Clean Architecture** per fitur di `lib/features/` (data / domain / presentation), `lib/core/` dan `lib/shared/`.

## Menjalankan lokal

```sh
git clone https://github.com/wannn-one/beranibicara.git
cd beranibicara
flutter pub get
```

Salin `.env.example` menjadi `.env` (file ini tidak di-commit):

```
SUPABASE_URL=
SUPABASE_ANON_KEY=
GOOGLE_CLIENT_ID=
TERMS_OF_USE_URL=https://beranibicara.site/terms-of-service
PRIVACY_POLICY_URL=https://beranibicara.site/privacy-policy
```

Untuk Android, siapkan `android/app/google-services.json` (gitignored). Contoh keystore: `android/key.properties.example`.

```sh
flutter run
```

Deep link auth: `com.beranibicara.app://callback`.

Skema database, RLS, dan seed **tidak dipublikasikan** di README. Tim yang maintain backend memakai salinan SQL lokal / SQL Editor Supabase.

## Deep link & paket

- Application ID Android: `com.beranibicara.app`
- Legal: [Syarat penggunaan](https://beranibicara.site/terms-of-service) · [Kebijakan privasi](https://beranibicara.site/privacy-policy)

---

Dibuat untuk lingkungan belajar yang lebih aman.