## QUIZZAR
QuizZAR merupakan aplikasi kuis pengetahuan umum berbasis Android yang dikembangkan menggunakan Flutter. Aplikasi ini dirancang untuk membantu pengguna menguji dan meningkatkan pengetahuan umum melalui soal pilihan ganda yang interaktif.

Selain fitur kuis, aplikasi juga menyediakan pengelolaan soal (CRUD), autentikasi pengguna, penyimpanan riwayat pengerjaan kuis, serta berbagai fitur tambahan seperti dark mode, audio feedback, dan animasi interaktif.

---

## Fitur Utama

#### Autentikasi Pengguna
- Register akun
- Login akun
- Logout

### Kelola Soal (CRUD)
- Tambah soal
- Lihat daftar soal
- Edit soal
- Hapus soal
- Pencarian soal

### Sistem Quiz
- Pemilihan jumlah soal
- Soal ditampilkan secara acak
- Progress bar pengerjaan
- Validasi jawaban otomatis
- Perhitungan skor otomatis
- Popup hasil kuis

### Riwayat Quiz
- Menyimpan hasil kuis
- Menampilkan riwayat pengerjaan
- Menampilkan tanggal dan skor

### Fitur Tambahan
- Dark Mode & Light Mode
- Audio feedback jawaban benar/salah
- Animasi Lottie
- Animasi Confetti

---

## Teknologi yang Digunakan
| Teknologi | Kegunaan |
|------------|-----------|
| Flutter | Framework aplikasi mobile |
| Dart | Bahasa pemrograman |
| SQLite (sqflite) | Penyimpanan data soal |
| SharedPreferences | Penyimpanan akun, sesi login, dan riwayat |
| Provider | State Management |
| Audioplayers | Efek suara |
| Lottie | Animasi |
| Confetti | Animasi perayaan |

---

## Struktur Proyek

```text
lib/
├── models/
├── providers/
├── services/
├── screens/
├── widgets/
└── main.dart
```

---

---

## Cara Menjalankan Aplikasi
### 1. Clone Repository
```bash
git clone https://github.com/username/QuizZAR.git
```
### 2. Masuk ke Folder Project
```bash
cd QuizZAR
```
### 3. Install Dependency
```bash
flutter pub get
```
### 4. Jalankan Aplikasi
```bash
flutter run
```
---

## Persyaratan
- Flutter SDK 3.x
- Dart SDK 3.x
- Android Studio / VS Code
- Android Emulator atau perangkat Android
---

## Tim Pengembang
Kelompok 4
- Zaki Maulana (24091397062)
- Azkiya Azimi(24091397046)  
- Reva Anindya Octavina (24091397042)
---

## 📄 Lisensi
Proyek ini dibuat untuk memenuhi tugas Ujian Akhir Semester Mata Kuliah Pemrograman Mobile.



This project is a starting point for a Flutter application.

A few resources to get you started if this is your first Flutter project:

- [Learn Flutter](https://docs.flutter.dev/get-started/learn-flutter)
- [Write your first Flutter app](https://docs.flutter.dev/get-started/codelab)
- [Flutter learning resources](https://docs.flutter.dev/reference/learning-resources)

For help getting started with Flutter development, view the
[online documentation](https://docs.flutter.dev/), which offers tutorials,
samples, guidance on mobile development, and a full API reference.
