# Berani Bicara App 🚀

Aplikasi mobile lintas platform (Android & iOS) yang dibangun dengan Flutter untuk membantu pencegahan dan penanganan kasus perundungan (bullying) di lingkungan sekolah terkhusus SDN Kaliasin 1 Surabaya. Proyek ini bertujuan untuk memberdayakan siswa agar berani bicara dan menyediakan kanal yang aman bagi mereka untuk melapor kepada tim TPPK sekolah.

## ✨ Fitur Utama

* **Autentikasi Aman:** Pendaftaran dan Login menggunakan Email/Password dan Google Sign-In.
* **Sistem Peran Pengguna:** Alur yang berbeda untuk Siswa, Guru (Wali Kelas), dan Admin (TPPK).
* **Pelengkapan Profil:** Alur onboarding bagi siswa baru untuk melengkapi data diri, termasuk pemilihan kelas.
* **Dashboard Sesuai Peran:** Tampilan dashboard yang disesuaikan dengan hak akses setiap peran pengguna.
* **(Dalam Pengembangan) Pelaporan Insiden:** Form untuk melaporkan kejadian perundungan secara detail.
* **(Dalam Pengembangan) Pelacakan Status Laporan:** Siswa dapat memantau status laporan yang mereka kirimkan.
* **(Dalam Pengembangan) Konten Edukasi:** Halaman berisi materi sosialisasi dan edukasi dari tim TPPK.

## 🛠️ Teknologi yang Digunakan

* **Frontend:** Flutter
* **Backend & Database:** Supabase
    * **Authentication:** Supabase GoTrue
    * **Database:** PostgreSQL
    * **Security:** Row Level Security (RLS)
* **Bahasa:** Dart, SQL

## 🚀 Memulai (Getting Started)

Untuk menjalankan proyek ini secara lokal, ikuti langkah-langkah berikut:

1.  **Clone repository ini:**
    ```sh
    git clone https://github.com/wannn-one/beranibicara.git
    cd beranibicara
    ```

2.  **Install dependencies Flutter:**
    ```sh
    flutter pub get
    ```

3.  **Setup Backend Supabase:**
    * Buat proyek baru di [Supabase](https://supabase.com/).
    * Jalankan skrip SQL yang ada di folder `/database` (Anda bisa buat folder ini) untuk membuat tabel dan RLS policies.
    * Isi tabel `kelas` dengan data awal menggunakan skrip seeder.

4.  **Konfigurasi Environment Variables:**
    * Buat file `.env` di direktori utama proyek.
    * Isi file tersebut dengan kredensial Supabase dan Google Client ID Anda:
        ```
        SUPABASE_URL=URL_PROYEK_ANDA
        SUPABASE_ANON_KEY=ANON_KEY_ANDA
        GOOGLE_CLIENT_ID=WEB_CLIENT_ID_ANDA
        ```

5.  **Jalankan aplikasi:**
    ```sh
    flutter run
    ```

## 🎯 Status Proyek

Proyek ini sedang dalam tahap pengembangan aktif dengan target penyelesaian pada **Oktober 2025**.

---
*Dibuat dengan ❤️ untuk lingkungan belajar yang lebih baik.*